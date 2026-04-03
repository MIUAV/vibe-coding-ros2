---
name: px4-rtl-mode
description: PX4 RTL (Return to Launch) 返航模式技能 - 自动返回起飞点并降落，保障飞行安全
argument-hint: "RTL" / "返航" / "Return to Launch" / "一键返航"
user-invocable: true
---

# PX4 RTL 返航模式技能

> 自动返回起飞点并降落，用于失控保护、电量不足等紧急情况

---

## 何时使用

当需要以下帮助时使用此技能：
- 设置失控保护触发 RTL
- 低电量自动返航
- 遥测信号丢失返航
- 一键手动返航
- 任务失败安全返航

---

## 模式特性

### 控制原理

```yaml
rtl_mode:
  phases:
    1. climb: 爬升到安全高度 (MIS_RTL_ALT)
    2. cruise: 直线飞向家点
    3. descend: 下降到进场高度
    4. landing: 执行着陆
    
  home_position:
    source: first arm position / custom set
    storage: 自动保存
```

### 返航阶段

| 阶段 | 说明 | 典型参数 |
|------|------|----------|
| 爬升 | 垂直爬升到RTL高度 | `MIS_RTL_ALT` = 15m |
| 巡航 | 直线飞向家点 | 最大速度 `MPC_XY_CRUISE` |
| 进场 | 下降到进场高度 | 高度 `MIS_LTRMIN_ALT` |
| 着陆 | 执行自动着陆 | 着陆速度 `MPC_LAND_SPEED` |

### 与任务模式对比

| 特性 | RTL | 任务返航 |
|------|------|----------|
| 目标 | 起飞点 | 任务规划点 |
| 路径 | 直线 | 可设置 |
| 动作 | 固定 | 可配置 |
| 触发 | 手动/自动 | 任务内 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/home_position: 家点位置
  - lat, lon, alt: 经纬度高度
  - q: 偏航角
/fmu/out/vehicle_global_position: 全球位置
/fmu/out/vehicle_status: 飞行器状态
  - arming_state
  - flight_mode
  - failure_status
  
# 发布话题
/fmu/in/vehicle_command: 发送命令
  - command: DO_SET_MODE
  - mode: RTL
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/home_position/home: 家点
/mavros/global_position/global: GPS位置

# 服务
/mavros/cmd/command: 发送命令
  - command: MAV_CMD_NAV_RTL
```

---

## 开发技能

### RTL 触发技能

```yaml
name: rtl_trigger_skill
description: RTL 触发条件配置
type: safety

params:
  trigger_conditions:
    - condition: low_battery
      threshold: 20%  # 电池电量低于20%
      action: RTL
      
    - condition: signal_loss
      threshold: 1.0s  # 信号丢失超过1秒
      action: RTL
      
    - condition: geofence_breach
      threshold: fence_radius + 5m
      action: RTL
      
    - condition: manual_trigger
      trigger: RC switch 或 遥测指令
      action: RTL
      
triggers:
  low_battery:
    type: battery_remaining
    value: 0.2
  datalink_loss:
    type: connection_timeout
    timeout: 1.0
  geofence:
    type: distance_from_home
    max_distance: 500
```

### RTL 自定义技能

```yaml
name: rtl_custom_skill
description: 自定义 RTL 行为
type: mission

params:
  rtl_path_type: {type: enum, values: [straight_line, mission_land, hill_top]}
  rtl_altitude: {type: float, default: 15.0}  # m
  landing_type: {type: enum, values: [auto, precision,螺旋]}
  
  # 直线返航
  straight_line:
    use_current_heading: false
    heading_towards_home: true
    
  # 任务降落
  mission_land:
    use_predefined_landing: true
    landing_pattern: custom_mission
    
  # 山顶降落
  hill_top:
    search_highest: true
    min_altitude: 10.0
```

### 返航决策技能

```yaml
name: rtl_decision_skill
description: 返航决策逻辑
type: decision

interface:
  inputs:
    - topic: /fmu/out/battery_status
    - topic: /fmu/out/vehicle_status
    - topic: /fmu/out/home_position
    - topic: /fmu/out/vehicle_global_position
  outputs:
    - topic: /fmu/in/vehicle_command
      
params:
  decision_logic:
    battery_check:
      if battery < 20%: trigger_rtl
      if battery < 10%: trigger_immediate_land
      
    distance_check:
      if distance_home > max_flight_distance: trigger_rtl
      if estimated_return_battery < 10%: trigger_rtl
      
    failure_check:
      if motor_failure: trigger_immediate_land
      if gps_failure: trigger_attitude_mode
      
preconditions:
  - home_position_set
  - gps_available
  - sufficient_battery_for_rtl
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `MIS_RTL_ALT` | RTL 返航高度 | 15.0 m |
| `MPC_XY_CRUISE` | 返航巡航速度 | 5.0 m/s |
| `MPC_Z_VEL_MAX_UP` | 爬升速度 | 3.0 m/s |
| `MPC_LAND_ALT` | 进场起始高度 | 5.0 m |
| `MPC_LAND_SPEED` | 着陆速度 | 0.5 m/s |
| `RTL_RETURN_ALT` | 返回高度 | same as MIS_RTL_ALT |
| `RTL_DESCEND_ALT` | 下降开始高度 | 5.0 m |

### RTL 类型选择

```yaml
rtl_type:
  # 直接返回降落
  0: RTL Land (默认)
  
  # 在当前位置上方悬停
  1: RTL Hover (等待指令)
  
  # 执行任务降落
  2: RTL Mission Landing (如果有任务)
```

---

## 测试与验证

### RTL 测试流程

```bash
# 1. 安全检查
确认飞行区域开阔无障碍
确认家点已正确设置
准备手动接管遥控器

# 2. 功能测试
起飞到 10m → 悬停
手动触发 RTL → 观察返航行为
确认降落位置与家点偏差

# 3. 保护触发测试
低电量保护: 使用低电量模拟
失控保护: 移动到信号差区域
```

### 测试检查单

```yaml
rtl_tests:
  - home_accuracy: 返航点与实际家点偏差 < 5m
  - altitude_maintenance: 爬升/下降高度准确
  - landing_precision: 着陆位置精度 < 3m
  - obstacle_avoidance: 避开障碍物
  
  # 触发测试
  - battery_rtl_trigger: 低电量正确触发
  - signal_loss_rtl: 信号丢失正确触发
  - geofence_rtl: 围栏触发正确
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| RTL 不执行 | 家点未设置 | 解锁一次设置家点 |
| 返航高度过高 | MIS_RTL_ALT 设置过大 | 减小参数值 |
| 降落位置不准 | GPS 精度问题 | 使用 RTK 提高精度 |
| RTL 后悬停不停 | RTL_TYPE 设置错误 | 检查参数或切换降落模式 |
| 无法触发 RTL | 失控保护未配置 | 检查 Failsafe 参数 |

---

## 相关技能

- `px4-position-mode`: 位置模式（返航后进入）
- `px4-mission-mode`: 任务模式（可包含 RTL）
- `px4-failsafe`: 失效保护配置
- `px4-landing`: 着陆技能
