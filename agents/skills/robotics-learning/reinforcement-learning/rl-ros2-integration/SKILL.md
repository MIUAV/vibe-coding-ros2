---
name: rl-ros2-integration
description: 强化学习 ROS2 集成技能 - Gazebo/Isaac Gym 训练环境、ROS2 消息、行动服务器
argument-hint: "RL ROS2" / "Gazebo RL" / "Isaac Gym" / "ros2 reinforcement"
user-invocable: true
---

# 强化学习 ROS2 集成技能

> 在 ROS2 环境中部署和运行强化学习算法

---

## 何时使用

当需要以下帮助时使用此技能：
- ROS2 机器人 RL 训练
- Gazebo/Isaac Gym 集成
- ROS2 消息接口定义
- Action/Service 通讯

---

## ROS2 环境封装

### Gazebo RL 环境

```python
import rclpy
from rclpy.node import Node
from gazebo_msgs.srv import SetModelState, GetModelState
from geometry_msgs.msg import Pose
import numpy as np

class GazeboRLEnv(Node):
    def __init__(self):
        super().__init__('gazebo_rl_env')
        self.set_state_client = self.create_client(SetModelState, '/gazebo/set_model_state')
        self.get_state_client = self.create_client(GetModelState, '/gazebo/get_model_state')
        
    def reset(self):
        # 重置机器人位置
        req = SetModelState.Request()
        req.model_state.pose.position.x = 0.0
        # ... 设置初始姿态
        self.set_state_client.call_async(req)
        return self._get_state()
        
    def step(self, action):
        # 发送控制命令
        self._apply_action(action)
        
        # 获取下一个状态
        next_state = self._get_state()
        reward = self._compute_reward(next_state)
        done = self._is_done(next_state)
        
        return next_state, reward, done, {}
        
    def _get_state(self):
        # 获取机器人状态
        req = GetModelState.Request()
        req.model_name = 'robot'
        response = self.get_state_client.call(req)
        return np.array([
            response.pose.position.x, response.pose.position.y,
            response.twist.linear.x, response.twist.linear.y
        ])
```

### Isaac Gym 集成

```python
class IsaacGymEnv:
    def __init__(self, num_envs=100):
        import isaacgym
        from isaacgym import gymapi
        from isaacgym import gymutilities
        
        self.gym = gymapi.acquire_gym()
        
        # 创建仿真器
        sim_params = gymapi.SimParams()
        sim_params.dt = 1.0 / 60.0
        self.sim = self.gym.create_sim(0, 0, sim_type=gymapi.SIM_PHYSX, params=sim_params)
        
        # 创建环境
        self.envs = []
        for i in range(num_envs):
            env = self._create_env(self.sim)
            self.envs.append(env)
            
    def reset(self):
        states = []
        for env in self.envs:
            state = self._reset_env(env)
            states.append(state)
        return np.array(states)
        
    def step(self, actions):
        # 并行执行所有环境
        for env, action in zip(self.envs, actions):
            self._apply_action(env, action)
        self.gym.step_graphics(self.sim)
        
        states, rewards, dones = [], [], []
        for env in self.envs:
            states.append(self._get_state(env))
            rewards.append(self._compute_reward(env))
            dones.append(self._is_done(env))
            
        return np.array(states), np.array(rewards), np.array(dones), {}
```
