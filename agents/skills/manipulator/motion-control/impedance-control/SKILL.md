---
name: impedance-control
description: 机械臂阻抗控制技能 - 位置控制、力控制、混合力位控制、柔顺控制、碰撞检测
argument-hint: 机械臂力控 OR 阻抗控制 OR 力位混合 OR 柔顺控制 OR impedance control
user-invocable: true
---

# 机械臂阻抗控制技能

> 用于实现机械臂的柔顺力控制，涵盖阻抗控制、力位混合控制、碰撞检测和力矩传感器集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现机械臂与环境交互的柔顺控制
- 力控磨削、插拔、装配任务
- 碰撞检测和安全控制
- 混合力位控制（Hybrid Force/Position Control）
- 关节力矩传感器标定

---

## 快速参考

### 控制模式对比

```
机器人控制模式:
├── 位置控制 (Position) → 精确轨迹，跟踪误差小
├── 速度控制 (Velocity) → 响应快，可与力控嵌套
├── 力矩控制 (Torque) → 直接力输出，刚性最低
└── 阻抗控制 (Impedance) ← 本技能重点
    └── 末端力 ↔ 末端速度的动态关系
```

### 核心方程

```
阻抗控制: F = M(ddX) + B(dX) + K(X - Xd)

其中:
- M: 目标惯性矩阵 (Desired Inertia)
- B: 阻尼矩阵 (Damping)
- K: 刚度矩阵 (Stiffness)
- Xd: 期望位置
- X: 实际位置
- F: 末端接触力
```

### ROS2 依赖

```bash
sudo apt install -y ros-humble-controller-manager
sudo apt install -y ros-humble-joint-trajectory-controller
sudo apt install -y ros-humble-effort-controllers
```

---

## 阻抗控制原理

### 阻抗控制核心

```python
import numpy as np
from dataclasses import dataclass


@dataclass
class ImpedanceParams:
    """阻抗控制器参数"""
    M: np.ndarray  # 目标惯性矩阵 6x6
    B: np.ndarray  # 阻尼矩阵 6x6
    K: np.ndarray  # 刚度矩阵 6x6


class ImpedanceController:
    """
    阻抗控制器

    将末端执行器的期望动态特性建模为二阶系统
    适用于: 装配、磨削、插拔等接触任务
    """

    def __init__(self, params: ImpedanceParams):
        self.M = params.M
        self.B = params.B
        self.K = params.K

        # 状态
        self.Xd = np.zeros(6)      # 期望位置/姿态
        self.X = np.zeros(6)        # 实际位置/姿态
        self.Xd_dot = np.zeros(6)   # 期望速度
        self.X_dot = np.zeros(6)    # 实际速度
        self.F_ext = np.zeros(6)    # 外部力/力矩

        # 积分项（可选，用于消除静差）
        self.X_error_integral = np.zeros(6)

    def compute_torque(
        self,
        X: np.ndarray,
        X_dot: np.ndarray,
        F_ext: np.ndarray,
        Xd: np.ndarray,
        Xd_dot: np.ndarray,
        Xd_ddot: np.ndarray,
        dt: float
    ) -> np.ndarray:
        """
        计算末端期望力矩

        Args:
            X: 当前末端位姿 (x, y, z, roll, pitch, yaw)
            X_dot: 当前末端速度
            F_ext: 外部接触力（从力矩传感器获取）
            Xd: 期望位姿
            Xd_dot: 期望速度
            Xd_ddot: 期望加速度
            dt: 控制周期

        Returns:
            tau: 关节力矩命令 (n_joints,)
        """
        self.X = X
        self.X_dot = X_dot
        self.F_ext = F_ext
        self.Xd = Xd
        self.Xd_dot = Xd_dot

        # 位置误差
        X_error = Xd - X

        # 积分项（抗静差）
        self.X_error_integral += X_error * dt
        # 积分限幅
        max_integral = 0.05
        self.X_error_integral = np.clip(
            self.X_error_integral, -max_integral, max_integral
        )

        # 阻抗方程: M(ddX_r) + B(dX_r) + K(X_r) = F_ext
        # 其中 X_r = Xd - X（位置误差）
        X_r = X_error
        X_r_dot = Xd_dot - X_dot

        # 期望加速度（从误差计算）
        # M * X_r_ddot + B * X_r_dot + K * X_r = F_ext
        # => X_r_ddot = M^-1 * (F_ext - B * X_r_dot - K * X_r)
        try:
            X_r_ddot = np.linalg.inv(self.M) @ (
                F_ext - self.B @ X_r_dot - self.K @ X_r
            )
        except np.linalg.LinAlgError:
            X_r_ddot = np.zeros(6)

        # 实际末端期望加速度
        X_ddot_desired = Xd_ddot + X_r_ddot

        # 转换为关节空间力矩（需要雅可比矩阵）
        # tau = J^T * F_desired
        # 这里假设已在关节空间直接计算

        return np.zeros(6)  # 占位，需外部提供 Jacobian


class JointImpedanceController:
    """
    关节空间阻抗控制
    （更常用，计算更简单）
    """

    def __init__(
        self,
        n_joints: int,
        Kp: np.ndarray = None,
        Kd: np.ndarray = None
    ):
        self.n = n_joints
        # 关节空间 PD 增益（等价于阻抗）
        self.Kp = Kp if Kp is not None else np.diag([50] * n_joints)
        self.Kd = Kd if Kd is not None else np.diag([10] * n_joints)

        self.q_desired = np.zeros(n_joints)
        self.q_dot_desired = np.zeros(n_joints)
        self.tau_ext = np.zeros(n_joints)  # 外部力矩

    def compute(
        self,
        q: np.ndarray,
        q_dot: np.ndarray,
        q_ddot: np.ndarray,
        q_desired: np.ndarray,
        tau_ext: np.ndarray
    ) -> np.ndarray:
        """
        计算关节力矩命令

        Args:
            q: 当前关节位置
            q_dot: 当前关节速度
            q_ddot: 当前关节加速度
            q_desired: 期望关节位置
            tau_ext: 外部力矩（重力补偿后的净力矩）

        Returns:
            tau_cmd: 力矩命令
        """
        # 误差
        q_error = q_desired - q
        q_dot_error = self.q_dot_desired - q_dot

        # 阻抗控制力矩 = Kp * error + Kd * derror + tau_ext
        tau_cmd = self.Kp @ q_error + self.Kd @ q_dot_error + tau_ext

        # 输出限幅（保护关节）
        max_torque = 100.0  # Nm
        tau_cmd = np.clip(tau_cmd, -max_torque, max_torque)

        return tau_cmd
```

