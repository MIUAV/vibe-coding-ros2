---
name: balance-control
description: 双足平衡控制技能 - 重心控制、支撑多边形、扰动恢复、踝/髋策略
argument-hint: 平衡控制 OR balance OR CoM OR ZMP OR ankle strategy
user-invocable: true
---

# 双足平衡控制技能

> 双足机器人平衡控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 重心控制
- 支撑多边形
- 踝/髋策略
- 扰动恢复
- 在线平衡调整

---

## 核心实现

### 平衡控制器

```python
import numpy as np

class BalanceController:
    def __init__(self):
        # 平衡阈值
        self.com_margin = 0.03  # COM 到支撑多边形边界
        self.ankle_margin = 0.02
        
        # 控制增益
        self.kp_com = 10.0
        self.kp_ankle = 5.0
        
    def compute_ankle_torque(self, com_pos, cop_pos, support_polygon):
        """计算踝关节力矩"""
        # COM 位置误差
        cop_target = self.get_com_target(com_pos, support_polygon)
        cop_error = cop_target - cop_pos
        
        # 踝关节力矩
        torque = self.kp_ankle * cop_error
        
        return torque
        
    def get_com_target(self, com_pos, support_polygon):
        """获取 COM 目标位置 (支撑多边形中心)"""
        center = np.mean(support_polygon, axis=0)
        
        # 确保 COM 在支撑多边形内
        if self.is_inside_polygon(com_pos, support_polygon):
            return com_pos
        else:
            # 投影到多边形内
            return self.project_to_polygon(com_pos, support_polygon)
```

### 支撑多边形

```python
class SupportPolygon:
    def __init__(self):
        self.vertices = None
        
    def from_foot_positions(self, left_foot, right_foot):
        """从双脚位置构建支撑多边形"""
        # 脚掌顶点 (简化)
        l_verts = self.foot_vertices(left_foot, 'left')
        r_verts = self.foot_vertices(right_foot, 'right')
        
        self.vertices = np.vstack([l_verts, r_verts])
        
        return self.vertices
        
    def foot_vertices(self, foot_pose, side):
        """获取脚掌顶点"""
        w, l = 0.1, 0.2  # 脚掌宽和长
        
        offset_x = 0.03 if side == 'left' else -0.03
        
        return np.array([
            foot_pose + np.array([l/2 + offset_x, w/2, 0]),
            foot_pose + np.array([l/2 + offset_x, -w/2, 0]),
            foot_pose + np.array([-l/2 + offset_x, -w/2, 0]),
            foot_pose + np.array([-l/2 + offset_x, w/2, 0]),
        ])
        
    def is_inside_polygon(self, point, polygon):
        """点是否在多边形内 (射线法)"""
        x, y = point[:2]
        n = len(polygon)
        
        inside = False
        j = n - 1
        
        for i in range(n):
            xi, yi = polygon[i][:2]
            xj, yj = polygon[j][:2]
            
            if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
                inside = not inside
                
            j = i
            
        return inside
```

### 踝/髋/迈步策略

```python
class BalanceStrategy:
    def __init__(self):
        self.ankle_strategy_active = False
        self.hip_strategy_active = False
        self.step_strategy_active = False
        
    def select_strategy(self, com_pos, cop_pos, support_polygon, disturbance):
        """选择平衡策略"""
        cop_disturbance = np.linalg.norm(cop_pos - com_pos[:2])
        
        # 踝策略: COP 在脚掌范围内
        if cop_disturbance < 0.05:
            return 'ankle'
            
        # 髋策略: 需要髋部侧向移动
        elif cop_disturbance < 0.08:
            return 'hip'
            
        # 迈步策略: 需要踏步
        else:
            return 'step'
            
    def ankle_strategy(self, com_pos, cop_pos, support_polygon):
        """踝策略"""
        # 踝部力矩补偿
        return self.balance_controller.compute_ankle_torque(
            com_pos, cop_pos, support_polygon)
            
    def hip_strategy(self, com_pos, target_com):
        """髋策略"""
        # 髋部侧向移动
        hip_offset = target_com - com_pos
        hip_offset[2] = 0
        
        return hip_offset * self.kp_com
        
    def step_strategy(self, current_foot, target_foot, disturbance):
        """迈步策略"""
        # 计算落脚点
        new_foot = current_foot + 1.5 * disturbance
        
        return new_foot
```
