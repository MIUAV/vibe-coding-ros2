# Examples — 复杂任务工作流案例库

> 所有复杂机器人任务案例已移至 `mcp-workflow/cases/`。

## 结构

```
examples/
├── mcp-workflow/         ← MCP 多智能体框架
│   ├── cases/            ← 10 个复杂任务案例
│   │   ├── go2-scurve/
│   │   ├── manipulator-pickplace/
│   │   ├── drone-exploration/
│   │   ├── wheeled-nav2/
│   │   ├── multi-robot-swarm/
│   │   ├── biped-walk/
│   │   ├── underwater-nav/
│   │   ├── sensor-fusion-locate/
│   │   ├── aerial-photography/
│   │   └── industrial-integration/
│   ├── MCP_WORKFLOW.md   ← 框架说明
│   └── MCP_ORCHESTRATOR.md ← 编排脚本
└── memory-bank-example/  ← 项目记忆库模板
```

## 案例列表

| Case | 机器人 | 任务 |
|------|--------|------|
| `go2-scurve/` | 四足 | S 曲线轨迹 |
| `manipulator-pickplace/` | 机械臂 | 抓取放置 |
| `drone-exploration/` | 无人机 | 自主探索 |
| `wheeled-nav2/` | 轮式 | Nav2 导航 |
| `multi-robot-swarm/` | 多机 | 蜂群协同 |
| `biped-walk/` | 双足 | 步行控制 |
| `underwater-nav/` | AUV | 水下导航 |
| `sensor-fusion-locate/` | 通用 | 传感器融合定位 |
| `aerial-photography/` | 无人机 | 航拍任务 |
| `industrial-integration/` | 工业 | ROS2-PLC 集成 |

## 快速开始

```bash
# 查看案例计划
cat examples/mcp-workflow/cases/go2-scurve/PLAN.md

# 运行 MCP 编排
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude
```
