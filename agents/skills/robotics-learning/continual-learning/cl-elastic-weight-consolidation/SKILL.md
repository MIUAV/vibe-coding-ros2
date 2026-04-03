---
name: cl-elastic-weight-consolidation
description: 弹性权重巩固技能 - EWC、SI、RWalk 算法实现
argument-hint: EWC OR 弹性权重巩固 OR elastic weight consolidation OR Synaptic Intelligence
user-invocable: true
---

# 弹性权重巩固技能

> 通过评估参数重要性来保护关键权重的持续学习方法

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 EWC、SI、RWalk 算法
- 保护重要神经网络权重
- 连续任务学习
- 机器人多技能学习

---

## 核心算法

### EWC (Elastic Weight Consolidation)

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

class EWC:
    def __init__(self, model, lr=1e-3, lambda_ewc=1000):
        self.model = model
        self.lambda_ewc = lambda_ewc
        self.lr = lr
        self.params = {n: p.clone().detach() for n, p in model.named_parameters() if p.requires_grad}
        self.fisher = {n: torch.zeros_like(p) for n, p in model.named_parameters() if p.requires_grad}
        
    def compute_fisher(self, dataloader, num_samples=200):
        """计算 Fisher 信息矩阵（对角近似）"""
        self.model.eval()
        fisher_accum = {n: torch.zeros_like(p) for n, p in self.model.named_parameters() if p.requires_grad}
        
        for i, (data, _) in enumerate(dataloader):
            if i >= num_samples:
                break
            self.model.zero_grad()
            output = self.model(data)
            loss = output.mean()
            loss.backward()
            
            for n, p in self.model.named_parameters():
                if p.requires_grad:
                    fisher_accum[n] += p.grad.data ** 2
                    
        for n in fisher_accum:
            fisher_accum[n] /= num_samples
            
        self.fisher = fisher_accum
        
    def penalty(self):
        """EWC 惩罚项"""
        loss = 0
        for n, p in self.model.named_parameters():
            if p.requires_grad and n in self.fisher:
                loss += (self.fisher[n] * (p - self.params[n]) ** 2).sum()
        return self.lambda_ewc * loss
    
    def update_params(self):
        """更新保存的参数"""
        self.params = {n: p.clone().detach() for n, p in self.model.named_parameters() if p.requires_grad}
```

### Synaptic Intelligence (SI)

```python
class SynapticIntelligence:
    def __init__(self, model, lambda_si=1000, c=0.5):
        self.model = model
        self.lambda_si = lambda_si
        self.c = c
        self.params = {}
        self.omega = {}
        self.w_sum = {}
        
    def initialize(self):
        """初始化 SI 变量"""
        for n, p in self.model.named_parameters():
            if p.requires_grad:
                self.params[n] = p.data.clone()
                self.omega[n] = torch.zeros_like(p)
                self.w_sum[n] = torch.zeros_like(p)
                
    def compute_surrogate_loss(self):
        """计算 SI 代理损失"""
        loss = 0
        for n, p in self.model.named_parameters():
            if p.requires_grad and n in self.omega:
                loss += (self.omega[n] * (p - self.params[n]) ** 2).sum()
        return self.lambda_si * loss
    
    def update_omega(self, params_prev):
        """更新 Omega 矩阵"""
        for n, p in self.model.named_parameters():
            if p.requires_grad and n in self.omega:
                delta_p = p - params_prev[n]
                self.w_sum[n] += self.lr * (p.grad * delta_p).detach()
                self.omega[n] += self.w_sum[n] / (delta_p ** 2 + self.c)
```
