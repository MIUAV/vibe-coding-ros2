# Reinforcement Learning Control Context

## RL 算法速查
| 算法 | 类型 | 动作空间 | 适用场景 | 库 |
|------|------|---------|---------|----|
| DDPG | Off-policy | 连续 | 连续控制（机械臂）| SB3 |
| PPO | On-policy | 连续/离散 | 通用，稳定性好 | SB3 / Tianshou |
| SAC | Off-policy | 连续 | 最大熵机器人控制 | SB3 |
| TD3 | Off-policy | 连续 | DDPG 优化版 | SB3 |
| QMIX | 值分解 | 离散 | 多智能体协作 | PyMARL |

## Sim2Real 流水线
```
仿真训练（域随机化）
  ↓ 百万步训练
检查点 (.pth / .onnx)
  ↓ 量化校准
边缘部署（TensorRT / RKNN / OpenVINO）
```

## 域随机化（Domain Randomization）
```python
import numpy as np

def randomize_env(sim):
    sim.robot_mass      = np.random.uniform(0.8, 1.2) * base_mass
    sim.friction        = np.random.uniform(0.5, 1.5)
    sim.camera_noise    = np.random.uniform(0.0, 0.05)
    sim.light_intensity = np.random.uniform(0.7, 1.3)
    sim.object_position = np.random.uniform(-0.1, 0.1, 3)
```

## ROS2 集成
```python
import rclpy
from rclpy.node import Node
from stable_baselines3 import SAC
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint

class RLAgentNode(Node):
    def __init__(self):
        super().__init__('rl_agent')
        self.model = SAC.load('/path/to/model.zip')
        self.joint_sub = self.create_subscription(
            JointTrajectory, '/joint_states', self.joint_callback, 10)
        self.action_pub = self.create_publisher(
            JointTrajectory, '/position_joint_trajectory_controller/joint_trajectory_cmd', 1)
        self.state = None

    def joint_callback(self, msg):
        # 归一化状态
        self.state = np.array(msg.positions) / np.pi
        action, _ = self.model.predict(self.state, deterministic=True)
        self.publish_action(action)

    def publish_action(self, action):
        # 反归一化 + 发布
        action_rad = action * np.pi
        pt = JointTrajectoryPoint(positions=action_rad.tolist())
        cmd = JointTrajectory(joint_names=['joint1','joint2','joint3'], points=[pt])
        self.action_pub.publish(cmd)
```

## 常用奖励函数
```python
def reward_function(state, action, next_state):
    r_task    = -distance_to_goal(next_state)   # 任务奖励
    r_control = -0.01 * np.sum(action**2)       # 能量惩罚
    r_smooth  = -0.01 * np.sum(np.diff(action)) # 动作平滑
    return r_task + r_control + r_smooth
```

## 生成器选择
- `ros2-rl-controller-generator.sh` — DDPG | PPO | SAC | TD3
- `ros2-simulator-generator.sh` — manipulator | wheeled（配合 RL）
