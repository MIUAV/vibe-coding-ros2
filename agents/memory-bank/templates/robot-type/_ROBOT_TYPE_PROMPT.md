# 🔀 Robot-Type Memory — 自动切换模板

> 当 AI Agent 识别到机器人类型时，自动加载对应模板。
> 将本文件复制到 `agents/memory-bank/active-context.md` 启用。

---

## 加载规则

根据用户需求中的机器人类型，启用对应的 memory-bank：

| 机器人 | 加载文件 |
|--------|---------|
| 轮式移动机器人 | `wheeled-vehicle.md` |
| 无人机 / UAV | `multi-rotor-uav.md` |
| 四足机器人 | `quadruped.md` |
| 机械臂 /  manipulator | `manipulator.md` |
| 人形机器人 | `humanoid.md` |
| 水下机器人 / AUV | `underwater.md` |
| 多机器人系统 | `multi-robot.md` |

---

## wheeled-vehicle.md

```markdown
# Wheeled Vehicle Context

## 运动模型
- 差速驱动（Diff Drive）：左右轮速差转向
- 阿克曼（Ackermann）：汽车模型，前轮转向
- 全向轮（Omni）：麦轮/瑞典轮，任意方向移动

## 关键依赖
- `nav2_msgs` — 导航消息
- `nav2_util` — 导航工具（LifecycleNode）
- `geometry_msgs/Twist` — 速度命令 `/cmd_vel`
- `nav_msgs/Odometry` — 里程计 `/odom`
- `sensor_msgs/Imu` — IMU 数据

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/cmd_vel` | `geometry_msgs/Twist` | 速度控制 |
| `/odom` | `nav_msgs/Odometry` | 里程计 |
| `/imu/data` | `sensor_msgs/Imu` | IMU |
| `/scan` | `sensor_msgs/LaserScan` | 激光雷达 |
| `/camera/image_raw` | `sensor_msgs/Image` | 相机 |

## 标准 Launch
```bash
ros2 launch nav2_bringup bringup_launch.py slam:=False map:=xxx.yaml
```

## 常用参数
```yaml
min_vel_x: 0.0
max_vel_x: 2.0
min_vel_theta: -3.14
max_vel_theta: 3.14
```

## 生成器选择
- `ros2-package-generator.sh` — 导航包
- `ros2-nav2-node-generator.sh` — lifecycle / costmap / controller
- `ros2-param-generator.sh` — ackermann / diff
- `ros2-simulator-generator.sh` — wheeled
```

---

## multi-rotor-uav.md

```markdown
# Multi-Rotor UAV Context

## 飞行模式
- 手动模式（Manual）— 遥控器直接控制
- 定高模式（Altitude）— 保持高度，水平手动
- 增稳模式（Stabilized）— 角度控制
- 位置模式（Position）— GPS/视觉定位自主飞行
- Offboard 模式 — ROS2 控制（最高权限）

## 关键依赖
- `mavros` — PX4 通信桥接
- `mavros_msgs` — MAVLink 消息（State, Setpoint, Trajectory）
- `geometry_msgs/Twist` — 速度 setpoint `/mavros/setpoint_velocity/cmd_vel_unset`
- `sensor_msgs/NavSatFix` — GPS 数据

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/mavros/state` | `mavros_msgs/State` | 飞控状态 |
| `/mavros/setpoint_position/local` | `geometry_msgs/PoseStamped` | 位置 setpoint |
| `/mavros/setpoint_velocity/cmd_vel_unset` | `geometry_msgs/Twist` | 速度 setpoint |
| `/mavros/local_position/pose` | `geometry_msgs/PoseStamped` | 本地位置 |
| `/mavros/battery/battery_state` | `sensor_msgs/BatteryState` | 电池 |

## 安全规则
- Offboard 模式前必须先发 setpoint（1Hz以上）
- 飞行区域必须设置地理围栏（mavros/geofence）
- 紧急降落：`mavros/cmd/land`

## 生成器选择
- `ros2-simulator-generator.sh` — drone
- `ros2-package-generator.sh` — mavros 相关
- `ros2-nav2-node-generator.sh` — 室内/视觉导航
- `ros2-behavior-tree-generator.sh` — exploration / patrol
```

---

## quadruped.md