---

## 混合力位控制 (Hybrid Force/Position Control)

### Mason 1981 框架

```python
import numpy as np


class HybridForcePositionController:
    """
    混合力位控制器 (Hybrid Force/Position Control)

    在不同方向上同时进行力控制和位置控制
    典型应用: 擦拭平面（法向力控，平面内位置控制）
    """

    def __init__(self, n_joints: int):
        self.n = n_joints

        # 选择矩阵 (Task Space Selection Matrix)
        # S[i] = 1 表示沿该方向力控制
        # S[i] = 0 表示沿该方向位置控制
        self.S = np.zeros(6)  # [Fx, Fy, Fz, Mx, My, Mz]

        # 位置控制器
        self.Kp_pos = np.diag([20] * 6)
        self.Kd_pos = np.diag([5] * 6)

        # 力控制器
        self.Kp_force = np.diag([5] * 6)
        self.Ki_force = np.diag([0.5] * 6)
        self.Kd_force = np.diag([0.1] * 6)

        # 积分状态
        self.force_integral = np.zeros(6)

        # 期望力
        self.F_desired = np.zeros(6)
        self.X_desired = np.zeros(6)

    def set_force_control_directions(self, directions: list):
        """设置力控制方向"""
        self.S = np.zeros(6)
        for d in directions:
            self.S[d] = 1.0

    def set_position_control_directions(self, directions: list):
        """设置位置控制方向"""
        for d in directions:
            if self.S[d] == 0:
                pass  # 已经是位置控制

    def compute(
        self,
        X: np.ndarray,
        X_dot: np.ndarray,
        F_ext: np.ndarray,
        Xd: np.ndarray,
        Fd: np.ndarray,
        dt: float
    ) -> np.ndarray:
        """
        计算任务空间力命令

        Returns:
            F_cmd: 任务空间力命令 (6,)
        """
        # 位置控制部分
        X_error = Xd - X
        X_dot_error = -X_dot  # 期望速度为0
        F_pos = self.Kp_pos @ X_error + self.Kd_pos @ X_dot_error

        # 力控制部分
        F_error = Fd - F_ext
        self.force_integral += F_error * dt
        # 积分限幅
        self.force_integral = np.clip(self.force_integral, -5, 5)
        F_force = self.Kp_force @ F_error + self.Ki_force @ self.force_integral

        # 混合: 根据选择矩阵组合
        S_pos = 1.0 - self.S  # 位置控制方向
        F_cmd = np.zeros(6)
        for i in range(6):
            if self.S[i] > 0:
                F_cmd[i] = F_force[i]  # 力控制
            else:
                F_cmd[i] = F_pos[i]     # 位置控制

        return F_cmd
```

---

## ROS2 力矩控制节点

### 力矩控制器

