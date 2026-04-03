---
name: humanoid-motion-control
description: 人形机器人运动控制技能 - 步态规划、逆运动学、ZMP平衡控制、全身协调、关节力控
argument-hint: "人形运动控制" / "双足步态" / "IK控制" / "ZMP平衡" / "力控"
user-invocable: true
---

# 人形机器人运动控制技能

> 用于开发双足人形机器人的运动控制系统，包含步态规划、逆运动学、ZMP平衡和全身协调

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现双足步态规划和行走
- 逆运动学（IK）求解和关节控制
- ZMP / CoM 平衡控制
- 全身运动协调
- 关节力矩控制
- 不平整地形步态适应

---

## 快速参考

### 坐标系定义

```
人形机器人坐标系 (ROS2 standard):
- X: 前进方向 (forward)
- Y: 侧向 (left = negative, right = positive)
- Z: 垂直向上 (up)
- 原点: 骨盆中心 (pelvis center)

关节链: hip_yaw → hip_roll → hip_pitch → knee_pitch → ankle_pitch → ankle_roll
```

### 常用参数

```yaml
humanoid_motion:
  leg_length: 0.45          # 腿长 (m)
  hip_height: 0.85         # 髋高 (m)
  foot_size: 0.15 x 0.08   # 脚尺寸 (m)

  gait:
    step_height: 0.06       # 步高 (m)
    step_length: 0.25        # 步长 (m)
    step_period: 0.8         # 单步周期 (s)
    support_ratio: 0.6       # 支撑相占比
    double_support: 0.1      # 双脚支撑时间 (s)

  balance:
    zmp_margin: 0.03        # ZMP 安全裕度 (m)
    com_height: 0.75        # 质心高度 (m)
    ankle_height: 0.04       # 踝关节高度 (m)
```

---

## 步态规划

### 步态周期分解

```
单步周期 (step_period)
├── 支撑相 (60%): 单脚支撑
│   └── 双脚支撑 (12%): 过渡阶段
└── 摆动相 (40%): 另一只脚向前摆动
```

### 步态时序生成

```python
import numpy as np
from typing import List, Tuple

class GaitPlanner:
    """步态规划器"""

    def __init__(self, params: dict):
        self.step_height = params["step_height"]
        self.step_length = params["step_length"]
        self.step_period = params["step_period"]
        self.support_ratio = params["support_ratio"]
        self.leg_length = params["leg_length"]

    def generate_gait_sequence(
        self,
        steps: int,
        direction: Tuple[float, float] = (1.0, 0.0)
    ) -> List[dict]:
        """生成步态序列"""
        sequence = []
        support_leg = "left"

        for i in range(steps):
            if support_leg == "left":
                swing_foot_target = {
                    "leg": "right",
                    "position": [
                        direction[0] * self.step_length * i,
                        -self.step_length * 0.5,
                        self.step_height,
                    ],
                    "time": i * self.step_period,
                }
                support_leg = "right"
            else:
                swing_foot_target = {
                    "leg": "left",
                    "position": [
                        direction[0] * self.step_length * i,
                        self.step_length * 0.5,
                        self.step_height,
                    ],
                    "time": i * self.step_period,
                }
                support_leg = "left"

            sequence.append(swing_foot_target)

        return sequence

    def compute_zmp_trajectory(
        self,
        com_positions: List[np.ndarray],
        forces: List[np.ndarray]
    ) -> List[np.ndarray]:
        """计算 ZMP 轨迹"""
        zmp_trajectory = []
        for com, f in zip(com_positions, forces):
            if np.sum(f) > 1e-6:
                x_zmp = np.sum(com[0] * f) / np.sum(f)
                y_zmp = np.sum(com[1] * f) / np.sum(f)
                zmp_trajectory.append(np.array([x_zmp, y_zmp, 0.0]))
            else:
                zmp_trajectory.append(com)
        return zmp_trajectory
```

### 步态状态机

```python
from enum import Enum

class GaitState(Enum):
    IDLE = "idle"
    STAND = "stand"
    WALK_START = "walk_start"
    WALKING = "walking"
    WALK_STOP = "walk_stop"
    STEP_OVER = "step_over"
    RECOVERY = "recovery"

class GaitStateMachine:
    """步态状态机"""

    def __init__(self):
        self.state = GaitState.IDLE
        self.transitions = {
            GaitState.IDLE: [GaitState.STAND],
            GaitState.STAND: [GaitState.WALK_START, GaitState.IDLE],
            GaitState.WALK_START: [GaitState.WALKING],
            GaitState.WALKING: [GaitState.WALK_STOP, GaitState.STEP_OVER],
            GaitState.STEP_OVER: [GaitState.WALKING, GaitState.RECOVERY],
            GaitState.WALK_STOP: [GaitState.STAND],
            GaitState.RECOVERY: [GaitState.STAND, GaitState.WALKING],
        }

    def transition(self, new_state: GaitState) -> bool:
        if new_state in self.transitions[self.state]:
            self.state = new_state
            return True
        return False
```

