---
name: auv-control
description: AUV 控制技能 - 水下潜航器动力学、螺旋桨控制、深度控制、航向控制、ROS2 集成
argument-hint: AUV OR 水下控制 OR 潜航器 OR ROV OR depth control
user-invocable: true
---

# AUV 控制技能

> 用于开发水下自主潜航器(AUV)的控制系统，涵盖动力学建模、螺旋桨控制、深度控制和 ROS2 集成

---

## 何时使用

当需要以下帮助时使用此技能：
- AUV/ROV 动力学建模
- 螺旋桨和推进器配置
- 深度/航向/姿态控制
- 水下导航和安全机制
- 水声通信集成

---

## 快速参考

### AUV 配置

```yaml
auv:
  mass: 300              # 质量 (kg)
  volume: 0.31           # 排水体积 (m³)
  length: 1.5            # 长度 (m)
  max_depth: 100          # 最大工作深度 (m)
  max_speed: 3.0         # 最大速度 (m/s)
  thrusters:
    count: 6             # 推进器数量
    config: "矢量布置"    # 矢量推进配置
```

---

## 动力学模型

```python
import numpy as np
from dataclasses import dataclass


@dataclass
class AUVState:
    """AUV 状态"""
    position: np.ndarray      # [x, y, z]  世界坐标
    velocity: np.ndarray      # [u, v, w]  体坐标系速度
    orientation: np.ndarray   # [phi, theta, psi]  roll, pitch, yaw
    angular_velocity: np.ndarray  # [p, q, r]  体坐标系角速度


class AUVDynamics:
    """
    AUV 6-DOF 动力学模型

    参考: Fossen 船舶动力学
    """

    def __init__(self, params: dict):
        # 质量矩阵 (包含附加质量)
        self.M = np.diag([
            params['M_u'], params['M_v'], params['M_w'],
            params['M_p'], params['M_q'], params['M_r']
        ])

        # 科里奥利向心矩阵
        self.C = np.zeros((6, 6))

        # 水动力阻尼矩阵
        self.D = np.diag([
            params['D_u'], params['D_v'], params['D_w'],
            params['D_p'], params['D_q'], params['D_r']
        ])

        # 重力和浮力
        self.g = params['gravity']
        self.W = params['weight']      # 重力
        self.B = params['buoyancy']   # 浮力
        self.z_meta = params['z_meta']  # 稳心高度

        # 推进器配置
        self.thruster_config = params.get('thrusters', [])

    def compute_dynamics(
        self,
        state: AUVState,
        thrust_commands: np.ndarray
    ) -> np.ndarray:
        """
        计算动力学方程

        M * ν̇ + C(ν) * ν + D * ν + g(η) = τ

        Returns:
            ν_dot: 广义加速度 [u̇, v̇, ẇ, ṗ, q̇, ṙ]
        """
        nu = np.concatenate([state.velocity, state.angular_velocity])

        # 科里奥利矩阵
        C = self._compute_C_matrix(nu)

        # 水动力阻尼
        D_nu = D @ nu

        # 重力和浮力（仅影响 z, roll, pitch）
        g_eta = self._compute_gravity_buoyancy(state.orientation)

        # 推进力
        tau_thrust = self._thrust_mapping(thrust_commands)

        # 合力
        tau = tau_thrust + g_eta

        # 求解
        nu_dot = np.linalg.inv(M) @ (tau - C @ nu - D_nu)

        return nu_dot

    def _compute_C_matrix(self, nu: np.ndarray) -> np.ndarray:
        """计算科里奥利向心矩阵"""
        u, v, w, p, q, r = nu
        C = np.zeros((6, 6))
        C[0, 1] = -self.M[1,1] * r
        C[0, 2] = self.M[2,2] * q
        # ... 完整公式参考 Fossen
        return C

    def _compute_gravity_buoyancy(self, orientation: np.ndarray) -> np.ndarray:
        """计算重力浮力项"""
        phi, theta, psi = orientation
        g = np.zeros(6)
        g[2] = -(W - B) * np.cos(phi) * np.cos(theta)
        g[3] = -(W - B) * self.z_meta * np.sin(theta)
        g[4] = (W - B) * self.z_meta * np.sin(phi) * np.cos(theta)
        return g

    def _thrust_mapping(self, commands: np.ndarray) -> np.ndarray:
        """推进器力映射"""
        tau = np.zeros(6)
        for i, cmd in enumerate(commands):
            pos = self.thruster_config[i]['position']
            dir = self.thruster_config[i]['direction']
            tau += self.thruster_config[i]['k'] * cmd * dir
        return tau


class PIDController:
    """PID 控制器"""

    def __init__(self, kp: float, ki: float, kd: float):
        self.kp, self.ki, self.kd = kp, ki, kd
        self.prev_error = 0.0
        self.integral = 0.0

    def compute(self, setpoint: float, actual: float, dt: float) -> float:
        error = setpoint - actual
        self.integral += error * dt
        derivative = (error - self.prev_error) / dt if dt > 0 else 0.0
        self.prev_error = error
        return self.kp * error + self.ki * self.integral + self.kd * derivative
```

