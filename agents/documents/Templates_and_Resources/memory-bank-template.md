# Memory Bank 模板

> VibeCoding 的核心是保持清晰的上下文，Memory Bank 是存储项目上下文的机制。

---

## 1. Memory Bank 概述

```
memory-bank/
├── project-context.md        # 项目上下文 (核心)
├── implementation-plan.md     # 实施计划
├── progress.md               # 进度记录
├── architecture.md           # 架构文档
└── decisions.md              # 设计决策记录
```

---

## 2. project-context.md (项目上下文)

```markdown
# 项目上下文 - [项目名称]

> 最后更新: YYYY-MM-DD
> AI 模型: Claude Opus 4.5 / Codex-5.1

## 1. 项目概述

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| 项目名称 | [名称] |
| 版本 | v1.0.0 |
| 负责人 | [姓名] |
| AI 助手 | [模型] |

### 1.2 功能描述

[详细描述项目的主要功能和目标]

### 1.3 目标平台

| 平台 | 说明 |
|------|------|
| 开发机 | x86_64 / Ubuntu 22.04 |
| 目标机 | Jetson OrinNX / RDK-X5 |
| ROS2 | Humble |

---

## 2. 技术栈

### 2.1 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| ROS2 Humble | 22.04 | 机器人操作系统 |
| OpenCV | 4.8 | 图像处理 |
| TensorRT | 8.6 | GPU 推理 (ARM64) |
| Navigation2 | humble | 导航堆栈 |

### 2.2 编程语言

| 语言 | 用途 | 比例 |
|------|------|------|
| C++17 | 节点实现、算法 | 70% |
| Python3 | 脚本、工具 | 20% |
| CMake | 构建系统 | 10% |

---

## 3. 包结构

### 3.1 包列表

| 包名 | 职责 | 依赖 |
|------|------|------|
| my_robot_driver | 硬件驱动 | rclcpp, SDK |
| my_robot_perception | 感知算法 | cv_bridge, tensorrt |
| my_robot_navigation | 导航规划 | nav2 |
| my_robot_control | 运动控制 | geometry_msgs |
| my_robot_bringup | 启动集合 | 无 |

### 3.2 目录树

```
src/
├── my_robot_driver/
│   ├── src/
│   ├── config/
│   └── launch/
├── my_robot_perception/
│   ├── msg/
│   ├── src/
│   └── test/
└── my_robot_bringup/
    ├── launch/
    └── config/
```

---

## 4. 消息流

### 4.1 数据流图

```
[Camera] ──(Image)──> [Perception] ──(Detection)──> [Planning]
                                                          │
[LiDAR] ──(PointCloud)──> [Localization] ──(Pose)──────┘
                                                          │
                                                          ▼
[Controller] <──(Twist)──── [Control] <──(Path)──── [Planner]
     │
     ▼
[Motor Driver] ──(PWM)──> [Actuators]
```

### 4.2 Topic 列表

| Topic | 类型 | 频率 | 说明 |
|-------|------|------|------|
| /camera/image_raw | Image | 30Hz | 原始图像 |
| /camera/image_detected | Image | 30Hz | 检测结果 |
| /scan | LaserScan | 10Hz | 激光数据 |
| /odom | Odometry | 50Hz | 里程计 |
| /cmd_vel | Twist | 50Hz | 速度指令 |

### 4.3 Service 列表

| Service | 类型 | 说明 |
|---------|------|------|
| /reset_odom | Trigger | 重置里程计 |
| /set_mode | SetMode | 设置运行模式 |
| /emergency_stop | Trigger | 紧急停止 |

### 4.4 Action 列表

| Action | 类型 | 说明 |
|--------|------|------|
| /navigate_to_pose | NavigateToPose | 导航到目标点 |
| /patrol | Patrol | 巡检任务 |

---

## 5. 参数配置

### 5.1 相机参数

```yaml
camera:
  device: /dev/video0
  width: 640
  height: 480
  fps: 30
  exposure: 100
  gain: 50
```

### 5.2 导航参数

```yaml
nav:
  max_velocity: 1.0
  max_acceleration: 0.5
  robot_radius: 0.3
  obstacle_clearance: 0.5
```

---

## 6. 硬件配置

### 6.1 传感器

| 传感器 | 型号 | 接口 | 说明 |
|--------|------|------|------|
| 相机 | ZED2i | USB3.0 | 深度相机 |
| 激光雷达 | Livox MID360 | Ethernet | 360° 激光 |
| IMU | BMI088 | SPI | 惯性测量 |

### 6.2 计算平台

| 平台 | CPU | GPU | 说明 |
|------|-----|-----|------|
| 开发机 | Intel i7 | RTX 3060 | x86_64 |
| OrinNX | ARMv8.2 | Ampere | ARM64 |

---

## 7. 构建配置

### 7.1 编译选项

```bash
# x86_64
colcon build --packages-skip livox_ros_driver2 \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

# ARM64 (交叉编译)
colcon build --cmake-args \
  -DCMAKE_TOOLCHAIN_FILE=... \
  -DCMAKE_SYSROOT=... \
  -DENABLE_JETSON=ON
