---
name: il-task-incremental
description: 任务增量学习技能 - 任务专属参数、渐进网络、动态架构
argument-hint: 任务增量 OR task incremental OR task-aware OR 渐进扩展
user-invocable: true
---

# 任务增量学习技能

> 每个任务有专属参数，网络逐步扩展的能力

---

## 何时使用

当需要以下帮助时使用此技能：
- 多任务机器人学习
- 任务专属技能获取
- 网络动态扩展
- 任务边界清晰场景

---

## 核心实现

### 任务专属参数

```python
import torch
import torch.nn as nn

class TaskIncrementalNetwork(nn.Module):
    def __init__(self, input_dim, task_configs):
        super().__init__()
        self.input_dim = input_dim
        self.task_configs = task_configs
        
        # 共享基础参数
        self.shared_layers = nn.Sequential(
            nn.Linear(input_dim, 256),
            nn.ReLU(),
            nn.Linear(256, 128),
            nn.ReLU()
        )
        
        # 任务特定参数
        self.task_heads = nn.ModuleDict()
        self.task_params = nn.ModuleDict()
        
        for task_id, config in enumerate(task_configs):
            # 添加任务专属头
            self.task_heads[str(task_id)] = nn.Linear(128, config['num_classes'])
            
            # 添加任务特定层 (可选)
            if config.get('add_layers', False):
                self.task_params[f'task_{task_id}_extra'] = nn.Sequential(
                    nn.Linear(128, 64),
                    nn.ReLU()
                )
                
    def forward(self, x, task_id):
        """任务感知前向传播"""
        shared_features = self.shared_layers(x)
        
        # 获取任务专属输出
        if str(task_id) in self.task_heads:
            task_output = self.task_heads[str(task_id)](shared_features)
        else:
            # 默认使用最后一个任务的分类器
            task_output = self.task_heads[str(max(int(k) for k in self.task_heads.keys()))](shared_features)
            
        return task_output
    
    def add_task(self, task_config):
        """添加新任务"""
        new_task_id = len(self.task_configs)
        self.task_configs.append(task_config)
        
        # 添加新任务的分类头
        self.task_heads[str(new_task_id)] = nn.Linear(128, task_config['num_classes'])
        
        # 添加新任务的专属层
        if task_config.get('add_layers', False):
            self.task_params[f'task_{new_task_id}_extra'] = nn.Sequential(
                nn.Linear(128, 64),
                nn.ReLU()
            )
```

### 渐进式网络扩展

```python
class ProgressiveTaskNetwork(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.input_dim = input_dim
        self.task_columns = nn.ModuleList()
        self.lateral_connections = nn.ModuleList()
        
        # 第一个任务列
        self.add_task_column(input_dim, task_id=0)
        
    def add_task_column(self, input_dim, task_id):
        """添加新任务列"""
        if task_id == 0:
            # 第一个任务使用直接输入
            column = nn.Sequential(
                nn.Linear(input_dim, 128),
                nn.ReLU(),
                nn.Linear(128, 64)
            )
            self.task_columns.append(column)
        else:
            # 新任务列接收前一个任务的特征
            prev_output_dim = 64  # 前一个任务的输出维度
            
            column = nn.Sequential(
                nn.Linear(input_dim + prev_output_dim, 128),
                nn.ReLU(),
                nn.Linear(128, 64)
            )
            self.task_columns.append(column)
            
            # 横向连接
            lateral = nn.Linear(prev_output_dim, prev_output_dim)
            self.lateral_connections.append(lateral)
            
    def forward(self, x, task_id):
        """前向传播"""
        if task_id >= len(self.task_columns):
            task_id = len(self.task_columns) - 1  # 使用最后一个任务
            
        if task_id == 0:
            return self.task_columns[0](x)
        else:
            # 获取前一个任务的特征
            prev_features = self.task_columns[task_id - 1](x)
            lateral_features = self.lateral_connections[task_id - 1](prev_features)
            
            # 融合输入
            fused_input = torch.cat([x, lateral_features], dim=-1)
            
            return self.task_columns[task_id](fused_input)
```
