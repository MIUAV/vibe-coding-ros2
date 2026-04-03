# ROS2 Examples

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
