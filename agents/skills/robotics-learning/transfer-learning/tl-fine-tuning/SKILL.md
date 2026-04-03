---
name: tl-fine-tuning
description: 模型微调技能 - 渐进微调、特征冻结、层间迁移、学习率调度
argument-hint: 微调 OR fine-tuning OR 模型微调 OR transfer learning
user-invocable: true
---

# 模型微调技能

> 将预训练模型适配到新任务的技术

---

## 何时使用

当需要以下帮助时使用此技能：
- 预训练模型适配
- 机器人仿真模型到现实
- 特征复用
- 学习率策略设计

---

## 微调策略

### 渐进式微调

```python
import torch
import torch.nn as nn
from torchvision import models

class ProgressiveFineTuner:
    def __init__(self, pretrained_model, num_classes):
        self.model = pretrained_model
        self.num_classes = num_classes
        
        # 替换分类头
        in_features = self.model.fc.in_features
        self.model.fc = nn.Linear(in_features, num_classes)
        
    def freeze_backbone(self):
        """冻结骨干网络"""
        for param in self.model.parameters():
            param.requires_grad = False
        # 只训练分类头
        for param in self.model.fc.parameters():
            param.requires_grad = True
            
    def unfreeze_stage(self, num_layers):
        """逐步解冻层"""
        # 假设模型是按阶段组织的
        layers_to_unfreeze = []
        for name, param in self.model.named_parameters():
            if 'layer' in name:
                layer_num = int(name.split('.')[0].replace('layer', ''))
                if layer_num <= num_layers:
                    layers_to_unfreeze.append(name)
                    
        for name, param in self.model.named_parameters():
            if name in layers_to_unfreeze:
                param.requires_grad = True

class LrScheduler:
    def __init__(self, optimizer, warmup_epochs=5, max_lr=1e-3):
        self.optimizer = optimizer
        self.warmup_epochs = warmup_epochs
        self.max_lr = max_lr
        
    def get_lr(self, epoch):
        if epoch < self.warmup_epochs:
            return self.max_lr * (epoch + 1) / self.warmup_epochs
        else:
            return self.max_lr * 0.1 ** ((epoch - self.warmup_epochs) / 10)
```
