---
name: manipulator-force-position-hybrid
description: 机械臂力位混合控制技能 - 任务空间选择矩阵、力/位置并行控制、装配应用、ROS2实现
argument-hint: 力位混合 OR hybrid force position OR 任务空间 OR 力控制 OR 装配
user-invocable: true
---

# 机械臂力位混合控制技能

> 用于实现机械臂的混合力位控制，在任务空间同时进行力控制和位置控制，典型应用于装配、插销、磨削等场景

---

## 何时使用

当需要以下帮助时使用此技能：
- 同时控制某些方向的位置和其他方向的压力
- 精密装配（销钉插入、齿轮咬合）
- 曲面跟踪（法向力保持恒定）
- 力/位置切换控制
- 接触任务规划

---

## 快速参考

### 控制原理

```
力位混合控制核心:
在任务空间定义选择矩阵 S
- S[i]=1 → 该方向力控制
- S[i]=0 → 该方向位置控制

常用配置（擦拭任务）:
方向: X     Y     Z     Rx    Ry    Rz
      0     0     1     0     0     0     → Z向力控制，其余位置控制
```

### 典型应用

| 任务 | 位置控制方向 | 力控制方向 |
|------|-------------|-----------|
| 擦玻璃 | X, Y, Rz | Z (法向力) |
| 销钉插孔 | X, Y | Z (插入力) |
| 磨削 | Rz | X, Y, Z (法向力) |
| 开门 | X, Y, Z, Rz | Ry (力矩) |

---

## 核心算法

### 选择矩阵与雅可比

```python
import numpy as np
from typing import Tuple, List


class TaskSpaceModel:
    """任务空间模型"""

    def __init__(self, n_joints: int):
        self.n = n_joints
        self.joint_limits = np.zeros((n_joints, 2))

        # 雅可比矩阵（需要实时更新）
        self.J = np.zeros((6, n_joints))
        self.J_dot = np.zeros((6, n_joints))  # 雅可比时间导数

    def compute_jacobian(self, q: np.ndarray, robot_model) -> np.ndarray:
        """计算雅可比矩阵"""
        # 末端执行器雅可比
        # J = [Jv; Jw] - 线速度和角速度雅可比
        return robot_model.get_jacobian(q)

    def joint_to_task_torque(
        self,
        tau_task: np.ndarray,
        J: np.ndarray
    ) -> np.ndarray:
        """
        将任务空间力矩转换为关节空间力矩

        Args:
            tau_task: 6D 任务空间力矩 (Fx, Fy, Fz, Mx, My, Mz)
            J: 6xn 雅可比矩阵

        Returns:
            tau_joints: n 关节力矩
        """
        # 逆雅可比转置（常用简化）
        return J.T @ tau_task
```

### 混合控制器

