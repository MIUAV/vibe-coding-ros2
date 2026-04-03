---
name: multi-robot-planning
description: 多机器人路径规划技能 - ORCA、VR算法、冲突解决、协同规划
argument-hint: "多机器人规划" / "ORCA" / "multi-robot" / "协同规划"
user-invocable: true
---

# 多机器人路径规划技能

> 多机器人协同路径规划

---

## 何时使用

当需要以下帮助时使用此技能：
- ORCA 速度障碍
- 多机器人路径规划
- 冲突检测与解决
- 编队控制
- 协同导航

---

## 核心实现

### ORCA 算法

```python
import numpy as np

class ORCAPlanner:
    def __init__(self, time_horizon=5.0, radius=0.3):
        self.time_horizon = time_horizon
        self.radius = radius
        
    def compute_velocity(self, robot_pos, robot_vel, other_robots, obstacles):
        """
        ORCA 速度障碍算法
        """
        # 构建 ORCA 半平面
        orca_lines = []
        
        for other in other_robots:
            # 相对位置和速度
            pos_diff = other['position'] - robot_pos
            vel_diff = robot_vel - other['velocity']
            
            # 检测碰撞
            dist = np.linalg.norm(pos_diff)
            if dist > self.time_horizon * self.radius:
                continue
                
            # 计算 ORCA 半平面
            line = self.compute_orca_line(pos_diff, vel_diff, other['velocity'])
            orca_lines.append(line)
            
        # 优化求解
        return self.optimize_velocity(robot_vel, orca_lines)
        
    def compute_orca_line(self, pos_diff, vel_diff, other_vel):
        """计算 ORCA 约束线"""
        dist = np.linalg.norm(pos_diff)
        
        if dist < 1e-6:
            return None
            
        # 单位向量
        u = pos_diff / dist
        v = vel_diff
        
        # 相对速度在单位向量上的投影
        proj = np.dot(v, u)
        
        # 法向量
        n = v - proj * u
        
        if np.linalg.norm(n) > 1e-6:
            n = n / np.linalg.norm(n)
        else:
            n = np.array([-u[1], u[0]])
            
        # ORCA 线
        w = v - (pos_diff / dist - u) * self.radius / self.time_horizon
        
        return {'point': np.array([0, 0]), 'normal': n}
        
    def optimize_velocity(self, preferred_vel, orca_lines):
        """在 ORCA 半平面内优化速度"""
        # 线性规划或几何求解
        return preferred_vel
```

### 多机器人路径规划

```python
class MultiRobotPlanner:
    def __init__(self, num_robots):
        self.num_robots = num_robots
        
    def plan(self, starts, goals, obstacles):
        """多机器人路径规划"""
        # 1. 独立规划
        paths = []
        for i in range(self.num_robots):
            path = self.plan_single(starts[i], goals[i], obstacles)
            paths.append(path)
            
        # 2. 冲突检测
        conflicts = self.detect_conflicts(paths)
        
        # 3. 冲突解决
        while conflicts:
            for conflict in conflicts:
                self.resolve_conflict(paths, conflict)
            conflicts = self.detect_conflicts(paths)
            
        return paths
        
    def detect_conflicts(self, paths):
        """检测路径冲突"""
        conflicts = []
        
        for i in range(self.num_robots):
            for j in range(i + 1, self.num_robots):
                conflict = self.check_path_conflict(paths[i], paths[j])
                if conflict:
                    conflicts.append((i, j, conflict))
                    
        return conflicts
        
    def resolve_conflict(self, paths, conflict):
        """解决冲突"""
        robot1, robot2, time_step = conflict
        
        # 速度调节或路径重规划
        pass
```
