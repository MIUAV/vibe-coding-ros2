---
name: ros2-integration
description: Jetson ROS2集成 - v4l2_camera isaac_ros 机器人框架
argument-hint: Jetson ROS2 OR v4l2 OR isaac_ros OR 机器人集成
user-invocable: true
---

# Jetson ROS2 集成技能

> 在Jetson上集成ROS2和视觉系统

## 何时使用

- ROS2机器人开发
- 相机集成
- Isaac ROS部署

## 常用包

### 相机

```bash
# v4l2相机
sudo apt install ros-humble-v4l2-camera
ros2 run v4l2_camera v4l2_camera_node

# 深度相机
sudo apt install ros-humble-realsense2-camera
```

### Isaac ROS

```bash
# 安装Isaac ROS
cd /opt/isaac_ros_common
./scripts/run_base.sh

# 目标检测
ros2 launch isaac_ros_detection isaac_ros_detection_tensor_rt.launch.py
```

### 性能优化

```bash
# 绑定CPU核心
taskset -c 0-3 ros2 run package node

# 实时优先级
sudo chrt -f 99 ros2 run package node
```

## 延迟优化

- 使用DMA buffer
- Zero-copy传输
- 管道并行处理