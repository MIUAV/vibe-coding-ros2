---
name: humanoid-kinematics
description: 人形机器人运动学技能 - 全身运动学、闭链运动学、根骨跟踪、ROS2 HRGCF
argument-hint: 人形机器人 OR humanoid OR whole-body OR HRGCF OR kinematics
user-invocable: true
---

# 人形机器人运动学技能

> 人形机器人全身运动学

---

## 何时使用

当需要以下帮助时使用此技能：
- 人形机器人建模
- 全身运动学
- 根骨跟踪
- 闭链约束
- ROS2 人形控制

---

## 核心实现

### 人形机器人模型

```python
import numpy as np

class HumanoidKinematics:
    def __init__(self):
        # 关节定义 (名称, 父关节, DH参数)
        self.joints = {
            'root': {'parent': None, 'dof': 6},
            'torso': {'parent': 'root', 'dof': 3},
            'head': {'parent': 'torso', 'dof': 2},
            'left_arm': {'parent': 'torso', 'dof': 7},
            'right_arm': {'parent': 'torso', 'dof': 7},
            'left_leg': {'parent': 'root', 'dof': 6},
            'right_leg': {'parent': 'root', 'dof': 6},
        }
        
        # 末端执行器
        self.end_effectors = [
            'left_hand', 'right_hand', 'left_foot', 'right_foot'
        ]
        
    def solve_wbik(self, root_pose, tasks):
        """
        全身逆运动学
        tasks: [{'end_effector': 'left_foot', 'pose': T_target}, ...]
        """
        q = np.zeros(30)  # 30 DOF 人形
        
        for _ in range(50):
            # 计算误差
            errors = []
            for task in tasks:
                ee = task['end_effector']
                T_target = task['pose']
                
                # 当前末端位姿
                T_current = self.fk(ee, q)
                
                # 误差
                error = self.pose_error(T_current, T_target)
                errors.append((ee, error))
                
            # 堆叠误差
            error_stack = np.concatenate([e for _, e in errors])
            
            if np.linalg.norm(error_stack) < 1e-4:
                break
                
            # 雅可比
            J = self.compute_task_jacobian(errors)
            
            # 阻尼最小二乘
            q_delta = self.damped_least_squares(J, error_stack)
            
            q = q + 0.5 * q_delta
            
        return q
        
    def compute_task_jacobian(self, tasks):
        """计算任务雅可比"""
        J_total = []
        
        for ee, error in tasks:
            Ji = self.fk.get_jacobian(ee, q)
            J_total.append(Ji)
            
        return np.vstack(J_total)
        
    def damped_least_squares(self, J, error, lambda_=0.01):
        """阻尼最小二乘"""
        H = J.T @ J + lambda_ ** 2 * np.eye(J.shape[1])
        return np.linalg.solve(H, J.T @ error)
```

### 根骨跟踪

```python
class RootTracking:
    def __init__(self):
        self.pelvis_height = 0.9
        self.hip_height_offset = 0.05
        
    def compute_foot_targets(self, root_pose, com_position):
        """计算双脚目标位置"""
        left_foot = root_pose.copy()
        left_foot[2] = self.pelvis_height - self.hip_height_offset
        
        right_foot = root_pose.copy()
        right_foot[2] = self.pelvis_height - self.hip_height_offset
        right_foot[0] += 0.1  # 步宽
        
        return left_foot, right_foot
        
    def balance_com(self, current_com, foot_positions):
        """质心平衡控制"""
        # 支撑多边形
        support_poly = self.compute_support_polygon(foot_positions)
        
        # 投影 COM 到支撑多边形
        projected_com = self.project_to_support(current_com, support_poly)
        
        return projected_com
```
