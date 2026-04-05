---
name: federated-learning
description: 联邦学习技能 — FedAvg 算法、差分隐私、ROS2 分布式训练数据聚合，适用于多机器人协同学习
argument-hint: 联邦学习 OR federated learning OR FedAvg OR 隐私保护 OR distributed training
user-invocable: true
---

# federated-learning — 联邦学习 SKILL

## FedAvg 算法

```
1. 全局服务器广播模型参数 θ
2. 各机器人用本地数据训练 → θ_i
3. 机器人回传 θ_i 到服务器
4. 全局服务器聚合: θ = Σ (n_i/n) × θ_i
5. 重复直到收敛
```

## ROS2 分布式实现

```python
# 机器人端
class FederatedClient(Node):
    def __init__(self):
        super().__init__('fed_client')
        self.subscription = self.create_subscription(
            Float32MultiArray,
            '/fed/model_update',
            self.receive_model)
        self.publisher = self.create_publisher(
            Float32MultiArray,
            '/fed/model_submit')

    def train_local(self, data):
        # 本地训练
        return model_gradients
```

## 禁止

- ❌ 传输原始数据（隐私泄露）
- ❌ 不做差分隐私（梯度攻击）
