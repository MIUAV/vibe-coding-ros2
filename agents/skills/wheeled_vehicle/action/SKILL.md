---
name: wheeled-vehicle-action
description: 轮式车辆执行控制技能 - 底盘运动控制、差速驱动、阿克曼转向、麦克纳姆轮控制
argument-hint: "轮式车辆控制" / "底盘驱动" / "差速控制" / "阿克曼" / "麦克纳姆轮"
user-invocable: true
---

# 轮式车辆执行控制技能

> 用于开发轮式车辆的底层运动控制系统，包括差速驱动、阿克曼转向和麦克纳姆轮控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现轮式车辆底盘控制
- 差速驱动运动学
- 阿克曼（Ackermann）转向几何
- 麦克纳姆轮（Omni-wheel）控制
- 里程计与速度闭环
- 车辆动力学参数调优

---

## 快速参考

### 车辆类型判别

```
轮式车辆类型:
├── 差速驱动 (Differential Drive): 两轮/四轮差速
│   └── 适用: 轮式机器人、AGV、服务机器人
├── 阿克曼转向 (Ackermann): 汽车式前轮转向
│   └── 适用: 自动驾驶车辆、无人车
└── 全向移动 (Omni/Mecanum): 麦克纳姆轮
    └── 适用: 狭窄空间、任意方向移动
```

### 常用参数

```yaml
wheeled_vehicle:
  # 差速驱动参数
  differential:
    wheel_base: 0.5        # 轮间距 (m)
    wheel_radius: 0.1      # 轮半径 (m)
    max_linear_speed: 1.0  # 最大线速度 (m/s)
    max_angular_speed: 2.0 # 最大角速度 (rad/s)

  # 阿克曼参数
  ackermann:
    wheel_base: 2.5        # 前后轴距离 (m)
    front_track: 1.5       # 前轮轮距 (m)
    rear_track: 1.5        # 后轮轮距 (m)
    max_steering_angle: 0.5 # 最大转向角 (rad)

  # 麦克纳姆轮参数
  mecanum:
    wheel_radius: 0.05     # 轮半径 (m)
    roller_radius: 0.015   # 辊轮半径 (m)
    wheel_layout: "X"       # 排列方式: X 或 O
```

---

## 差速驱动 (Differential Drive)

### 运动学模型

```python
import numpy as np
from typing import Tuple

class DifferentialDrive:
    """差速驱动底盘"""

    def __init__(self, wheel_base: float, wheel_radius: float):
        self.wheel_base = wheel_base      # 两轮间距 (m)
        self.wheel_radius = wheel_radius    # 轮半径 (m)

    def forward_kinematics(
        self,
        v_left: float,
        v_right: float
    ) -> Tuple[float, float]:
        """
        正运动学: 轮速 → 机器人速度

        Args:
            v_left: 左轮线速度 (m/s)
            v_right: 右轮线速度 (m/s)

        Returns:
            (v, omega): 线速度 (m/s), 角速度 (rad/s)
        """
        v = (v_left + v_right) / 2.0
        omega = (v_right - v_left) / self.wheel_base
        return v, omega

    def inverse_kinematics(
        self,
        v: float,
        omega: float
    ) -> Tuple[float, float]:
        """
        逆运动学: 机器人速度 → 轮速

        Args:
            v: 期望线速度 (m/s)
            omega: 期望角速度 (rad/s)

        Returns:
            (v_left, v_right): 左/右轮线速度 (m/s)
        """
        v_left = v - omega * self.wheel_base / 2.0
        v_right = v + omega * self.wheel_base / 2.0
        return v_left, v_right

    def compute_odometry(
        self,
        v_left: float,
        v_right: float,
        dt: float
    ) -> Tuple[float, float, float]:
        """
        里程计计算

        Returns:
            (x, y, theta): 位置和朝向
        """
        v, omega = self.forward_kinematics(v_left, v_right)
        theta_dot = omega
        x_dot = v * np.cos(theta_dot) * dt
        y_dot = v * np.sin(theta_dot) * dt
        return x_dot, y_dot, theta_dot * dt
```

### 速度控制器

```python
class DifferentialSpeedController:
    """差速驱动速度控制器"""

    def __init__(self, kp: float = 1.0, ki: float = 0.0, kd: float = 0.1):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.prev_error_left = 0.0
        self.prev_error_right = 0.0
        self.integral_left = 0.0
        self.integral_right = 0.0

    def compute(
        self,
        target_left: float,
        target_right: float,
        actual_left: float,
        actual_right: float,
        dt: float
    ) -> Tuple[float, float]:
        """计算 PWM/电压控制量"""
        # 左轮 PID
        error_left = target_left - actual_left
        self.integral_left += error_left * dt
        derivative_left = (error_left - self.prev_error_left) / dt if dt > 0 else 0.0
        u_left = self.kp * error_left + self.ki * self.integral_left + self.kd * derivative_left

        # 右轮 PID
        error_right = target_right - actual_right
        self.integral_right += error_right * dt
        derivative_right = (error_right - self.prev_error_right) / dt if dt > 0 else 0.0
        u_right = self.kp * error_right + self.ki * self.integral_right + self.kd * derivative_right

        self.prev_error_left = error_left
        self.prev_error_right = error_right

        return u_left, u_right
```

