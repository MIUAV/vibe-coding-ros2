---
name: px4-stabilized-mode
description: PX4 姿态稳定模式技能 - 手动控制姿态角，油门控制高度，飞控保持飞机水平
argument-hint: 自稳模式 OR Stabilized Mode OR 姿态模式 OR PX4自稳
user-invocable: true
---

# PX4 姿态稳定模式技能

> 遥控器控制飞行姿态角，油门控制上升/下降，飞控自动保持水平

---

## 何时使用

当需要以下帮助时使用此技能：
- 从手动模式过渡到自稳飞行
- 练习基本飞行控制
- 需要手动姿态控制但希望保持稳定
- 飞行新手学习阶段

---

## 模式特性

### 控制原理

```yaml
stabilized_mode:
  roll: RC_roll_input → 目标Roll角 → P控制器 → 电机输出
  pitch: RC_pitch_input → 目标Pitch角 → P控制器 → 电机输出
  yaw: RC_yaw_input → 偏航角速率 → 电机输出
  throttle: RC_throttle_input → 直接油门 → 电机输出
  
  stabilization: ATTITUDE (姿态角稳定)
  altitude_hold: NONE (无高度保持)
  position_hold: NONE (无位置保持)
```

### 与手动模式对比

| 特性 | 手动模式 | 姿态稳定模式 |
|------|----------|--------------|
| 姿态控制 | 电机直出 | 角度P控制 |
| 水平稳定 | 无 | 飞控保持水平 |
| 适合人群 | 高级飞手 | 初学者 |
| 机动性 | 极限机动 | 受限但安全 |

### 典型应用

| 场景 | 说明 |
|------|------|
| 飞行训练 | 新手练习基本控制 |
| 室内飞行 | GPS不可用时的基础稳定 |
| 颠簸环境 | 需要快速手动姿态调整 |
| 航拍 | 需要手动姿态但希望画面稳定 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/vehicle_attitude: 当前姿态 (vehicle_attitude)
  - q: quaternion [w, x, y, z]
  - rollspeed, pitchspeed, yawspeed: 角速度
/fmu/out/vehicle_attitude_setpoint: 目标姿态
/fmu/out/rc_channels: RC输入值
/fmu/out/actuator_outputs: 电机输出

# 发布话题
/fmu/in/vehicle_command: 发送命令
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/imu/data: IMU数据 (姿态)
/mavros/rc/in: 遥控器输入
/mavros/actuator_control: 电机控制

# 发布话题
/mavros/cmd/command: 发送命令
```

---

## 开发技能

### 姿态控制技能

```yaml
name: attitude_control_skill
description: 姿态环控制开发
type: control

interface:
  inputs:
    - topic: /fmu/out/vehicle_attitude
    - topic: /fmu/out/rc_channels
  outputs:
    - topic: /fmu/in/vehicle_command
      
params:
  roll_max: 35.0        # degrees
  pitch_max: 35.0       # degrees
  roll_rate_max: 90.0  # deg/s
  pitch_rate_max: 90.0 # deg/s
  
control_laws:
  roll_control:
    type: P_controller
    P: 5.0
    input: RC_roll → angle_error
    output: motor_diff
    
  pitch_control:
    type: P_controller
    P: 5.0
    input: RC_pitch → angle_error
    output: motor_diff
```

### 增稳 (Stabilization) 技能

```yaml
name: stabilization_skill
description: 增稳开发技能
type: control

params:
  # 姿态控制参数
  attitude_p: {type: float, default: 5.0}
  attitude_d: {type: float, default: 0.0}  # 通常无D项
  
  # 角速率控制参数
  rate_p: {type: float, default: 3.0}
  rate_i: {type: float, default: 0.0}
  rate_d: {type: float, default: 0.1}
  
  # 控制频率
  control_freq: {type: int, default: 250}  # Hz
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `MTC_TYPE` | 姿态控制器类型 | 1 (manual) |
| `MC_ROLL_P` | 滚转角度P | 5.0 |
| `MC_PITCH_P` | 俯仰角度P | 5.0 |
| `MC_YAW_P` | 偏航角速率P | 3.0 |
| `MC_ROLL_RATE_P` | 滚转角速率P | 3.0 |
| `MC_PITCH_RATE_P` | 俯仰角速率P | 3.0 |
| `MC_YAW_RATE_P` | 偏航角速率P |  3.0 |

### 感度设置

```yaml
sensitivity:
  # 操纵感度 ( Expo )
  roll_expo: {type: float, default: 0.0}  # 0-1, 越大中心区越不敏感
  pitch_expo: {type: float, default: 0.0}
  yaw_expo: {type: float, default: 0.0}
  
  # 行程极限
  roll_max: 35.0   # degrees
  pitch_max: 35.0  # degrees
  yaw_max_rate: 90.0 # deg/s
```

---

## 测试与验证

### 地面测试

```bash
# 1. 安全检查
确认螺旋桨安装牢固
电池连接前检查遥控器信号
地面测试时保持飞机固定

# 2. 感度测试
# 轻轻推动摇杆 → 观察响应是否平滑
# 调整 MC_ROLL_P, MC_PITCH_P 改善响应

# 3. 中心回中测试
# 释放摇杆 → 飞机应保持水平
# 调整 trim 参数修正水平偏差
```

### 飞行测试检查单

```yaml
preflight:
  1. 解锁后轻轻推动油门 (10-20%)
  2. 观察飞机是否水平保持
  3. 轻推roll摇杆 → 飞机应倾斜并保持
  4. 释放 → 飞机应回平
  5. 推俯仰 → 飞机应低头并保持
  
flight_tests:
  - hover_test: 维持油门悬停
  - roll_response: 左右滚转响应
  - pitch_response: 前后俯仰响应
  - yaw_response: 偏航旋转响应
  - recovery_test: 大角度倾斜后放手应自动回平
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 飞机不停抖动 | P值过大 | 减小 MC_ROLL_P, MC_PITCH_P |
| 倾斜后不回平 | P值过小 | 增大 P值 |
| 响应迟钝 | P值过小 | 增大 P值 |
| 自转 (yaw drift) | yaw偏置未校准 | 检查陀螺仪校准 |
| pitch/roll偏移 | 机架校准问题 | 重新校准加速度计 |

---

## 相关技能

- `px4-manual-mode`: 纯手动模式
- `px4-altitude-mode`: 高度保持模式
- `px4-position-mode`: 位置保持模式
- `px4-mc-tuning`: 多旋翼参数调整
