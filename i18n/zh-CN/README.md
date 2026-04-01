# Vibe Coding ROS2 多语言项目说明

> 本目录存放 vibe-coding-ros2 项目的多语言文档，引导 AI 智能体选择习惯性的开发方式

---

## 项目结构概览

```
vibe-coding-ros2/
├── agents/                   # Agent 主目录
│   ├── skills/               # 技能模块目录
│   │   ├── README.md         # 技能索引
│   │   ├── ros2-package-generator/
│   │   ├── ros2-debugging/
│   │   └── arm64-cross-compile/
│   ├── prompts/              # 提示词模板
│   │   ├── coding_prompts/
│   │   ├── system_prompts/
│   │   └── user_prompts/
│   ├── robots/               # 机器人类型指南
│   │   ├── common/
│   │   ├── wheeled_vehicle/
│   │   ├── quadruped/
│   │   ├── manipulator/
│   │   ├── humanoid/
│   │   └── multi_rotor_uav/
│   ├── documents/            # 文档资料
│   │   ├── Methodology_and_Principles/
│   │   ├── Templates_and_Resources/
│   │   └── Tutorials_and_Guides/
│   └── memory-bank/          # 记忆银行
│       ├── project-context.md
│       ├── implementation-plan.md
│       └── progress.md
├── i18n/                     # 多语言文档（本目录）
│   ├── README.md             # 语言索引
│   ├── en/                   # 英文文档
│   │   ├── README.md
│   │   └── CHANGELOG.md
│   └── zh-CN/                # 简体中文文档
│       ├── README.md
│       └── CHANGELOG.md
└── README.md                 # 项目主说明
```

---

## 技能模块详解

### 1. ROS2 包生成器 (`skills/ros2-package-generator/`)

**用途**: 生成完整的 ROS2 功能包结构

**触发词**:
- "创建一个 ROS2 包"
- "创建功能包"
- "generate ros2 package"

**功能**:
- 生成标准 CMakeLists.txt
- 生成 package.xml 依赖配置
- 生成节点代码框架
- 生成自定义消息/服务/动作
- 生成 launch 文件
- 生成参数配置文件

**输出结构**:
```
package_name/
├── CMakeLists.txt
├── package.xml
├── include/package_name/
├── src/
├── launch/
├── config/
├── msg/
├── srv/
└── test/
```

---

### 2. ROS2 调试技能 (`skills/ros2-debugging/`)

**用途**: 调试 ROS2 节点、话题分析、bag 回放

**触发词**:
- "调试 ROS2"
- "ros2 debug"
- "排查问题"

**功能**:
- 节点调试 (ros2 node)
- 话题分析 (ros2 topic)
- 服务调试 (ros2 service)
- 参数调试 (ros2 param)
- Bag 录制与回放
- rqt 工具使用

**常用命令速查**:

| 类别 | 命令 | 说明 |
|------|------|------|
| 节点 | `ros2 node list` | 列出所有节点 |
| 节点 | `ros2 node info /node_name` | 查看节点详情 |
| 话题 | `ros2 topic list` | 列出所有话题 |
| 话题 | `ros2 topic echo /topic_name` | 查看话题数据 |
| 话题 | `ros2 topic hz /topic_name` | 查看发布频率 |
| 服务 | `ros2 service list` | 列出所有服务 |
| 参数 | `ros2 param list` | 列出所有参数 |
| Bag | `ros2 bag record /topic` | 录制话题 |
| Bag | `ros2 bag play bag_name` | 回放 bag |

---

### 3. ARM64 交叉编译 (`skills/arm64-cross-compile/`)

**用途**: x86 开发机到 ARM64 目标机的交叉编译

**目标平台**:
- NVIDIA Jetson OrinNX
- RDK-X5 (Horizon)
- 其他 ARM64 嵌入式设备

**触发词**:
- "交叉编译 ARM"
- "cross compile ARM"
- "ARM64 编译"

**工具链配置**:
```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_SYSROOT /opt/orin_sysroot)
```

**Docker 编译环境**:
```bash
docker run -d --name orin-cross \
  -v /path/to/rootfs:/opt/orin_sysroot:ro \
  -v /workspace/ros2_ws:/workspace/ros2_ws \
  ros2-humble-cross-compile sleep infinity
```

---

## 开发工作流

### 1. 环境准备

```bash
# 克隆项目
git clone https://github.com/MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 安装依赖
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 启动 ROS2
source /opt/ros/humble/setup.bash
```

### 2. 创建新包

```
@skills/ros2-package-generator 创建一个感知包
```

智能体将自动生成:
- 包结构
- CMakeLists.txt
- package.xml
- 基础节点代码
- Launch 配置

### 3. 交叉编译

```
使用 arm64 交叉编译技能编译当前包
```

### 4. 调试

```
使用 ros2 调试技能分析 /scan 话题数据
```

---

## 机器人类型指南

### 轮式车辆 (`robots/wheeled_vehicle/`)

适用于:
- 智能小车
- 自动导引车 (AGV)
- 清洁机器人

### 四足机器人 (`robots/quadruped/`)

适用于:
- 仿生四足机器人
- 巡检机器人

### 机械臂 (`robots/manipulator/`)

适用于:
- 工业机械臂
- 服务机械臂
- 协作机器人 (Cobot)

### 人形机器人 (`robots/humanoid/`)

适用于:
- 双足人形机器人
- 仿人研究平台

### 多旋翼无人机 (`robots/multi_rotor_uav/`)

适用于:
- 四轴/六轴飞行器
- 无人机控制系统
- 自主导航飞行

---

## 提交规范 (Apache 2.0)

### Commit Message 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| Type | 说明 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档变更 |
| style | 代码格式（不影响功能） |
| refactor | 重构 |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具变更 |

### 示例

```
feat(perception): 添加激光雷达点云处理节点

- 实现点云滤波
- 添加降采样功能
- 集成 PCL 库

Closes #123
```

### Pull Request 原则

1. **原子提交**: 每个 PR 只做一件事
2. **可审查**: 代码审查者能快速理解
3. **测试**: 包含必要的单元测试
4. **文档**: 更新相关文档
5. **签名**: 所有提交需签署 DCO

---

## Apache 2.0 开源协议

```
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright [2026] [MIUAV Organization]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
```

完整协议见: [LICENSE](LICENSE)

---

## 快速开始

```bash
# 1. 初始化工作空间
mkdir -p ~/vibe_ws/src
cd ~/vibe_ws
source /opt/ros/humble/setup.bash

# 2. 创建功能包
# 使用 @skills/ros2-package-generator

# 3. 编译
colcon build

# 4. 运行
source install/setup.bash
ros2 run <package_name> <node_name>

# 5. 调试
# 使用 @skills/ros2-debugging
```

---

## 获取帮助

- 查看 `skills/README.md` 了解所有可用技能
- 查看 `documents/Tutorials_and_Guides/` 获取详细教程
- 查看 `memory-bank/` 了解项目上下文
