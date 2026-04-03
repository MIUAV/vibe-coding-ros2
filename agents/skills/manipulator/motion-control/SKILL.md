---
name: motion-control
description: 机械臂运动控制 - 逆运动学、轨迹规划、力控、协作控制
argument-hint: "机械臂控制" / "轨迹规划" / "力控" / "协作"
user-invocable: true
---

# 机械臂运动控制技能

> 用于开发机械臂的运动控制和规划系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 逆运动学求解
- 轨迹规划与优化
- 力控制模式
- 协作机器人控制

---

## 快速参考

### 控制配置

```yaml
manipulator_control:
  # 控制模式
  mode: position / velocity / torque / hybrid
  
  # 轨迹参数
  trajectory:
    max_velocity: 1.0  # m/s
    max_acceleration: 2.0  # m/s²
    planner: OMPL / CHOMP
    
  # 力控
  force_control:
    stiffness: 1000.0  # N/m
    damping: 50.0  # N*s/m
```

---

## 逆运动学

### 数值 IK

```python
class NumericalIK:
    def __init__(self, link_lengths):
        self.links = link_lengths
        self.max_iterations = 100
        self.tolerance = 1e-4
        
    def solve(self, target_pose, initial_joints=None):
        """数值迭代求解 IK"""
        if initial_joints is None:
            joints = np.zeros(len(self.links))
            
        for i in range(self.max_iterations):
            # 正运动学
            current_pose = self.forward_kinematics(joints)
            
            # 误差
            error = target_pose - current_pose
            
            if np.linalg.norm(error) < self.tolerance:
                return joints
                
            # 雅可比
            J = self.compute_jacobian(joints)
            
            # 关节增量
            delta_joints = np.linalg.pinv(J) @ error
            joints += delta_joints
            
        return joints  # 可能未收敛
```

---

## 轨迹规划

### 时间最优轨迹

```python
class TrajectoryPlanner:
    def __init__(self):
        self.velocity_limits = np.array([1.0, 1.0, 1.5, 1.5, 2.0, 2.0])  # rad/s
        self.acceleration_limits = np.array([2.0, 2.0, 3.0, 3.0, 4.0, 4.0])
        
    def plan(self, waypoints):
        """时间最优轨迹规划"""
        # 1. 空间轨迹 (样条插值)
        spatial = self.spatial_interpolation(waypoints)
        
        # 2. 时间最优分配
        temporal = self.time_optimization(spatial)
        
        return temporal
        
    def compute_torque(self, trajectory):
        """计算所需扭矩"""
        torques = []
        for t in trajectory:
            q, qd, qdd = trajectory.sample(t)
            tau = self.inertia_matrix(q) @ qdd + self.coriolis(q, qd) + self.gravity(q)
            torques.append(tau)
        return np.array(torques)
```

---

## 力控制

### 阻抗控制

```python
class ImpedanceController:
    def __init__(self, M, B, K):
        # 惯性、阻尼、刚度矩阵
        self.M = np.diag(M)
        self.B = np.diag(B)
        self.K = np.diag(K)
        
    def compute_torque(self, error, error_dot, error_ddot):
        """阻抗控制扭矩"""
        # M * (error_ddot - desired_ddot) + B * error_dot + K * error
        tau = self.M @ error_ddot + self.B @ error_dot + self.K @ error
        
        # 添加重力补偿
        tau += self.gravity_compensation()
        
        return tau
```

---

## 相关文档

- `./manipulator/perception/SKILL.md` - 感知系统
- `./manipulator/localization/SKILL.md` - 定位系统
- `./manipulator/skill-planning/SKILL.md` - 技能规划
