# SKILL — multi_rotor_uav

> 多旋翼无人机（UAV）开发技能

## Tools
- **px4_offboard**: PX4 室外飞控 + ROS2 offboard 控制
- **mavros_interface**: MAVROS 节点（/mavros/* topics）
- **uav_nav**: 室内 UAV 定位（OptiTrack + VIO）

## Usage
多旋翼无人机项目，包括：
- Pixhawk/PX4 + ROS2 集成（MAVROS 或 PX4 ROS2 Bridge）
- 室内无人机定位（OptiTrack、AprilTag、VIO）
- 四轴/六轴飞行控制（DJI A3/M600 Pro）

## Tips
- PX4 需要设置 `COM_OBS_AVOID=0` 关闭碰撞检测（室内测试）
- MAVROS 订阅 `/mavros/state` 检查 FCU 连接状态
- 室内飞行关闭 GPS，使用 vision_position_estimator 融合
- 电池电压监控：`/mavros/battery` topic
