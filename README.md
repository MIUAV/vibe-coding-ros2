# Vibe-Coding-ROS2

> 用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

[comment]: # (ZH: 本文件是项目唯一根目录文档 | EN: This is the project's single root-level document)

---

## 核心问题

ROS2 开发中 LLM 的三大致命弱点：

| 问题 | 后果 |
|------|------|
| CMake 依赖地狱 | 经常漏写 `ament_export_dependencies`，链接失败 |
| QoS 静默失败 | 发布/订阅都成功但数据不过去 |
| Lifecycle 状态机 | 用 `rclcpp::Node` 而非 `LifecycleNode` |

## 解决方案

| 工具 | 作用 |
|------|------|
| `ros2-cmake-guard` | CMake 强制规则 |
| `ros2-qos-checker` | QoS 兼容性检测 |
| `ros2-build-feedback` | 编译后自动验证 + 错误修正 |
| `ros2-package-generator` | 一键生成可编译 ROS2 包 |

## 快速开始

```bash
# 生成一个新 ROS2 包
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs
cd my_robot && colcon build

# 验证生成的代码
bash scripts/ros2-build-feedback.sh my_robot

# 检查 QoS 配置
# (见 agents/skills/ros2-qos-checker/SKILL.md)
```

## 项目结构

```
vibe-coding-ros2/
├── SOUL.md              # 项目哲学
├── SYSTEM.md           # AI Agent 系统指令
├── AGENTS.md           # 项目结构
├── PROJECT_ROADMAP.md  # 技术路线图
├── agents/skills/      # 77 个技能定义
│   ├── ros2-cmake-guard/
│   ├── ros2-qos-checker/
│   ├── ros2-debug/
│   └── navigation/nav2-config/
├── scripts/
│   ├── generators/ros2-package-generator.sh
│   ├── ros2-build-feedback.sh
│   ├── mcp/ros-mcp-integration.sh
│   └── validators/skill-frontmatter-validator.sh
└── examples/
    ├── rclcpp-minimal/  # 可编译的 C++ 示例
    └── mcp-workflow/    # MCP 多智能体工作流
```

## AI Agent 使用指南

1. **克隆本仓库**到你的 ROS2 工作区
2. **设置 GitHub SSH key**（如需推送）
3. **阅读 SOUL.md + SYSTEM.md** 了解项目哲学和强制规则
4. **按 PROJECT_ROADMAP.md** 选择要开发的功能
5. **使用 ros2-package-generator.sh** 生成代码框架

## 质量保证

- 276 个 SKILL.md 全部通过 frontmatter 验证
- 所有生成代码必须 `colcon build` 零错误
- 违反 SYSTEM.md 规则 = 编译失败

## 许可证

Apache-2.0