```python
#!/usr/bin/env python3
"""机械臂力矩控制节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
from geometry_msgs.msg import WrenchStamped
import numpy as np


class TorqueControlNode(Node):
    def __init__(self):
        super().__init__('torque_control_node')

        # 参数
        self.declare_parameter('n_joints', 6)
        self.declare_parameter('control_mode', 'impedance')  # impedance / torque
        self.n = self.get_parameter('n_joints').value

        # 阻抗参数
        self.Kp = np.diag([30.0] * self.n)
        self.Kd = np.diag([8.0] * self.n)

        # 关节状态
        self.q = np.zeros(self.n)
        self.q_dot = np.zeros(self.n)
        self.tau_ext = np.zeros(self.n)

        # 目标
        self.q_desired = np.zeros(self.n)
        self.tau_desired = np.zeros(self.n)

        # 订阅
        self.joint_state_sub = self.create_subscription(
            JointState,
            '/joint_states',
            self.joint_state_callback,
            10
        )
        self.ft_sub = self.create_subscription(
            WrenchStamped,
            '/ft_sensor/wrench',
            self.ft_callback,
            10
        )
        self.target_sub = self.create_subscription(
            JointState,
            '/torque_target',
            self.target_callback,
            10
        )

        # 发布
        self.tau_pub = self.create_publisher(
            JointState,
            '/joint_effort_controller/commands',
            10
        )

        # 定时控制
        self.timer = self.create_timer(0.001, self.control_loop)  # 1kHz

        self.get_logger().info('Torque Control Node ready')

    def joint_state_callback(self, msg: JointState):
        if len(msg.position) >= self.n:
            self.q = np.array(msg.position[:self.n])
        if len(msg.velocity) >= self.n:
            self.q_dot = np.array(msg.velocity[:self.n])

    def ft_callback(self, msg: WrenchStamped):
        # 力矩传感器数据 (相对于传感器坐标系)
        self.tau_ext[0] = msg.wrench.torque.x
        self.tau_ext[1] = msg.wrench.torque.y
        self.tau_ext[2] = msg.wrench.torque.z
        # 实际需要坐标变换到关节空间

    def target_callback(self, msg: JointState):
        if len(msg.position) >= self.n:
            self.q_desired = np.array(msg.position[:self.n])

    def control_loop(self):
        """1kHz 控制循环"""
        # 阻抗控制
        q_error = self.q_desired - self.q
        q_dot_error = -self.q_dot

        # 加上外部力矩前馈（重力等）
        tau_cmd = self.Kp @ q_error + self.Kd @ q_dot_error - self.tau_ext * 0.5

        # 发布
        cmd = JointState()
        cmd.header.stamp = self.get_clock().now().to_msg()
        cmd.name = [f'joint{i+1}' for i in range(self.n)]
        cmd.effort = tau_cmd.tolist()
        self.tau_pub.publish(cmd)
```

---

## 力矩传感器标定

### 重力补偿 + 零点标定

```python
class ForceTorqueCalibrator:
    """力矩传感器标定"""

    def __init__(self, n_joints: int = 6):
        self.n = n_joints
        self.wrench_bias = np.zeros(6)  # 零点偏移
        self.wrench_transform = np.eye(6)  # 坐标系变换矩阵
        self.gravity_direction = np.array([0, 0, -9.81])

    def calibrate_zero(self, samples: int = 100):
        """
        零点标定 - 机器人处于无负载姿态时采集

        Args:
            samples: 采样次数
        """
        raw_data = []

        for _ in range(samples):
            # 读取当前力矩
            wrench = self.read_wrench()
            raw_data.append(wrench)

        raw_data = np.array(raw_data)

        # 取中位数作为零点（抗异常值）
        self.wrench_bias = np.median(raw_data, axis=0)

        return self.wrench_bias

    def calibrate_transform(
        self,
        joint_positions: list,
        wrench_readings: list
    ):
        """
        标定坐标系变换

        使用最小二乘法求解变换矩阵
        关节力矩 = transform @ wrench + bias
        """
        n = len(joint_positions)
        A = np.zeros((n * 6, 42))  # 6x7 变换矩阵拉直
        b = np.zeros(n * 6)

        for i, (q, w) in enumerate(zip(joint_positions, wrench_readings)):
            # 关节力矩与传感器读数的关系
            A[i*6:(i+1)*6, :42] = self._build_regression_row(w)
            b[i*6:(i+1)*6] = q

        # 最小二乘求解
        x, _, _, _ = np.linalg.lstsq(A, b, rcond=None)

        # 重塑为 6x7 矩阵
        self.wrench_transform = x.reshape(6, 7)
        self.wrench_bias = x.reshape(6, 7)[:, 6]

        return self.wrench_transform

    def transform_wrench(self, raw_wrench: np.ndarray) -> np.ndarray:
        """将传感器读数转换为关节力矩"""
        # 去零点
        wrench = raw_wrench - self.wrench_bias

        # 线性变换 + 偏移
        joint_torque = self.wrench_transform @ np.append(wrench, 1)

        return joint_torque
```

