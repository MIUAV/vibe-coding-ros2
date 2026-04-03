---
name: fl-differential-privacy
description: 差分隐私技能 - DP-SGD、隐私预算、梯度扰动、ROS2安全通讯
argument-hint: "差分隐私" / "differential privacy" / "DP-SGD" / "隐私预算"
user-invocable: true
---

# 差分隐私技能

> 通过添加噪声保护隐私的联邦学习技术

---

## 何时使用

当需要以下帮助时使用此技能：
- 隐私敏感数据学习
- 安全联邦训练
- 梯度噪声注入
- 隐私预算管理

---

## 核心算法

### DP-SGD

```python
import torch
import torch.nn as nn
import numpy as np

class DPClient:
    def __init__(self, model, optimizer, noise_multiplier=1.0, max_grad_norm=1.0):
        self.model = model
        self.optimizer = optimizer
        self.noise_multiplier = noise_multiplier
        self.max_grad_norm = max_grad_norm
        
    def clip_gradients(self, parameters):
        """梯度裁剪"""
        total_norm = torch.sqrt(sum(p.grad.data.norm(2) ** 2 for p in parameters))
        clip_coef = self.max_grad_norm / (total_norm + 1e-6)
        
        if clip_coef < 1:
            for p in parameters:
                p.grad.data.mul_(clip_coef)
                
        return total_norm
        
    def add_noise(self, parameters):
        """添加高斯噪声"""
        for p in parameters:
            noise = torch.randn_like(p.grad.data) * self.noise_multiplier * self.max_grad_norm
            p.grad.data.add_(noise)
            
    def local_train(self, data, target, epsilon=1.0, delta=1e-5):
        """差分隐私本地训练"""
        self.optimizer.zero_grad()
        output = self.model(data)
        loss = nn.functional.cross_entropy(output, target)
        loss.backward()
        
        # 裁剪梯度
        self.clip_gradients([p for p in self.model.parameters() if p.grad is not None])
        
        # 添加噪声
        self.add_noise([p for p in self.model.parameters() if p.grad is not None])
        
        self.optimizer.step()

class PrivacyBudget:
    def __init__(self, epsilon=1.0, delta=1e-5):
        self.epsilon = epsilon
        self.delta = delta
        self.spent_budget = 0.0
        
    def compute_privacy_spent(self, sample_size, batch_size, epochs, noise_multiplier):
        """计算隐私预算消耗 (基于 RDP)"""
        q = batch_size / sample_size
        sigma = noise_multiplier
        
        # 简化计算
        alpha = 2 * np.log(1.25 / self.delta)
        privacy_spent = alpha * q * epochs / (sigma ** 2)
        
        self.spent_budget += privacy_spent
        return privacy_spent
```
