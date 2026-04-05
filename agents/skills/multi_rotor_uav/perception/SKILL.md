# SKILL — uav_perception

> 无人机感知技能

## Tools
- **obj_detection**: 目标检测（YOLOv8 + ROS2，DetectNet / SSD）
- **depth_perception**: 深度相机（RealSense D455i + librealsense）
- **pointcloud_filter**: 点云滤波（VoxelGrid + PassThrough + RANSAC地面分割）

## Usage
无人机环境感知，用于避障、目标跟踪：
- YOLOv8 实时检测（ROS2 接口：yolov8_ros2）
- 深度点云处理（PCL → 降采样 → 地面分割 → 障碍物聚类）
- 视觉里程计（rtabmap_ros/republish 用于稠密重建）

## Tips
- 机载 GPU 有限，YOLOv8 用 INT8 量化模型（ Jetson Nano 可实时）
- 深度相机在户外强光下失效，补充超声波测距传感器
- 目标检测后用 EKF 跟踪（避免单帧漏检导致频繁切换）