---

## 阿克曼转向 (Ackermann)

### 转向几何

```
       ○ ← 前轮转向中心
      / \
     /   \
    A     B ← 前轮
    |  ←  |  主销后倾距
    |     |
    C-----D ← 后轮
    |     |
    ←────→  wheel_base (前后轴距)
    ←─────→  front_track (前轮距)
    ←─────→  rear_track (后轮距)

内轮转角 α, 外轮转角 β:
tan(β) = wheel_base / (wheel_base + front_track / tan(α))
```

### 阿克曼运动学

```python
class AckermannSteering:
    """阿克曼转向"""

    def __init__(
        self,
        wheel_base: float,
        front_track: float,
        rear_track: float,
        wheel_radius: float
    ):
        self.L = wheel_base
        self.front_track = front_track
        self.rear_track = rear_track
        self.R = wheel_radius

    def steering_angles(self, steering_angle: float) -> Tuple[float, float]:
        """
        计算内外轮转向角

        Args:
            steering_angle: 方向盘输入角 (rad)

        Returns:
            (inner_angle, outer_angle): 内轮和外轮转角
        """
        if abs(steering_angle) < 1e-6:
            return 0.0, 0.0

        inner = steering_angle
        outer = np.arctan(
            self.L * np.tan(steering_angle) /
            (self.L + self.front_track / np.tan(steering_angle))
        )
        return inner, outer

    def velocity_to_wheel_velocities(
        self,
        v: float,
        omega: float
    ) -> dict:
        """
        车辆速度 → 各轮速度

        Args:
            v: 纵向速度 (m/s)
            omega: 转向角速度 (rad/s)

        Returns:
            各轮速度 (rad/s)
        """
        # 转向半径
        if abs(omega) < 1e-6:
            R = float('inf')
        else:
            R = v / omega

        # 四个车轮的转向角
        if R == float('inf'):
            # 直行
            return {
                "front_left": v / self.R,
                "front_right": v / self.R,
                "rear_left": v / self.R,
                "rear_right": v / self.R,
                "steering_front_left": 0.0,
                "steering_front_right": 0.0,
            }

        # 左转
        if omega > 0:
            inner_angle = np.arctan(self.L / (R - self.front_track / 2))
            outer_angle = np.arctan(self.L / (R + self.front_track / 2))
            rear_angle = 0.0
        else:
            inner_angle = -np.arctan(self.L / (R + self.front_track / 2))
            outer_angle = -np.arctan(self.L / (R - self.front_track / 2))
            rear_angle = 0.0

        # 各轮转速
        w_fl = omega * np.sqrt((R - self.front_track/2)**2 + self.L**2) / self.R
        w_fr = omega * np.sqrt((R + self.front_track/2)**2 + self.L**2) / self.R
        w_rl = omega * R / self.R
        w_rr = omega * R / self.R

        return {
            "front_left": w_fl,
            "front_right": w_fr,
            "rear_left": w_rl,
            "rear_right": w_rr,
            "steering_front_left": inner_angle if omega > 0 else outer_angle,
            "steering_front_right": outer_angle if omega > 0 else inner_angle,
        }
```

---

## 麦克纳姆轮 (Mecanum)

### 运动学 (X 型排列)

```python
class MecanumDrive:
    """麦克纳姆轮全向驱动"""

    def __init__(self, wheel_radius: float, robot_width: float, robot_length: float):
        self.R = wheel_radius
        self.w = robot_width    # 机器人宽度
        self.l = robot_length    # 机器人长度
        self.diagonal = np.sqrt(self.w**2 + self.l**2)

    def inverse_kinematics(
        self,
        vx: float,
        vy: float,
        omega: float
    ) -> Tuple[float, float, float, float]:
        """
        逆运动学: 机器人速度 → 四轮速度

        Args:
            vx: X方向速度 (m/s)
            vy: Y方向速度 (m/s)
            omega: 角速度 (rad/s)

        Returns:
            (w1, w2, w3, w4): 四轮角速度 (rad/s)
        """
        # X型排列的逆运动学矩阵
        k = 1.0 / self.R

        w1 = k * (vx - vy - omega * self.diagonal / 2)  # 左前
        w2 = k * (vx + vy + omega * self.diagonal / 2)  # 右前
        w3 = k * (vx + vy - omega * self.diagonal / 2)  # 右后
        w4 = k * (vx - vy + omega * self.diagonal / 2)  # 左后

        return w1, w2, w3, w4

    def forward_kinematics(
        self,
        w1: float,
        w2: float,
        w3: float,
        w4: float
    ) -> Tuple[float, float, float]:
        """
        正运动学: 四轮速度 → 机器人速度
        """
        k = self.R / 4.0

        vx = k * (w1 + w2 + w3 + w4)
        vy = k * (-w1 + w2 + w3 - w4)
        omega = k * (-w1 - w2 + w3 + w4) / (2 * self.diagonal)

        return vx, vy, omega
```

