---
name: px4-altitude-mode
description: PX4 高度保持模式技能 - 水平方向手动控制，垂直方向自动保持设定高度
argument-hint: "高度模式" / "Altitude Mode" / "定高模式" / "PX4高度"
user-invocable: true
---

# PX4 高度保持模式技能

> 水平方向由遥控器手动控制，垂直方向自动保持设定高度

---

## 何时使用

当需要以下帮助时使用此技能：
- 手动导航但希望保持高度稳定
- 地形起伏时的恒定高度飞行
- 从自稳模式过渡
- 航拍时需要保持拍摄高度

---

## 模式特性

### 控制原理

```yaml
altitude_mode:
  roll: RC_roll_input → 目标Roll角 → 姿态控制 → 电机输出
  pitch: RC_pitch_input → 目标Pitch角 → 姿态控制 → 电机输出
  yaw: RC_yaw_input → 偏航角速率 → 电机输出
  throttle: RC_throttle_input → 目标爬升率 → 高度控制器 → 电机输出
  
  stabilization: ATTITUDE (姿态角稳定)
  altitude_hold: ALTITUDE (自动保持高度)
  position_hold: NONE (无水平位置保持)
```

### 与姿态模式对比

| 特性 | 姿态模式 | 高度模式 |
|------|----------|----------|
| 姿态控制 | 手动姿态角 | 手动姿态角 |
| 高度控制 | 手动油门 | 自动高度保持 |
| 水平位置 | 无保持 | 无保持 |
| 操纵难度 | 中等 | 较易 |
| 适合场景 | 练习/机动 | 巡航/航拍 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/vehicle_local_position: 本地位置
  - x, y, z: 位置 (m)
  - vx, vy, vz: 速度 (m/s)
/fmu/out/vehicle_global_position: 全局位置
/fmu/out/vehicle_local_position_setpoint: 位置设定点
/fmu/out/vehicle_attitude: 当前姿态

# 发布话题
/fmu/in/vehicle_command: 发送命令
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/local_position/pose: 本地位置
/mavros/local_position/velocity: 速度
/mavros/imu/data: IMU数据

# 发布话题
/mavros/cmd/command: 发送命令
```

---

## 开发技能

### 高度控制技能

```yaml
name: altitude_control_skill
description: 高度环控制开发
type: control

interface:
  inputs:
    - topic: /fmu/out/vehicle_local_position
    - topic: /fmu/out/barometer_altitude
    - topic: /fmu/out/rc_channels
  outputs:
    - topic: /fmu/in/vehicle_command
      
params:
  # 高度控制参数
  alt_control_p: {type: float, default: 1.0}
  alt_control_i: {type: float, default: 0.1}
  alt_control_d: {type: float, default: 0.05}
  
  # 爬升率限制
  climb_rate_max: {type: float, default: 3.0}   # m/s
  descent_rate_max: {type: float, default: 1.5} # m/s
  
control_laws:
  throttle_from_climb_rate:
    input: RC_throttle → target_climb_rate
    altitude_error = current_alt - setpoint_alt
    output = P(alt_error) + I(alt_error) + D(alt_error)
```

### 定高飞行技能

```yaml
name: altitude_hold_skill
description: 定高飞行技能
type: flight

params:
  target_altitude: {type: float, unit: m}
  altitude_tolerance: {type: float, default: 0.5}  # m
  
  # 油门参数
  hover_throttle: {type: float, default: 0.5}  # 悬停油门
  alt_offset: {type: float, default: 0.0}       # 高度微调
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `MC_ALT_HOLD` | 高度保持模式启用 | enabled |
| `MPC_ALT_HOLD` | 最低保持高度 | 0.3 m |
| `MPC_Z_P` | 高度位置P | 1.0 |
| `MPC_Z_VEL_P` | 高度速度P | 1.0 |
| `MPC_Z_VEL_I` | 高度速度I | 0.1 |
| `MPC_Z_VEL_D` | 高度速度D | 0.05 |
| `MPC_TKO_RAMP_T` | 起飞油门斜坡时间 | 1.0 s |

### 高度源选择

```yaml
altitude_sources:
  barometer: 
    priority: 1  # 默认
    accuracy: ~1m
  range_finder:
    priority: 2  # 室内/低空
    accuracy: ~0.1m
  gps_altitude:
    priority: 3  # 户外
    accuracy: ~2m
  vision:
    priority: 4  # 室内定位
    accuracy: ~0.05m
```

---

## 测试与验证

### 高度控制测试

```bash
# 1. 起飞前检查
确认气压计已校准
确认高度源选择正确 (barometer/rangefinder)
检查 MPC_Z_* 参数

# 2. 地面测试
解锁 → 低油门 → 观察高度估计是否稳定

# 3. 飞行测试
起飞到 5m → 稳定悬停 → 观察高度保持
手动横移 → 观察高度是否有明显波动
```

### 高度保持性能指标

```yaml
performance:
  altitude_hold_accuracy: ±0.5m (正常飞行)
  altitude_hold_accuracy: ±0.2m (静止悬停)
  climb_rate_response: < 0.5s (到63%)
  disturbance_rejection: < 1.0m (风扰动)
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 高度漂移 | 气压计漂移 | 起飞前重新校准气压计 |
| 高度忽高忽低 | P/I参数不匹配 | 调整 MPC_Z_VEL_P/I |
| 起飞掉高 | 起飞油门不足 | 增加 MPC_TKO_RAMP_T |
| 高度响应迟钝 | D值过大 | 减小 MPC_Z_VEL_D |
| 低空高度不稳 | 超声波干扰 | 使用气压计代替测距仪 |

---

## 相关技能

- `px4-stabilized-mode`: 姿态模式（无高度保持）
- `px4-position-mode`: 位置模式（全自动保持）
- `px4-stabilized-mode`: 高度控制是位置控制的基础
- `px4-mc-tuning`: PID参数调整
