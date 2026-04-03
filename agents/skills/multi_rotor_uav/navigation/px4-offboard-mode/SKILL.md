---
name: px4-offboard-mode
description: PX4 Offboard 模式技能 - 外部计算机通过 ROS2/MicroXRCE-DDS 或 MAVLink 实现实时轨迹、速度和姿态控制
argument-hint: Offboard OR 外部控制 OR ROS2控制 OR 自主导航
user-invocable: true
---

# PX4 Offboard 模式技能

> 由外部计算机通过 MAVLink 发送位置/速度/姿态目标，实现完全自主控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现自主避障导航
- 运行高级路径规划算法
- 集成视觉里程计/VIO
- 多机编队控制
- 实时轨迹跟踪

---

## 模式特性

### 控制原理

```yaml
offboard_mode:
  source: external_computer (ROS2/MicroXRCE-DDS or MAVLink)
  command_type: position / velocity / attitude / thrust
  update_rate: 10 Hz (minimum)
  
  safety:
    timeout: 1.0s  # 无命令超时应退出
    must_armed: true
    must_position_lock: true
```

### 命令类型

| 类型 | 说明 | 典型应用 |
|------|------|----------|
| `SET_POSITION` | 位置目标 (x,y,z,yaw) | 航点飞行 |
| `SET_VELOCITY` | 速度目标 (vx,vy,vz,v_yaw) | 避障 |
| `SET_ATTITUDE` | 姿态目标 (q,thrust) | 特技飞行 |
| `SET_THROTTLE` | 推力目标 | 高级控制 |

### 与任务模式对比

| 特性 | 任务模式 | Offboard 模式 |
|------|----------|---------------|
| 控制来源 | 预设航线 | 实时命令 |
| 路径规划 | 离线规划 | 在线规划 |
| 避障 | 无 | 可集成 |
| 灵活性 | 低 | 高 |
| 可靠性 | 高 | 依赖链路 |

---

## ROS2 接口

### MicroXRCE-DDS (推荐)

```yaml
# 订阅话题
/fmu/out/vehicle_odometry: 车辆里程计
  - position: [x, y, z] (m)
  - velocity: [vx, vy, vz] (m/s)
  - q: quaternion [w, x, y, z]
/fmu/out/vehicle_status: 飞行器状态
/fmu/out/timesync_status: 时间同步状态

# 发布话题
/fmu/in/vehicle_command: 车辆命令
  - command: SET_POSITION / SET_VELOCITY / SET_ATTITUDE
  - param1-7: 根据命令类型不同
  - target_system: 1
  - target_component: 1
  
# 时间同步
/timesync/control_in: 时间同步输入
```

### MAVROS (备选)

```yaml
# 订阅话题
/mavros/state: 连接状态
/mavros/local_position/pose: 位置
/mavros/setpoint_position/local: 位置设定点
/mavros/setpoint_velocity/cmd_vel: 速度设定点
/mavros/setpoint_attitude/attitude: 姿态设定点

# 发布话题
/mavros/cmd/command: 命令
```

---

## 开发技能

### Offboard 连接技能

```yaml
name: offboard_connection_skill
description: Offboard 通信连接建立
type: setup

interface:
  inputs:
    - topic: /fmu/out/vehicle_status
    - topic: /fmu/out/vehicle_odometry
  outputs:
    - topic: /fmu/in/vehicle_command
    
params:
  connection_type: {type: enum, values: [udp, serial, wifi]}
  fcu_url: {type: string, default: "udp://:14540@"}
  protocol: {type: string, default: "v2.0"}
  
preconditions:
  - timesync_established
  - vehicle_odometry_received
  - local_position_estimate_valid
  
connection_sequence:
  1. Establish UDP/Serial connection
  2. Wait for timesync
  3. Verify position estimate
  4. Arm vehicle
  5. Start setpoint stream
  6. Request mode switch to OFFBOARD
```

### 位置控制技能

```yaml
name: offboard_position_control_skill
description: Offboard 位置控制
type: control

interface:
  inputs:
    - topic: /fmu/out/vehicle_odometry
  outputs:
    - topic: /fmu/in/vehicle_command
      
params:
  setpoint_rate: {type: int, default: 20}  # Hz
  timeout: {type: float, default: 1.0}    # s
  
command_format:
  type: SET_POSITION
  frame: MAV_FRAME_LOCAL_NED
  position: [x, y, z]  # m
  yaw: {type: float, unit: rad}
  
control_loop:
  - step: 1
    action: stream_position_setpoint
    rate: 20Hz
  - step: 2
    action: monitor_timeout
    threshold: 1.0s
  - step: 3
    action: emergency_rtl on_timeout
```

