# ROS2 Examples

> 所有示例均可 `colcon build --packages-select <pkg> --symlink-install` 编译

## 目录

```
examples/
├── mcp-workflow/           # 多智能体自主开发（重点）
│   ├── MCP_WORKFLOW.md    # 架构 + 快速启动
│   ├── MCP_ORCHESTRATOR.md # 编排器使用
│   └── cases/
│       ├── go2-scurve/     # 四足S曲线轨迹
│       └── manipulator-pickplace/  # 机械臂抓取
├── memory-bank-example/    # ROS2 Memory Bank 架构
└── ros2-wheeled/           # 轮式机器人
    └── diff_drive_controller/  # 差速驱动控制器
```

## 多智能体工作流

### 🚀 快速启动

前置要求：
```bash
# 安装 Claude Code CLI（推荐）
npm install -g @anthropic-ai/claude-code

# 或安装 OpenAI Codex CLI
npm install -g @openai/codex
```

一键启动：
```bash
cd /path/to/vibe-coding-ros2

# 案例一：宇树 GO2 机器狗 S 曲线
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude

# 案例二：机械臂自主抓取
./scripts/mcp/mcp-agent-orchestrator.sh manipulator-pickplace --agent claude

# 自定义任务（交互式）
./scripts/mcp/mcp-agent-orchestrator.sh custom --agent claude
```

### 环境变量

```bash
# 指定模型
AGENT_MODEL=claude-opus-4 ./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude

# 指定超时（秒）
AGENT_TIMEOUT=600 ./scripts/mcp/mcp-agent-orchestrator.sh manipulator-pickplace --agent claude
```

详见 [MCP_WORKFLOW.md](mcp-workflow/MCP_WORKFLOW.md)

## 轮式机器人

### diff_drive_controller

差速驱动：`/cmd_vel` → 左右轮速 + 里程计 + TF

```bash
colcon build --packages-select diff_drive_controller --symlink-install
ros2 run diff_drive_controller diff_drive_controller
```

规范：SharedPtr / MultiThreadedExecutor + Mutex / QoS reliable

差速驱动数学：v_l = v − ω·W/2，v_r = v + ω·W/2

## 基础示例

| 示例 | 内容 | 规范 |
|------|------|------|
| cpp_publisher | C++ 发布者 + QoS + wall_timer | SharedPtr, QoS reliable |
| py_subscriber | Python 订阅者 + rclpy 规范 | rclpy shutdown |
| lifecycle_sensor | Lifecycle 节点（状态机） | Lifecycle 状态机 |
| add_two_ints | Service + Client + 超时保护 | wait_for() 超时 |

详情见各子目录 README。
