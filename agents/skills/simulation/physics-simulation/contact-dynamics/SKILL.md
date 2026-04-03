---
name: contact-dynamics
description: 接触动力学技能 - 碰撞检测、摩擦模型、接触力计算、栖体仿真
argument-hint: 接触动力学 OR collision OR friction OR contact OR dynamics
user-invocable: true
---

# 接触动力学技能

> 机器人接触动力学仿真

---

## 何时使用

当需要以下帮助时使用此技能：
- 碰撞检测
- 摩擦模型
- 接触力计算
- 栖体仿真
- 接触参数识别

---

## 核心实现

### 碰撞检测

```python
import numpy as np
from scipy.spatial import ConvexHull

class CollisionDetector:
    def __init__(self):
        self.collision_pairs = []
        
    def check_collision(self, body1, body2):
        """检测两物体是否碰撞"""
        # 获取包围盒
        aabb1 = body1.get_aabb()
        aabb2 = body2.get_aabb()
        
        # AABB 检测
        if not self.aabb_intersect(aabb1, aabb2):
            return False
            
        # 精细碰撞检测
        return self.separating_axis_theorem(body1, body2)
        
    def aabb_intersect(self, aabb1, aabb2):
        """轴对齐包围盒检测"""
        return (aabb1.min <= aabb2.max).all() and \
               (aabb2.min <= aabb1.max).all()
               
    def separating_axis_theorem(self, body1, body2):
        """SAT 碰撞检测"""
        # 获取凸包顶点
        vertices1 = body1.get_convex_hull()
        vertices2 = body2.get_convex_hull()
        
        # 检测所有可能分离轴
        axes = self.get_potential_axes(vertices1, vertices2)
        
        for axis in axes:
            proj1 = self.project(vertices1, axis)
            proj2 = self.project(vertices2, axis)
            
            if not self.overlap(proj1, proj2):
                return False  # 分离轴存在，无碰撞
                
        return True
```

### 接触力计算

```python
class ContactForce:
    def __init__(self, stiffness=10000, damping=100):
        self.stiffness = stiffness
        self.damping = damping
        
    def compute_contact_force(self, penetration, velocity, normal):
        """
        计算接触力
        """
        # 弹性力
        F_normal = self.stiffness * penetration
        
        # 阻尼力
        vel_normal = np.dot(velocity, normal)
        D_normal = self.damping * vel_normal
        
        return (F_normal + D_normal) * normal
        
    def compute_friction_force(self, tangent_velocity, normal_force):
        """计算摩擦力"""
        # Coulomb 摩擦
        mu = 0.5  # 摩擦系数
        
        vel_tangent = tangent_velocity - np.dot(tangent_velocity, normal) * normal
        vel_tangent_mag = np.linalg.norm(vel_tangent)
        
        if vel_tangent_mag < 1e-6:
            return np.zeros(3)
            
        friction_direction = vel_tangent / vel_tangent_mag
        max_friction = mu * np.abs(normal_force)
        
        return -friction_direction * max_friction
```

### 栖体仿真

```python
class GroundContact:
    def __init__(self):
        self.ground_height = 0.0
        
    def compute_ground_reaction(self, foot_position, foot_velocity):
        """计算地反力"""
        # 脚底高度
        z = foot_position[2]
        
        # 穿透深度
        penetration = max(0, self.ground_height - z)
        
        if penetration > 0:
            # 垂直力
            Fz = 10000 * penetration - 100 * foot_velocity[2]
            
            # 摩擦力 (简化)
            Fx = -0.5 * foot_velocity[0]
            Fy = -0.5 * foot_velocity[1]
            
            return np.array([Fx, Fy, max(0, Fz)])
            
        return np.zeros(3)
```
