# Humanoid Robot Context

## 核心技术挑战
- **重心（CoM）估计**：实时质心位置，决定平衡
- **ZMP / Capture Point**：零力矩点 / 捕获点理论
- **全身运动学（WBC）**：末端 + 关节耦合控制
- **双足行走**：摆动相 / 支撑相切换

## 关键依赖
- `whole_body_msgs` — 全身运动消息
- `geometry_msgs/WrenchStamped` — 力传感数据
- `sensor_msgs/Imu` — 髋部/足部 IMU
- `sensor_msgs/JointState` — 全身关节角度

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/whole_body_controller/command` | `JointTrajectory` | 关节轨迹命令 |
| `/contacts/l_foot` | `WrenchStamped` | 左脚力传感器 |
| `/contacts/r_foot` | `WrenchStamped` | 右脚力传感器 |
| `/imu/pelvis` | `Imu` | 骨盆 IMU（核心惯性） |

## URDF 关键点
- 典型 DOF：髋3 + 膝1 + 踝2 × 2 + 臂 × 2 + 头2 ≈ 30+DOF
- 运动学链：pelvis → spine → hip → knee → ankle / shoulder → elbow → wrist

## 生成器选择
- MoveIt：`ros2-moveit-generator.sh mobile_manipulator`（移动+臂）
- 控制：`ros2-control-node-generator.sh force_position_hybrid`（力位混合）
- 参数：`ros2-param-generator.sh humanoid`
