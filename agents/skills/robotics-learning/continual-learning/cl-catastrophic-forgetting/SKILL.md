---
name: cl-catastrophic-forgetting
description: 灾难性遗忘预防技能 - 正交权重更新、活性正则化、渐进掩码
argument-hint: "灾难性遗忘" / "catastrophic forgetting" / "OWM" / "渐进掩码"
user-invocable: true
---

# 灾难性遗忘预防技能

> 防止神经网络在学习新任务时遗忘旧任务的知识

---

## 何时使用

当需要以下帮助时使用此技能：
- 多任务机器人学习
- 连续技能获取
- 防止网络覆盖旧知识
- 在线学习场景

---

## 核心方法

### OWM (Orthogonal Weight Modification)

```python
import torch
import torch.nn as nn
import numpy as np

class OWMTrainer:
    def __init__(self, model, alpha=0.5):
        self.model = model
        self.alpha = alpha
        self.old_params = {}
        self.identity_mat = {}
        
    def save_old_params(self):
        """保存旧任务参数"""
        for name, param in self.model.named_parameters():
            self.old_params[name] = param.data.clone()
            
    def compute_identity_matrix(self, dataloader):
        """计算每个参数的正交矩阵"""
        self.identity_mat = {}
        for name, param in self.model.named_parameters():
            if param.requires_grad:
                self.identity_mat[name] = torch.eye(param.shape[0]).to(param.device)
                
    def owm_update(self, param_name, param_data, grad):
        """OWM 参数更新"""
        if param_name in self.identity_mat:
            P = self.identity_mat[param_name]
            grad = P @ grad.view(-1, 1)
            grad = grad.view(param_data.shape)
        return param_data - self.alpha * grad
```

### Progressive Masking

```python
class ProgressiveMasking:
    def __init__(self, model, initial_mask_ratio=0.1):
        self.model = model
        self.mask_ratio = initial_mask_ratio
        self.masks = {}
        
    def create_mask(self, layer):
        """创建随机掩码"""
        mask = torch.rand(layer.weight.shape) > self.mask_ratio
        return mask.float().to(layer.weight.device)
        
    def apply_mask(self):
        """应用掩码到所有层"""
        for name, module in self.model.named_modules():
            if hasattr(module, 'weight') and name in self.masks:
                module.weight.data *= self.masks[name]
                
    def update_mask(self, importance_scores):
        """基于重要性更新掩码"""
        for name, score in importance_scores.items():
            threshold = torch.quantile(score, self.mask_ratio)
            self.masks[name] = (score > threshold).float()
```
