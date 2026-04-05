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

## 🎯 核心开发准则

> **AI 是打字员，不是架构师。AI 生成 → 编译验证 → 错误修正 → 重新生成。**

AI Agent 首次克隆本项目后，**必须按顺序阅读以下文件，再开始写代码：**

```
SOUL.md    → 项目哲学（5 分钟）
SYSTEM.md  → AI 强制规则（10 分钟）
CLAUDE.md → 开发指南（10 分钟）
```

### 准则 1：CMake 三行必须同时存在

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)           # 必须
ament_export_include_directories(include)     # 必须
ament_export_libraries(${PROJECT_NAME})      # 必须
```
缺少任意一行 → 链接错误 → 编译失败。

### 准则 2：QoS 选错 = 静默失败

| 场景 | QoS |
|------|------|
| 控制命令（cmd_vel） | `QoS(10).reliable()` |
| Sensor 数据（laser/camera） | `QoS(10).best_effort()` |
| Lifecycle 状态 | `QoS(10).transient_local()` |

### 准则 3：生产环境用 LifecycleNode

```cpp
// ❌ 错误 — 生产机器人控制
auto node = std::make_shared<rclcpp::Node>("controller");

// ✅ 正确 — 带状态机的 LifecycleNode
class RobotController : public rclcpp_lifecycle::LifecycleNode { ... };
```

---

## 🛠️ 工具链

```bash
# 代码生成（最常用）
bash scripts/generators/ros2-package-generator.sh <pkg> cpp <deps>   # C++ 包
bash scripts/generators/ros2-package-generator.sh <pkg> python     # Python 包
bash scripts/generators/ros2-cpp-node.sh <type> <pkg> [deps]       # 节点生成

# 编译验证（生成后必用）
bash scripts/ros2-build-feedback.sh .        # 自动分析错误，给修复建议
bash scripts/validators/skill-frontmatter-validator.sh agents/skills  # SKILL 格式验证

# 环境诊断
bash scripts/ros2-env-check.sh              # ROS2 环境 7 项检查
bash scripts/ros2-monitor.sh               # 运行时节点监控
bash scripts/ros2-bag-tool.sh record /scan  # 录制 bag
```

---

## 📁 项目结构

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
│   │   ├── ros2-debug/           # 调试指南
│   │   └── navigation/nav2-config/ # Nav2 参数
│   │
│   ├── prompts/       # AI 提示词模板
│   ├── documents/      # 文档（Methodology / Tutorials / Project Management）
│   └── robots/         # 机器人类型
│
├── scripts/
│   ├── generators/     # 代码生成器
│   ├── mcp/          # MCP 多智能体编排
│   ├── validators/    # 验证工具
│   └── ros2-build-feedback.sh  # 编译验证
│
└── examples/
    └── mcp-workflow/cases/  # 10 个复杂任务案例
```

---

## 🤖 AI Agent 工作流

```
用户需求
  │
  ▼
┌──────────────────────┐
│ SOUL.md + SYSTEM.md  │  ← AI 必读
└──────────────────────┘
  │
  ▼
接口定义 (msg/srv/action)
  │
  ▼
生成 CMakeLists.txt + C++ 代码
  │
  ▼
colcon build 验证
  │
  ▼ 报错
ros2-build-feedback.sh 分析
  │
  ▼
修正 → 重新生成（最多 3 轮）
```

---

## 📖 文档索引

| 文件 | 作用 |
|------|------|
| `SOUL.md` | 项目哲学，必读 |
| `SYSTEM.md` | AI 强制规则，必读 |
| `CLAUDE.md` | AI 开发指南，必读 |
| `AGENTS.md` | agents/ 目录结构说明 |
| `agents/skills/ros2-cmake-guard/` | CMake 依赖三行规则 |
| `agents/skills/ros2-qos-checker/` | QoS 选择规则 |
| `agents/skills/ros2-debug/` | 编译/运行时调试 |
| `agents/documents/Methodology_and_Principles/` | 开发方法论 |
| `agents/documents/Tutorials_and_Guides/` | 教程指南 |
| `examples/mcp-workflow/cases/` | 10 个复杂任务案例 |

---

## 📦 SKILL 数量

| 类别 | 数量 |
|------|------|
| skills 总数 | 276 |
| 场景 | 77 |
| 本周新增 | 0 (已整理) |

---

## 📄 许可证

Apache-2.0 · [LICENSE](LICENSE)
