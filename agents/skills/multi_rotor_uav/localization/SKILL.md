# SKILL — uav_localization

> 无人机定位技能

## Tools
- **gps_fusion**: GPS + IMU + 气压计 EKF 融合
- **vio_node**: 视觉惯性里程计（VIO: rtabmap_ros, okvis, VINS-Fusion）
- **SLAM**: 激光/视觉 SLAM（slam_toolbox, fast_lio）

## Usage
无人机精确定位，室内外无缝切换：
- 室外：robot_localization ekf_node 融合 GPS + IMU
- 室内：VIO（Intel T265/Realsense D455i）或激光 SLAM
- 室外→室内切换：GPS 失效时自动切换 VIO（需要可靠触发）

## Tips
- GPS 精度受多路径影响（高楼旁误差可达 5m），需要 RTK 修正
- T265 VIO 在快速旋转时容易丢帧，IMU 带宽 200Hz 以上
- EKF 输出频率建议 50-100Hz，输出 `odom` → `base_link` TF