```python
class HybridForcePositionController:
    """
    混合力位控制器

    基于任务空间选择矩阵，在不同方向上分别执行力控制和位置控制
    """

    def __init__(self, n_joints: int):
        self.n = n_joints

        # === 选择矩阵 ===
        # S[i] = 1 → i 方向力控制
        # S[i] = 0 → i 方向位置控制
        self.S = np.zeros(6)  # 默认全位置控制

        # === 位置控制增益 ===
        self.Kp_pos = np.diag([50.0] * 6)
        self.Kd_pos = np.diag([15.0] * 6)

        # === 力控制增益 ===
        self.Kp_force = np.diag([2.0] * 6)
        self.Ki_force = np.diag([0.5] * 6)
        self.Kd_force = np.diag([0.2] * 6)

        # 积分状态
        self.force_integral = np.zeros(6)

        # 期望值
        self.Xd = np.zeros(6)      # 期望位置
        self.Fd = np.zeros(6)     # 期望力

        # 任务空间惯性矩阵（用于动力学前馈）
        self.M_task = np.eye(6)

    def set_force_control_directions(self, directions: List[int]):
        """设置力控制方向 (0-5: x, y, z, rx, ry, rz)"""
        self.S[:] = 0
        for d in directions:
            self.S[d] = 1.0
        # 重置积分
        self.force_integral = np.zeros(6)

    def set_position_control_directions(self, directions: List[int]):
        """设置位置控制方向"""
        self.S[:] = 0
        for d in directions:
            self.S[d] = 0.0  # 0 = 位置控制
        self.force_integral = np.zeros(6)

    def compute_task_wrench(
        self,
        X: np.ndarray,
        X_dot: np.ndarray,
        F_ext: np.ndarray,
        Xd: np.ndarray,
        Fd: np.ndarray,
        dt: float
    ) -> np.ndarray:
        """
        计算任务空间控制力矩

        Args:
            X: 当前末端位姿 (x, y, z, roll, pitch, yaw)
            X_dot: 当前末端速度
            F_ext: 外部接触力（末端坐标系）
            Fd: 期望接触力
            dt: 控制周期

        Returns:
            F_cmd: 6D 任务空间力矩命令
        """
        # 位置控制输出
        pos_error = Xd - X
        pos_error_dot = -X_dot  # 期望速度=0
        F_pos = self.Kp_pos @ pos_error + self.Kd_pos @ pos_error_dot

        # 力控制输出
        force_error = Fd - F_ext
        self.force_integral += force_error * dt

        # 积分限幅（防止积分饱和）
        max_integral = np.array([10.0] * 6)
        self.force_integral = np.clip(self.force_integral, -max_integral, max_integral)

        F_force = self.Kp_force @ force_error + \
                  self.Ki_force @ self.force_integral

        # 选择矩阵混合
        # S=1 → 全力控制; S=0 → 全位置控制
        S = self.S
        F_cmd = np.zeros(6)

        for i in range(6):
            if S[i] > 0.5:  # 力控制
                F_cmd[i] = F_force[i]
            else:           # 位置控制
                F_cmd[i] = F_pos[i]

        # 添加重力补偿前馈（如果有）
        # F_cmd += self.gravity_compensation(X)

        return F_cmd

    def compute_joint_torque(
        self,
        F_cmd: np.ndarray,
        J: np.ndarray,
        q: np.ndarray,
        q_dot: np.ndarray
    ) -> np.ndarray:
        """
        将任务空间力矩转换为关节力矩

        Args:
            F_cmd: 6D 任务空间力矩
            J: 雅可比矩阵
            q: 关节位置
            q_dot: 关节速度

        Returns:
            tau: 关节力矩命令
        """
        # 基本转换
        tau = J.T @ F_cmd

        # 可选：添加关节空间阻抗
        # tau += self.Kp_joint @ (self.q_desired - q) - self.Kd_joint @ q_dot

        return tau
```

---

## 装配应用：销钉插入

```python
class PegInHoleController:
    """
    销钉插入控制器

    阶段1: 接近（位置控制移动到孔上方）
    阶段2: 搜索（力控制法向，位置控制切向）
    阶段3: 插入（Z向位置控制 + 径向力适应）
    阶段4: 到位（位置锁定）
    """

    def __init__(self, n_joints: int):
        self.hybrid = HybridForcePositionController(n_joints)
        self.phase = "approach"
        self.insertion_depth = 0.0
        self.max_insertion = 0.05  # 5cm

        # 接近位置
        self.approach_pose = np.zeros(6)
        self.approach_pose[2] = 0.1  # 孔上方 10cm

        # 插入时的力阈值
        self.force_threshold = 5.0  # N

        # 成功标志
        self.insertion_complete = False

    def plan(self, hole_position: np.ndarray) -> dict:
        """
        规划插入任务

        Args:
            hole_position: 孔的位置 (x, y, z)

        Returns:
            控制参数
        """
        # 接近点在孔上方 5cm
        self.approach_pose[:3] = hole_position
        self.approach_pose[2] += 0.05

        return {
            "approach_pose": self.approach_pose,
            "insertion_force": 2.0,  # 2N
            "search_directions": [0, 1],  # X, Y 力控制（切向）
        }

    def execute_phase(self, X: np.ndarray, F_ext: np.ndarray, dt: float) -> np.ndarray:
        """
        执行当前阶段

        Returns:
            控制输出
        """
        if self.phase == "approach":
            return self._phase_approach(X, dt)
        elif self.phase == "search":
            return self._phase_search(X, F_ext, dt)
        elif self.phase == "insertion":
            return self._phase_insertion(X, F_ext, dt)
        else:
            return np.zeros(6)

    def _phase_approach(self, X: np.ndarray, dt: float) -> np.ndarray:
        """阶段1: 移动到接近点"""
        # 全位置控制
        self.hybrid.set_position_control_directions([0, 1, 2, 3, 4, 5])
        return self.hybrid.compute_task_wrench(
            X, np.zeros(6), np.zeros(6),
            self.approach_pose, np.zeros(6), dt
        )

    def _phase_search(self, X: np.ndarray, F_ext: np.ndarray, dt: float) -> np.ndarray:
        """阶段2: 搜索（切向力控，法向位置）"""
        # Z 向位置控制，X/Y 力控制
        self.hybrid.set_force_control_directions([0, 1])  # X, Y 力控制
        self.hybrid.set_position_control_directions([2, 3, 4, 5])

        # 检测接触
        if abs(F_ext[2]) > self.force_threshold:
            self.phase = "insertion"
            self.insertion_depth = 0.0

        # Z 方向缓慢下降
        target = self.approach_pose.copy()
        target[2] -= 0.001 * dt  # 慢速下降

        return self.hybrid.compute_task_wrench(
            X, np.zeros(6), F_ext,
            target, np.zeros(6), dt
        )

    def _phase_insertion(self, X: np.ndarray, F_ext: np.ndarray, dt: float) -> np.ndarray:
        """阶段3: 插入"""
        # Z 向位置控制，X/Y 自适应（低刚度）
        self.hybrid.set_position_control_directions([2, 3, 4, 5])  # Z + 姿态位置

        # X/Y 低增益力控制（适应孔位）
        Fd = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

        # 目标：继续下降到完全插入
        target = self.approach_pose.copy()
        target[2] -= self.max_insertion

        return self.hybrid.compute_task_wrench(
            X, np.zeros(6), F_ext,
            target, Fd, dt
        )
```

