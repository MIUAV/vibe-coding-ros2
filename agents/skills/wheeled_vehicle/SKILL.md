---
name: wheeled_vehicle
description: 轮式车辆导航与控制 - 差速/阿克曼/麦克纳姆轮运动控制、路径规划
argument-hint: "轮式车辆" / "差速驱动" / "阿克曼" / "麦克纳姆轮"
user-invocable: true
---

# 轮式车辆技能

> 用于开发轮式底盘机器人的运动控制和导航系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置底盘运动模型
- 实现路径跟踪
- 运动模式切换
- 复杂地形通行

---

## 快速参考

### 底盘类型

| 类型 | 机动性 | 负载 | 适用场景 |
|------|--------|------|----------|
| 两轮差速 | ★★★★ | 中 | 室内机器人 |
| 四轮差速 | ★★★ | 高 | 轮式机器人 |
| 阿克曼 | ★★ | 高 | 室外车辆 |
| 麦克纳姆轮 | ★★★★★ | 中 | 狭窄空间 |
| 全向轮 | ★★★★★ | 中 | 精密操作 |
| 履带式 | ★★★★ | 高 | 复杂地形 |

---

## 运动模型

### 差速驱动 (Differential Drive)

```python
class DifferentialDrive:
    def __init__(self, wheel_radius, axle_track):
        self.r = wheel_radius
        self.L = axle_track
        
    def forward_kinematics(self, v_left, v_right):
        """速度转位姿"""
        v = (v_left + v_right) / 2          # 线速度
        omega = (v_right - v_left) / self.L  # 角速度
        
        return v, omega
        
    def inverse_kinematics(self, v, omega):
        """位姿转速度"""
        v_left = (v - omega * self.L / 2) / self.r
        v_right = (v + omega * self.L / 2) / self.r
        
        return v_left, v_right
```

### 阿克曼转向 (Ackermann)

```python
class AckermannDrive:
    def __init__(self, wheelbase, track_width):
        self.L = wheelbase
        self.T = track_width
        
    def steering_angle(self, radius):
        """计算转向角"""
        # 阿克曼几何
        alpha = atan(self.L / radius)
        
        # 左右轮转向角差异
        alpha_inner = atan(self.L / (radius - self.T/2))
        alpha_outer = atan(self.L / (radius + self.T/2))
        
        return alpha_inner, alpha_outer
```

### 麦克纳姆轮 (Mecanum)

```python
class MecanumDrive:
    def __init__(self, a, b, r):
        # a: 轮子到中心X距离
        # b: 轮子到中心Y距离
        # r: 轮子半径
        self.a = a
        self.b = b
        self.r = r
        
    def inverse_kinematics(self, vx, vy, omega):
        """全向运动"""
        # 4个轮子的速度
        v1 = (vx - vy - omega*(self.a+self.b)) / self.r
        v2 = (vx + vy + omega*(self.a+self.b)) / self.r
        v3 = (vx + vy - omega*(self.a+self.b)) / self.r
        v4 = (vx - vy + omega*(self.a+self.b)) / self.r
        
        return [v1, v2, v3, v4]
```

---

## 控制器

### PID 速度控制

```python
class VelocityController:
    def __init__(self, kp, ki, kd):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        
        self.integral = 0
        self.prev_error = 0
        
    def compute(self, target_vel, current_vel, dt):
        error = target_vel - current_vel
        
        # PID
        P = self.kp * error
        self.integral += error * dt
        I = self.ki * self.integral
        D = self.kd * (error - self.prev_error) / dt
        
        output = P + I + D
        
        self.prev_error = error
        return output
```

### Pure Pursuit 路径跟踪

```python
class PurePursuit:
    def __init__(self, lookahead_dist, gain):
        self.lookahead = lookahead_dist
        self.gain = gain
        
    def compute_control(self, pose, path):
        # 1. 找到前瞻点
        lookahead_point = find_lookahead_point(
            pose, path, self.lookahead)
        
        # 2. 计算角度误差
        angle_to_point = atan2(
            lookahead_point.y - pose.y,
            lookahead_point.x - pose.x)
        
        error_angle = angle_to_point - pose.theta
        
        # 3. 计算曲率
        curvature = (2 * sin(error_angle)) / self.lookahead
        
        # 4. 速度控制
        velocity = self.gain * (1 - abs(error_angle) / pi)
        
        return curvature, velocity
```

---

## 导航配置

### Navigation2 配置

```yaml
navigation:
  local_planner: "dwb"  # DWB 局部规划
  global_planner: "navfn"  # NavFn 全局规划
  
  # 运动参数
  max_vel_x: 1.0
  max_vel_theta: 1.0
  acc_lim_x: 0.5
  acc_lim_theta: 0.5
  
  # 目标容差
  xy_goal_tolerance: 0.1
  yaw_goal_tolerance: 0.05
```

---

## 常用框架

### ROS 2 功能包

| 包 | 功能 |
|----|------|
| `navigation2` | 导航堆栈 |
| `nav2_bringup` | 启动配置 |
| `diff_drive_controller` | 差速控制 |
| `ackermann_controller` | 阿克曼控制 |

### 开源项目

- **Navigation2**: https://navigation.ros.org/
- **ROS2 Control**: https://control.ros.org/

---

## 相关文档

- [Navigation2 文档](https://navigation.ros.org/)
- [ROS2 Control](https://control.ros.org/)