---
name: px4-position-mode
description: PX4 位置保持模式技能 - 水平/垂直方向自动保持位置和高度，遥控器控制移动速度
argument-hint: "位置模式" / "Position Mode" / "定点模式" / "GPS模式"
user-invocable: true
---

# PX4 位置保持模式技能

> 自动保持当前位置和高度，遥控器控制移动速度和方向

---

## 何时使用

当需要以下帮助时使用此技能：
- GPS 信号良好的户外飞行
- 需要自动悬停保持位置
- 航点飞行前的位置确认
- 手飞但需要省力的巡航飞行

---

## 模式特性

### 控制原理

```yaml
position_mode:
  roll: RC_roll_input → 目标横移速度 → 速度控制器 → 电机输出
  pitch: RC_pitch_input → 目标前后速度 → 速度控制器 → 电机输出
  yaw: RC_yaw_input → 偏航角速率 → 姿态控制器 → 电机输出
  throttle: RC_throttle_input → 目标爬升率 → 高度控制器 → 电机输出
  
  stabilization: ATTITUDE (姿态角稳定)
  altitude_hold: ALTITUDE (自动保持高度)
  position_hold: XY_POSITION (水平位置自动保持)
```

### 与高度模式对比

| 特性 | 高度模式 | 位置模式 |
|------|----------|----------|
| 水平位置 | 无保持 | 自动保持 |
| 姿态控制 | 手动姿态角 | 自动姿态 |
| 推杆响应 | 姿态角变化 | 速度变化 |
| GPS依赖 | 建议有 | 必须有 |
| 适合场景 | 地形跟踪 | 定点悬停 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/vehicle_local_position: 本地位置 (NED)
  - x, y, z: 位置 (m)
  - vx, vy, vz: 速度 (m/s)
/fmu/out/vehicle_local_position_setpoint: 位置设定点
/fmu/out/vehicle_attitude: 当前姿态
/fmu/out/vehicle_odometry: 里程计数据

# 发布话题
/fmu/in/vehicle_command: 发送命令
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/local_position/pose: 本地位置
/mavros/local_position/velocity: 速度
/mavros/setpoint_velocity/cmd_vel: 速度设定点

# 发布话题
/mavros/cmd/command: 发送命令
```

---

## 开发技能

### 位置控制技能

```yaml
name: position_control_skill
description: 位置环控制开发
type: control

interface:
  inputs:
    - topic: /fmu/out/vehicle_local_position
    - topic: /fmu/out/vehicle_odometry
    - topic: /fmu/out/rc_channels
  outputs:
    - topic: /fmu/in/vehicle_command
      
params:
  # 水平位置控制参数
  xy_control_p: {type: float, default: 1.0}
  xy_control_i: {type: float, default: 0.0}
  xy_control_d: {type: float, default: 0.1}
  
  # 速度控制参数
  vel_xy_p: {type: float, default: 0.2}
  vel_xy_i: {type: float, default: 0.02}
  vel_xy_d: {type: float, default: 0.05}
  
  # 速度限制
  vel_max: {type: float, default: 5.0}   # m/s
  accel_max: {type: float, default: 5.0} # m/s²

control_laws:
  horizontal_control:
    position_error = target_pos - current_pos
    target_vel = P(position_error)
    target_att = velocity_controller(target_vel)
    
  vertical_control:
    altitude_error = target_alt - current_alt
    target_climbrate = P(altitude_error)
    target_throttle = alt_controller(target_climbrate)
```

### 定点悬停技能

```yaml
name: position_hold_skill
description: 定点悬停技能
type: flight

params:
  hold_position: [x, y, z]  # 目标位置
  hold_tolerance: {type: float, default: 0.5}  # m
  
  # 悬停参数
  hover_throttle: {type: float, default: 0.5}
  hover_altitude: {type: float}  # 设定悬停高度
  
performance:
  position_hold_accuracy: ±0.3m
  velocity_stability: ±0.2m/s
  heading_stability: ±5°
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `MPC_XY_P` | 水平位置P | 1.0 |
| `MPC_XY_VEL_P` | 水平速度P | 0.2 |
| `MPC_XY_VEL_I` | 水平速度I | 0.02 |
| `MPC_XY_VEL_D` | 水平速度D | 0.05 |
| `MPC_Z_P` | 垂直位置P | 1.0 |
| `MPC_Z_VEL_P` | 垂直速度P | 1.0 |
| `MPC_XY_VEL_MAX` | 最大水平速度 | 5.0 m/s |
| `MPC_Z_VEL_MAX_UP` | 最大上升速度 | 3.0 m/s |
| `MPC_Z_VEL_MAX_DN` | 最大下降速度 | 1.5 m/s |

### 感度/行程设置

```yaml
sticks:
  # 速度映射
  xy_vel_sensitivity: {type: float, default: 1.0}  # 摇杆最大行程对应的速度
  z_vel_sensitivity: {type: float, default: 1.0}
  
  # Expo
  roll_pitch_expo: {type: float, default: 0.0}
  throttle_expo: {type: float, default: 0.0}
```

---

## 测试与验证

### 位置保持测试

```bash
# 1. GPS 检查
# QGC → 确认 GPS 信号 > 8 颗星
# 确认位置估计绿色

# 2. 飞行测试
起飞到 3m → 稳定悬停 → 观察位置漂移
观察 30 秒 → 记录漂移范围

# 3. 抗扰测试
轻推飞机 → 松手 → 观察是否回原位
```

### 性能指标

```yaml
position_mode_performance:
  hover_drift: < 1.0m over 5 minutes
  position_accuracy: ±0.5m (GPS)
  position_accuracy: ±0.1m (RTK)
  velocity_accuracy: ±0.3m/s
  
  disturbance_recovery:
    wind_5mps: < 1.5m drift
    recovery_time: < 3s
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 位置漂移大 | GPS 精度差 | 等待更多卫星或使用 RTK |
| 定点来回摆动 | D 值过大 | 减小 MPC_XY_VEL_D |
| 定点响应迟钝 | P 值过小 | 增大 MPC_XY_VEL_P |
| 无法进入位置模式 | GPS 未锁定 | 等待 GPS 锁定 |
| 高度保持不稳 | 气压漂移 | 重新校准或使用测距仪 |

---

## 相关技能

- `px4-altitude-mode`: 高度模式（只有高度保持）
- `px4-mission-mode`: 任务模式（自动航线飞行）
- `px4-offboard-mode`: Offboard 模式（外部控制）
- `px4-rtl-mode`: 返航模式
- `px4-mc-tuning`: PID 参数调整
