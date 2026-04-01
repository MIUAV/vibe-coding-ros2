---
name: action
description: 轮式车辆运动控制 - 底盘控制、驱动控制、转向控制、车辆模型
argument-hint: "车辆控制" / "底盘驱动" / "转向控制" / "车辆模型"
user-invocable: true
---

# 轮式车辆运动控制技能

> 用于开发轮式车辆底盘的运动控制系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 底盘运动控制
- 差速驱动控制
- 阿克曼转向
- 高速车辆控制

---

## 快速参考

### 控制配置

```yaml
wheeled_vehicle_action:
  # 底盘类型
  chassis_type: differential / ackermann / omnidirectional
  
  # 驱动参数
  drive:
    motor: brushless_dc
    max_rpm: 3000
    gear_ratio: 20
    
  # 安全参数
  safety:
    max_speed: 10  # m/s
    max_accel: 3   # m/s²
    emergency_brake_dist: 5  # m
```

---

## 差速驱动

### 差速控制

```python
class DifferentialDriveController:
    def __init__(self, wheel_radius, axle_track):
        self.r = wheel_radius
        self.L = axle_track
        
    def compute_wheel_velocities(self, v, omega):
        """计算轮速"""
        v_left = (v - omega * self.L / 2) / self.r
        v_right = (v + omega * self.L / 2) / self.r
        
        return v_left, v_right
        
    def compute_vehicle_motion(self, v_left, v_right):
        """计算车辆运动"""
        v = (v_left + v_right) * self.r / 2
        omega = (v_right - v_left) * self.r / self.L
        
        return v, omega
```

---

## 阿克曼转向

### 转向控制

```python
class AckermannController:
    def __init__(self, wheelbase, track_width, max_steer_angle=30):
        self.L = wheelbase
        self.T = track_width
        self.max_steer = max_steer_angle  # deg
        
    def compute_steering_angles(self, curvature):
        """计算阿克曼转向角"""
        # 内外轮转向角
        alpha_inner = atan(self.L / (1/curvature - self.T/2))
        alpha_outer = atan(self.L / (1/curvature + self.T/2))
        
        # 限幅
        alpha_inner = clip(alpha_inner, -self.max_steer, self.max_steer)
        alpha_outer = clip(alpha_outer, -self.max_steer, self.max_steer)
        
        return alpha_inner, alpha_outer
        
    def compute_vehicle_velocity(self, v_long, steering_angle):
        """车辆速度"""
        # 瞬时转向半径
        radius = self.L / tan(steering_angle)
        
        # 横摆角速度
        omega = v_long / radius
        
        return v_long, omega
```

---

## 高速控制

### 车辆稳定性控制

```python
class VehicleStabilityControl:
    def __init__(self):
        self.esp = ElectronicStabilityProgram()
        self.tc = TractionControl()
        
    def干预(self, vehicle_state, driver_input):
        """稳定性干预"""
        # 计算横摆力矩
        yaw_moment = self.esp.compute_yaw_moment(vehicle_state)
        
        # 牵引力控制
        traction = self.tc.compute_traction(vehicle_state)
        
        # 分配到各轮
        brake_pressures = self分配制动力(yaw_moment, traction)
        
        return brake_pressures
```

---

## 相关文档

- `./wheeled_vehicle/perception/SKILL.md` - 感知系统
- `./wheeled_vehicle/localization/SKILL.md` - 定位系统
- `./wheeled_vehicle/navigation/SKILL.md` - 导航系统
