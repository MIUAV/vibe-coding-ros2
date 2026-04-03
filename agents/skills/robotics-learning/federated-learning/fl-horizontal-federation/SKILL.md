---
name: fl-horizontal-federation
description: 水平联邦学习技能 - 样本划分、特征对齐、分布式数据
argument-hint: "水平联邦" / "horizontal federation" / "样本划分" / "数据并行"
user-invocable: true
---

# 水平联邦学习技能

> 各参与方拥有不同样本但特征相同的联邦学习场景

---

## 何时使用

当需要以下帮助时使用此技能：
- 多机器人数据并行
- 样本级别的联邦训练
- 特征空间相同的分布式学习
- 数据分布不均匀场景

---

## 核心实现

### 水平联邦架构

```python
import torch
import torch.nn as nn
from collections import OrderedDict

class HorizontalFederation:
    def __init__(self, model_fn, client_configs):
        self.global_model = model_fn()
        self.clients = []
        
        for config in client_configs:
            client_data = self._load_client_data(config)
            client = FederatedClient(self.global_model, client_data)
            self.clients.append(client)
            
    def _load_client_data(self, config):
        """加载客户端数据"""
        # 返回本地数据加载器
        pass
        
    def train(self, num_rounds, local_epochs=5):
        """水平联邦训练"""
        for round_idx in range(num_rounds):
            print(f"Round {round_idx + 1}/{num_rounds}")
            
            # 1. 分发全局模型
            self._broadcast_model()
            
            # 2. 本地训练
            client_updates = []
            for client in self.clients:
                update = client.local_train(epochs=local_epochs)
                client_updates.append(update)
                
            # 3. 聚合更新
            self._aggregate_updates(client_updates)
            
    def _broadcast_model(self):
        """广播全局模型到所有客户端"""
        global_state = self.global_model.state_dict()
        for client in self.clients:
            client.set_model_state(global_state)
            
    def _aggregate_updates(self, updates):
        """加权聚合模型更新"""
        total_samples = sum(u['num_samples'] for u in updates)
        
        new_state = OrderedDict()
        for key in self.global_model.state_dict().keys():
            weighted_sum = None
            
            for update in updates:
                weight = update['num_samples'] / total_samples
                if weighted_sum is None:
                    weighted_sum = weight * update['state_dict'][key].float()
                else:
                    weighted_sum += weight * update['state_dict'][key].float()
                    
            new_state[key] = weighted_sum.to(self.global_model.state_dict()[key].dtype)
            
        self.global_model.load_state_dict(new_state)

class FederatedClient:
    def __init__(self, model, data_loader):
        self.local_model = model.__class__()
        self.data_loader = data_loader
        
    def set_model_state(self, state_dict):
        """设置本地模型状态"""
        self.local_model.load_state_dict(state_dict)
        
    def local_train(self, epochs=5):
        """本地训练"""
        optimizer = torch.optim.SGD(self.local_model.parameters(), lr=0.01)
        
        for epoch in range(epochs):
            for data, target in self.data_loader:
                optimizer.zero_grad()
                output = self.local_model(data)
                loss = nn.functional.cross_entropy(output, target)
                loss.backward()
                optimizer.step()
                
        return {
            'state_dict': self.local_model.state_dict(),
            'num_samples': len(self.data_loader.dataset)
        }
```
