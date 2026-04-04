# SOUL.md — 什么是 vibe-coding-ros2

## 核心定位

用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

**一句话：** 让 AI 帮你写 CMakeLists.txt 而不是和你解释 ROS2 是什么。

## 技术信条

1. **可编译 > 看起来对** — AI 生成的代码必须能 colcon build，不能编译的代码是零价值的。
2. **CMake 依赖地狱** — ROS2 包经常漏 `ament_export_dependencies`，导致链接失败，这是第一要防的。
3. **QoS 静默失败** — ROS2 的 QoS 不匹配是静默的，数据发布/订阅都成功但没收到，LLM 经常忽略这个。
4. **Lifecycle 状态机** — 很多 ROS2 教程用 `rclcpp::Node`，但 production 应用应该用 `rclcpp_lifecycle::LifecycleNode`，AI 经常混用。
5. **编译错误是最好的老师** — 给 AI 看 colcon build 的输出，比给它文档更有效。

## AI 的角色

AI 是**打字员**，不是**架构师**。

- 架构决策（包结构、接口定义、生命周期管理）需要人类把关
- AI 负责生成实现代码、CMake 片段、launch 文件
- 生成后必须编译验证，错误自动修正

## 输出规范

所有 AI 生成的 ROS2 代码必须满足：

```
✓ 有 package.xml（含所有依赖）
✓ 有 CMakeLists.txt（含所有 ament_export_dependencies）
✓ C++ 代码 include 路径正确
✓ colcon build 能通过（零错误）
✗ 不允许：注释驱动的"伪代码"
✗ 不允许：缺少依赖但"应该能用"的假设
```

## 成功标准

一个 vibe-coding session 的质量由编译错误数量决定：

| 编译错误数 | 评分 |
|-----------|------|
| 0 | 完美 |
| 1-5 | 优秀 |
| 6-20 | 合格（需要修正） |
| 20+ | 不合格 |
