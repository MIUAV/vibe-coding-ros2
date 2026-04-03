---
name: walking-pattern
description: 行走模式生成技能 - ZMP、CPG、步态周期、预观控制、ROS2 walk接口
argument-hint: "行走模式" / "ZMP" / "CPG" / "步态" / "walking pattern"
user-invocable: true
---

# 行走模式生成技能

> 双足步行模式生成

---

## 何时使用

当需要以下帮助时使用此技能：
- ZMP 步态规划
- CPG 振荡器
- 步态周期
- 预观控制
- ROS2 步行接口

---

## 核心实现

### ZMP 步态规划

```python
import numpy as np

class ZMPWalkPlanner:
    def __init__(self):
        self.step_height = 0.1
        self.step_length = 0.3
        self.step_period = 0.8
        self.step_width = 0.2
        
        # ZMP 补偿
        self.zmp_x_offset = 0.02
        self.zmp_y_offset = 0.05
        
    def generate_walk_trajectory(self, num_steps, direction='forward'):
        """生成步行轨迹"""
        footsteps = self.generate_footsteps(num_steps, direction)
        zmp_trajectory = self.generate_zmp(footsteps)
        com_trajectory = self.compute_com(zmp_trajectory)
        
        return {
            'footsteps': footsteps,
            'zmp': zmp_trajectory,
            'com': com_trajectory
        }
        
    def generate_footsteps(self, num_steps, direction):
        """生成脚掌位置序列"""
        footsteps = []
        
        # 左脚起始
        left_pos = np.array([0, self.step_width/2, 0])
        right_pos = np.array([0, -self.step_width/2, 0])
        
        for i in range(num_steps):
            if i % 2 == 0:
                # 左脚摆动
                swing_foot = 'left'
                stance_foot = right_pos.copy()
                
                # 摆动脚目标
                target = left_pos + np.array([
                    self.step_length * (1 if direction == 'forward' else -1),
                    0, 0
                ])
            else:
                # 右脚摆动
                swing_foot = 'right'
                stance_foot = left_pos.copy()
                target = right_pos + np.array([
                    self.step_length * (1 if direction == 'forward' else -1),
                    0, 0
                ])
                
            footsteps.append({
                'swing': swing_foot,
                'target': target,
                'stance': stance_foot
            })
            
        return footsteps
        
    def generate_zmp(self, footsteps):
        """生成 ZMP 轨迹"""
        zmp_traj = []
        
        for step in footsteps:
            # 双脚中心
            center = (step['target'] + step['stance']) / 2
            
            # ZMP 偏移
            zmp = center + np.array([self.zmp_x_offset, 0, 0])
            zmp_traj.append(zmp)
            
        return np.array(zmp_traj)
        
    def compute_com(self, zmp_trajectory):
        """预观控制计算 COM"""
        # 简化的线性倒立摆
        g = 9.81
        h = 0.8  # COM 高度
        
        omega = np.sqrt(g / h)
        
        com_traj = []
        for zmp in zmp_trajectory:
            # COM 在 ZMP 上方
            com = np.array([zmp[0], zmp[1], h])
            com_traj.append(com)
            
        return np.array(com_traj)
```

### CPG 振荡器

```python
class CPGOscillator:
    def __init__(self, params):
        self.alpha = params.get('alpha', 5.0)
        self.beta = params.get('beta', 1.0)
        self.gamma = params.get('gamma', 1.0)
        self.mu = params.get('mu', 1.0)
        
    def hopf_oscillator(self, x, y, omega):
        """
        Hopf 振荡器
        dx/dt = alpha*(mu - r^2)*x - omega*y
        dy/dt = beta*(mu - r^2)*y + omega*x
        """
        r = np.sqrt(x**2 + y**2)
        
        dx = self.alpha * (self.mu - r**2) * x - omega * y
        dy = self.beta * (self.mu - r**2) * y + omega * x
        
        return dx, dy
        
    def step(self, state, dt, omega):
        """积分一步"""
        x, y = state
        dx, dy = self.hopf_oscillator(x, y, omega)
        return x + dx * dt, y + dy * dt
```

### ROS2 步行接口

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Pose
from unitree_leash_msgs.msg import WalkCommand

class WalkCommandNode(Node):
    def __init__(self):
        super().__init__('walk_command')
        
        self.walk_pub = self.create_publisher(
            WalkCommand, '/walk_command', 10)
            
    def publish_walk(self, step_length, step_height, step_period, num_steps):
        """发布步行命令"""
        cmd = WalkCommand()
        cmd.step_length = step_length
        cmd.step_height = step_height
        cmd.step_period = step_period
        cmd.num_steps = num_steps
        cmd.direction = 0  # forward
        
        self.walk_pub.publish(cmd)
```
