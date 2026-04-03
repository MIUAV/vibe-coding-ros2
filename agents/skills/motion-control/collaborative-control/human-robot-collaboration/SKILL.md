---
name: human-robot-collaboration
description: 人机协作技能 - 直接示教、安全监控、力限接触、协作空间、ROS2 CSR
argument-hint: "人机协作" / "HRC" / "direct teaching" / "collaborative" / "human-robot"
user-invocable: true
---

# 人机协作控制技能

> 人机协作控制与安全

---

## 何时使用

当需要以下帮助时使用此技能：
- 直接示教
- 安全监控
- 力限接触
- 协作空间 (CSPACE)
- ROS2 协作接口

---

## 核心实现

### 直接示教

```python
import numpy as np

class DirectTeaching:
    def __init__(self, robot_model):
        self.robot = robot_model
        self.gravity_compensation = True
        
    def compute_teaching_torque(self, q, q_dot, F_ext):
        """
        直接示教力矩
        仅需要重力补偿 + 外力跟踪
        """
        # 重力补偿
        if self.gravity_compensation:
            tau_gravity = self.robot.compute_gravity(q)
        else:
            tau_gravity = np.zeros_like(q)
            
        # 外力跟踪 (阻抗为 0)
        J = self.robot.get_jacobian(q)
        tau_ext = J.T @ F_ext * 0.1  # 缩放因子
        
        return tau_gravity + tau_ext
        
    def gravity_compensation(self, q):
        """重力补偿"""
        g = 9.81
        
        # 简化的重力模型
        tau_g = np.zeros_like(q)
        
        for i in range(len(q)):
            # 每个关节的重力矩
            m_i = self.robot.link_mass[i]
            com_i = self.robot.link_com[i]
            tau_g[i] = m_i * g * com_i[1]
            
        return tau_g
```

### 安全监控

```python
class SafetyMonitor:
    def __init__(self):
        self.velocity_limit = 0.5  # m/s
        self.force_limit = 150.0   # N
        self.power_limit = 200.0   # W
        
        self.safety_state = 'normal'
        
    def check_safety(self, robot_state):
        """
        检查安全状态
        返回: 'normal', 'warning', 'stop'
        """
        # 速度检查
        if np.any(np.abs(robot_state.ee_velocity) > self.velocity_limit):
            return 'warning'
            
        # 力检查
        if np.any(np.abs(robot_state.ee_force) > self.force_limit):
            return 'stop'
            
        # 功率检查
        power = np.abs(robot_state.motor_power).sum()
        if power > self.power_limit:
            return 'warning'
            
        return 'normal'
        
    def generate_safety_response(self, safety_state):
        """生成安全响应"""
        if safety_state == 'stop':
            # 紧急停止
            return {'type': 'stop', 'duration': 0.0}
        elif safety_state == 'warning':
            # 减速
            return {'type': 'slow', 'factor': 0.5}
        else:
            return {'type': 'normal'}
```

### 力限接触

```python
class ForceLimitedContact:
    def __init__(self):
        self.force_threshold = 50.0  # N
        
    def compute_safe_velocity(self, direction, F_contact):
        """
        根据接触力计算安全速度
        """
        F_mag = np.linalg.norm(F_contact)
        
        if F_mag > self.force_threshold:
            # 减速或停止
            scale = min(1.0, F_threshold / F_mag)
        else:
            scale = 1.0
            
        return direction * scale
```

### 协作空间 (CSPACE)

```python
class CollaborativeSpace:
    def __init__(self):
        # ISO 10218 协作空间定义
        self.safety_distance = 0.5  # m
        self.warning_distance = 1.0  # m
        
    def get_cspace_status(self, human_pos, robot_pos, robot_velocity):
        """
        获取协作空间状态
        """
        distance = np.linalg.norm(human_pos - robot_pos)
        
        if distance < self.safety_distance:
            return 'stop'
        elif distance < self.warning_distance:
            # 计算所需的安全速度
            min_safe_velocity = self.compute_safe_velocity(
                distance, robot_velocity)
            return {'type': 'speed_limit', 'velocity': min_safe_velocity}
        else:
            return 'normal'
            
    def compute_safe_velocity(self, distance, current_velocity):
        """计算安全速度"""
        # ISO/TS 15066 公式
        z_max = 2.0  # 最大安全速度
        d = max(0.5, distance)
        
        v_max = z_max * (d - self.safety_distance) / (self.warning_distance - self.safety_distance)
        
        return min(v_max, current_velocity)
```
