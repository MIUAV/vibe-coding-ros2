# 项目上下文文档生成 · ROS2 工程化 Prompt

> AI 辅助生成 ROS2 机器人项目的完整上下文文档

---

## 触发条件

当用户提供以下信息时使用此 Prompt：
- 项目名称和目标
- 机器人平台 (OrinNX/RDK-X5/x86)
- ROS2 版本
- 核心功能需求

---

## 模板

```markdown
# 项目上下文 - [项目名称]

> 生成日期: YYYY-MM-DD
> AI 助手: [模型名称]
> 版本: v1.0.0

---

## 1. 项目概述

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| 项目名称 | [名称] |
| 项目类型 | 机器人感知/导航/控制/综合 |
| 目标平台 | [Jetson OrinNX / RDK-X5 / x86] |
| ROS2 版本 | Humble |
| 开发语言 | [C++ / Python / 混合] |

### 1.2 功能描述

[详细描述项目要实现的功能]

### 1.3 项目范围

**包含**:
- [功能 1]
- [功能 2]

**不包含**:
- [排除的功能 1]
- [排除的功能 2]

---

## 2. 技术栈

### 2.1 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| ROS2 Humble | 22.04 | 机器人操作系统 |
| OpenCV | 4.8 | 图像处理 |
| TensorRT | 8.6 | GPU 推理 (ARM64) |
| Navigation2 | humble | 导航堆栈 |

### 2.2 可选依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| Livox SDK | - | 激光雷达 |
| ZED SDK | - | 深度相机 |

---

## 3. 系统架构

### 3.1 层次结构

```
[应用层] ── 任务规划、UI
    ↓
[导航层] ── SLAM、路径规划
    ↓
[感知层] ── 视觉、雷达
    ↓
[控制层] ── 电机、舵机
    ↓
[驱动层] ── 硬件接口
```

### 3.2 消息流

```
[传感器] → [感知] → [规划] → [控制] → [执行]
```

---

## 4. ROS2 包结构

### 4.1 包列表

| 包名 | 职责 | 语言 | 依赖 |
|------|------|------|------|
| my_driver | 驱动 | C++ | SDK |
| my_perception | 感知 | C++ | OpenCV, TensorRT |
| my_navigation | 导航 | C++ | nav2 |
| my_control | 控制 | C++ | - |
| my_bringup | 启动 | Python | - |

### 4.2 目录结构

```
src/
├── my_driver/
├── my_perception/
├── my_navigation/
├── my_control/
└── my_bringup/
```

---

## 5. Topic 设计

### 5.1 话题列表

| Topic | 类型 | 频率 | 说明 |
|-------|------|------|------|
| /camera/image_raw | Image | 30Hz | 原始图像 |
| /scan | LaserScan | 10Hz | 激光数据 |
| /odom | Odometry | 50Hz | 里程计 |
| /cmd_vel | Twist | 50Hz | 速度指令 |

### 5.2 QoS 配置

```cpp
// 传感器: RELIABLE + KEEP_LAST(10)
rclcpp::SensorDataQoS qos;

// 控制: RELIABLE + TRANSIENT_LOCAL
rclcpp::ParametersQoS qos;
```

---

## 6. Service 设计

| Service | 类型 | 说明 |
|---------|------|------|
| /reset_odom | Trigger | 重置里程计 |
| /set_mode | SetMode | 设置模式 |
| /emergency_stop | Trigger | 紧急停止 |

---

## 7. Action 设计

| Action | 类型 | 说明 |
|--------|------|------|
| /navigate_to_pose | NavigateToPose | 导航到目标 |
| /patrol | Patrol | 巡检任务 |

---

## 8. 参数配置

### 8.1 相机参数

```yaml
camera:
  device: /dev/video0
  width: 640
  height: 480
  fps: 30
```

### 8.2 导航参数

```yaml
nav:
  max_velocity: 1.0
  robot_radius: 0.3
```

---

## 9. 硬件配置

### 9.1 传感器

| 传感器 | 型号 | 接口 |
|--------|------|------|
| 相机 | ZED2i | USB3.0 |
| 激光雷达 | Livox MID360 | Ethernet |

### 9.2 计算平台

| 平台 | CPU | GPU |
|------|-----|-----|
| OrinNX | 8-core ARM | Ampere |
| 开发机 | Intel i7 | RTX 3060 |

---

## 10. 构建配置

### 10.1 编译选项

```bash
# x86_64
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# ARM64
colcon build --cmake-args \
    -DCMAKE_TOOLCHAIN_FILE=... \
    -DCMAKE_SYSROOT=...
```

### 10.2 Docker 镜像

```bash
# x86
ros:humble

# ARM64
hcseok/zed_orinnx_ros2:1.2.0
```

---

## 11. 风险与限制

### 已知风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| SDK 依赖 | 高 | 提前准备 |
| 性能瓶颈 | 中 | 优化代码 |

### 已知限制

- livox_ros_driver2 需要 Livox SDK
- ARM64 无 RDK BPU 支持

---

## 12. 参考资源

- [ROS2 Humble 文档](https://docs.ros.org/en/humble/)
- [Navigation2 文档](https://navigation.ros.org/)
- [本项目迁移文档](../MIGRATION_RDK_TO_ORINNX.md)
```

---

## 使用说明

1. **触发**: 用户提供项目基本信息时调用
2. **输入**: 项目名称、平台、功能需求
3. **输出**: 完整的上下文文档
4. **验证**: 用户确认后写入 `memory-bank/project-context.md`

---

## 示例

**用户输入**:
```
我要开发一个巡检机器人，使用 OrinNX + ZED 相机 + Livox 激光雷达
```

**AI 输出**: 按照模板生成完整的项目上下文文档