---

## 碰撞检测

```python
class CollisionDetector:
    """关节空间碰撞检测"""

    def __init__(self, n_joints: int):
        self.n = n_joints

        # 碰撞阈值（根据正常操作力矩设定）
        self.torque_threshold = np.array([30.0] * n_joints)  # Nm

        # 碰撞标志
        self.collision_detected = False

        # 碰撞前的正常力矩估计（EMA）
        self.tau_normal_estimate = np.zeros(n_joints)
        self.alpha = 0.95  # EMA 平滑因子

    def detect(
        self,
        tau_cmd: np.ndarray,
        tau_actual: np.ndarray
    ) -> bool:
        """
        检测是否发生碰撞

        Args:
            tau_cmd: 发送的力矩命令
            tau_actual: 实际测量的力矩

        Returns:
            True if collision detected
        """
        # 计算力矩残差
        tau_residual = np.abs(tau_actual - tau_cmd)

        # 更新正常力矩估计
        self.torque_normal_estimate = (
            self.alpha * self.torque_normal_estimate +
            (1 - self.alpha) * tau_cmd
        )

        # 动态阈值：正常力矩的 2 倍或固定阈值
        dynamic_threshold = np.maximum(
            2.0 * np.abs(self.torque_normal_estimate),
            self.torque_threshold
        )

        # 碰撞判定：残差超过阈值
        self.collision_detected = np.any(tau_residual > dynamic_threshold)

        return self.collision_detected

    def get_collision_direction(self, tau_residual: np.ndarray) -> np.ndarray:
        """判断碰撞方向"""
        # 正值表示正方向有碰撞，负值表示负方向
        return np.sign(tau_residual)


class SafeStopController:
    """安全停止控制器"""

    def __init__(self):
        self.collision_joint = -1
        self.collision_direction = 0

    def emergency_stop(self):
        """
        紧急停止策略:

        1. 检测到碰撞的关节立即停止
        2. 其他关节柔顺停止（减小增益）
        3. 可选：反向运动一段距离脱离接触
        """
        # 方案A: 全部柔顺停止
        return "compliant_stop"

        # 方案B: 反向运动
        return "reverse_and_stop"

    def compliant_stop(self, q_dot: np.ndarray) -> np.ndarray:
        """柔顺停止：减小关节速度到零"""
        return q_dot * 0.5  # 逐步减速
```

---

## ROS2 配置

### Controllers YAML

```yaml
effort_controllers:
  ros__parameters:
    joints:
      - joint1
      - joint2
      - joint3
      - joint4
      - joint5
      - joint6
    command_interfaces:
      - effort
    state_interfaces:
      - position
      - velocity
      - effort

impedance_controller:
  ros__parameters:
    n_joints: 6
    Kp: [30.0, 30.0, 25.0, 20.0, 15.0, 10.0]
    Kd: [8.0, 8.0, 6.0, 5.0, 4.0, 3.0]
    max_torque: [100.0, 100.0, 80.0, 50.0, 30.0, 30.0]
```

### Launch

```python
# launch/torque_control.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        Node(
            package='controller_manager',
            executable='spawner',
            arguments=['effort_controller'],
        ),
        Node(
            package='torque_control',
            executable='torque_control_node',
            name='torque_control_node',
            parameters=[{
                'n_joints': 6,
                'control_mode': 'impedance',
            }],
        ),
    ])
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 机械臂振荡 | Kp/Kd 增益过高 | 减小 Kd，或增加 Kp |
| 响应迟缓 | 刚度太低 | 增加 Kp，降低阻尼比 |
| 力控制不稳 | 力传感器噪声大 | 增加低通滤波，减小微分项 |
| 碰撞后不停止 | 阈值设置不当 | 标定正常力矩，重新设置阈值 |
| 启动抖动 | 初始误差大 | 增加启动缓冲，渐进达到目标 |
| 关节异响 | 力矩超限摩擦 | 减小最大力矩限幅 |

### 调试命令

```bash
# 监听关节力矩
ros2 topic echo /joint_states

# 监听力矩传感器
ros2 topic echo /ft_sensor/wrench

# 发送力矩命令测试
ros2 topic pub /joint_effort_controller/commands std_msgs.msg/Float64MultiArray \
  'data: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]' --once

# 录制数据进行后分析
ros2 bag record /joint_states /ft_sensor/wrench -o torque_data
```

---

## 相关技能

- `manipulator/motion-control` — 机械臂运动控制基础
- `manipulator/motion-control/grasp-planning` — 抓取规划
- `manipulator/motion-control/trajectory` — 轨迹规划
- `manipulator/force-control/force-position-hybrid` — 力位混合控制
- `manipulator/force-control/impedance-control` — 阻抗控制（本文）
- `manipulator/force-control` — 力控技能目录
