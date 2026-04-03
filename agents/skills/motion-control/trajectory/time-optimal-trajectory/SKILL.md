---
name: time-optimal-trajectory
description: 时间最优轨迹技能 - SQP 优化、可行速度规划、动态约束、TOPP-RA
argument-hint: "时间最优" / "time-optimal" / "TOPP" / "SQP" / "optimal trajectory"
user-invocable: true
---

# 时间最优轨迹技能

> 时间最优轨迹规划

---

## 何时使用

当需要以下帮助时使用此技能：
- 时间最优轨迹
- 动态约束
- SQP 优化
- 可行速度规划
- TOPP-RA 算法

---

## 核心实现

### TOPP-RA 算法

```python
import numpy as np
from scipy.optimize import minimize

class TimeOptimalTrajectory:
    def __init__(self, path, vmax, amax, v_start=0, v_end=0):
        """
        时间最优轨迹规划 (TOPP-RA)
        path: N x 3 路径点
        vmax, amax: 速度和加速度限制
        """
        self.path = np.array(path)
        self.vmax = vmax
        self.amax = amax
        self.v_start = v_start
        self.v_end = v_end
        
        # 路径参数化
        self.s = self.compute_arc_lengths()
        
    def compute_arc_lengths(self):
        """计算弧长"""
        diff = np.diff(self.path, axis=0)
        segment_lengths = np.linalg.norm(diff, axis=1)
        return np.concatenate([[0], np.cumsum(segment_lengths)])
        
    def compute_curvature(self):
        """计算曲率"""
        n = len(self.path)
        kappas = []
        
        for i in range(n - 2):
            v1 = self.path[i+1] - self.path[i]
            v2 = self.path[i+2] - self.path[i+1]
            
            cross = np.cross(v1, v2)
            norm = np.linalg.norm(cross)
            
            if norm > 1e-6:
                k = norm / (np.linalg.norm(v1) * np.linalg.norm(v2))
            else:
                k = 0
                
            kappas.append(k)
            
        return np.array(kappas)
        
    def compute_feasible_velocity(self):
        """计算可行速度曲线"""
        n = len(self.s)
        v_sq = np.zeros(n)
        v_sq[0] = self.v_start ** 2
        
        # 前向传播
        for i in range(n - 1):
            dv = self.s[i+1] - self.s[i]
            
            # 加减速约束
            v_sq[i+1] = min(self.vmax**2, v_sq[i] + 2 * self.amax * dv)
            
        # 后向传播
        v_sq[-1] = min(v_sq[-1], self.v_end**2)
        
        for i in range(n - 2, -1, -1):
            dv = self.s[i+1] - self.s[i]
            v_sq[i] = min(v_sq[i], v_sq[i+1] + 2 * self.amax * dv)
            
        return np.sqrt(v_sq)
```

### SQP 优化

```python
class SQPOptimizer:
    def __init__(self, num_points, vmax, amax):
        self.n = num_points
        self.vmax = vmax
        self.amax = amax
        
    def optimize_time(self, path):
        """SQP 优化时间"""
        # 初始猜测
        t = np.linspace(0, 1, self.n)
        
        def objective(beta):
            # 惩罚项: 时间 + 速度约束违反
            return np.sum(beta) + 1e6 * self.constraint_violation(path, t, beta)
            
        result = minimize(
            objective, 
            np.ones(self.n - 1),
            method='SLSQP',
            options={'maxiter': 100}
        )
        
        return result.x
        
    def constraint_violation(self, path, t, beta):
        """约束违反量"""
        # 时间导数
        dt = np.diff(t + beta)
        
        # 速度
        v = np.linalg.norm(np.diff(path, axis=0), axis=1) / dt
        
        # 违反速度约束
        return np.sum(np.maximum(0, v - self.vmax)**2)
```
