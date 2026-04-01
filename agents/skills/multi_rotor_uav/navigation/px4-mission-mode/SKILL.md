---
name: px4-mission-mode
description: PX4 任务模式技能 - 执行预设航线任务，支持航点、航点动作、条件跳转等
argument-hint: "任务模式" / "Mission Mode" / "航线规划" / "自主飞行"
user-invocable: true
---

# PX4 任务模式技能

> 自动执行预设航线任务，支持复杂航点动作和条件逻辑

---

## 何时使用

当需要以下帮助时使用此技能：
- 规划区域巡检航线
- 执行测绘任务
- 自动物资投放
- 定时拍照/录像任务
- 编队飞行任务

---

## 模式特性

### 控制原理

```yaml
mission_mode:
  execution: 自动按顺序执行任务项
  navigation: 全局路径规划 → 航点跟踪
  control: 位置模式内嵌任务控制器
  
  mission_items:
    - waypoint: 飞向目标点
    - takeoff: 起飞到指定高度
    - land: 降落
    - rtl: 返回起飞点
    - loiter: 盘旋
    - do_jump: 条件跳转
    - do_set_mode: 切换模式
    - camera_trigger: 拍照触发
```

### 任务结构

```yaml
mission:
  start_item: 1
  current_item: 自动跟踪
  total_items: N
  
  navigation:
    acceptance_radius: 3.0  # m, 到达判定
    time_inside: 0.0       # s, 停留时间
    yaw_mode: next_waypoint # 偏航模式
    
  termination:
    when: last_item / rtl_land_hybrid
    land_at_home: true
```

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/mission_result: 任务执行结果
  - current_seq: 当前航点序号
  - item_changed: 航点变更标志
  - mission_type: normal/rtl/flight_training
/fmu/out/mission_state: 任务状态
/fmu/out/vehicle_local_position: 当前位置

# 发布话题
/fmu/in/mission_upload: 上传任务
/fmu/in/mission_clear: 清除任务
/fmu/in/mission_set_current: 设置当前航点
/fmu/in/vehicle_command: 发送命令
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/mission/current: 当前航点
/mavros/mission/reached: 已到达航点
/mavros/mission/waypoints: 任务航点列表

# 服务
/mavros/mission/push: 上传任务
/mavros/mission/pull: 下载任务
/mavros/mission/set_current: 设置当前航点
```

---

## 开发技能

### 任务规划技能

```yaml
name: mission_planning_skill
description: 任务航线规划技能
type: planning

interface:
  inputs:
    - area_boundary: PolygonStamped  # 任务区域
    - survey_params: SurveyParams    # 巡检参数
  outputs:
    - /fmu/in/mission_upload: 上传任务
      
params:
  # 基本参数
  survey_altitude: {type: float, default: 50.0}  # m
  survey_speed: {type: float, default: 5.0}      # m/s
  acceptance_radius: {type: float, default: 3.0} # m
  
  # 覆盖模式
  pattern: {type: enum, values: [lawn_mower, spiral, waypoint]}
  overlap: {type: float, default: 0.2}         # 20%
  
  # 航点动作
  gimbal_pitch: {type: float, default: -45.0}   # degrees
  photo_interval: {type: float, default: 2.0}   # s

generation:
  lawn_mower:
    direction: along_longest_edge
    turn_type: splined
  spiral:
    start: center
    outward: true
```

### 航点动作技能

```yaml
name: waypoint_action_skill
description: 航点动作配置技能
type: mission_item

supported_actions:
  - name: NAV_WAYPOINT
    params: [lat, lon, alt, acceptance, time_inside, yaw, yaw_valid]
    
  - name: NAV_TAKEOFF
    params: [min_pitch, takeoff_alt]
    
  - name: NAV_LAND
    params: [lat, lon, alt, land_precision]
    
  - name: NAV_RTL
    params: [rtl_altitude, land_mode]
    
  - name: DO_JUMP
    params: [target_seq, repeat_count]
    
  - name: DO_SET_MODE
    params: [mode_id, custom_mode]
    
  - name: DO_CHANGE_SPEED
    params: [speed_type, speed_value]
    
  - name: DO_SET_CAMERA_TRIGGER
    params: [trigger_enable, trigger_interval]
    
  - name: DO_MOUNT_CONTROL
    params: [pitch, roll, yaw, altitude_mode]
```

### 条件跳转技能

```yaml
name: conditional_jump_skill
description: 任务条件跳转技能
type: mission_control

conditions:
  - type: time
    operator: greater_than
    value: 300  # 5分钟后
    
  - type: battery_remaining
    operator: less_than
    value: 0.2  # 20%
    
  - type: hit_count
    target_seq: 5
    operator: equals
    value: 3  # 跳过航点5共3次后继续
    
  - type: distance_to_home
    operator: greater_than
    value: 1000  # m
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `NAV_ACC_RAD` | 航点接受半径 | 3.0 m |
| `NAV_LOITER_RAD` | 盘旋半径 | 50 m |
| `MPC_XY_CRUISE` | 任务飞行速度 | 5.0 m/s |
| `MPC_Z_CRUISE` | 垂直速度 | 3.0 m/s |
| `MIS_TAKEOFF_ALT` | 默认起飞高度 | 10.0 m |
| `MIS_RTL_ALT` | RTL 默认高度 | 15.0 m |

### 任务失效保护

```yaml
failsafe:
  mission_timeout: 0  # 0=disabled
  RTL_on_loss: disabled
  Land_on_loss: disabled
  
fence:
  mission_fence: enabled  # 允许任务地理围栏
  floor_alt: 0.0
```

---

## 测试与验证

### 任务创建流程

```bash
# 1. QGC 任务规划
QGC → Plan View → 添加航点 → 设置动作 → 保存

# 2. 上传到飞控
QGC → Upload 按钮

# 3. 验证任务
QGC → Review → 检查航点顺序和动作

# 4. 执行任务
确认GPS锁定 → 切换到任务模式 → 自动执行
```

### 飞行测试检查单

```yaml
preflight:
  1. 确认 GPS 锁定 > 8 颗星
  2. 确认任务已上传
  3. 检查起始航点位置正确
  4. 确认安全区域无障碍
  5. 设置失控保护为 RTL
  
flight_tests:
  - waypoint_accuracy: 测试每个航点到达精度
  - action_timing: 验证拍照/动作触发时机
  - condition_trigger: 测试条件跳转
  - RTL_trigger: 测试低电量RTL
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 航点跳过 | 接受半径太小 | 增加 NAV_ACC_RAD |
| 任务不执行 | 未切换到任务模式 | 确认飞行模式 |
| 相机未触发 | 触发间隔太小 | 增加触发间隔 |
| 高度不对 | 高度参考错误 | 检查 MSL/AGL 设置 |
| 盘旋不停 | Loiter 未设置退出条件 | 检查盘旋圈数/时间 |

---

## 相关技能

- `px4-position-mode`: 位置模式（任务内嵌控制）
- `px4-rtl-mode`: RTL返航模式
- `px4-offboard-mode`: Offboard 模式（主动控制）
- `px4-mission-mode`: 任务规划和执行
