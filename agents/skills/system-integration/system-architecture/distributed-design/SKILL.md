---
name: distributed-design
description: 分布式设计技能 - 多机通信、时钟同步、数据分发、边缘计算架构
argument-hint: "分布式" / "distributed" / "multi-machine" / "时钟同步" / "edge"
user-invocable: true
---

# 分布式设计技能

> 分布式机器人系统设计

---

## 何时使用

当需要以下帮助时使用此技能：
- 多机通信架构
- 时钟同步
- 数据分发服务
- 边缘计算部署
- 分布式 SLAM

---

## 核心实现

### 多机通信架构

```python
# distributed_node.py
import rclpy
from rclpy.node import Node
from rclpy.executors import MultiThreadedExecutor
import threading

class DistributedNode(Node):
    def __init__(self, node_name, namespace=None):
        super().__init__(node_name, namespace=namespace)
        
        # 跨机器通信
        self.declare_parameter('master_uri', 'http://192.168.1.100:11311')
        self.declare_parameter('robot_id', 1)
        
        # 数据分发
        self.publisher_map = {}
        self.subscription_map = {}
        
    def create_cross_machine_publisher(self, topic, msg_type):
        """创建跨机器发布者"""
        pub = self.create_publisher(msg_type, topic, 10)
        self.publisher_map[topic] = pub
        return pub
        
    def create_cross_machine_subscription(self, topic, msg_type, callback):
        """创建跨机器订阅"""
        sub = self.create_subscription(msg_type, topic, callback, 10)
        self.subscription_map[topic] = sub
        return sub
```

### 时钟同步

```python
class ClockSynchronizer:
    def __init__(self):
        self.offset = 0.0
        self.samples = []
        
    def add_sample(self, local_time, remote_time):
        """添加时间同步样本"""
        self.samples.append((local_time, remote_time))
        
        if len(self.samples) > 10:
            # 计算偏移
            self.compute_offset()
            
    def compute_offset(self):
        """计算时钟偏移"""
        if len(self.samples) < 3:
            return
            
        # 使用中位数
        offsets = [remote - local for local, remote in self.samples]
        offsets.sort()
        self.offset = offsets[len(offsets) // 2]
        
    def remote_to_local(self, remote_time):
        """远程时间转本地时间"""
        return remote_time - self.offset
```

### ROS2 跨机器配置

```bash
# 机器 A
export ROS_DOMAIN_ID=42
export ROS_IP=192.168.1.100
ros2 run package node_a

# 机器 B
export ROS_DOMAIN_ID=42
export ROS_IP=192.168.1.101
ros2 run package node_b
```

### 数据分发服务

```python
class DataDistributionService:
    def __init__(self):
        self.nodes = {}  # node_id -> NodeInfo
        
    def register_node(self, node_id, capabilities):
        """注册节点"""
        self.nodes[node_id] = {
            'capabilities': capabilities,
            'last_heartbeat': time.time()
        }
        
    def publish_data(self, source_id, data_type, payload):
        """发布数据到所有订阅者"""
        for node_id, info in self.nodes.items():
            if node_id != source_id:
                if data_type in info['capabilities']:
                    self.send_to_node(node_id, data_type, payload)
```
