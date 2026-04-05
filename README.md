# Vibe-Coding-ROS2

> 用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

[comment]: # (ZH: AI agent reads SOUL.md + SYSTEM.md first | EN: AI agent reads CLAUDE.md for workflow)

---

## 🔥 GitHub Stats

[![Stars](https://img.shields.io/github/stars/MIUAV/vibe-coding-ros2?style=flat-square&label=Stars)](https://github.com/MIUAV/vibe-coding-ros2/stargazers)
[![Forks](https://img.shields.io/github/forks/MIUAV/vibe-coding-ros2?style=flat-square&label=Forks)](https://github.com/MIUAV/vibe-coding-ros2/network/members)
[![Issues](https://img.shields.io/github/issues/MIUAV/vibe-coding-ros2?style=flat-square&label=Issues)](https://github.com/MIUAV/vibe-coding-ros2/issues)
[![License](https://img.shields.io/github/license/MIUAV/vibe-coding-ros2?style=flat-square&label=License)](https://github.com/MIUAV/vibe-coding-ros2/blob/main/LICENSE)

| 指标 | 数值 |
|------|------|
| ⭐ Stars | 17 |
| 🍴 Forks | 1 |
| 👀 Watchers | 1 |
| 🐛 Issues | 0 |
| 📝 Commits | 1168+ |
| 📦 Packages | 276 SKILLs |
| 🤖 Contributors | 1 |

**Latest commit:** `be074f4` · 2026-04-05

---

## ⚡ 1 分钟快速开始

```bash
# 第 1 步：克隆
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 第 2 步：生成一个 ROS2 包
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 第 3 步：编译验证
cd my_robot && colcon build

# 第 4 步：自动检查编译错误
bash ../scripts/ros2-build-feedback.sh .
```

---

## 🧪 实验性方法

> 这是一个不断生长和自我否定的项目。AI 能力的变化可能导致当下经验失效，请保持以 AI 为主的思维，辩证地采纳。

**什么是 Vibe-Coding-ROS2？**

用 LLM 辅助编写 ROS2 代码，主张「先沉浸式做出能跑的东西」，以极低门槛快速产出可编译的 ROS2 C++ 原型。

```
AI 是打字员，不是架构师
AI 生成 → 编译验证 → 错误修正 → 重新生成
可编译 > 看起来对
```

**三个致命弱点（ROS2 开发中 LLM 的）：**

| 弱点 | 后果 | 解法 |
|------|------|------|
| CMake 依赖地狱 | 链接失败 | `ament_export_dependencies` 三行必须同时存在 |
| QoS 静默失败 | 数据不通 | 控制命令 RELIABLE，sensor BEST_EFFORT |
| Lifecycle 状态机 | 节点卡住 | 生产环境用 LifecycleNode |

---

## 🧭 经验

### 核心教训

- **「可编译 > 看起来对」** — 代码必须 `colcon build` 零错误
- **「反馈回路优先」** — AI 生成后必须编译验证，错误直接修正
- **「强制规则 > 建议」** — `SYSTEM.md` 的禁区零容忍

### CMake 依赖地狱

CMakeLists.txt 必须同时有这三行，缺一不可：

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)           # 必须
ament_export_include_directories(include)     # 必须
ament_export_libraries(${PROJECT_NAME})      # 必须
```

### QoS 静默失败

ROS2 默认 QoS 是 `RELIABLE + VOLATILE`。常见场景：

```cpp
// 控制命令 — 必须可靠
QoS(10).reliable();  // 禁止 BEST_EFFORT

// Sensor 数据 — 允许丢帧
QoS(10).best_effort();

// Lifecycle 状态 — 新订阅者收到最近状态
QoS(10).transient_local();
```

### Lifecycle 状态机

生产机器人控制必须用 `rclcpp_lifecycle::LifecycleNode`：

```cpp
// ❌ 错误 — 无法优雅关闭/重启
auto node = std::make_shared<rclcpp::Node>("controller");

// ✅ 正确 — 带状态机
class RobotController : public rclcpp_lifecycle::LifecycleNode { ... };
```

---

## 📋 工具与资源

### 生成器

```bash
# 包生成器（最常用）
bash scripts/generators/ros2-package-generator.sh <pkg> cpp <deps>   # C++ 包
bash scripts/generators/ros2-package-generator.sh <pkg> python     # Python 包
bash scripts/generators/ros2-cpp-node.sh <type> <pkg> [deps]       # 节点生成器

# type: publisher | subscriber | lifecycle | service | action | timer | parameters
```

### 验证工具

```bash
bash scripts/ros2-build-feedback.sh .                              # 编译错误分析
bash scripts/ros2-env-check.sh                                   # 环境 7 项检查
bash scripts/ros2-monitor.sh                                    # 运行时监控
bash scripts/validators/skill-frontmatter-validator.sh agents/skills  # SKILL 格式验证
bash scripts/ros2-bag-tool.sh record /scan                      # bag 录制
```

### MCP 多智能体

```bash
./scripts/mcp/ros-mcp-integration.sh              # 启动 MCP Server
./scripts/mcp/mcp-agent-orchestrator.sh <case>  # 编排多 Agent 协作
```

---

## 🏁 编码模型性能分级参考

| 等级 | 模型 | 适用场景 |
|------|------|---------|
| L1 | GPT-4 / Claude 3.5 | 复杂多模块系统设计 |
| L2 | GPT-3.5 / Claude 3 | 标准 ROS2 包生成 |
| L3 | Gemini / DeepSeek | 单文件代码生成 |
| L4 | 小模型 | 代码补全、错误解释 |

---

## 🗂️ 项目目录结构概览

```
vibe-coding-ros2/
├── SOUL.md              # 项目哲学
├── SYSTEM.md            # AI 强制规则（CMake/QoS/Lifecycle）
├── CLAUDE.md           # AI 开发指南
├── README.md            # 本文件
│
├── agents/
│   ├── skills/         # 276 个技能定义（强制规则）
│   │   ├── ros2-cmake-guard/     # CMake 禁区
│   │   ├── ros2-qos-checker/     # QoS 兼容性
│   │   ├── ros2-debug/          # 调试指南
│   │   └── navigation/nav2-config/ # Nav2 参数
│   │
│   ├── prompts/        # AI 提示词模板
│   ├── documents/      # 项目文档
│   │   ├── Methodology_and_Principles/  # 开发方法论
│   │   ├── Tutorials_and_Guides/       # 教程指南
│   │   └── Project_Management/         # 项目管理
│   └── robots/          # 机器人类型
│
├── scripts/
│   ├── generators/      # ros2-package-generator / ros2-cpp-node
│   ├── mcp/           # MCP 多智能体
│   ├── validators/     # SKILL 验证器
│   └── ros2-build-feedback.sh  # 编译验证
│
└── examples/
    └── mcp-workflow/
        └── cases/      # 10 个复杂任务案例
```

---

## 📺 演示与产出

### 已有工具产出

| 工具 | 状态 | 说明 |
|------|------|------|
| `ros2-package-generator.sh` | ✅ 可用 | 生成 C++/Python ROS2 包 |
| `ros2-build-feedback.sh` | ✅ 可用 | 编译错误自动分析 |
| `ros2-cpp-node.sh` | ✅ 可用 | 7 种节点类型生成 |
| `ros2-env-check.sh` | ✅ 可用 | 环境诊断 |
| `ros2-monitor.sh` | ✅ 可用 | 运行时监控 |
| `skill-frontmatter-validator.sh` | ✅ 可用 | 276 SKILL 格式验证 |

### 复杂任务案例

| Case | 机器人 | 任务 |
|------|--------|------|
| `go2-scurve/` | 四足 | S 曲线轨迹规划 |
| `manipulator-pickplace/` | 机械臂 | 抓取放置 |
| `drone-exploration/` | 无人机 | 自主探索 |
| `wheeled-nav2/` | 轮式 | Nav2 导航 |
| `multi-robot-swarm/` | 多机 | 蜂群协同 |
| `biped-walk/` | 双足 | 步行控制 |
| `underwater-nav/` | AUV | 水下导航 |
| `sensor-fusion-locate/` | 通用 | 传感器融合 |
| `aerial-photography/` | 无人机 | 航拍任务 |
| `industrial-integration/` | 工业 | ROS2-PLC 集成 |

---

## 🎯 原仓库翻译

本项目从 [tukuaiai/vibe-coding-cn](https://github.com/tukuaiai/vibe-coding-cn) 的 Vibe Coding 哲学衍生而来，专注文 ROS2 机器人开发领域，将通用 Vibe Coding 方法论落地为可编译的代码和工具。

---

## 📄 许可证

Apache-2.0 · [LICENSE](LICENSE)
