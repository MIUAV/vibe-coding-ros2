# Vibe-Coding-ROS2

> 用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

---

## 快速开始

```bash
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 生成一个 ROS2 包
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 编译
cd my_robot && colcon build

# 自动检查编译错误
bash ../scripts/ros2-build-feedback.sh .
```

---

## 开发准则

AI Agent 开发前必须阅读：

| 文件 | 作用 |
|------|------|
| `SOUL.md` | 项目哲学（必读）|
| `SYSTEM.md` | AI 强制规则（必读）|
| `CLAUDE.md` | AI 开发指南（必读）|

**三个致命弱点（见 `SYSTEM.md`）：**

| 问题 | 解法 |
|------|------|
| CMake 依赖地狱 | `ament_export_dependencies` 三行必须同时存在 |
| QoS 静默失败 | 控制命令用 RELIABLE，sensor 用 BEST_EFFORT |
| Lifecycle 状态机 | 生产环境用 LifecycleNode，不是 rclcpp::Node |

---

## 工具链

```bash
# 代码生成
bash scripts/generators/ros2-package-generator.sh <pkg> cpp <deps>   # C++ 包
bash scripts/generators/ros2-package-generator.sh <pkg> python        # Python 包

# 编译验证
bash scripts/ros2-build-feedback.sh .   # 自动分析编译错误

# 环境诊断
bash scripts/ros2-env-check.sh           # ROS2 环境 7 项检查
bash scripts/ros2-monitor.sh            # 运行时节点监控

# SKILL 验证
bash scripts/validators/skill-frontmatter-validator.sh agents/skills
```

---

## 项目结构

```
vibe-coding-ros2/
├── SOUL.md                      # 项目哲学
├── SYSTEM.md                    # AI 强制规则
├── CLAUDE.md                    # AI 开发指南
├── README.md                    # 本文件
│
├── agents/
│   ├── skills/                 # 276 个技能定义（强制规则）
│   │   ├── ros2-cmake-guard/
│   │   ├── ros2-qos-checker/
│   │   ├── ros2-debug/
│   │   └── navigation/nav2-config/
│   │
│   ├── prompts/               # AI 提示词
│   ├── documents/             # 项目文档（已从根目录移入）
│   │   ├── Methodology_and_Principles/  # 开发方法论
│   │   ├── Tutorials_and_Guides/       # 教程指南
│   │   ├── Project_Management/         # 项目管理
│   │   └── Templates_and_Resources/    # 模板资源
│   │
│   ├── robots/              # 机器人类型
│   └── memory-bank/          # 项目记忆库
│
├── scripts/
│   ├── generators/          # 代码生成器
│   ├── mcp/                # MCP 多智能体
│   ├── validators/          # SKILL 验证器
│   └── ros2-build-feedback.sh  # 编译验证
│
└── examples/
    └── mcp-workflow/
        └── cases/           # 10 个复杂任务案例
```

---

## AI Agent 工作流

```
用户需求 → 接口定义 (msg/srv/action)
         → 生成 CMakeLists.txt + C++ 代码
         → colcon build 验证
         → 编译报错 → 分析 → 修正 → 重新生成
```

---

## 质量标准

- `colcon build` 零错误
- 违反 `SYSTEM.md` 规则 = 编译失败
- 所有 SKILL.md 通过 frontmatter 验证

---

## 许可证

Apache-2.0
