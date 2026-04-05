# SKILL — simulator

> 机器人仿真技能

## Tools
- **gazebo_classic**: Gazebo Classic 仿真（ROS2 版本使用 ignition/gazebo）
- **sdf_urdf**: SDF/URDF 模型构建 + xacro 动态参数
- **sensor_sim**: 传感器仿真（camera/lidar/IMU/GPS 噪声模型）

## Usage
用于机器人仿真，节省硬件测试时间：
- Gazebo 中加载 URDF + xacro（`ros2 launch gazebo_ros robot.launch.py`）
- 激光雷达仿真：Gazebo Plugin（libgazebo_ros_ray_sensor.so）
- IMU 噪声模型：`<noise type='gaussian'>` 标签配置
- ROS2 + Gazebo 联合仿真：gz-sim / ros_gz_bridge

## Tips
- Gazebo Forge 模型库（https://app.gazebosim.org/）可直接下载复用
- 相机仿真用 image_transport plugin，避免 raw image 带宽问题
- ignition-gazebo 已改名为 gz-sim，注意 ROS2 文档版本
- 仿真帧率设置建议 ≤ 50Hz，避免实时因子上限告警
