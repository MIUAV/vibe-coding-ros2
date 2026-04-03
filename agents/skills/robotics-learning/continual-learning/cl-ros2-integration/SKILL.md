---
name: cl-ros2-integration
description: 持续学习 ROS2 集成技能 - 任务切换、经验存储、知识迁移
argument-hint: "CL ROS2" / "持续学习 ROS2" / "continual learning ros2"
user-invocable: true
---

# 持续学习 ROS2 集成技能

> 在 ROS2 环境中实现持续学习系统

---

## 何时使用

当需要以下帮助时使用此技能：
- ROS2 多任务学习系统
- 机器人经验存储管理
- 任务切换机制
- 在线学习部署

---

## ROS2 实现

### 多任务学习节点

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Float32MultiArray
import numpy as np
import torch

class ContinualLearningNode(Node):
    def __init__(self):
        super().__init__('continual_learning_node')
        
        # 订阅任务指令
        self.task_sub = self.create_subscription(
            String, '/task/command', self.task_callback, 10)
            
        # 发布模型更新
        self.model_pub = self.create_publisher(
            String, '/model/update', 10)
            
        # 经验回放缓冲区
        self.replay_buffer = PrioritizedReplayBuffer(capacity=10000)
        
        # EWC 重要性矩阵
        self.ewc = None
        
        self.current_task = None
        self.task_count = 0
        
    def task_callback(self, msg):
        """处理新任务"""
        task_name = msg.data
        
        if self.current_task != task_name:
            # 保存旧任务信息
            if self.current_task is not None:
                self.save_task_info()
                
            # 加载新任务
            self.current_task = task_name
            self.load_task(task_name)
            self.task_count += 1
            
    def save_task_info(self):
        """保存当前任务的重要性信息"""
        if self.ewc is not None:
            self.ewc.compute_fisher(self.get_task_dataloader())
            self.ewc.update_params()
            self.get_logger().info(f'Saved task {self.current_task} importance')
            
    def load_task(self, task_name):
        """加载任务配置"""
        self.get_logger().info(f'Loading task: {task_name}')
        
    def get_task_dataloader(self):
        """获取任务数据加载器"""
        # 实现数据加载逻辑
        pass
```

### 知识迁移服务

```python
class KnowledgeTransferService(Node):
    def __init__(self):
        super().__init__('knowledge_transfer_service')
        
        self.srv = self.create_service(
            KnowledgeTransfer, '/knowledge/transfer', self.transfer_callback)
            
    def transfer_callback(self, request, response):
        """处理知识迁移请求"""
        source_robot = request.source_robot
        target_robot = request.target_robot
        task_id = request.task_id
        
        # 加载源机器人模型
        source_params = self.load_model_params(source_robot, task_id)
        
        # 迁移到目标机器人
        self.apply_params_to_robot(target_robot, source_params)
        
        response.success = True
        response.message = f'Transferred task {task_id} from {source_robot} to {target_robot}'
        
        return response
```
