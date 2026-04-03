---
name: tl-curriculum-learning
description: 课程学习技能 - 难度渐进、Self-Paced Learning、先验知识整合
argument-hint: "课程学习" / "curriculum learning" / "难度渐进" / "self-paced"
user-invocable: true
---

# 课程学习技能

> 从简单到复杂渐进学习的策略

---

## 何时使用

当需要以下帮助时使用此技能：
- 机器人技能渐进训练
- 任务难度排序
- 自主课程设计
- 学习效率优化

---

## 核心方法

### Self-Paced Learning

```python
import numpy as np
import torch
import torch.nn as nn

class SelfPacedLearning:
    def __init__(self, model, loss_fn, lambda_init=0.1, eta=0.1):
        self.model = model
        self.loss_fn = loss_fn
        self.lambda_ = lambda_init
        self.eta = eta
        self.v = None  # 样本权重
        
    def select_samples(self, dataloader, epoch):
        """根据损失选择简单样本"""
        self.model.eval()
        losses = []
        
        with torch.no_grad():
            for data, target in dataloader:
                output = self.model(data)
                loss = self.loss_fn(output, target)
                losses.append(loss.item())
                
        losses = np.array(losses)
        
        # 计算样本权重
        self.v = (losses < self.lambda_).float()
        self.lambda_ *= (1 + self.eta)  # 逐渐增加难度
        
        return self.v
        
    def train_epoch(self, dataloader, optimizer):
        """使用选定样本训练"""
        self.model.train()
        total_loss = 0
        
        for i, (data, target) in enumerate(dataloader):
            if self.v is not None and i < len(self.v) and self.v[i] == 0:
                continue
                
            optimizer.zero_grad()
            output = self.model(data)
            loss = self.loss_fn(output, target)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            
        return total_loss
```

### 难度评估器

```python
class DifficultyAssessor:
    def __init__(self):
        self.task_difficulties = {}
        
    def compute_difficulty(self, task_features):
        """
        基于任务特征计算难度
        - 状态空间维度
        - 动作空间复杂度
        - 环境动态不确定性
        - 稀疏奖励程度
        """
        difficulty = 0.0
        
        # 状态空间复杂度
        difficulty += 0.2 * np.log(task_features['state_dim'] + 1)
        
        # 动作空间复杂度
        difficulty += 0.2 * np.log(task_features['action_dim'] + 1)
        
        # 环境不确定性
        difficulty += 0.3 * task_features['dynamics_variance']
        
        # 奖励稀疏度
        difficulty += 0.3 * (1.0 - task_features['reward_density'])
        
        return difficulty
    
    def sort_tasks(self, tasks):
        """按难度排序任务"""
        difficulties = [self.compute_difficulty(t) for t in tasks]
        sorted_indices = np.argsort(difficulties)
        return sorted_indices
```
