---
name: rl-multi-agent
description: 多智能体强化学习技能 - MADDPG、QMIX、COMA、MAPPO 实现
argument-hint: "多智能体" / "MADDPG" / "QMIX" / "MARL" / "multi-agent"
user-invocable: true
---

# 多智能体强化学习技能

> 多个机器人协同决策的强化学习方法

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 MADDPG、QMIX、COMA、MAPPO
- 多机器人协同控制
- 合作/竞争场景
- 联合动作空间

---

## 核心算法

### MADDPG (Multi-Agent DDPG)

```python
import torch
import torch.nn as nn

class MADDPGAgent:
    def __init__(self, state_dim, action_dim, num_agents):
        self.num_agents = num_agents
        self.actors = [Actor(state_dim, action_dim) for _ in range(num_agents)]
        self.critics = [Critic(state_dim * num_agents, action_dim * num_agents) 
                        for _ in range(num_agents)]
        
    def get_actions(self, states, noise=0.1):
        actions = []
        for i, actor in enumerate(self.actors):
            action = actor(states[i])
            action += torch.randn_like(action) * noise
            actions.append(action.clamp(-1, 1))
        return actions
    
    def update(self, experiences, agent_idx):
        states, actions, rewards, next_states, dones = experiences
        
        # 更新 Critic
        all_next_actions = [self.actors[i](next_states[i]) for i in range(self.num_agents)]
        all_next_actions_flat = torch.cat(all_next_actions, dim=-1)
        
        with torch.no_grad():
            next_q = self.critics[agent_idx](next_states, all_next_actions_flat)
            target_q = rewards[agent_idx] + 0.99 * next_q
            
        current_q = self.critics[agent_idx](states, actions)
        critic_loss = nn.MSELoss()(current_q, target_q)
        
        # 更新 Actor
        all_actions = [self.actors[i](states[i]) for i in range(self.num_agents)]
        all_actions[agent_idx] = self.actors[agent_idx](states[agent_idx])
        all_actions_flat = torch.cat(all_actions, dim=-1)
        
        actor_loss = -self.critics[agent_idx](states, all_actions_flat).mean()
```

### QMIX

```python
class QMixer(nn.Module):
    def __init__(self, num_agents, state_dim, embed_dim=32):
        super().__init__()
        self.num_agents = num_agents
        self.state_dim = state_dim
        
        # 超网络生成权重
        self.hyper_w1 = nn.Sequential(
            nn.Linear(state_dim, embed_dim),
            nn.ReLU(),
            nn.Linear(embed_dim, num_agents * embed_dim)
        )
        self.hyper_b1 = nn.Linear(state_dim, embed_dim)
        
        self.hyper_w2 = nn.Sequential(
            nn.Linear(state_dim, embed_dim),
            nn.ReLU(),
            nn.Linear(embed_dim, embed_dim)
        )
        self.hyper_b2 = nn.Linear(state_dim, embed_dim)
        
    def forward(self, q_values, state):
        # q_values: [batch, num_agents]
        batch_size = q_values.shape[0]
        
        w1 = torch.abs(self.hyper_w1(state))
        b1 = self.hyper_b1(state)
        w2 = torch.abs(self.hyper_w2(state))
        b2 = self.hyper_b2(state)
        
        # 混合网络
        q_values = q_values.view(batch_size, 1, self.num_agents)
        hidden = torch.relu(torch.bmm(q_values, w1.view(batch_size, self.num_agents, -1)) + b1.view(batch_size, 1, -1))
        q_tot = torch.bmm(hidden, w2.view(batch_size, -1, 1)).squeeze(-1) + b2.squeeze(-1)
        
        return q_tot
```
