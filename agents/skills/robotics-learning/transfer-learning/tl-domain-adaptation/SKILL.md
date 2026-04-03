---
name: tl-domain-adaptation
description: 域适应技能 - DANN、ADR、CORAL、域混淆、特征对齐
argument-hint: 域适应 OR domain adaptation OR DANN OR CORAL OR 域迁移
user-invocable: true
---

# 域适应技能

> 解决源域和目标域分布差异的迁移学习方法

---

## 何时使用

当需要以下帮助时使用此技能：
- 仿真到现实迁移
- 不同机器人平台迁移
- 环境变化适应
- 特征分布对齐

---

## 核心算法

### DANN (Domain Adversarial Neural Network)

```python
import torch
import torch.nn as nn

class DomainAdversarial(nn.Module):
    def __init__(self, feature_dim, num_classes, domain_dim=2):
        super().__init__()
        
        # 特征提取器
        self.feature_extractor = nn.Sequential(
            nn.Linear(feature_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(256, 128),
            nn.ReLU()
        )
        
        # 标签分类器
        self.label_classifier = nn.Linear(128, num_classes)
        
        # 域分类器
        self.domain_classifier = nn.Sequential(
            GradientReversalLayer(),
            nn.Linear(128, domain_dim)
        )
        
    def forward(self, x, alpha=1.0):
        features = self.feature_extractor(x)
        features_rev = GradientReversalLayer.apply(features, alpha)
        
        class_pred = self.label_classifier(features)
        domain_pred = self.domain_classifier(features_rev)
        
        return class_pred, domain_pred, features

class GradientReversalLayer(nn.Module):
    @staticmethod
    def forward(x, alpha=1.0):
        return x
    
    @staticmethod
    def backward(x, grad_output, alpha=1.0):
        return -alpha * grad_output
```

### CORAL (Correlation Alignment)

```python
class CORALLoss(nn.Module):
    def __init__(self):
        super().__init__()
        
    def coral_loss(self, source, target):
        """CORAL 损失函数"""
        d = source.size(1)
        
        # 中心化
        source = source - source.mean(0)
        target = target - target.mean(0)
        
        # 协方差矩阵
        cov_source = (source.t() @ source) / (source.size(0) - 1)
        cov_target = (target.t() @ target) / (target.size(0) - 1)
        
        # Frobenius 范数
        loss = torch.norm(cov_source - cov_target, p='fro')
        loss = loss ** 2 / (4 * d * d)
        
        return loss
```
