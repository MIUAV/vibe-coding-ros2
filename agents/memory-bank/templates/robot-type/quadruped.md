# Quadruped Robot Context

## 步态类型
| 步态 | 说明 | 适用场景 |
|------|------|---------|
| 静态行走（Static Walk）| 任意时刻三角支撑，稳定性好，速度慢 | 崎岖地面 |
| 对角小跑（Trot）| 对角腿同时着地，最常用 | 一般行走 |
| 踱步（Pace）| 同侧腿同时着地 | 高速 |
| 跳跃（Pound）| 对角腿略微错相 | 特殊 |

## 关键依赖
- `unitree_msgs` / `legged_msgs` — 腿式专用消息
- `geometry_msgs/Twist` — `/cmd_vel` 期望速度
- `sensor_msgs/JointState` — 关节状态反馈

## 核心 Topic
| Topic | 类型 | 用途 |
|-------|------|------|
| `/machine_state` | — | 机器人整体状态（运行/故障） |
| `/LowCmd` | — | 低层控制命令（20Hz+，发布到电机） |
| `/LowState` | — | 低层状态反馈（电机角度/速度/力） |
| `/cmd_vel` | `Twist` | 期望速度（机身坐标系） |
| `/imu` | `Imu` | IMU 数据 |

## 低层控制接口（High-Level → Low-Level）
```
ROS2 (cmd_vel) → 步态生成器 → LowCmd (20Hz UART/CAN) → 电机驱动
```
Unitree A1/Go2 使用 `lola` 或 `unitree_ros2` 驱动。

## 生成器选择
- 控制节点：`ros2-control-node-generator.sh hardware_interface|joint_trajectory`
- 仿真：`ros2-simulator-generator.sh quadruped`
- 参数：`ros2-param-generator.sh quadruped`

## URDF 关键点
- 每个腿 3 个关节（髋/膝/踝），12 DOF（4腿×3）
- base_link → hip → thigh → calf 运动学链
