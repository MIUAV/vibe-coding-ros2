---
name: fl-vertical-federation
description: 垂直联邦学习技能 - 特征划分、隐私集合交集、嵌入共享
argument-hint: "垂直联邦" / "vertical federation" / "特征划分" / "PSI"
user-invocable: true
---

# 垂直联邦学习技能

> 各参与方拥有不同特征维度的联邦学习场景

---

## 何时使用

当需要以下帮助时使用此技能：
- 特征级别的联邦训练
- 多机器人协同感知
- 数据垂直划分
- 隐私集合交集

---

## 核心实现

### 垂直联邦架构

```python
import torch
import torch.nn as nn
import numpy as np

class VerticalFederation:
    def __init__(self, feature_dims, embedding_dim=64):
        """
        feature_dims: 每个客户端的特征维度列表
        """
        self.embedding_dim = embedding_dim
        self.clients = []
        
        for i, feat_dim in enumerate(feature_dims):
            client = VerticalClient(feat_dim, embedding_dim)
            self.clients.append(client)
            
        # 聚合器
        self.aggregator = FeatureAggregator(embedding_dim, len(feature_dims))
        
    def train_round(self, client_data, local_epochs=5):
        """垂直联邦训练"""
        # 1. 各客户端本地计算嵌入
        embeddings = []
        for client, data in zip(self.clients, client_data):
            emb = client.compute_embedding(data)
            embeddings.append(emb)
            
        # 2. 聚合特征
        fused_embedding = self.aggregator fuse(embeddings)
        
        # 3. 本地更新
        for client in self.clients:
            client.update(fused_embedding, local_epochs)

class VerticalClient:
    def __init__(self, feature_dim, embedding_dim):
        self.embedding_dim = embedding_dim
        
        # 本地特征编码器
        self.encoder = nn.Sequential(
            nn.Linear(feature_dim, 128),
            nn.ReLU(),
            nn.Linear(128, embedding_dim)
        )
        
        # 本地模型
        self.local_model = nn.Linear(embedding_dim, 1)
        
    def compute_embedding(self, features):
        """计算本地特征嵌入"""
        with torch.no_grad():
            embedding = self.encoder(features)
        return embedding
        
    def update(self, fused_embedding, epochs):
        """使用聚合嵌入更新本地模型"""
        optimizer = torch.optim.SGD(self.local_model.parameters(), lr=0.01)
        
        for epoch in range(epochs):
            optimizer.zero_grad()
            output = self.local_model(fused_embedding)
            loss = output.mean()  # 具体损失函数
            loss.backward()
            optimizer.step()

class FeatureAggregator(nn.Module):
    def __init__(self, embedding_dim, num_clients):
        super().__init__()
        self.attention = nn.MultiheadAttention(embedding_dim, num_heads=4)
        
    def fuse(self, embeddings):
        """注意力特征融合"""
        stacked = torch.stack(embeddings, dim=0)  # [num_clients, batch, dim]
        fused, _ = self.attention(stacked, stacked, stacked)
        return fused.mean(dim=0)  # 聚合客户端特征
```

### 隐私集合交集 (PSI)

```python
class PSIBucket:
    """基于桶的 PSI 实现"""
    
    def __init__(self, num_buckets=100):
        self.num_buckets = num_buckets
        self.local_buckets = {}
        
    def hash_to_bucket(self, sample_id, salt):
        """哈希到桶"""
        hash_val = hash((sample_id, salt)) % self.num_buckets
        return hash_val
        
    def build_local_buckets(self, sample_ids, salt):
        """构建本地桶"""
        for sid in sample_ids:
            bucket = self.hash_to_bucket(sid, salt)
            if bucket not in self.local_buckets:
                self.local_buckets[bucket] = []
            self.local_buckets[bucket].append(sid)
            
    def compute_intersection(self, partner_buckets):
        """计算交集"""
        intersection = []
        for bucket_id, local_ids in self.local_buckets.items():
            if bucket_id in partner_buckets:
                # 找到共同样本
                partner_ids = set(partner_buckets[bucket_id])
                common = [sid for sid in local_ids if sid in partner_ids]
                intersection.extend(common)
        return intersection
```
