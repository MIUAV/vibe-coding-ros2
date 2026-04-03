---
name: fl-fedavg
description: FedAvg 联邦平均技能 - 分布式训练、模型聚合、ROS2多机器人协同
argument-hint: "FedAvg" / "联邦平均" / "federated averaging" / "分布式训练"
user-invocable: true
---

# FedAvg 联邦平均技能

> 联邦学习基础算法 - 多机器人分布式协同训练

---

## 何时使用

当需要以下帮助时使用此技能：
- 多机器人协同训练
- 分布式深度学习
- 隐私保护学习
- 模型聚合策略

---

## 核心算法

### FedAvg 实现

```python
import torch
import torch.nn as nn
import numpy as np
from collections import OrderedDict

class FedAvgServer:
    def __init__(self, global_model, clients):
        self.global_model = global_model
        self.clients = clients
        self.client_weights = [1.0 / len(clients)] * len(clients)
        
    def broadcast_model(self):
        """向所有客户端广播全局模型"""
        for client in self.clients:
            client.update_model(self.global_model.state_dict())
            
    def aggregate_models(self, client_updates):
        """聚合客户端模型更新"""
        total_samples = sum([u['num_samples'] for u in client_updates])
        
        aggregated_state = OrderedDict()
        for key in self.global_model.state_dict().keys():
            weighted_sum = torch.zeros_like(self.global_model.state_dict()[key], dtype=torch.float32)
            
            for update, weight in zip(client_updates, self.client_weights):
                num_samples = update['num_samples']
                client_weight = num_samples / total_samples
                weighted_sum += client_weight * update['state_dict'][key].float()
                
            aggregated_state[key] = weighted_sum.to(self.global_model.state_dict()[key].dtype)
            
        self.global_model.load_state_dict(aggregated_state)
        
    def train_round(self, local_epochs=5, batch_size=32):
        """执行一轮联邦训练"""
        # 广播全局模型
        self.broadcast_model()
        
        # 收集客户端更新
        client_updates = []
        for client in self.clients:
            update = client.local_train(epochs=local_epochs, batch_size=batch_size)
            client_updates.append(update)
            
        # 聚合模型
        self.aggregate_models(client_updates)
        
class FederatedClient:
    def __init__(self, model, train_loader, device='cpu'):
        self.model = model.to(device)
        self.train_loader = train_loader
        self.device = device
        
    def update_model(self, global_state_dict):
        """更新本地模型"""
        self.model.load_state_dict(global_state_dict)
        
    def local_train(self, epochs=5, batch_size=32):
        """本地训练"""
        optimizer = torch.optim.SGD(self.model.parameters(), lr=0.01)
        criterion = nn.CrossEntropyLoss()
        
        self.model.train()
        for epoch in range(epochs):
            for data, target in self.train_loader:
                data, target = data.to(self.device), target.to(self.device)
                optimizer.zero_grad()
                output = self.model(data)
                loss = criterion(output, target)
                loss.backward()
                optimizer.step()
                
        return {
            'state_dict': self.model.state_dict(),
            'num_samples': len(self.train_loader.dataset)
        }
```