```markdown
# Quadruped Robot Context

## 步态类型
- 静态行走（Static Walk）— 任意时刻三角支撑
- 动态行走（Dynamic Walk）— 对角小跑（Trot）/ 跳跃（Pace）
- 对角小跑（Trot）— 对角腿同时着地，最常用
- 踱步（Pace）/ 跳跃（Pound）

## 关键依赖
- `unitree_msgs` / `legged_msgs` — 腿式机器人专用消息
- `geometry_msgs/Twist` — 期望速度 `/cmd_vel`
- `sensor_msgs/JointState` — 关节状态

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/machine_state` | — | 机器人整体状态 |
| `/LowCmd` | — | 低层控制命令（20Hz+） |
| `/LowState` | — | 低层状态反馈 |
| `/cmd_vel` | `geometry_msgs/Twist` | 期望速度 |

## 生成器选择
- `ros2-control-node-generator.sh` — hardware_interface / joint_trajectory
- `ros2-simulator-generator.sh` — quadruped
- `ros2-param-generator.sh` — quadruped
```

---

## manipulator.md

```markdown
# Manipulator Context

## 运动规划
- 关节空间规划（Joint Space）— 直接指定各关节角度
- 笛卡尔空间规划（Cartesian Space）— 末端执行器轨迹
- 抓取规划（Grasp Planning）— 目标物体位姿 → 抓取姿态

## 关键依赖
- `moveit_ros_planning_interface` — MoveIt2 C++ API
- `moveit_msgs/Grasp` — 抓取描述
- `trajectory_msgs/JointTrajectory` — 关节轨迹
- `geometry_msgs/PoseStamped` — 末端执行器目标

## 核心 Topic / Service
| 名称 | 类型 | 用途 |
|------|------|------|
| `/plan` | `moveit_msgs/MotionPlanRequest` | 运动规划请求 |
| `/execute` | `action_msgs/ExecuteTrajectory` | 执行轨迹 |
| `/pick` | `moveit_msgs/Pickup` | 抓取动作 |

## URDF/XACRO 关键点
- `<group name="arm">` — 臂运动学链
- `<group name="gripper">` — 夹爪
- `<xacro:robotiq_85_gripper>` — 夹爪宏

## 生成器选择
- `ros2-package-generator.sh` — moveit 相关
- `ros2-moveit-generator.sh` — move_group / cartesian / pick_place
- `ros2-simulator-generator.sh` — manipulator
- `ros2-camera-calibration-generator.sh` — hand_eye
```

---

## humanoid.md

```markdown
# Humanoid Robot Context

## 关键挑战
- 重心（CoM）实时估计 — 动态平衡
- 双足行走（Walking）— ZMP / Capture Point
- 全身运动学（WBC）— 末端 + 关节耦合控制

## 关键依赖
- `whole_body_msgs` — 全身运动消息
- `geometry_msgs/WrenchStamped` — 力传感
- `sensor_msgs/Imu` — 惯性测量

## 生成器选择
- `ros2-moveit-generator.sh` — mobile_manipulator（移动+臂）
- `ros2-control-node-generator.sh` — force_position_hybrid
- `ros2-param-generator.sh` — humanoid
```

---

## underwater.md

```markdown
# Underwater Robot (AUV/ROV) Context

## 特殊挑战
- 水声通信（Acoustic Modem）— 低带宽、高延迟
- 静水压力（Depth）— 密封耐压
- 水下定位 — USBL / DVL / 视觉里程计融合

## 关键依赖
- `sensor_msgs/FluidPressure` — 深度计
- `sensor_msgs/Image` — 光学相机（水下灯）
- `gps_common/NavSatFix` — GPS（仅水面）
- `geographic_msgs/GeoPoseStamped` — 地理坐标

## 生成器选择
- `ros2-simulator-generator.sh` — underwater（水密度、阻力模型）
- `ros2-slam-generator.sh` — visual / lidar_visual
- `ros2-sensor-fusion-generator.sh` — kalman_filtering（深度+姿态融合）
```

---

## multi-robot.md

```markdown
# Multi-Robot System Context

## 协调模式
- 编队控制（Formation）— 保持几何形状
- 任务分配（Task Allocation）— 拍卖/集中式
- 碰撞避免（Collision Avoidance）— ORCA / VO

## 关键依赖
- `formation_control_msgs` — 编队消息
- `multi_robot_interfaces` — 多机通信
- `nav2_util` — 多机 Nav2

## 生成器选择
- `ros2-multi-agent-generator.sh` — formation / auction / BOIDs / ORCA
- `ros2-nav2-node-generator.sh` — multi-robot
- `ros2-behavior-tree-generator.sh` — swarm
```