### 速度控制技能

```yaml
name: offboard_velocity_control_skill
description: Offboard 速度控制
type: control

params:
  setpoint_rate: {type: int, default: 20}  # Hz
  timeout: {type: float, default: 1.0}    # s
  
command_format:
  type: SET_VELOCITY
  frame: MAV_FRAME_BODY_NED
  velocity: [vx, vy, vz]  # m/s
  angular_velocity: [yaw_rate]  # rad/s
  
velocity_limits:
  vx_max: 5.0  # m/s
  vy_max: 5.0  # m/s
  vz_max: 3.0  # m/s
  yaw_rate_max: 90.0  # deg/s
```

### 轨迹控制技能

```yaml
name: offboard_trajectory_control_skill
description: Offboard 轨迹跟踪控制
type: control

interface:
  inputs:
    - topic: /trajectory (Trajectory)
    - topic: /fmu/out/vehicle_odometry
  outputs:
    - topic: /fmu/in/vehicle_command
    
params:
  trajectory_type: {type: enum, values: [ Jerk, Snap, Polynomial ]}
  execution_time: auto  # 实时跟踪
  
trajectory_message:
  type: trajectory_msgs/Trajectory
  points:
    - position: [x, y, z]
      velocity: [vx, vy, vz]
      time_from_start: t
```

---

## 配置参数

### 关键参数

| 参数 | 说明 | 典型值 |
|------|------|--------|
| `COM_OF_LOSS_T` | 失控超时 | 1.0 s |
| `COM_RC_LOSS_T` | RC 失控超时 | 1.0 s |
| `MPC_XY_VEL_MAX` | 最大水平速度 | 5.0 m/s |
| `MPC_Z_VEL_MAX_UP` | 最大上升速度 | 3.0 m/s |
| `MPC_Z_VEL_MAX_DN` | 最大下降速度 | 1.5 m/s |
| `MPC_XY_MAN_EXPO` | 手动Expo | 0.0 |

### 安全设置

```yaml
safety:
  offboard_timeout: 1.0  # s
  RC_loss_action: RTL
  datalink_loss_action: RTL
  battery_low_action: RTL
  
failsafe:
  enable_offboard_failsafe: true
  min_setpoint_rate: 10  # Hz
```

---

## 测试与验证

### 连接测试流程

```bash
# 1. 启动 MicroXRCE-DDS Bridge
ros2 launch micro_ros_ddsx agent.launch.py

# 或启动 MAVROS
ros2 launch mavros px4.launch fcu_url:="udp://:14540@"

# 2. 检查连接状态
ros2 topic echo /fmu/out/vehicle_status

# 3. 发送测试 setpoint
ros2 topic pub /fmu/in/vehicle_command <msg> -r 20

# 4. 切换到 Offboard 模式
ros2 service call /mavros/set_mode std_srvs/srv/Trigger "{custom_mode: 'OFFBOARD'}"
```

### 典型测试序列

```yaml
test_sequence:
  1. arm_vehicle: 解锁飞控
  2. takeoff_to_3m: 起飞到3米
  3. switch_to_offboard: 切换到Offboard模式
  4. send_position_setpoints: 发送位置目标
  5. verify_tracking: 验证轨迹跟踪
  6. switch_back_to_position: 切换回位置模式
  7. land: 降落
```

---

## 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 无法进入Offboard | 未满足前置条件 | 检查位置估计、解锁状态 |
| 位置跳变 | setpoint间隔过大 | 提高发送频率到20Hz |
| 退出Offboard | 超时或RC失控 | 检查COM_OF_LOSS_T参数 |
| 轨迹不平滑 | 控制频率波动 | 使用定时器保证稳定频率 |
| 偏航异常 | yaw帧参考错误 | 确认使用NED帧 |

---

## 相关技能

- `px4-position-mode`: 位置模式（Offboard的替代）
- `px4-mission-mode`: 任务模式（离线规划）
- `px4-ros2`: ROS2 集成基础
- `px4-vision-nav`: 视觉导航集成
- `px4-mc-tuning`: 参数调优
