# AGENTS.md

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
├── SOUL.md              # 项目定位
├── SYSTEM.md            # AI Agent 系统指令
├── AGENTS.md            # 本文件
├── PROJECT_ROADMAP.md   # 技术路线图
├── CRITICAL_ISSUES.md   # 关键问题追踪
├── ARCHITECTURE_REPORT.md # 架构健康报告
├── examples/
│   ├── rclcpp-minimal/  # 真实可编译的 C++ 节点
│   ├── mcp-workflow/    # MCP 多智能体工作流
│   └── memory-bank-example/
├── agents/
│   ├── prompts/          # 提示词模板
│   ├── skills/           # 技能定义（强制规则）
│   └── documents/        # 开发文档
├── scripts/
│   ├── mcp/              # MCP 集成
│   ├── generators/        # ROS2 包生成器
│   ├── translators/      # 多语言翻译
│   └── validators/       # SKILL 验证器
└── i18n/                # 多语言文档
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