---

## 逆运动学 (IK)

### 腿部 IK 求解

```python
import numpy as np
from typing import List, Optional

class LegIK:
    """腿部逆运动学"""

    JOINT_LIMITS = {
        "hip_yaw": (-0.5, 0.5),
        "hip_roll": (-0.3, 0.3),
        "hip_pitch": (-1.2, 0.8),
        "knee_pitch": (-0.2, 2.2),
        "ankle_pitch": (-0.8, 0.8),
        "ankle_roll": (-0.4, 0.4),
    }

    def __init__(self, leg_length: float = 0.45):
        self.L_upper = leg_length * 0.5
        self.L_lower = leg_length * 0.5

    def solve(
        self,
        foot_pos: np.ndarray,
        hip_roll: float = 0.0,
        is_left: bool = True
    ) -> Optional[List[float]]:
        """
        求解腿部逆运动学
        Returns: [hip_yaw, hip_roll, hip_pitch, knee_pitch, ankle_pitch, ankle_roll]
        """
        x, y, z = foot_pos
        side_sign = 1.0 if is_left else -1.0
        h = np.sqrt(x**2 + y**2)
        r = np.sqrt(h**2 + z**2)

        max_reach = self.L_upper + self.L_lower
        min_reach = abs(self.L_upper - self.L_lower)
        if r > max_reach or r < min_reach:
            return None

        alpha = np.arctan2(h, -z)
        cos_knee = (r**2 - self.L_upper**2 - self.L_lower**2) / (2 * self.L_upper * self.L_lower)
        cos_knee = np.clip(cos_knee, -1.0, 1.0)
        knee_angle = np.arccos(cos_knee)

        beta = np.arctan2(self.L_lower * np.sin(knee_angle),
                         self.L_upper + self.L_lower * np.cos(knee_angle))
        hip_pitch = alpha + beta
        ankle_pitch = -(hip_pitch - knee_angle) - hip_pitch * 0.5

        return [
            0.0,
            hip_roll * side_sign,
            hip_pitch,
            -knee_angle,
            ankle_pitch,
            0.0,
        ]
```

### 全身 IK (Whole-Body IK)

```python
class WholeBodyIK:
    """全身逆运动学"""

    def __init__(self):
        self.legs = {"left": LegIK(), "right": LegIK()}
        self.torso_orientation = np.array([0.0, 0.0, 0.0])

    def solve(
        self,
        left_foot_pos: np.ndarray,
        right_foot_pos: np.ndarray,
        com_pos: np.ndarray,
        torso_orientation: np.ndarray = None,
    ) -> dict:
        """全身 IK 求解"""
        result = {}
        left_joints = self.legs["left"].solve(left_foot_pos, is_left=True)
        result["left_leg"] = left_joints
        right_joints = self.legs["right"].solve(right_foot_pos, is_left=False)
        result["right_leg"] = right_joints

        if torso_orientation is not None:
            self.torso_orientation = torso_orientation

        pelvis_roll = np.arctan2(
            right_foot_pos[1] - left_foot_pos[1],
            right_foot_pos[0] - left_foot_pos[0]
        )
        dx = right_foot_pos[0] - left_foot_pos[0]
        dz = right_foot_pos[2] - left_foot_pos[2]
        pelvis_pitch = np.arctan2(dx, -dz) if abs(dz) > 1e-6 else 0.0

        result["torso"] = [0.0, pelvis_roll, pelvis_pitch]
        return result
```

---

## ZMP 平衡控制

