# 项目上下文 - [项目名称]

> 最后更新: YYYY-MM-DD
> AI 模型: [模型名称]
> 版本: v1.0.0

---

## 1. 项目概述

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| 项目名称 | [名称] |
| 负责人 | [姓名] |
| AI 助手 | [模型] |

### 1.2 功能描述

[详细描述项目的主要功能和目标]

### 1.3 目标平台

| 平台 | 说明 |
|------|------|
| 开发机 | x86_64 / Ubuntu 22.04 |
| 目标机 | Jetson OrinNX / AGX |
| ROS2 | Humble |

---

## 2. 技术栈

| 依赖 | 版本 | 用途 |
|------|------|------|
| ROS2 Humble | 22.04 | 机器人操作系统 |
| OpenCV | 4.8 | 图像处理 |
| TensorRT | 8.6 | GPU 推理 (ARM64) |
| Navigation2 | humble | 导航堆栈 |

---

## 3. 包结构

| 包名 | 职责 | 依赖 |
|------|------|------|
| my_driver | 硬件驱动 | rclcpp, SDK |
| my_perception | 感知算法 | cv_bridge, tensorrt |
| my_navigation | 导航规划 | nav2 |
| my_control | 运动控制 | geometry_msgs |
| my_bringup | 启动集合 | 无 |

---

## 4. 消息流

```
[Camera] ──(Image)──> [Perception] ──(Detection)──> [Planning]
                                                          │
[LiDAR] ──(PointCloud)──> [Localization] ──(Pose)──────┘
                                                          │
                                                          ▼
[Controller] <──(Twist)──── [Control] <──(Path)──── [Planner]
```

---

## 5. Topic / Service / Action

| Topic | 类型 | 频率 | 说明 |
|-------|------|------|------|
| /camera/image_raw | Image | 30Hz | 原始图像 |
| /scan | LaserScan | 10Hz | 激光数据 |
| /odom | Odometry | 50Hz | 里程计 |
| /cmd_vel | Twist | 50Hz | 速度指令 |

---

## 6. 硬件配置

| 传感器 | 型号 | 接口 |
|--------|------|------|
| 相机 | [型号] | USB3.0 |
| 激光雷达 | [型号] | Ethernet |
| IMU | [型号] | SPI |

---

## 7. 构建配置

```bash
# x86_64
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# ARM64 (交叉编译)
colcon build --cmake-args \
    -DCMAKE_TOOLCHAIN_FILE=... \
    -DCMAKE_SYSROOT=...
```

---

## 8. 已知限制

- [限制1]
- [限制2]