---

## ROS2 AUV 控制节点

```python
#!/usr/bin/env python3
"""AUV 控制节点"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import Imu, FluidPressure
from nav_msgs.msg import Odometry
import numpy as np


class AUVControlNode(Node):
    def __init__(self):
        super().__init__('auv_control')

        # 控制器
        self.depth_pid = PIDController(kp=2.0, ki=0.1, kd=1.0)
        self.yaw_pid = PIDController(kp=1.5, ki=0.05, kd=0.5)
        self.pitch_pid = PIDController(kp=1.0, ki=0.0, kd=0.5)

        # 状态
        self.current_depth = 0.0
        self.target_depth = 0.0
        self.current_yaw = 0.0
        self.target_yaw = 0.0
        self.vehicle_state = AUVState(
            position=np.zeros(3),
            velocity=np.zeros(3),
            orientation=np.zeros(3),
            angular_velocity=np.zeros(3)
        )

        # 订阅
        self.cmd_sub = self.create_subscription(
            Twist, '/cmd_vel', self.cmd_callback, 10)
        self.imu_sub = self.create_subscription(
            Imu, '/imu/data', self.imu_callback, 10)
        self.pressure_sub = self.create_subscription(
            FluidPressure, '/pressure', self.pressure_callback, 10)

        # 发布
        self.thrust_pub = self.create_publisher(
            Twist, '/thruster_commands', 10)

        self.timer = self.create_timer(0.05, self.control_loop)  # 20Hz

    def cmd_callback(self, msg: Twist):
        self.target_depth = max(0, min(100, -msg.linear.z))  # z 负方向 = 下潜
        self.target_yaw = msg.angular.z

    def imu_callback(self, msg: Imu):
        # 更新姿态
        q = msg.orientation
        roll, pitch, yaw = self._quaternion_to_euler(q.x, q.y, q.z, q.w)
        self.vehicle_state.orientation = np.array([roll, pitch, yaw])
        self.current_yaw = yaw

    def pressure_callback(self, msg: FluidPressure):
        # 压力 → 深度 (淡水: 1m ≈ 9806 Pa)
        pressure_ Pa = msg.fluid_pressure
        self.current_depth = (pressure - 101325.0) / 9806.0

    def control_loop(self):
        dt = 0.05

        # 深度控制
        depth_cmd = self.depth_pid.compute(
            self.target_depth, self.current_depth, dt
        )

        # 航向控制
        yaw_cmd = self.yaw_pid.compute(
            self.target_yaw, self.current_yaw, dt
        )

        # 推进器分配
        thrust = self._allocate_thrust(
            surge=0.0,  # 来自 cmd_vel.linear.x
            sway=0.0,   # 来自 cmd_vel.linear.y
            heave=depth_cmd,
            roll=0.0,
            pitch=self.pitch_pid.compute(0, self.vehicle_state.orientation[1], dt),
            yaw=yaw_cmd
        )

        # 发布
        cmd = Twist()
        cmd.linear.x = thrust[0]
        cmd.linear.y = thrust[1]
        cmd.linear.z = thrust[2]
        cmd.angular.x = thrust[3]
        cmd.angular.y = thrust[4]
        cmd.angular.z = thrust[5]
        self.thrust_pub.publish(cmd)

    def _allocate_thrust(self, **thrust):
        """简化推进器分配"""
        # 6个推进器：4个主推 + 2个垂直
        return np.array([
            thrust['surge'] * 4,   # 4个主推
            0, 0, 0, 0, thrust['heave'] * 2, thrust['yaw']
        ])

    @staticmethod
    def _quaternion_to_euler(x, y, z, w):
        """四元数 → 欧拉角"""
        roll = np.arctan2(2*(w*x + y*z), 1 - 2*(x*x + y*y))
        pitch = np.arcsin(2*(w*y - z*x))
        yaw = np.arctan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
        return roll, pitch, yaw
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| AUV 不下潜 | 浮力过大 | 调整 ballast 或配重 |
| 航向漂移 | 偏航 PID 增益不对 | 调整 yaw_pid 参数 |
| 深度振荡 | 微分项不足 | 增加 kd，减少 kp |
| 推进器响应慢 | 命令限幅 | 检查 thruster_manager 参数 |
| 姿态不稳 | 传感器噪声 | 添加滤波器 |

---

## 相关技能

- `underwater/sonar-perception` — 声呐感知
- `navigation/nav2-integration` — 导航集成
