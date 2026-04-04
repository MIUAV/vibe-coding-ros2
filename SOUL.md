# SOUL.md

## 什么是 vibe-coding-ros2

用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

## 三个核心原则

1. **LLM 会生成错误的代码** — 因此需要 colcon build 验证反馈
2. **上下文比提示词重要** — AI 看不到 ROS2 运行时 = 盲人摸象
3. **先接口后实现** — msg/srv/action 定义优先于代码

## 四个层次

| 层次 | 说明 |
|------|------|
| **道** | 为什么要用 LLM 辅助 ROS2 开发 |
| **法** | 工作流程：规划 → 接口定义 → 生成 → 验证 → 迭代 |
| **术** | SKILL.md 中的强制规则，阻止 LLM 犯常见错误 |
| **器** | Shell 脚本，执行 colcon build、包生成、代码验证 |

## LLM 的致命弱点

- 经常生成无法编译的 CMakeLists.txt（漏写 ament_export_dependencies）
- 混淆 QoS 导致静默丢数据
- 不理解 Lifecycle 状态机
- 消息类型写错（裸类型 vs 包前缀）

→ 必须用规则库（cmake-guard）和反馈回路（colcon build）约束

## 什么是真实代码

- ✅ `examples/rclcpp-minimal/` 中真实可编译的 C++ 节点
- ❌ `agents/skills/` 中只有 frontmatter 的占位文件
