# SKILL — quadruped

> 四足机器人开发技能

## Tools
- **gait_generation**: 步态生成（Trot、Pace、Walking、Bounding）
- **foot_control**: 足端力控制 + 接触检测（bumper sensor）
- ** locomotion_control**: 身体姿态控制（pitch/roll/yaw stabilization）

## Usage
四足机器人（Unitree Aliengo/Go1、ANYbotics ANYmal）开发：
- ROS2 控制接口（Unitree SDK → ros2_control）
- 步态切换（Trot→Walk→Stand）
- 地形适应（IMU 姿态稳定 + 足端力传感器）

## Tips
- 站立姿态：`ros2 topic pub /cmd_vel geometry_msgs/Twist '{}' -1`
- Trot 步态速度最快（对角腿交替），适用于平地
- 上下楼梯用 Crawl 步态（安全性 > 速度）
- 电池电量低于 20% 时禁止楼梯任务
