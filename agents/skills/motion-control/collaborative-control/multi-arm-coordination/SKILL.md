---
name: multi-arm-coordination
description: 多臂协调技能 - 协调约束、同步控制、负载分配、碰撞避免、ROS2 MoveIt 多臂
argument-hint: "多臂协调" / "multi-arm" / "协调控制" / "collision avoidance"
user-invocable: true
---

# 多臂协调控制技能

> 多机械臂协同控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 多臂协调运动
- 同步控制
- 负载分配
- 臂间碰撞避免
- ROS2 MoveIt 多臂

---

## 核心实现

### 多臂协调控制

```python
import numpy as np

class MultiArmCoordinator:
    def __init__(self, num_arms):
        self.num_arms = num_arms
        self.arms = []
        
    def compute_coordinated_q_dot(self, task_commands, q_list, collision_check=True):
        """
        协调多臂运动
        task_commands: 每个臂的末端速度命令
        """
        q_dot_total = []
        
        for i, (cmd, q) in enumerate(zip(task_commands, q_list)):
            # 单臂雅可比
            Ji = self.arms[i].get_jacobian(q)
            
            # 关节速度
            q_dot_i = np.linalg.pinv(Ji) @ cmd
            
            # 碰撞避免
            if collision_check:
                q_dot_i = self.collision_avoidance(i, q, q_dot_i)
                
            q_dot_total.append(q_dot_i)
            
        return q_dot_total
        
    def collision_avoidance(self, arm_idx, q, q_dot):
        """碰撞避免"""
        min_dist = 0.1  # 最小距离阈值
        
        for j, other_arm in enumerate(self.arms):
            if j == arm_idx:
                continue
                
            # 计算两臂末端距离
            pos_i = self.arms[arm_idx].forward_kinematics(q)[:3, 3]
            pos_j = other_arm.forward_kinematics(other_arm.q)[:3, 3]
            
            dist = np.linalg.norm(pos_i - pos_j)
            
            if dist < min_dist:
                # 惩罚项
                repulsion = (pos_i - pos_j) / dist
                q_dot += 0.1 * repulsion
                
        return q_dot
```

### 负载分配

```python
class LoadDistribution:
    def __init__(self, num_arms, payload_weight, com):
        self.num_arms = num_arms
        self.payload_weight = payload_weight
        self.com = np.array(com)
        
    def compute_load_allocation(self, grasp_points):
        """计算每个臂的负载分配"""
        loads = []
        total_weight = self.payload_weight
        
        for i, grasp in enumerate(grasp_points):
            # 从抓取点到 COM 的向量
            r = self.com - grasp
            r_norm = np.linalg.norm(r)
            
            # 负载分配 (基于力矩平衡)
            load_i = total_weight * 0.5  # 简化: 平均分配
            
            loads.append(load_i)
            
        # 确保平衡
        total_load = sum(loads)
        if abs(total_load - total_weight) > 1e-3:
            # 调整
            scale = total_weight / total_load
            loads = [l * scale for l in loads]
            
        return loads
```

### ROS2 MoveIt 多臂

```python
import rclpy
from rclpy.node import Node
from moveit_msgs.action import MoveGroup
from rclpy.action import ActionClient

class MultiArmMoveIt(Node):
    def __init__(self):
        super().__init__('multi_arm_moveit')
        
        # 创建左右臂 MoveGroup 客户端
        self.left_arm_client = ActionClient(
            self, MoveGroup, '/move_group_left')
        self.right_arm_client = ActionClient(
            self, MoveGroup, '/move_group_right')
            
    def move_both_arms(self, left_target, right_target):
        """同时移动双臂"""
        # 发送并行目标
        # ...
        pass
```
