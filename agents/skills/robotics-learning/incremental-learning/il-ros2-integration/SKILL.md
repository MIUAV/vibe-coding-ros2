---
name: il-ros2-integration
description: 增量学习 ROS2 集成技能 - 动态类别更新、在线学习、模型热插拔
argument-hint: 增量学习 ROS2 OR IL ROS2 OR 在线学习 OR incremental ros2
user-invocable: true
---

# 增量学习 ROS2 集成技能

> 在 ROS2 环境中实现增量学习系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 机器人在线学习
- 动态识别新物体
- 模型热更新
- 增量式技能获取

---

## ROS2 实现

### 增量分类节点

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String, Float32MultiArray, Int32
from sensor_msgs.msg import Image
import torch
import torch.nn as nn
import numpy as np

class IncrementalClassifier(Node):
    def __init__(self):
        super().__init__('incremental_classifier')
        
        # 订阅图像输入
        self.image_sub = self.create_subscription(
            Image, '/camera/image_raw', self.image_callback, 10)
            
        # 发布分类结果
        self.result_pub = self.create_publisher(
            String, '/classifier/result', 10)
            
        # 新类别订阅
        self.new_class_sub = self.create_subscription(
            String, '/classifier/new_class', self.new_class_callback, 10)
            
        # 模型服务
        self.model_srv = self.create_service(
            UpdateModel, '/classifier/update', self.update_callback)
            
        # 分类模型
        self.model = None
        self.current_classes = {}
        self.class_counter = 0
        
    def image_callback(self, msg):
        """处理输入图像"""
        if self.model is None:
            return
            
        # 图像预处理
        image = self.preprocess_image(msg)
        
        # 前向传播
        with torch.no_grad():
            output = self.model(image)
            pred_class = output.argmax(dim=-1).item()
            
        # 发布结果
        if pred_class in self.current_classes:
            result = String()
            result.data = self.current_classes[pred_class]
            self.result_pub.publish(result)
            
    def new_class_callback(self, msg):
        """处理新类别注册"""
        class_name = msg.data
        self.current_classes[self.class_counter] = class_name
        self.class_counter += 1
        self.get_logger().info(f'Registered new class: {class_name}')
        
        # 扩展模型
        self.expand_model()
        
    def expand_model(self):
        """扩展模型以容纳新类别"""
        if self.model is None:
            # 初始化模型
            self.model = nn.Sequential(
                nn.Linear(512, 256),
                nn.ReLU(),
                nn.Linear(256, self.class_counter)
            )
        else:
            # 添加新输出节点
            old_num_classes = self.model[-1].out_features
            new_fc = nn.Linear(256, self.class_counter)
            
            # 复制旧权重
            new_fc.weight.data[:old_num_classes] = self.model[-1].weight.data
            new_fc.bias.data[:old_num_classes] = self.model[-1].bias.data
            
            self.model[-1] = new_fc
            
    def preprocess_image(self, msg):
        """预处理图像"""
        # 实现图像预处理
        image = np.frombuffer(msg.data, dtype=np.uint8).reshape(msg.height, msg.width, -1)
        image = torch.tensor(image, dtype=torch.float32).flatten() / 255.0
        return image
        
    def update_callback(self, request, response):
        """模型更新服务"""
        new_model_state = request.model_state
        self.model.load_state_dict(new_model_state)
        
        response.success = True
        response.message = 'Model updated'
        return response
```

### 在线学习节点

```python
class OnlineLearning(Node):
    def __init__(self):
        super().__init__('online_learning')
        
        # 经验回放缓冲区
        self.replay_buffer = ReplayBuffer(capacity=10000)
        
        # 订阅训练数据
        self.train_sub = self.create_subscription(
            Float32MultiArray, '/learning/train_data', self.train_callback, 10)
            
        # 发布学习状态
        self.status_pub = self.create_publisher(
            String, '/learning/status', 10)
            
        self.learning_enabled = True
        
    def train_callback(self, msg):
        """处理训练数据"""
        if not self.learning_enabled:
            return
            
        # 解析数据
        state = np.array(msg.data[:-2])  # 假设格式: [state, action, reward, next_state]
        action = int(msg.data[-2])
        reward = msg.data[-1]
        
        # 存储到回放缓冲区
        self.replay_buffer.push(state, action, reward)
        
        # 在线更新
        if len(self.replay_buffer) > 100:
            self.online_update()
            
    def online_update(self):
        """在线模型更新"""
        # 从回放缓冲区采样
        batch = self.replay_buffer.sample(batch_size=32)
        
        if batch is None:
            return
            
        states, actions, rewards, next_states, dones = batch
        
        # 执行增量更新
        # ... (使用增量学习算法更新模型)
        
        # 发布状态
        status = String()
        status.data = f'Updated with {len(self.replay_buffer)} samples'
        self.status_pub.publish(status)

class ReplayBuffer:
    def __init__(self, capacity=10000):
        self.capacity = capacity
        self.buffer = []
        self.position = 0
        
    def push(self, state, action, reward, next_state=None, done=False):
        if len(self.buffer) < self.capacity:
            self.buffer.append(None)
        self.buffer[self.position] = (state, action, reward, next_state, done)
        self.position = (self.position + 1) % self.capacity
        
    def sample(self, batch_size=32):
        if len(self.buffer) < batch_size:
            return None
        indices = np.random.choice(len(self.buffer), batch_size, replace=False)
        samples = [self.buffer[i] for i in indices]
        states, actions, rewards, next_states, dones = zip(*samples)
        return states, actions, rewards, next_states, dones
        
    def __len__(self):
        return len(self.buffer)
```
