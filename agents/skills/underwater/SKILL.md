# SKILL — underwater

> 水下机器人（AUV/ROV）开发技能

## Tools
- **sonar_perception**: 水声成像、声纳点云处理
- **depth_control**: 深度 PID/AUV 垂向控制
- **underwater_nav**: 水下定位（USBL/DVL/里程计融合）

## Usage
用于 AUV/ROV 项目开发，典型场景：
- 湖泊/海洋环境 SLAM（需要修改 Rtabmap 的深度传感器配置）
- 水声通信节点（acoustic_modem 驱动）
- 动力学建模（水阻力参数辨识）

## Tips
- 水下光照差，视觉 SLAM 需要主动光源或声学方案
- 深度传感器（压力计）有延迟，融合时需要时间对齐
- ROS2 水下节点注意防水压舱密封（防水壳 IP68）
