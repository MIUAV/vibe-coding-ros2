---
name: rl-model-based
description: 模型-based 强化学习技能 - World Models、MPC、PlaNet、MuZero 实现
argument-hint: World Models OR MPC OR PlaNet OR 模型学习 OR model based RL
user-invocable: true
---

# 模型-Based 强化学习技能

> 学习环境模型的强化学习方法 - 数据效率高的机器人学习

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 World Models、PlaNet、MuZero
- 学习环境动力学模型
- 模型预测控制 (MPC)
- 想象推理 (Imagination)

---

## 核心算法

### World Models

```python
import torch
import torch.nn as nn

class WorldModel:
    def __init__(self, state_dim, action_dim, hidden_dim=256):
        # 编码器
        self.encoder = nn.Sequential(
            nn.Linear(state_dim + action_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, state_dim)  # 潜在空间
        )
        
        # 奖励预测器
        self.reward_predictor = nn.Sequential(
            nn.Linear(state_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, 1)
        )
        
        # 判别器 (用于 VAE)
        self.discriminator = nn.Sequential(
            nn.Linear(state_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, 1),
            nn.Sigmoid()
        )
        
    def forward(self, state, action):
        # 预测下一个潜在状态
        next_latent = self.encoder(torch.cat([state, action], dim=-1))
        reward = self.reward_predictor(next_latent)
        return next_latent, reward
    
    def imagine_rollout(self, initial_state, policy, horizon=50):
        """想象轨迹展开"""
        states = [initial_state]
        rewards = []
        
        for _ in range(horizon):
            action = policy(states[-1])
            next_state, reward = self.forward(states[-1], action)
            states.append(next_state)
            rewards.append(reward)
            
        return states, rewards
```

### MPC (Model Predictive Control)

```python
class MPCController:
    def __init__(self, world_model, action_dim, horizon=10, num_samples=100):
        self.world_model = world_model
        self.action_dim = action_dim
        self.horizon = horizon
        self.num_samples = num_samples
        
    def get_action(self, state, policy_net=None):
        best_action = None
        best_reward = float('-inf')
        
        for _ in range(self.num_samples):
            # 随机采样动作序列
            actions = torch.randn(self.horizon, self.action_dim)
            
            # 模拟轨迹
            current_state = state
            total_reward = 0
            
            for t in range(self.horizon):
                next_state, reward = self.world_model(current_state, actions[t])
                total_reward += reward
                
            if total_reward > best_reward:
                best_reward = total_reward
                best_action = actions[0]
                
        return best_action.unsqueeze(0)
```
