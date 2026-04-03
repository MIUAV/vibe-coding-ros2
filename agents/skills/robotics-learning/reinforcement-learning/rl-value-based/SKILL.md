---
name: rl-value-based
description: 值函数强化学习技能 - DQN、Double DQN、PER、Dueling DQN 算法实现
argument-hint: DQN OR Double DQN OR PER OR 值函数 OR value based
user-invocable: true
---

# 值函数强化学习技能

> 基于值函数的强化学习方法 - 离散动作空间的机器人决策

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 DQN、Double DQN、PER、Dueling DQN
- 离散动作空间的机器人决策
- 经验回放缓冲区管理
- 目标网络更新

---

## 核心算法

### DQN (Deep Q-Network)

```python
import torch
import torch.nn as nn
import numpy as np

class DQN(nn.Module):
    def __init__(self, state_dim, action_dim, hidden_dim=128):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, action_dim)
        )
        
    def forward(self, state):
        return self.net(state)

class DQNAgent:
    def __init__(self, state_dim, action_dim, lr=1e-3, gamma=0.99):
        self.q_net = DQN(state_dim, action_dim)
        self.target_net = DQN(state_dim, action_dim)
        self.target_net.load_state_dict(self.q_net.state_dict())
        self.optimizer = torch.optim.Adam(self.q_net.parameters(), lr=lr)
        self.gamma = gamma
        self.action_dim = action_dim
        
    def update(self, states, actions, rewards, next_states, dones):
        with torch.no_grad():
            target_q = rewards + (1 - dones) * self.gamma * self.target_net(next_states).max(1)[0]
        
        current_q = self.q_net(states).gather(1, actions.unsqueeze(1)).squeeze()
        loss = nn.MSELoss()(current_q, target_q)
        
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()
        
    def update_target(self):
        self.target_net.load_state_dict(self.q_net.state_dict())
```

### PER (Prioritized Experience Replay)

```python
class PrioritizedReplayBuffer:
    def __init__(self, capacity, alpha=0.6):
        self.capacity = capacity
        self.alpha = alpha
        self.buffer = []
        self.priorities = np.zeros(capacity, dtype=np.float32)
        self.position = 0
        
    def push(self, state, action, reward, next_state, done):
        max_priority = self.priorities.max() if self.buffer else 1.0
        if len(self.buffer) < self.capacity:
            self.buffer.append((state, action, reward, next_state, done))
        else:
            self.buffer[self.position] = (state, action, reward, next_state, done)
        self.priorities[self.position] = max_priority
        self.position = (self.position + 1) % self.capacity
        
    def sample(self, batch_size, beta=0.4):
        if len(self.buffer) == self.capacity:
            priorities = self.priorities
        else:
            priorities = self.priorities[:self.position]
            
        probs = priorities ** self.alpha
        probs /= probs.sum()
        
        indices = np.random.choice(len(self.buffer), batch_size, p=probs)
        samples = [self.buffer[idx] for idx in indices]
        
        weights = (len(self.buffer) * probs[indices]) ** (-beta)
        weights /= weights.max()
        
        return samples, indices, weights
```
