---
name: joint-space-trajectory
description: 关节空间轨迹技能 - 五次多项式、七次多项式、梯形速度、LSPB
argument-hint: 关节空间 OR joint space OR 多项式轨迹 OR LSPB OR trapezoidal
user-invocable: true
---

# 关节空间轨迹技能

> 关节空间轨迹规划

---

## 何时使用

当需要以下帮助时使用此技能：
- 五次/七次多项式轨迹
- 梯形速度规划
- LSPB (线性-正弦-抛物线)
- 多关节协调
- 轨迹平滑

---

## 核心实现

### 五次多项式轨迹

```python
import numpy as np

class QuinticPolynomial:
    def __init__(self, q0, qf, v0, vf, a0, af, T):
        """
        五次多项式系数
        q(t) = a0 + a1*t + a2*t^2 + a3*t^3 + a4*t^4 + a5*t^5
        """
        self.T = T
        
        # 边界条件求解
        A = np.array([
            [1, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 0],
            [0, 0, 2, 0, 0, 0],
            [1, T, T**2, T**3, T**4, T**5],
            [0, 1, 2*T, 3*T**2, 4*T**3, 5*T**4],
            [0, 0, 2, 6*T, 12*T**2, 20*T**3]
        ])
        
        b = np.array([q0, v0, a0, qf, vf, af])
        
        self.a = np.linalg.solve(A, b)
        
    def position(self, t):
        """位置"""
        t = np.atleast_1d(t)
        return (self.a[0] + self.a[1]*t + self.a[2]*t**2 + 
                self.a[3]*t**3 + self.a[4]*t**4 + self.a[5]*t**5)
                
    def velocity(self, t):
        """速度"""
        t = np.atleast_1d(t)
        return (self.a[1] + 2*self.a[2]*t + 3*self.a[3]*t**2 + 
                4*self.a[4]*t**3 + 5*self.a[5]*t**4)
                
    def acceleration(self, t):
        """加速度"""
        t = np.atleast_1d(t)
        return (2*self.a[2] + 6*self.a[3]*t + 12*self.a[4]*t**2 + 
                20*self.a[5]*t**3)
```

### 梯形速度规划

```python
class TrapezoidalProfile:
    def __init__(self, q0, qf, vmax, amax):
        self.q0 = q0
        self.qf = qf
        self.vmax = vmax
        self.amax = amax
        
        # 计算时间
        self.dq = abs(qf - q0)
        
        # 加减速时间
        t_acc = vmax / amax
        
        # 检查是否能达到最大速度
        if vmax * t_acc < self.dq / 2:
            # 可以达到最大速度
            self.t_acc = t_acc
            self.t_dec = t_acc
            self.v_cruise = vmax
            self.t_cruise = (self.dq - vmax * t_acc) / vmax
        else:
            # 达不到最大速度
            self.t_acc = np.sqrt(self.dq / amax)
            self.t_dec = self.t_acc
            self.v_cruise = amax * self.t_acc
            self.t_cruise = 0
            
        self.T = 2 * self.t_acc + self.t_cruise
        
    def position(self, t):
        """位置"""
        if t < self.t_acc:
            # 加速段
            return self.q0 + 0.5 * self.amax * t**2
        elif t < self.t_acc + self.t_cruise:
            # 匀速段
            return (self.q0 + 0.5 * self.amax * self.t_acc**2 + 
                   self.v_cruise * (t - self.t_acc))
        else:
            # 减速段
            t_dec = t - self.t_acc - self.t_cruise
            return (self.q0 + self.v_cruise * self.t_cruise + 
                   self.v_cruise * t_dec - 0.5 * self.amax * t_dec**2)
```

### ROS2 轨迹发布

```python
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint

class JointTrajectoryPublisher(Node):
    def __init__(self):
        super().__init__('trajectory_publisher')
        
        self.publisher = self.create_publisher(
            JointTrajectory, '/joint_trajectory', 10)
            
    def publish_trajectory(self, joint_names, positions, durations):
        """发布轨迹"""
        traj = JointTrajectory()
        traj.joint_names = joint_names
        
        for pos, dur in zip(positions, durations):
            point = JointTrajectoryPoint()
            point.positions = pos
            point.time_from_start = rclpy.duration.Duration(seconds=dur).to_msg()
            traj.points.append(point)
            
        self.publisher.publish(traj)
```
