# Context Index — 项目上下文

> 由 init-agent.sh 自动生成。

## 项目结构

```
vibe-coding-ros2/
├── agents/
│   ├── skills/          # 技能定义（270+ SKILL.md）
│   ├── robots/          # 机器人类型指南
│   ├── prompts/         # 提示词模板
│   ├── memory-bank/    # 项目记忆
│   └── generated/       # 自动生成的索引
├── examples/            # 可运行的示例代码（可编译）
│   ├── ros2-minimal/    # cpp_publisher + py_subscriber
│   ├── ros2-lifecycle/  # lifecycle_sensor
│   └── ros2-service/    # add_two_ints
├── scripts/
│   ├── generators/      # 包生成器
│   ├── validators/      # 代码验证器
│   └── deployers/       # 部署脚本
└── i18n/
    ├── zh-CN/           # 中文文档
    └── en/              # 英文文档
```

## 可运行的示例（全部可编译）

| 示例 | 内容 | 验证规则 |
|------|------|----------|
| `examples/ros2-minimal/cpp_publisher` | C++ pub + QoS + wall_timer | SharedPtr, QoS, rclcpp::init/shutdown |
| `examples/ros2-minimal/py_subscriber` | Python sub + rclpy 规范 | rclpy.shutdown(), try/finally |
| `examples/ros2-lifecycle/lifecycle_sensor` | LifecycleNode 状态机 | on_configure/activate/deactivate/cleanup |
| `examples/ros2-service/add_two_ints` | Service + Client + 超时 | wait_for() timeout, async_send_request |

## 关键文件

| 文件 | 用途 |
|------|------|
| i18n/zh-CN/AGENTS_CONCISE.md | 极简工作流指令卡 |
| i18n/zh-CN/ANTI_PATTERNS.md | C++/QoS/并发安全规则 |
| init-agent.sh | 初始化脚本 |
| scripts/generators/ros2-package-generator.sh | 一键生成 ROS2 包 |
| scripts/validators/ros2-node-validator.sh | 代码安全验证 |
