---
name: force-position-hybrid
description: 力-位置混合控制技能 - 混合控制框架、力/位置分解、任务优先、零空间控制
argument-hint: "混合控制" / "hybrid" / "force-position" / "task priority" / "null space"
user-invocable: true
---

# 力-位置混合控制技能

> 力-位置混合控制实现

---

## 何时使用

当需要以下帮助时使用此技能：
- 混合力/位置控制
- 任务空间分解
- 力控制框架
- 零空间控制
- 任务优先级

---

## 核心实现

### 混合控制框架

```python
import numpy as np

class HybridForcePosition:
    def __init__(self, force_dims, position_dims):
        """
        混合控制
        force_dims: 力控制的维度 [True, True, False, False, False, False]
        position_dims: 位置控制的维度
        """
        self.force_dims = np.array(force_dims, dtype=bool)
        self.position_dims = np.array(position_dims, dtype=bool)
        
    def compute_control(self, x, x_dot, x_d, x_d_dot, F_ext, F_d, Kp, Kd):
        """
        混合力/位置控制
        """
        # 位置误差
        e = x_d - x
        e_dot = x_d_dot - x_dot
        
        # 雅可比
        J = self.compute_jacobian(x)
        
        # 任务空间雅可比分解
        J_f = J[:, self.force_dims]  # 力控制列
        J_p = J[:, self.position_dims]  # 位置控制列
        
        # 位置控制
        if np.any(self.position_dims):
            x_dot_d = Kp * e[:3] + Kd * e_dot[:3]
            
        # 力控制
        if np.any(self.force_dims):
            F_error = F_ext - F_d
            F_control = -Kp * F_error - Kd * np.sum(F_error)
            
        # 雅可比伪逆
        J_p_inv = np.linalg.pinv(J_p)
        
        # 零空间投影
        I = np.eye(6)
        N = I - J_p @ J_p_inv
        
        # 总控制
        q_dot = J_p_inv @ x_dot_d + N @ np.linalg.pinv(J_f) @ F_control
        
        return q_dot
        
    def compute_jacobian(self, q):
        """计算雅可比"""
        return np.eye(6)
```

### 任务优先级控制

```python
class TaskPriorityControl:
    def __init__(self):
        self.tasks = []
        
    def add_task(self, jacobian, priority):
        """添加任务"""
        self.tasks.append((jacobian, priority))
        
    def compute_control(self, q, q_dot, task_commands):
        """
        任务优先级控制
        """
        q_dot_total = np.zeros_like(q)
        
        for (J, priority), cmd in zip(self.tasks, task_commands):
            if priority == 0:
                # 最高优先级
                J_pinv = np.linalg.pinv(J)
                q_dot = J_pinv @ cmd
            else:
                # 投影到零空间
                J_null = self.compute_nullspace_projection(J)
                J_pinv = np.linalg.pinv(J)
                
                q_dot_null = J_null @ np.linalg.pinv(J) @ cmd
                q_dot = q_dot_total + q_dot_null
                
            q_dot_total = q_dot
            
        return q_dot_total
        
    def compute_nullspace_projection(self, J):
        """计算零空间投影矩阵"""
        J_pinv = np.linalg.pinv(J)
        return np.eye(J.shape[1]) - J_pinv @ J
```

### ROS2 混合控制器

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Pose
from sensor_msgs.msg import JointState

class HybridController(Node):
    def __init__(self):
        super().__init__('hybrid_controller')
        
        self.hybrid = HybridForcePosition(
            force_dims=[True, True, True, False, False, False],
            position_dims=[False, False, False, True, True, True]
        )
        
        self.joint_pub = self.create_publisher(
            JointState, '/joint_group_position_controller/command', 10)
            
        self.target_sub = self.create_subscription(
            Pose, '/target_pose', self.target_callback, 10)
```

### 零空间控制

```python
class NullspaceControl:
    def __init__(self, robot_model):
        self.robot = robot_model
        
    def compute_q_dot(self, primary_task, secondary_task):
        """
        零空间控制 - 关节限位避障
        """
        # 主要任务: 末端位置
        J_primary = self.robot.get_jacobian()
        q_dot_primary = np.linalg.pinv(J_primary) @ self.primary_task_error
        
        # 次要任务: 关节限位避障
        q_dot_secondary = self.secondary_task_gradient()
        
        # 零空间投影
        J_primary_pinv = np.linalg.pinv(J_primary)
        nullspace_proj = np.eye(self.robot.n_dof) - J_primary_pinv @ J_primary
        
        # 组合
        q_dot = q_dot_primary + nullspace_proj @ q_dot_secondary * 0.3
        
        return q_dot
        
    def secondary_task_gradient(self):
        """次要任务梯度 (关节限位中心)"""
        q_mid = (self.robot.q_max + self.robot.q_min) / 2
        return (self.robot.q - q_mid) / (self.robot.q_max - self.robot.q_min)
```