---

## ROS2 实现

### 混合力位控制节点

```python
#!/usr/bin/env python3
"""混合力位控制 ROS2 节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
from geometry_msgs.msg import WrenchStamped
from std_msgs.msg import Float64MultiArray
import numpy as np


class HybridControlNode(Node):
    def __init__(self):
        super().__init__('hybrid_force_position_control')

        # 参数
        self.declare_parameter('n_joints', 6)
        self.declare_parameter('control_mode', 'hybrid')  # hybrid / position / force
        self.n = self.get_parameter('n_joints').value

        # 控制器
        self.hybrid = HybridForcePositionController(self.n)
        self.task_model = TaskSpaceModel(self.n)

        # 状态
        self.q = np.zeros(self.n)
        self.q_dot = np.zeros(self.n)
        self.end_effector_pose = np.zeros(6)
        self.F_ext = np.zeros(6)

        # 目标
        self.target_pose = np.zeros(6)
        self.target_force = np.zeros(6)

        # 订阅
        self.joint_state_sub = self.create_subscription(
            JointState, '/joint_states', self.joint_callback, 10)
        self.ft_sub = self.create_subscription(
            WrenchStamped, '/ft_sensor/wrench', self.ft_callback, 10)
        self.target_sub = self.create_subscription(
            Float64MultiArray, '/hybrid_target', self.target_callback, 10)

        # 发布
        self.tau_pub = self.create_publisher(
            Float64MultiArray, '/joint_effort_controller/commands', 10)

        # 定时器
        self.timer = self.create_timer(0.001, self.control_loop)  # 1kHz

        self.get_logger().info('Hybrid Force-Position Control ready')

    def joint_callback(self, msg: JointState):
        if len(msg.position) >= self.n:
            self.q = np.array(msg.position[:self.n])
        if len(msg.velocity) >= self.n:
            self.q_dot = np.array(msg.velocity[:self.n])

        # 估算末端位姿（简化：正运动学）
        self.end_effector_pose = self.fkine(self.q)

    def ft_callback(self, msg: WrenchStamped):
        self.F_ext[0] = msg.wrench.force.x
        self.F_ext[1] = msg.wrench.force.y
        self.F_ext[2] = msg.wrench.force.z
        self.F_ext[3] = msg.wrench.torque.x
        self.F_ext[4] = msg.wrench.torque.y
        self.F_ext[5] = msg.wrench.torque.z

    def target_callback(self, msg: Float64MultiArray):
        """接收目标: 前6个是位置，后6个是力"""
        data = np.array(msg.data)
        if len(data) >= 12:
            self.target_pose = data[:6]
            self.target_force = data[6:]

            # 根据目标自动设置控制方向
            for i in range(6):
                if abs(self.target_force[i]) > 0.01:
                    self.hybrid.S[i] = 1.0
                else:
                    self.hybrid.S[i] = 0.0

    def control_loop(self):
        dt = 0.001

        # 计算雅可比
        J = self.task_model.compute_jacobian(self.q, self.robot_model)

        # 任务空间控制
        F_cmd = self.hybrid.compute_task_wrench(
            self.end_effector_pose, np.zeros(6), self.F_ext,
            self.target_pose, self.target_force, dt
        )

        # 转换到关节空间
        tau_cmd = J.T @ F_cmd

        # 发布
        cmd = Float64MultiArray()
        cmd.data = tau_cmd.tolist()
        self.tau_pub.publish(cmd)

    def fkine(self, q) -> np.ndarray:
        """简化正运动学 - 实际应使用 RobotModel"""
        return np.zeros(6)  # 占位
```