```python
class ZMPController:
    """Zero Moment Point 平衡控制器"""

    def __init__(self, params: dict):
        self.com_height = params["com_height"]
        self.zmp_margin = params["zmp_margin"]
        self.ankle_height = params["ankle_height"]
        self.g = 9.81
        self.zmp_ref = np.array([0.0, 0.0])
        self.kp = 1.0
        self.kd = 0.5

    def compute_zmp(self, cop: np.ndarray, force: np.ndarray) -> np.ndarray:
        """计算 ZMP 位置"""
        if abs(force[2]) < 1e-6:
            return cop
        return np.array([cop[0], cop[1]])

    def is_zmp_inside_polygon(
        self,
        zmp: np.ndarray,
        polygon: np.ndarray
    ) -> bool:
        """检查 ZMP 是否在支撑多边形内"""
        min_x, max_x = np.min(polygon[:, 0]), np.max(polygon[:, 0])
        min_y, max_y = np.min(polygon[:, 1]), np.max(polygon[:, 1])
        return (min_x - self.zmp_margin <= zmp[0] <= max_x + self.zmp_margin and
                min_y - self.zmp_margin <= zmp[1] <= max_y + self.zmp_margin)

    def emergency_com_adjustment(
        self,
        zmp: np.ndarray,
        polygon: np.ndarray
    ) -> np.ndarray:
        """紧急情况下的 CoM 调整"""
        center = np.mean(polygon, axis=0)
        adjustment = center - zmp
        return adjustment * 2.0
```

---

## ROS2 集成

### 节点结构

```python
#!/usr/bin/env python3
"""人形机器人运动控制节点"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import JointState, Imu
import numpy as np


class HumanoidMotionControl(Node):
    """人形机器人运动控制节点"""

    def __init__(self):
        super().__init__('humanoid_motion_control')

        self.declare_parameter('leg_length', 0.45)
        self.leg_length = self.get_parameter('leg_length').value

        self.gait_planner = GaitPlanner({
            'step_height': 0.06,
            'step_length': 0.25,
            'step_period': 0.8,
            'support_ratio': 0.6,
            'leg_length': self.leg_length,
        })
        self.leg_ik = LegIK(self.leg_length)
        self.balance_controller = ZMPController({
            'com_height': 0.75,
            'zmp_margin': 0.03,
            'ankle_height': 0.04,
        })

        self.joint_cmd_pub = self.create_publisher(
            JointState, '/humanoid/joint_commands', 10
        )
        self.cmd_sub = self.create_subscription(
            Twist, '/humanoid/cmd_vel', self.cmd_callback, 10
        )
        self.imu_sub = self.create_subscription(
            Imu, '/imu/data', self.imu_callback, 10
        )

        self.get_logger().info('Humanoid Motion Control initialized')

    def cmd_callback(self, msg: Twist):
        direction = np.array([msg.linear.x, msg.linear.y])
        steps = int(abs(msg.linear.x) / 0.25) + 1
        gait_sequence = self.gait_planner.generate_gait_sequence(steps, direction)
        for step in gait_sequence:
            self.execute_step(step)

    def execute_step(self, step: dict):
        foot_pos = np.array(step['position'])
        if step['leg'] == 'left':
            joint_angles = self.leg_ik.solve(foot_pos, is_left=True)
        else:
            joint_angles = self.leg_ik.solve(foot_pos, is_left=False)
        if joint_angles:
            self.publish_joint_command(step['leg'], joint_angles)

    def publish_joint_command(self, leg: str, angles: list):
        cmd = JointState()
        cmd.header.stamp = self.get_clock().now().to_msg()
        cmd.name = [f'{leg}_hip_yaw', f'{leg}_hip_roll', f'{leg}_hip_pitch',
                    f'{leg}_knee', f'{leg}_ankle', f'{leg}_ankle_roll']
        cmd.position = angles
        self.joint_cmd_pub.publish(cmd)


def main(args=None):
    rclpy.init(args=args)
    node = HumanoidMotionControl()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 腿部 IK 返回 None | 目标位置超出可达范围 | 检查 foot_pos，确保在腿长范围内 |
| ZMP 不稳定 | 步长太大或地面湿滑 | 减小 step_length，增加 zmp_margin |
| 行走时身体前倾 | 质心靠前 | 调整 CoM 位置，或增大 ankle_height |
| 关节震动 | 增益过高 | 减小 kp/kd 值，增加阻尼 |
| 跨步时绊倒 | 摆动相时间不足 | 增加 step_period 或减小 step_length |

### 调试命令

```bash
ros2 topic echo /humanoid/joint_states
ros2 topic echo /imu/data
ros2 topic pub /humanoid/cmd_vel geometry_msgs/Twist '{linear: {x: 0.2, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}'
```

---

## 相关技能

- `humanoid/navigation` — 人形机器人导航系统
- `humanoid/perception` — 人形机器人感知系统
- `humanoid/localization` — 人形机器人定位系统
- `humanoid/skill-planning` — 人形机器人技能规划
- `humanoid/sdf-xacro-model` — 人形机器人 SDF/XACRO 模型
