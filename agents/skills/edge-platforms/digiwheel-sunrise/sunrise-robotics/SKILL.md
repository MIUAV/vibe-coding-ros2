---
name: sunrise-robotics
description: 旭日机器人应用 - 机械臂控制 移动机器人 导航避障
argument-hint: 机器人控制 OR 机械臂 OR 导航 OR 旭日机器人
user-invocable: true
---

# Sunrise 机器人技能

> 旭日BPU机器人应用

## 何时使用

- 机械臂控制
- 移动机器人导航
- 避障系统

## 应用场景

### 1. 机械臂视觉引导

- 手眼标定
- 目标定位
- 抓取规划

### 2. 移动机器人

- SLAM导航
- 路径规划
- 避障检测

### 3. 四足机器人

- 姿态估计
- 地形识别
- 步态控制

## ROS2集成

```bash
# 安装horizon_ros
apt install ros-humble-horizon-ros

# 运行示例
ros2 launch horizon_navigation navigation.launch.py
```

## 性能要求

| 任务 | 延迟 | FPS |
|------|------|-----|
| 目标检测 | <30ms | 30+ |
| 深度估计 | <50ms | 20+ |
| SLAM | <100ms | 10+ |