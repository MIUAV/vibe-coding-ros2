---
name: px4-hold-mode
description: PX4 悬停/盘旋模式技能 - 在当前位置上空自动悬停等待指令，适用于等待起飞许可、悬停观察等场景
argument-hint: "悬停" / "Hold Mode" / "Loiter" / "盘旋模式"
user-invocable: true
---

# PX4 悬停/盘旋模式技能

> 在当前位置上空自动悬停等待指令，可设置时间或手动退出

---

## 何时使用

当需要以下帮助时使用此技能：
- 等待起飞许可
- 悬停观察区域
- 任务暂停等待
- 航点间暂停
- 天气等待

---

## 模式特性

### 控制原理

```yaml
hold_mode:
  position_lock: CURRENT_POSITION
  altitude_control: ALTITUDE_HOLD
  heading_control: YAW_HOLD / YAW_RATE
  
  loiter_type:
    - horizontal: 小圈盘旋 (NAV_LOITER_RAD)
    - stationary: 定点悬停
    
  time_control:
    - duration: 定时退出
    - manual_exit: 手动切出
```

### 与位置模式对比

| 特性 | 位置模式 | 悬停模式 |
|------|----------|----------|
| 推杆响应 | 速度控制 | 位置修正 |
| 释放后行为 | 回到原位 | 保持悬停 |
| 适合场景 | 移动飞行 | 定点等待 |
| 抗风能力 | 较好 | 一般 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/vehicle_local_position: 本地位置
/fmu/out/vehicle_odometry: 里程计
/fmu/out/vehicle_attitude: 当前姿态
/fmu/out/loiter_status: 悬停状态
  - active: 是否悬停中
  - time_remaining: 剩余时间
  - heading_lock: 偏航锁定状态
  
# 发布话题
/fmu/in/vehicle_command: 发送命令
  - command: DO_SET_MODE
  - mode: LOITER
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/local_position/pose: 位置
/mavros/loiter/status: 悬停状态

# 服务
/mavros/cmd/command: 发送命令
  - command: MAV_CMD_NAV_LOITER_TIME
  - param1: 盘旋圈数/时间
```

---

## 开发技能

### 悬停控制技能

```yaml
name: loiter_control_skill
description: 盘旋/悬停控制技能
type: control

params:
  # 盘旋参数
  loiter_radius: {type: float, default: 50.0}  # m (正=右转)
  loiter_direction: {type: enum, values: [cw, ccw]}  # 盘旋方向
  
  # 悬停参数
  hover_position: [x, y, z]  # 保持位置
  hover_tolerance: {type: float, default: 0.5}  # m
  
  # 高度控制
  hold_altitude: {type: float}  # m
  altitude_tolerance: {type: float, default: 0.3}  # m

control_laws:
  position_maintenance:
    target: current_position
    correction: P(position_error)
    
  altitude_maintenance:
    target: hold_altitude
    throttle: auto_from_thrust_curve
    
  heading_control:
    mode: {type: enum, values: [hold, rate]}
    target_yaw: {type: float}  # rad
    yaw_rate: {type: float}  # rad/s
```

### 定时悬停技能

```yaml
name: timed_loiter_skill
description: 定时悬停技能
type: timed_action

interface:
  inputs:
    - topic: /loiter_duration
    - topic: /cancel_loiter
  outputs:
    - topic: /loiter_status
      
params:
  duration: {type: float, default: 30.0}  # s
  exit_mode: {type: enum, values: [auto_return, manual]} 
  
  # 自动返回模式
  auto_return_action:
    - action: resume_mission  # 继续任务
    - action: rtl            # 返航
    - action: land            # 降落
    
timeouts:
  loiter_timeout: 0  # 0=无限
  warning_time: 10.0  # 剩余10秒警告
```

### 盘旋飞行技能

```yaml
name: circling_skill
description: 环绕飞行技能
type: flight

params:
  center_point: {type: position, unit: m}
  radius: {type: float, default: 10.0}  # m
  altitude: {type: float, default: 30.0} # m
  direction: {type: enum, values: [cw, ccw]}
  angular_velocity: {type: float, default: 30.0}  # deg/s
  
  # 摄像头指向
  gimbal_mode: {type: enum, values: [center, forward, nadir]}
  gimbal_center: [lat, lon, alt]
  
loiter_patterns:
  circle:
    radius: fixed
    altitude: fixed
  spiral:
    radius_change: 1.0  # m/revolution
    altitude_change: 2.0  # m/revolution
  figure_eight:
    figure8_pattern: standard
    size_ratio: 2.0  # length/width
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `NAV_LOITER_RAD` | 盘旋半径 | 50 m |
| `LOITER_JERK | 盘旋加加速度限制 | 1.0 m/s³ |
| `MPC_XY_CRUISE` | 巡航速度 | 5.0 m/s |
| `MPC_Z_VEL_MAX_UP` | 最大上升速度 | 3.0 m/s |
| `MPC_Z_VEL_MAX_DN` | 最大下降速度 | 1.5 m/s |

### 盘旋方向

```yaml
loiter_direction:
  # 右转 (常用)
  right_hand: positive_radius
  
  # 左转
  left_hand: negative_radius
  
  # 根据任务自动选择
  auto: shortest_turn_to_next_waypoint
```

---

## 测试与验证

### 悬停测试

```bash
# 1. 基本悬停测试
起飞到 5m → 切换到 Loiter → 观察位置保持

# 2. 抗风测试
人工制造气流 → 观察位置修正

# 3. 长时间悬停
悬停 5 分钟 → 观察电池消耗和位置漂移

# 4. 切换测试
Loiter → Position → Loiter → 验证位置一致
```

### 性能指标

```yaml
loiter_performance:
  position_accuracy: ±1.0m (GPS)
  position_accuracy: ±0.3m (RTK)
  altitude_accuracy: ±0.5m
  
  battery_consumption: ~5% per 5 min (varies by model)
  heading_stability: ±5°
  
  recovery_from_wind:
    max_drift: 2.0m
    recovery_time: < 3s
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 位置漂移大 | GPS 精度差 | 等待更多卫星 |
| 高度不稳定 | 气压漂移 | 使用测距仪定高 |
| 盘旋半径不稳 | 速度P值问题 | 调整 MPC_XY_VEL_P |
| 无法进入悬停 | 位置模式未激活 | 先切换到 Position |
| 偏航持续旋转 | 偏航控制问题 | 检查偏航参数 |

---

## 相关技能

- `px4-position-mode`: 位置模式（悬停的基础）
- `px4-mission-mode`: 任务模式（航点间暂停）
- `px4-rtl-mode`: RTL 模式（悬停后可接 RTL）
- `px4-landing`: 着陆模式（悬停后可接着陆）
