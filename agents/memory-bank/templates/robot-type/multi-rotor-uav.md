# Multi-Rotor UAV Context

## 飞行模式
| 模式 | 说明 | 控制源 |
|------|------|--------|
| Manual | 遥控器直接控制 | RC |
| Altitude | 保持高度，水平手动 | RC |
| Stabilized | 角度控制 | RC |
| Position | GPS/视觉定位自主飞行 | ROS2 / RC |
| Offboard | **ROS2 控制**（最高权限）| MAVROS |

## 关键依赖
- `mavros` — PX4 ↔ ROS2 桥接
- `mavros_msgs` — MAVLink 消息（State, Setpoint, Trajectory）
- `geometry_msgs/TwistStamped` — 速度 setpoint
- `sensor_msgs/NavSatFix` — GPS 数据

## 核心 Topic（MAVROS 前缀 `/mavros`）
| Topic | 类型 | 用途 |
|-------|------|------|
| `/mavros/state` | `mavros_msgs/State` | 飞控状态（连接、模式） |
| `/mavros/setpoint_position/local` | `PoseStamped` | 位置 setpoint |
| `/mavros/setpoint_velocity/cmd_vel_unset` | `Twist` | 速度 setpoint |
| `/mavros/local_position/pose` | `PoseStamped` | 本地位置（ENU） |
| `/mavros/battery/battery_state` | `BatteryState` | 电池状态 |
| `/mavros/home_position/home` | `HomePosition` | Home 点 |

## 安全规则（强制）
1. **Offboard 模式前必须先发 setpoint**（频率 > 1Hz）
2. **必须设置地理围栏**（mavros/geofence 或 PX4 参数）
3. **紧急降落**：`ros2 service call /mavros/cmd/land mavros_msgs/srv/CommandHome`
4. **看门狗超时**：PX4 参数 `COM_OF_LOSS_T`（默认 5s）

## Offboard 启动流程
```bash
# 1. 启动 MAVROS
ros2 launch mavros offboard.launch.py

# 2. 等待 FCU 连接
ros2 topic echo /mavros/state  # 确认 "connected: True"

# 3. 解锁（先发 setpoint，再切 Offboard）
ros2 service call /mavros/cmd/arming mavros_msgs/srv/CommandBool "{value: True}"

# 4. 切 Offboard
ros2 service call /mavros/set_mode mavros_msgs/srv/SetMode "{custom_mode: 'offboard'}"
```

## 生成器选择
- 仿真：`ros2-simulator-generator.sh drone`
- 包生成：`ros2-package-generator.sh <pkg> cpp mavros,mavros_msgs`
- 导航：`ros2-nav2-node-generator.sh`（室内/视觉）
- 行为树：`ros2-behavior-tree-generator.sh exploration|patrol`

## PX4 参数（关键）
| 参数 | 说明 | 默认值 |
|------|------|--------|
| `NAV_DSP_ARR` | 盘旋半径 | 5m |
| `COM_OF_LOSS_T` | 丢失控制超时 | 5s |
| `MPC_XY_VEL_MAX` | 最大水平速度 | 3m/s |
| `MPC_Z_VEL_MAX_UP` | 最大上升速度 | 3m/s |