---

## ROS2 集成

### 底盘控制节点

```python
#!/usr/bin/env python3
"""轮式车辆底盘控制节点"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import JointState
import numpy as np


class WheeledVehicleControl(Node):
    """轮式车辆底盘控制节点"""

    def __init__(self, drive_type: str = "differential"):
        super().__init__('wheeled_vehicle_control')
        self.drive_type = drive_type

        self.declare_parameter('wheel_base', 0.5)
        self.declare_parameter('wheel_radius', 0.1)
        self.declare_parameter('max_linear_speed', 1.0)
        self.declare_parameter('max_angular_speed', 2.0)

        wb = self.get_parameter('wheel_base').value
        wr = self.get_parameter('wheel_radius').value
        self.differential = DifferentialDrive(wb, wr)

        self.joint_pub = self.create_publisher(
            JointState, '/vehicle/joint_commands', 10
        )
        self.cmd_sub = self.create_subscription(
            Twist, '/cmd_vel', self.cmd_callback, 10
        )

        self.get_logger().info(f'Wheeled Vehicle Control ({drive_type}) initialized')

    def cmd_callback(self, msg: Twist):
        v = np.clip(msg.linear.x, -1.0, 1.0)
        omega = np.clip(msg.angular.z, -2.0, 2.0)

        if self.drive_type == "differential":
            v_l, v_r = self.differential.inverse_kinematics(v, omega)
            self.publish_wheel_commands(v_l, v_r)
        elif self.drive_type == "mecanum":
            mecanum = MecanumDrive(0.05, 0.4, 0.4)
            w1, w2, w3, w4 = mecanum.inverse_kinematics(v, msg.linear.y, omega)
            self.publish_mecanum_commands(w1, w2, w3, w4)

    def publish_wheel_commands(self, v_left: float, v_right: float):
        cmd = JointState()
        cmd.header.stamp = self.get_clock().now().to_msg()
        cmd.name = ['left_wheel', 'right_wheel']
        cmd.velocity = [v_left / 0.1, v_right / 0.1]  # 线速度 → 角速度
        self.joint_pub.publish(cmd)

    def publish_mecanum_commands(self, w1, w2, w3, w4):
        cmd = JointState()
        cmd.header.stamp = self.get_clock().now().to_msg()
        cmd.name = ['wheel_fl', 'wheel_fr', 'wheel_rl', 'wheel_rr']
        cmd.velocity = [w1, w2, w3, w4]
        self.joint_pub.publish(cmd)


def main(args=None):
    rclpy.init(args=args)
    node = WheeledVehicleControl("differential")
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## URDF/XACRO 配置

```xml
<!-- 差速驱动底盘 URDF 示例 -->
<robot name="differential_robot">
  <link name="base_link">
    <visual>
      <geometry>
        <box size="0.5 0.3 0.1"/>
      </geometry>
    </visual>
  </link>

  <!-- 左轮 -->
  <joint name="left_wheel_joint" type="continuous">
    <parent link="base_link"/>
    <child link="left_wheel"/>
    <origin xyz="0 0.15 0" rpy="-1.5708 0 0"/>
    <axis xyz="0 0 1"/>
  </joint>

  <link name="left_wheel">
    <visual>
      <geometry>
        <cylinder radius="0.1" length="0.05"/>
      </geometry>
    </visual>
  </link>

  <!-- 右轮 -->
  <joint name="right_wheel_joint" type="continuous">
    <parent link="base_link"/>
    <child link="right_wheel"/>
    <origin xyz="0 -0.15 0" rpy="-1.5708 0 0"/>
    <axis xyz="0 0 1"/>
  </joint>

  <link name="right_wheel">
    <visual>
      <geometry>
        <cylinder radius="0.1" length="0.05"/>
      </geometry>
    </visual>
  </link>
</robot>
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 车辆走斜线 | 左右轮直径不一致 | 调校轮半径参数或电机增益 |
| 转向时打滑 | 麦克纳姆轮辊子方向装反 | 检查轮子 X/O 排列方向 |
| 阿克曼车辆转弯半径大 | 前后轴轴距过大 | 减小前轮最大转角 |
| 电机抖动 | PID 增益过高 | 减小 kp，增加 kd |

### 调试命令

```bash
# 查看里程计
ros2 topic echo /odom

# 手动发送速度命令
ros2 topic pub /cmd_vel geometry_msgs/Twist '{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.5}}'

# 查看关节状态
ros2 topic echo /vehicle/joint_states
```

---

## 相关技能

- `wheeled_vehicle/navigation` — 轮式车辆导航系统
- `wheeled_vehicle/localization` — 轮式车辆定位系统
- `wheeled_vehicle/perception` — 轮式车辆感知系统
- `wheeled_vehicle/sdf-xacro-model` — 轮式车辆 SDF/XACRO 模型
