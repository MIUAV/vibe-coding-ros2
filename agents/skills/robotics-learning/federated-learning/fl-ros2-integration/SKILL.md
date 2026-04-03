---
name: fl-ros2-integration
description: 联邦学习 ROS2 集成技能 - 多机器人协同、模型同步、安全通讯
argument-hint: 联邦学习 ROS2 OR FL ROS2 OR 多机器人协同 OR federated ros2
user-invocable: true
---

# 联邦学习 ROS2 集成技能

> 在 ROS2 环境中实现联邦学习系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 多机器人联邦训练
- ROS2 分布式通讯
- 模型同步服务
- 安全数据传输

---

## ROS2 实现

### 联邦学习服务器节点

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Float32MultiArray
from geometry_msgs.msg import Pose, Twist
import torch
import numpy as np

class FederatedServer(Node):
    def __init__(self, num_clients=5):
        super().__init__('federated_server')
        
        self.num_clients = num_clients
        self.global_model = None
        self.client_updates = []
        self.client_ready = set()
        
        # 订阅客户端模型更新
        self.update_sub = self.create_subscription(
            String, '/fl/client_update', self.update_callback, 10)
            
        # 发布全局模型
        self.model_pub = self.create_publisher(String, '/fl/global_model', 10)
        
        # 客户端注册服务
        self.register_srv = self.create_service(
            RegisterClient, '/fl/register', self.register_callback)
        
        # 初始化全局模型
        self.init_global_model()
        
    def init_global_model(self):
        """初始化全局模型"""
        # 创建示例模型
        self.global_model = {
            'fc1.weight': np.random.randn(256, 128),
            'fc1.bias': np.random.randn(256),
        }
        
    def register_callback(self, request, response):
        """注册新客户端"""
        client_id = request.client_id
        self.client_ready.add(client_id)
        self.get_logger().info(f'Client {client_id} registered')
        
        response.success = True
        response.message = f'Registered as client {client_id}'
        return response
        
    def update_callback(self, msg):
        """接收客户端更新"""
        import json
        update = json.loads(msg.data)
        self.client_updates.append(update)
        
        if len(self.client_updates) >= self.num_clients:
            self.aggregate_updates()
            
    def aggregate_updates(self):
        """聚合客户端更新"""
        self.get_logger().info('Aggregating client updates...')
        
        total_samples = sum(u['num_samples'] for u in self.client_updates)
        
        aggregated = {}
        for key in self.global_model.keys():
            weighted_sum = np.zeros_like(self.global_model[key], dtype=np.float32)
            
            for update in self.client_updates:
                weight = update['num_samples'] / total_samples
                weighted_sum += weight * np.array(update['model'][key])
                
            aggregated[key] = weighted_sum
            
        self.global_model = aggregated
        self.broadcast_model()
        self.client_updates = []
        
    def broadcast_model(self):
        """广播全局模型"""
        import json
        model_json = json.dumps(self.global_model.tolist() if isinstance(self.global_model, np.ndarray) else self.global_model)
        self.model_pub.publish(String(data=model_json))
        self.get_logger().info('Global model broadcasted')
```

### 联邦学习客户端节点

```python
class FederatedClient(Node):
    def __init__(self, client_id):
        super().__init__(f'federated_client_{client_id}')
        self.client_id = client_id
        self.local_model = {}
        
        # 订阅全局模型
        self.model_sub = self.create_subscription(
            String, '/fl/global_model', self.model_callback, 10)
            
        # 发布本地更新
        self.update_pub = self.create_publisher(String, '/fl/client_update', 10)
        
        # 注册到服务器
        self.register_to_server()
        
    def register_to_server(self):
        """注册到联邦服务器"""
        # 实现注册逻辑
        pass
        
    def model_callback(self, msg):
        """接收全局模型"""
        import json
        global_model = json.loads(msg.data)
        self.local_model = global_model
        self.get_logger().info('Received global model')
        
        # 执行本地训练
        self.local_train()
        
    def local_train(self, epochs=5):
        """本地训练"""
        # 实现本地训练逻辑
        update = {
            'client_id': self.client_id,
            'num_samples': 1000,
            'model': self.local_model  # 训练后的模型
        }
        
        import json
        self.update_pub.publish(String(data=json.dumps(update)))
```
