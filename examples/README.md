# ROS2 Examples — 实战示例目录

> 所有示例均可通过 `colcon build --packages-select <pkg> --symlink-install` 编译

---

## 目录结构

```
examples/
├── mcp-workflow/              # 🤖 MCP 多智能体自主开发（重点！）
│   ├── MCP_WORKFLOW.md         # MCP 架构 + 多 Agent 工具定义
│   ├── MCP_ORCHESTRATOR.md     # Orchestrator Agent 框架 + 模板
│   └── cases/
│       ├── go2-scurve/         # 案例一：宇树 GO2 机器狗 S 曲线
│       └── manipulator-pickplace/ # 案例二：机械臂自主抓取
│
├── ros2-minimal/               # 基础示例
│   ├── cpp_publisher/          # C++ 发布者
│   └── py_subscriber/          # Python 订阅者
│
├── ros2-lifecycle/            # Lifecycle 节点
│   └── lifecycle_sensor/
│
└── ros2-service/              # Service 示例
    └── add_two_ints/
```

---

## 🤖 MCP 多智能体工作流（重点）

> 使用 MCP 一键驱动 Claude Code / Codex / Copilot 等 Agent，自主完成完整的机器人开发任务。

### 前置要求

```bash
# 安装 Claude Code CLI（推荐）
# https://docs.anthropic.com/en/docs/claude-code/overview

# 或安装 OpenAI Codex CLI
# npm install -g @openai/codex

# 或安装 GitHub Copilot CLI
# gh extension install github/gh-copilot
```

### 快速启动

```bash
cd /path/to/vibe-coding-ros2

# 方式 1：一键启动（推荐）
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude

# 方式 2：指定模型
AGENT_MODEL=claude-opus-4-20250514 ./scripts/mcp/mcp-agent-orchestrator.sh manipulator-pickplace --agent claude

# 方式 3：交互式自定义任务
./scripts/mcp/mcp-agent-orchestrator.sh custom --agent claude
```

### 支持的 Agent

| Agent | CLI | 说明 |
|-------|-----|------|
| `claude` | Claude Code 官方 CLI | ⭐ 推荐，支持多轮对话 |
| `codex` | OpenAI Codex CLI | 代码生成能力强 |
| `copilot` | GitHub Copilot CLI | 与 GitHub 深度集成 |
| `copilot-chat` | VS Code Copilot Chat | 需手动在 VS Code 中执行 |

### 案例一：宇树 GO2 机器狗 S 曲线

```bash
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude
```

**涉及的 Skills：**
- `quadruped/sdf-xacro-model` — GO2 URDF/XACRO
- `quadruped/motion-control` — S 曲线轨迹 + Trot 步态
- `simulator/gazebo-harmonic/gazebo-simulation-env` — Gazebo 世界
- `common/ros2-package-generator-enhanced` — ROS2 包生成

**输出：** 完整的 `go2_controller` + `go2_description` + Gazebo world

### 案例二：机械臂自主抓取

```bash
./scripts/mcp/mcp-agent-orchestrator.sh manipulator-pickplace --agent claude
```

**涉及的 Skills：**
- `manipulator/sdf-xacro-model` — 机械臂 URDF
- `manipulator/motion-control/grasp-planning` — 抓取规划
- `manipulator/motion-control/impedance-control` — 力控夹爪
- `perception/lidar-camera-fusion` — 点云感知
- `manipulator/skill-planning` — MoveIt2 运动规划

**输出：** 完整的 MoveIt2 + 点云感知 + 力控抓取系统

### 自定义任务

```bash
./scripts/mcp/mcp-agent-orchestrator.sh custom --agent claude
# 交互式输入任务描述和机器人类型
```

---

## 📦 基础 ROS2 示例

### 快速运行

```bash
# 构建所有示例
colcon build \
  --packages-select cpp_publisher py_subscriber lifecycle_sensor add_two_ints \
  --symlink-install

# 运行发布者 + 订阅者
ros2 run cpp_publisher minimal_publisher      # 终端1
ros2 run py_subscriber py_subscriber          # 终端2

# 查看话题
ros2 topic list
ros2 topic echo /chatter
```

### Lifecycle 节点

```bash
ros2 run lifecycle_sensor lifecycle_sensor     # 终端1
ros2 lifecycle list /lifecycle_sensor        # 查看状态
ros2 lifecycle set /lifecycle_sensor configure
ros2 lifecycle set /lifecycle_sensor activate
```

### Service 调用

```bash
ros2 run add_two_ints add_two_ints_server   # 终端1
ros2 run add_two_ints add_two_ints_client   # 终端2
```

---

## ✅ 示例规范遵循

| 示例 | SharedPtr | QoS | Lifecycle | 超时保护 | rclpy shutdown |
|------|:---------:|:---:|:---------:|:---------:|:---------------:|
| cpp_publisher | ✅ | ✅ | — | — | — |
| py_subscriber | — | ✅ | — | — | ✅ |
| lifecycle_sensor | ✅ | ✅ | ✅ | — | — |
| add_two_ints | ✅ | — | — | ✅ | — |

---

## 🔧 MCP 工具链

```bash
scripts/mcp/
└── mcp-agent-orchestrator.sh   # 一键启动多 Agent 协作
```

环境变量：

```bash
AGENT=claude                          # Agent 类型
AGENT_MODEL=claude-sonnet-4-20250514  # 模型
AGENT_TIMEOUT=300                     # 超时秒数
WORKSPACE=~/ros2_ws                  # 开发工作区
```
