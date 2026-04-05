# SKILL — common

> 通用机器人开发技能

## Tools
- **tf2_transform**: 坐标系转换（URDF + TF2）
- **time_sync**: 多传感器时间同步（message_filters）
- **multi_sensor_fusion**: EKF/UKF 多传感器融合

## Usage
跨平台通用技能，适用于任何 ROS2 机器人项目：
- 坐标系树构建（robot_state_publisher + joint_state_publisher）
- IMU+编码器融合（robot_localization ekf_node）
- 硬件时间同步（camera_info + encoder tick 同步）

## Tips
- TF2 坐标系必须符合 REP105 标准（map → odom → base_link → ...）
- message_filters::ApproximateTimePolicy 用于异步传感器同步
- EKF 节点最多支持 3 个传感器输入（IMU、GPS、编码器）
