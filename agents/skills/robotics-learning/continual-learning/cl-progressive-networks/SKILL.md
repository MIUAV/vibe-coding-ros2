---
name: cl-progressive-networks
description: 渐进式网络技能 - 横向扩展网络、专家混合、模块化技能组合
argument-hint: "渐进网络" / "progressive networks" / "专家混合" / "mixture of experts"
user-invocable: true
---

# 渐进式网络技能

> 通过横向扩展网络容量来适应新任务的持续学习方法

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现渐进式网络架构
- 专家混合系统
- 模块化技能组合
- 机器人技能库扩展

---

## 核心架构

### 渐进式网络

```python
import torch
import torch.nn as nn

class ProgressiveNetwork(nn.Module):
    def __init__(self, input_dim, task_configs):
        super().__init__()
        self.task_configs = task_configs
        self.networks = nn.ModuleList()
        self.adapters = nn.ModuleList()
        
        # 第一个任务网络
        self.networks.append(self._create_network(input_dim, task_configs[0]))
        
    def add_task(self, task_config):
        """为新任务添加网络列"""
        # 获取之前网络的特征维度
        if len(self.networks) > 0:
            prev_output_dim = self.task_configs[len(self.networks) - 1]['hidden_dim']
        else:
            prev_output_dim = self.networks[-1][-1].out_features
            
        # 创建新任务网络
        new_network = self._create_network(input_dim, task_config, prev_output_dim)
        self.networks.append(new_network)
        
        # 添加横向连接适配器
        adapter = nn.Sequential(
            nn.Linear(prev_output_dim, task_config['hidden_dim']),
            nn.ReLU()
        )
        self.adapters.append(adapter)
        
    def forward(self, x, task_id):
        """前向传播指定任务"""
        if task_id == 0:
            return self.networks[0](x)
            
        # 获取之前任务的特征
        prev_features = x
        for i in range(task_id):
            prev_out = self.networks[i](prev_features)
            if i < len(self.adapters):
                prev_features = self.adapters[i](prev_out)
            else:
                prev_features = prev_out
                
        # 融合特征并通过当前任务网络
        current_out = self.networks[task_id](prev_features)
        return current_out

class MixtureOfExperts(nn.Module):
    def __init__(self, input_dim, hidden_dim, num_experts=5):
        super().__init__()
        self.num_experts = num_experts
        self.experts = nn.ModuleList([
            nn.Sequential(
                nn.Linear(input_dim, hidden_dim),
                nn.ReLU(),
                nn.Linear(hidden_dim, hidden_dim)
            ) for _ in range(num_experts)
        ])
        self.gate = nn.Linear(input_dim, num_experts)
        
    def forward(self, x):
        gate_values = torch.softmax(self.gate(x), dim=-1)
        expert_outputs = torch.stack([expert(x) for expert in self.experts], dim=1)
        output = torch.einsum('bne,bn->be', expert_outputs, gate_values)
        return output
```
