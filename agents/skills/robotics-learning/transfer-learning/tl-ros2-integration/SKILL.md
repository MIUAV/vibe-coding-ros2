---
name: tl-ros2-integration
description: 迁移学习 ROS2 集成技能 - 仿真到现实、模型导入导出、跨平台部署
argument-hint: 迁移学习 ROS2 OR sim2real OR domain randomization OR 迁移部署
user-invocable: true
---

# 迁移学习 ROS2 集成技能

> 在 ROS2 环境中实现迁移学习系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 仿真到现实迁移
- ROS2 模型导入导出
- 跨平台部署
- 域随机化

---

## ROS2 实现

### 仿真到现实节点

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist, Pose
from sensor_msgs.msg import Image, JointState
import torch
import numpy as np

class Sim2RealTransfer(Node):
    def __init__(self):
        super().__init__('sim2real_transfer')
        
        # 订阅仿真状态
        self.sim_state_sub = self.create_subscription(
            JointState, '/sim/joint_states', self.sim_state_callback, 10)
            
        # 订阅现实传感器
        self.real_state_sub = self.create_subscription(
            JointState, '/real/joint_states', self.real_state_callback, 10)
            
        # 发布控制命令
        self.cmd_pub = self.create_publisher(Twist, '/robot/cmd_vel', 10)
        
        # 域随机化参数
        self.domain_params = {
            'mass_scale': 1.0,
            'friction_scale': 1.0,
            'observation_noise': 0.0
        }
        
    def sim_state_callback(self, msg):
        """处理仿真状态"""
        sim_state = np.array(msg.position)
        
        # 添加域随机化
        noisy_state = self.apply_domain_randomization(sim_state)
        
        # 发布控制
        self.publish_control(noisy_state)
        
    def real_state_callback(self, msg):
        """处理现实状态"""
        real_state = np.array(msg.position)
        
        # 状态对齐
        aligned_state = self.align_states(real_state, 'real')
        
    def apply_domain_randomization(self, state):
        """应用域随机化"""
        # 质量随机化
        mass = self.domain_params['mass_scale']
        
        # 摩擦随机化
        friction = self.domain_params['friction_scale']
        
        # 观测噪声
        noise = self.domain_params['observation_noise'] * np.random.randn(*state.shape)
        
        return state * mass + noise
    
    def align_states(self, state, domain):
        """状态对齐"""
        # 实现状态对齐逻辑
        pass
```

### 模型导入服务

```python
class ModelImportExport(Node):
    def __init__(self):
        super().__init__('model_import_export')
        
        self.declare_parameter('model_path', '')
        self.model_path = self.get_parameter('model_path').value
        
    def export_model(self, model, path):
        """导出模型"""
        torch.save({
            'model_state_dict': model.state_dict(),
            'model_config': model.config,
            'normalization_params': model.normalization_params
        }, path)
        self.get_logger().info(f'Model exported to {path}')
        
    def import_model(self, path):
        """导入模型"""
        checkpoint = torch.load(path)
        model = self.build_model(checkpoint['model_config'])
        model.load_state_dict(checkpoint['model_state_dict'])
        model.normalization_params = checkpoint['normalization_params']
        self.get_logger().info(f'Model imported from {path}')
        return model
```
