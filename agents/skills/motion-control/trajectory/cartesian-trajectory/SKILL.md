---
name: cartesian-trajectory
description: 笛卡尔空间轨迹技能 - 直线插补、圆弧插补、姿态插值、ROS2 Cartesian 控制器
argument-hint: 笛卡尔轨迹 OR cartesian OR 直线插补 OR 圆弧插补 OR SLERP
user-invocable: true
---

# 笛卡尔空间轨迹技能

> 笛卡尔空间轨迹规划

---

## 何时使用

当需要以下帮助时使用此技能：
- 直线插补
- 圆弧插补
- 姿态插值 (SLERP)
- 笛卡尔速度控制
- ROS2 Cartesian 接口

---

## 核心实现

### 直线插补

```python
import numpy as np
from scipy.spatial.transform import Rotation

class CartesianLinear:
    def __init__(self, T_start, T_end, dt=0.01):
        self.T_start = T_start
        self.T_end = T_end
        self.dt = dt
        
        # 位移
        self.dp = T_end[:3, 3] - T_start[:3, 3]
        self.distance = np.linalg.norm(self.dp)
        
        # 旋转
        self.R_start = T_start[:3, :3]
        self.R_end = T_end[:3, :3]
        
        # 时间
        self.duration = self.distance / 0.1  # 默认 0.1 m/s
        
    def pose_at_time(self, t):
        """计算 t 时刻的位姿"""
        # 插值比例
        ratio = min(t / self.duration, 1.0)
        
        # 位置线性插补
        p = self.T_start[:3, 3] + ratio * self.dp
        
        # 姿态 SLERP
        r_start = Rotation.from_matrix(self.R_start)
        r_end = Rotation.from_matrix(self.R_end)
        r = r_start.slerp(r_end, ratio)
        
        # 构建变换矩阵
        T = np.eye(4)
        T[:3, :3] = r.as_matrix()
        T[:3, 3] = p
        
        return T
        
    def velocity_at_time(self, t):
        """计算 t 时刻的速度"""
        # 速度 = 距离 / 时间
        v = self.dp / self.duration if self.duration > 0 else np.zeros(3)
        
        # 角速度
        r_start = Rotation.from_matrix(self.R_start)
        r_end = Rotation.from_matrix(self.R_end)
        
        # 角速度 = (R_end @ R_start.T - I) 的反对称部分
        R_rel = r_end.as_matrix() @ r_start.as_matrix().T
        omega = self.rotation_to_angular_velocity(R_rel) / self.duration
        
        return np.concatenate([v, omega])
        
    def rotation_to_angular_velocity(self, R):
        """旋转矩阵转角速度"""
        return np.array([
            R[2, 1] - R[1, 2],
            R[0, 2] - R[2, 0],
            R[1, 0] - R[0, 1]
        ]) / 2
```

### 圆弧插补

```python
class CircularInterpolation:
    def __init__(self, p_start, p_end, p_center, normal):
        """
        圆弧插补
        p_start, p_end: 起点终点
        p_center: 圆心
        normal: 法向量
        """
        self.p_start = np.array(p_start)
        self.p_end = np.array(p_end)
        self.p_center = np.array(p_center)
        self.normal = np.array(normal) / np.linalg.norm(normal)
        
        # 半径
        self.radius = np.linalg.norm(p_start - p_center)
        
        # 角度
        self.theta_start = np.arctan2(
            np.dot(np.cross(self.normal, p_start - self.p_center), self.normal),
            np.dot(p_start - self.p_center, self.normal)
        )
        self.theta_end = np.arctan2(
            np.dot(np.cross(self.normal, p_end - self.p_center), self.normal),
            np.dot(p_end - self.p_center, self.normal)
        )
        
        # 确保角度正向运动
        if self.theta_end < self.theta_start:
            self.theta_end += 2 * np.pi
            
        self.total_angle = self.theta_end - self.theta_start
        
    def position_at_angle(self, theta):
        """根据角度计算位置"""
        # 切向和径向
        radial = np.cos(theta) * (self.p_start - self.p_center)
        tangent = np.cross(self.normal, radial)
        
        return self.p_center + radial + tangent * np.sin(theta)
```
