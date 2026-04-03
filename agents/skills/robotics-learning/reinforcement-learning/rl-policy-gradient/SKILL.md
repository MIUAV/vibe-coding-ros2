---
name: rl-policy-gradient
description: 策略梯度强化学习技能 - PPO、A3C、SAC、TRPO 算法实现与机器人应用
argument-hint: "PPO" / "A3C" / "SAC" / "策略梯度" / "policy gradient"
user-invocable: true
---

# 策略梯度强化学习技能

> 基于策略优化的强化学习算法 - 适用于连续动作空间的机器人控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 PPO、A3C、SAC、TRPO 算法
- 连续动作空间的机器人控制
- 策略网络设计
- 机器人运动规划

---

## 核心算法

### PPO (Proximal Policy Optimization)

```python
import torch
import torch.nn as nn
from torch.optim import Adam

class PPOLearner:
    def __init__(self, policy_net, value_net, lr=3e-4, clip_eps=0.2):
        self.policy_net = policy_net
        self.value_net = value_net
        self.optimizer = Adam(policy_net.parameters(), lr=lr)
        self.clip_eps = clip_eps
        
    def update(self, states, actions, rewards, old_log_probs, advantages):
        # 计算新策略的对数概率
        new_log_probs = self.policy_net.get_log_prob(states, actions)
        ratio = torch.exp(new_log_probs - old_log_probs)
        
        # PPO 裁剪目标
        surr1 = ratio * advantages
        surr2 = torch.clamp(ratio, 1 - self.clip_eps, 1 + self.clip_eps) * advantages
        policy_loss = -torch.min(surr1, surr2).mean()
        
        # 价值函数损失
        values = self.value_net(states)
        value_loss = nn.MSELoss()(values, rewards)
        
        # 联合优化
        loss = policy_loss + 0.5 * value_loss
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()
```

### SAC (Soft Actor-Critic)

```python
class SACLearner:
    def __init__(self, state_dim, action_dim):
        self.policy_net = GaussianPolicy(state_dim, action_dim)
        self.q_net1 = QNetwork(state_dim, action_dim)
        self.q_net2 = QNetwork(state_dim, action_dim)
        self.target_q_net1 = QNetwork(state_dim, action_dim)
        self.target_q_net2 = QNetwork(state_dim, action_dim)
        self.alpha = torch.tensor(0.2, requires_grad=True)
        
    def update(self, replay_buffer, batch_size=256):
        batch = replay_buffer.sample(batch_size)
        states, actions, rewards, next_states, dones = batch
        
        # 更新 Q 函数
        with torch.no_grad():
            next_actions, next_log_probs = self.policy_net.sample(next_states)
            target_q = torch.min(
                self.target_q_net1(next_states, next_actions),
                self.target_q_net2(next_states, next_actions)
            ) - self.alpha * next_log_probs
            target_q = rewards + (1 - dones) * 0.99 * target_q
            
        q1_loss = nn.MSELoss()(self.q_net1(states, actions), target_q)
        q2_loss = nn.MSELoss()(self.q_net2(states, actions), target_q)
        
        # 更新策略
        new_actions, log_probs = self.policy_net.sample(states)
        q_values = torch.min(
            self.q_net1(states, new_actions),
            self.q_net2(states, new_actions)
        )
        policy_loss = (self.alpha * log_probs - q_values).mean()
```

---

## ROS2 集成

### 环境封装

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import Float32MultiArray
import numpy as np

class RLEnvironment(Node):
    def __init__(self):
        super().__init__('rl_environment')
        self.state_sub = self.create_subscription(
            Float32MultiArray, '/robot/state', self.state_callback, 10)
        self.action_pub = self.create_publisher(
            Float32MultiArray, '/robot/action', 10)
        self.reward_pub = self.create_publisher(
            Float32MultiArray, '/robot/reward', 10)
        
    def state_callback(self, msg):
        self.current_state = np.array(msg.data)
        
    def reset(self):
        # 重置环境
        return self.current_state
        
    def step(self, action):
        self.action_pub.publish(Float32MultiArray(data=action))
        # 等待下一个状态
        return self.current_state, reward, done, info
```
