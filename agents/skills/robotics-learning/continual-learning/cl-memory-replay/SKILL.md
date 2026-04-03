---
name: cl-memory-replay
description: 记忆回放技能 - Experience Replay、Generative Replay、Constrained Optimization
argument-hint: "记忆回放" / "experience replay" / "generative replay" / "MEGA"
user-invocable: true
---

# 记忆回放技能

> 通过回放旧任务样本来防止遗忘的持续学习方法

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现经验回放缓冲区
- 生成式回放方法
- 混合旧新样本训练
- 机器人经验存储

---

## 核心方法

### Experience Replay Buffer

```python
import numpy as np
import torch
from collections import deque

class PrioritizedReplayBuffer:
    def __init__(self, capacity, alpha=0.6, beta=0.4):
        self.capacity = capacity
        self.alpha = alpha
        self.beta = beta
        self.buffer = deque(maxlen=capacity)
        self.priorities = np.zeros(capacity, dtype=np.float32)
        self.position = 0
        
    def push(self, state, action, reward, next_state, done):
        max_priority = self.priorities.max() if len(self.buffer) > 0 else 1.0
        
        if len(self.buffer) < self.capacity:
            self.buffer.append((state, action, reward, next_state, done))
        else:
            self.buffer[self.position] = (state, action, reward, next_state, done)
            
        self.priorities[self.position] = max_priority
        self.position = (self.position + 1) % self.capacity
        
    def sample(self, batch_size):
        if len(self.buffer) == 0:
            return None
            
        priorities = self.priorities[:len(self.buffer)]
        probs = priorities ** self.alpha
        probs /= probs.sum()
        
        indices = np.random.choice(len(self.buffer), batch_size, p=probs, replace=False)
        
        weights = (len(self.buffer) * probs[indices]) ** (-self.beta)
        weights /= weights.max()
        
        samples = [self.buffer[idx] for idx in indices]
        states, actions, rewards, next_states, dones = zip(*samples)
        
        return (np.array(states), np.array(actions), np.array(rewards),
                np.array(next_states), np.array(dones), indices, weights)

class GenerativeReplayBuffer:
    def __init__(self, generator, capacity=10000, latent_dim=128):
        self.generator = generator
        self.capacity = capacity
        self.latent_dim = latent_dim
        self.buffer = deque(maxlen=capacity)
        
    def store(self, state, label):
        """存储真实样本"""
        self.buffer.append((state, label))
        
    def generate_samples(self, num_samples):
        """生成伪样本"""
        self.generator.eval()
        with torch.no_grad():
            z = torch.randn(num_samples, self.latent_dim)
            fake_samples = self.generator(z)
        self.generator.train()
        return fake_samples
    
    def get_replay_samples(self, num_samples, use_generated=0.5):
        """获取混合回放样本"""
        num_real = int(num_samples * (1 - use_generated))
        num_fake = num_samples - num_real
        
        real_indices = np.random.choice(len(self.buffer), min(num_real, len(self.buffer)), replace=False)
        real_samples = [self.buffer[i][0] for i in real_indices]
        
        fake_samples = self.generate_samples(num_fake)
        
        return real_samples + [fake_samples[i] for i in range(fake_samples.shape[0])]
```
