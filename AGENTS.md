# AGENTS.md — AI Agent 开发规则

## 项目定位

vibe-coding-ros2 是一个用 LLM 辅助编写 ROS2 代码的工具集，目标用户是 ROS2 机器人开发者。

## 核心问题

ROS2 开发中 LLM 的三大致命弱点：
1. **CMake 依赖地狱** — 经常漏写 `ament_export_dependencies`
2. **QoS 静默失败** — 数据明明发布但订阅端收不到
3. **Lifecycle 状态机** — 经常用 `rclcpp::Node` 而非 `LifecycleNode`

## 解决方案

| 工具 | 作用 |
|------|------|
| `cmake-guard` 技能 | 强制规则阻止 CMake 错误 |
| `ros2-qos-checker` 技能 | QoS 兼容性检测 |
| `ros2-debug` 技能 | 编译/运行时问题诊断 |
| `colcon build` 反馈 | AI 生成代码后自动验证 |

## 项目结构

```
vibe-coding-ros2/
├── README.md              # 快速开始 + 工具链索引
├── AGENTS.md             # 本文件 — AI Agent 工作规则
├── CLAUDE.md              # AI Agent 开发指南
├── SOUL.md               # 项目哲学
├── PROJECT_ROADMAP.md    # 技术路线图
│
├── agents/
│   ├── skills/           # 19 个技能目录（SKILL.md）
│   ├── robots/           # 机器人类型指南
│   ├── memory-bank/      # AI Agent 上下文记忆（项目全景/规范/模板）
│   └── prompts/          # 提示词模板
│
├── scripts/
│   ├── generators/       # 21 个 ROS2 包生成器
│   ├── validators/       # SKILL 格式验证
│   ├── debugger/         # ros2-debug.sh 8类错误诊断
│   └── ros2-*.sh         # 各类工具脚本
│
└── examples/
    └── mcp-workflow/
        └── cases/        # 12 个完整案例（PLAN+SKILL+VERIFY）
```

## AI Agent 工作流

```
用户需求 → 接口定义(msg/srv/action)
         → 生成 CMakeLists.txt + C++ 代码
         → colcon build 验证
         → 如报错 → 分析错误 → 修正 → 重新生成
```

## LLM 提示词设计原则

1. **强制规则优先** — 告诉 AI 禁止做什么，而不是建议做什么
2. **具体代码模板** — 给出完整可编译的代码片段
3. **验证回路** — 生成代码后必须执行编译验证
4. **错误自动修复** — 编译错误直接告诉 AI 怎么修

## 关键规则

- 所有 ROS2 C++ 节点必须用 `rclcpp::Node::SharedPtr` 而非裸指针
- `ament_target_dependencies` 后必须跟随 `ament_export_dependencies`
- `QoS` 组合必须匹配：sensor 用 `best_effort`，control 用 `reliable`，state 用 `transient_local`
- 生命周期节点必须实现全部 5 个回调：`on_configure / on_activate / on_deactivate / on_cleanup / on_shutdown`
