---
name: il-representation-learning
description: 表示学习技能 - 特征空间稳定、可塑性、表示压缩、对比学习
argument-hint: 表示学习 OR representation learning OR 特征保持 OR 对比学习
user-invocable: true
---

# 表示学习技能

> 保持特征表示稳定性和可塑性的平衡

---

## 何时使用

当需要以下帮助时使用此技能：
- 特征表示不遗忘
- 可塑性-稳定性平衡
- 表示压缩与复用
- 对比学习保持

---

## 核心方法

### 可塑性-稳定性平衡

```python
import torch
import torch.nn as nn
import numpy as np

class RepresentationBalancer:
    def __init__(self, model, plasticity=0.1, stability=0.9):
        self.model = model
        self.plasticity = plasticity
        self.stability = stability
        self.old_representations = {}
        
    def compute_representation_drift(self, layer_name, new_features):
        """计算表示漂移"""
        if layer_name in self.old_representations:
            old_features = self.old_representations[layer_name]
            drift = torch.norm(new_features - old_features.mean(0)) / (torch.norm(old_features.mean(0)) + 1e-6)
            return drift.item()
        return 0.0
        
    def update_with_balance(self, layer_name, new_features):
        """平衡更新表示"""
        if layer_name not in self.old_representations:
            self.old_representations[layer_name] = new_features.detach()
            return
            
        # 计算漂移
        drift = self.compute_representation_drift(layer_name, new_features)
        
        # 根据漂移调整更新强度
        if drift > self.stability:
            # 特征变化太大，加强稳定性
            update_strength = self.plasticity * 0.5
        elif drift < self.plasticity:
            # 特征变化太小，增加可塑性
            update_strength = self.plasticity * 1.5
        else:
            update_strength = self.plasticity
            
        # 移动平均更新
        self.old_representations[layer_name] = (
            (1 - update_strength) * self.old_representations[layer_name] +
            update_strength * new_features.detach()
        )
```

### 对比表示学习

```python
class ContrastiveRepresentation(nn.Module):
    def __init__(self, encoder_dim=128, num_negatives=256):
        super().__init__()
        self.encoder_dim = encoder_dim
        self.num_negatives = num_negatives
        
        # 编码器
        self.encoder = nn.Sequential(
            nn.Linear(512, 256),
            nn.ReLU(),
            nn.Linear(256, encoder_dim)
        )
        
        # 投影头
        self.projector = nn.Sequential(
            nn.Linear(encoder_dim, encoder_dim),
            nn.ReLU(),
            nn.Linear(encoder_dim, encoder_dim)
        )
        
    def contrastive_loss(self, anchor, positive, negatives):
        """
        对比损失
        anchor: 锚点特征 [batch, dim]
        positive: 正样本特征 [batch, dim]
        negatives: 负样本特征 [num_negatives, dim]
        """
        # 归一化
        anchor = torch.nn.functional.normalize(anchor, dim=-1)
        positive = torch.nn.functional.normalize(positive, dim=-1)
        negatives = torch.nn.functional.normalize(negatives, dim=-1)
        
        # 正样本相似度
        pos_sim = (anchor * positive).sum(dim=-1)  # [batch]
        
        # 负样本相似度
        neg_sim = torch.mm(anchor, negatives.t())  # [batch, num_negatives]
        
        # InfoNCE 损失
        logits = torch.cat([pos_sim.unsqueeze(-1), neg_sim], dim=-1) / 0.07
        labels = torch.zeros(logits.shape[0], dtype=torch.long, device=logits.device)
        
        loss = nn.functional.cross_entropy(logits, labels)
        return loss
        
    def forward(self, x1, x2):
        """处理两个视图"""
        # 编码
        h1 = self.encoder(x1)
        h2 = self.encoder(x2)
        
        # 投影
        z1 = self.projector(h1)
        z2 = self.projector(h2)
        
        # 对比损失
        loss = self.contrastive_loss(z1, z2, z1)
        
        return loss, z1, z2
```

### 表示压缩

```python
class RepresentationCompressor:
    def __init__(self, latent_dim=64):
        self.latent_dim = latent_dim
        
    def compress(self, features):
        """压缩高维特征"""
        # 简化压缩实现
        if features.shape[-1] > self.latent_dim:
            # PCA 压缩
            with torch.no_grad():
                features_np = features.cpu().numpy()
                # 实际使用 torch.pca_lowrank 或类似方法
                compressed = features_np[:, :self.latent_dim]
                return torch.tensor(compressed, device=features.device)
        return features
        
    def diversity_loss(self, features_list):
        """表示多样性损失"""
        # 鼓励不同任务表示有差异
        loss = 0
        for i in range(len(features_list)):
            for j in range(i + 1, len(features_list)):
                # 余弦相似度
                sim = torch.nn.functional.cosine_similarity(
                    features_list[i], features_list[j], dim=-1
                ).mean()
                loss -= sim  # 最小化相似度 = 最大化多样性
        return loss / (len(features_list) * (len(features_list) - 1) / 2)
```