```

### 7.2 Docker 镜像

| 镜像 | 用途 | 基础系统 |
|------|------|----------|
| ros:humble | x86 开发 | Ubuntu 22.04 |
| hcseok/zed_orinnx_ros2:1.2.0 | ARM64 部署 | JetPack R36.3 |

---

## 8. 已知限制

- livox_ros_driver2 需要 Livox SDK
- detect_node 需要 TensorRT 推理支持
- ARM64 无 RDK BPU 支持

---

## 9. 参考文档

- [ROS2 Humble 文档](https://docs.ros.org/en/humble/)
- [Navigation2 文档](https://navigation.ros.org/)
- [本项目 VibeCoding 指南](../README.md)
```

---

## 3. implementation-plan.md (实施计划)

```markdown
# 实施计划 - [功能名称]

> 创建日期: YYYY-MM-DD
> 最后更新: YYYY-MM-DD
> 状态: [进行中/已完成/已暂停]

## 概述

[简要描述本次实施计划的目标和范围]

---

## 里程碑 1: [里程碑名称]

### 步骤 1.1: [步骤名称]

**目标**: [具体目标]

**指令**:
1. [具体指令]
2. [具体指令]
3. [具体指令]

**验证方法**:
```bash
# 验证命令
ros2 topic list | grep /topic_name
ros2 run pkg node
```

**预期产出**:
- 文件: `src/pkg/file.cpp`
- 功能: [描述]

**状态**: [待开始/进行中/已完成]

---

### 步骤 1.2: [步骤名称]

**目标**: [具体目标]

**指令**:
1. [具体指令]
2. [具体指令]

**验证方法**:
```bash
# 验证命令
colcon test --packages-select pkg_name
```

**状态**: [待开始/进行中/已完成]

---

## 里程碑 2: [里程碑名称]

### 步骤 2.1: [步骤名称]

**目标**: [具体目标]

**前置条件**:
- [已完成] 里程碑 1 完成

**指令**:
1. [具体指令]

**验证方法**:
```bash
ros2 launch pkg node.launch.py
```

**状态**: [待开始/进行中/已完成]

---

## 里程碑 3: [集成测试]

### 步骤 3.1: 端到端测试

**目标**: 验证完整数据流

**指令**:
1. 启动所有相关节点
2. 发送测试数据
3. 验证输出结果

**验证方法**:
```bash
# 启动测试
ros2 launch my_robot_bringup test.launch.py

# 发送测试数据
ros2 topic pub /camera/image_raw sensor_msgs/Image ...

# 验证结果
ros2 topic echo /detection/result
```

**状态**: [待开始/进行中/已完成]

---

## 风险与依赖

### 已知风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| SDK 依赖 | 高 | 提前获取 |
| 硬件延迟 | 中 | 优化代码 |

### 外部依赖

| 依赖 | 预计可用时间 | 负责人 |
|------|--------------|--------|
| Livox SDK | YYYY-MM-DD | @user |

---

## 进度统计

- [x] 里程碑 1: 完成
- [ ] 里程碑 2: 进行中 (60%)
- [ ] 里程碑 3: 待开始

**总体进度**: 30%
```

---

## 4. progress.md (进度记录)

```markdown
# 进度记录

> 项目: [项目名称]
> 开始日期: YYYY-MM-DD

---

## 2026-04-01

### 完成的工作

| 日期 | 功能 | 状态 | 产出 |
|------|------|------|------|
| 04-01 | 相机驱动节点 | ✅ 完成 | camera_driver.cpp |
| 04-01 | 图像预处理 | ✅ 完成 | preprocess.cpp |

### 遇到的问题

| 日期 | 问题 | 解决方案 |
|------|------|----------|
| 04-01 | USB 权限问题 | 添加 udev 规则 |

### 代码变更

```bash
# 提交记录
abc1234 feat: 添加相机驱动节点
def5678 fix: 修复 USB 权限问题
```

---

## 2026-04-02

### 完成的工作

| 日期 | 功能 | 状态 | 产出 |
|------|------|------|------|
| 04-02 | 目标检测节点 | 🔄 进行中 | - |

### 遇到的问题

| 日期 | 问题 | 解决方案 |
|------|------|----------|
| 04-02 | TensorRT 初始化慢 | 异步加载 |

### 明日计划

- [ ] 完成目标检测节点
- [ ] 编写单元测试
- [ ] 更新架构文档
```

---

## 5. decisions.md (设计决策)

```markdown
# 设计决策记录 (ADR)

> Architecture Decision Records

---

## ADR-001: 使用 Lifecycle Node

**日期**: YYYY-MM-DD
**状态**: 已接受

### 背景

需要管理节点的启动顺序和状态转换。

### 决策

使用 `rclcpp_lifecycle::LifecycleNode` 而非普通 Node。

### 理由

1. 可控的启动顺序
2. 优雅的降级处理
3. 内置状态监控

### 后果

- 需要为每个节点实现状态回调
- 增加少量代码复杂度

---

## ADR-002: 使用 Composable Node

**日期**: YYYY-MM-DD
**状态**: 已接受

### 背景

需要减少进程间通信开销。

### 决策

将相关节点放入同一容器进程。

### 理由

1. 减少进程间 IPC 开销
2. 共享内存传输大消息 (如图像)
3. 统一资源管理

### 后果

- 节点耦合度增加
- 需要注意线程安全
```

---

*使用 Memory Bank 保持项目上下文清晰，让 AI 每次对话都能快速进入状态*
