---
name: px4-manual-mode
description: PX4 手动模式技能 - 遥控器直接控制，电机输出无稳定辅助，用于调试和极限飞行
argument-hint: 手动模式 OR Manual Mode OR 遥控器控制 OR PX4手动
user-invocable: true
---

# PX4 手动模式技能

> 遥控器直接控制电机输出，飞控不进行任何稳定辅助

---

## 何时使用

当需要以下帮助时使用此技能：
- 调试电机和ESC响应
- 执行极限机动飞行
- 测试飞行器物理特性
- 飞手训练高级动作

---

## 模式特性

### 控制原理

```yaml
manual_mode:
  roll: RC_roll_input → motor_mix → 直接电机输出
  pitch: RC_pitch_input → motor_mix → 直接电机输出
  yaw: RC_yaw_input → motor_mix → 直接电机输出
  throttle: RC_throttle_input → 直接电机输出
  
  stabilization: NONE  # 无任何姿态稳定
  altitude_hold: NONE  # 无高度保持
  position_hold: NONE  # 无位置保持
```

### 使用场景

| 场景 | 说明 |
|------|------|
| ESC校准 | 直接发送全油门测试响应 |
| 电机测试 | 逐个验证电机转向和响应 |
| 极限机动 | 手动滚转、俯仰、偏航 |
| 飞手训练 | 练习手动控制技巧 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/rc_channels: RC输入通道
/fmu/out/actuator_outputs: 电机输出
/fmu/out/vehicle_status: 飞行器状态

# 发布话题
/fmu/in/vehicle_command: 发送命令
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/rc/in: 遥控器输入
/mavros/actuator_control: 电机控制输出

# 发布话题
/mavros/cmd/command: 发送命令
```

---

## 开发技能

### 电机测试技能

```yaml
name: motor_test_skill
description: 电机单独测试
type: actuator_test

interface:
  inputs: []
  outputs:
    - topic: /fmu/in/vehicle_command
      command: VEHICLE_CMD_DO_MOTOR_TEST
      
params:
  motor_number: {type: int, range: [1, 8]}
  throttle_value: {type: float, range: [0.0, 1.0]}
  test_duration: {type: float, default: 2.0}  # seconds
  
test_sequence:
  - step: 1
    motor: 1
    throttle: 0.1
  - step: 2
    motor: 2
    throttle: 0.1
  # ... 依次测试所有电机
```

### RC 映射技能

```yaml
name: rc_mapping_skill
description: 遥控器通道配置
type: configuration

params:
  mapping:
    roll: RC_MAP_ROLL
    pitch: RC_MAP_PITCH
    throttle: RC_MAP_THROTTLE
    yaw: RC_MAP_YAW
    mode_switch: RC_MAP_MODE_SWITCH
    
  limits:
    roll_max: 30.0    # degrees
    pitch_max: 30.0   # degrees
    throttle_min: 0.0 # 0-1
    throttle_max: 1.0
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `RC_MAP_*` | 通道功能映射 | 根据遥控器配置 |
| `RC_MIN_*` | 通道最小值 | 1000 |
| `RC_MAX_*` | 通道最大值 | 2000 |
| `RC_TRIM_*` | 通道中值 | 1500 |

### 安全限制

```yaml
safety:
  # 油门下限保护
  throttle_min: 0.05  # 最低油门限制
  
  # 电机输出限制
  motor_output_min: 0.0
  motor_output_max: 1.0
  
  # 紧急停止
  emergency_stop: arming_switch 或 特定RC组合
```

---

## 测试与验证

### 地面测试

```bash
# 1. 安全检查
检查螺旋桨已移除
检查电池未连接
确认遥控器信号正常

# 2. 参数配置
# QGC → Parameters
RC_MAP_ROLL = Channel 1
RC_MAP_PITCH = Channel 2
RC_MAP_THROTTLE = Channel 3
RC_MAP_YAW = Channel 4

# 3. 地面供电测试
# 遥控器解锁 → 轻推油门 → 观察电机响应
```

### 飞行测试

```yaml
test_sequence:
  1. 低油门悬停测试 (< 30%)
  2. 滚转响应测试
  3. 俯仰响应测试
  4. 偏航响应测试
  5. 全范围机动测试
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 电机不转 | 解锁未激活 | 推动油门前先解锁 |
| 电机响应迟钝 | ESC校准失败 | 重新校准ESC |
| 震动过大 | 电机平衡差 | 检查螺旋桨平衡 |
| 一个电机不转 | 接线或电调故障 | 检查连接和电调 |

---

## 相关技能

- `px4-stabilized-mode`: 姿态稳定模式（带姿态保持的手动控制）
- `px4-actuator-output`: 电机输出配置
- `px4-rc-mapping`: 遥控器配置