### Launch 配置

```python
# launch/hybrid_control.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        # 控制器管理器
        Node(
            package='controller_manager',
            executable='spawner',
            arguments=['joint_effort_controller'],
        ),

        # 力位混合控制器
        Node(
            package='manipulator_controllers',
            executable='hybrid_control_node',
            name='hybrid_control',
            parameters=[{
                'n_joints': 6,
                'control_mode': 'hybrid',
            }],
            remappings=[
                ('/joint_states', '/manipulator_controller/joint_states'),
                ('/ft_sensor/wrench', '/ft300/wrench'),
            ],
        ),

        # 位置目标发布（可选：任务规划器）
        Node(
            package='manipulator_planners',
            executable='insertion_planner',
            name='insertion_planner',
        ),
    ])
```

---

## 轨迹生成

```python
class HybridTrajectoryGenerator:
    """混合力位轨迹生成器"""

    def __init__(self):
        self.time = 0.0
        self.dt = 0.001

    def generate_approach_trajectory(
        self,
        start: np.ndarray,
        hole_pos: np.ndarray,
        approach_height: float = 0.05,
        approach_time: float = 5.0
    ) -> np.ndarray:
        """生成接近轨迹（位置控制段）"""
        num_steps = int(approach_time / self.dt)
        trajectory = np.zeros((num_steps, 6))

        # 接近点
        target = start.copy()
        target[:3] = hole_pos
        target[2] = hole_pos[2] + approach_height

        for i in range(num_steps):
            t = i / num_steps
            # 5次多项式插值
            s = 10 * t**5 - 15 * t**4 + 6 * t**3
            trajectory[i] = start + s * (target - start)

        self.time += approach_time
        return trajectory

    def generate_insertion_trajectory(
        self,
        hole_pos: np.ndarray,
        insertion_depth: float = 0.05,
        insertion_time: float = 10.0
    ) -> np.ndarray:
        """生成插入轨迹（Z向力控/位置控混合段）"""
        num_steps = int(insertion_time / self.dt)
        trajectory = np.zeros((num_steps, 6))

        start_z = hole_pos[2] + 0.005  # 接触后 5mm
        end_z = hole_pos[2] - insertion_depth

        for i in range(num_steps):
            t = i / num_steps
            # 线性下降 + 末端缓冲
            z = start_z + (end_z - start_z) * t
            trajectory[i, :3] = hole_pos
            trajectory[i, 2] = z

        self.time += insertion_time
        return trajectory
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 力控制振荡 | 增益过高或传感器噪声 | 减小 Kp_force，添加低通滤波 |
| 插入卡住 | 切向刚度过高 | 减小 X/Y 方向刚度 |
| 位置跟踪误差大 | 位置增益不足 | 增加 Kp_pos |
| 接触后力跳变 | 接触检测阈值太高 | 降低力阈值，提前切换 |
| 关节力矩饱和 | 轨迹规划不合理 | 减小速度/加速度，规划平滑轨迹 |

### 调试命令

```bash
# 监听末端力
ros2 topic echo /ft_sensor/wrench --field wrench.force

# 监听末端位姿
ros2 topic echo /end_effector_pose

# 手动发送目标
ros2 topic pub /hybrid_target std_msgs/Float64MultiArray \
  'data: [0.4, 0.0, 0.1, 0, 0, 0, 0, 0, 5, 0, 0, 0]' --once

# 录制数据
ros2 bag record /joint_states /ft_sensor/wrench /hybrid_target -o hybrid_data
```

---

## 相关技能

- `manipulator/impedance-control` — 阻抗控制
- `manipulator/force-control` — 力控制基础
- `manipulator/grasp-planning` — 抓取规划
- `manipulator/motion-control/trajectory` — 轨迹规划
- `perception/kalman-filtering` — 传感器滤波
