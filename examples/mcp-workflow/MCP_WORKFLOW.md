# MCP Workflow — 多智能体协作示例

## 概述

MCP (Model Context Protocol) 工作流通过多个专业化 AI Agent 协作完成复杂 ROS2 开发任务。

## 架构

```
用户需求
    │
    ▼
┌─────────────────────┐
│  Orchestrator Agent │  ← 主编排智能体，理解任务并分派
└─────────────────────┘
    │
    ├──────────────────┬──────────────────┐
    ▼                  ▼                  ▼
┌─────────┐    ┌─────────────┐    ┌────────────┐
│ MCP-SIM │    │ MCP-BUILD  │    │ MCP-DEBUG │
│ 仿真验证 │    │ 编译反馈    │    │ 调试诊断   │
└─────────┘    └─────────────┘    └────────────┘
    │                  │                  │
    └──────────────────┴──────────────────┘
                        │
                        ▼
               修正后的代码输出
```

## 启用 MCP Server

```bash
# 启动 ROS2 MCP Server
cd ~/vibe-coding-ros2
./scripts/mcp/ros-mcp-integration.sh

# 验证连接（在新终端）
./scripts/mcp/ros-mcp-integration.sh --verify
```

## Case 列表

所有复杂任务案例位于 `mcp-workflow/cases/` 目录：

| Case | 机器人类型 | 任务 |
|------|-----------|------|
| `go2-scurve/` | 四足 | S 曲线轨迹规划 |
| `manipulator-pickplace/` | 机械臂 | 抓取放置 |
| `drone-exploration/` | 无人机 | 自主探索 |
| `wheeled-nav2/` | 轮式 | Nav2 自主导航 |
| `multi-robot-swarm/` | 多机器人 | 蜂群协同 |
| `biped-walk/` | 双足 | 步行控制 |
| `underwater-nav/` | AUV | 水下导航 |
| `sensor-fusion-locate/` | 通用 | 多传感器融合定位 |
| `aerial-photography/` | 无人机 | 航拍任务 |
| `industrial-integration/` | 工业 | ROS2-PLC 集成 |

## Case 结构

每个 case 目录包含：

```
cases/<name>/
├── SKILL.md     # 任务描述 + 约束参数 + 引用 agents/skills/
├── PLAN.md      # Phase 分阶段计划 + MCP 调用
└── VERIFY.md   # 量化通过/失败标准
```

## 使用方式

```bash
# 运行指定 case
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude

# 或手动阅读 case 文档
cat mcp-workflow/cases/go2-scurve/PLAN.md
```

## Case 1: go2-scurve — 足式机器人轨迹规划

### Phase 0: 需求理解 + 环境检查

**输入:** "让 go2 机器人走 S 曲线"

**Orchestrator 分派:**
1. `MCP-SIM`: 查询当前机器人状态 (`ros2 topic list`)
2. `MCP-BUILD`: 检查是否有 `go2_scurve` 包

```bash
# 期望的 MCP 调用
mcp__ros2__topic_list
mcp__ros2__pkg_list
mcp__ros2__node_info /go2_state_estimation
```

### Phase 1: 接口定义

**MCP-SIM** 提供 URDF/状态反馈:
- 当前关节角度
- 足端力传感器读数
- 地形信息（如果有）

**生成:**
```cpp
// S曲线轨迹接口
geometry_msgs/msg/TrajectoryPoint[]  // 路径点序列
std_msgs/msg/Float64MultiArray       // 关节角度目标
```

### Phase 2: 代码生成

**MCP-BUILD** 反馈:
- CMakeLists.txt 依赖检查
- 编译错误实时修正
- 最多 3 轮重试

### Phase 3: 仿真验证

**MCP-SIM**:
- Gazebo 仿真启动
- 轨迹执行监控
- 成功/失败判定

---

## Agent 提示词模板

### Orchestrator

```
你是一个 ROS2 机器人任务编排专家。

任务：{user_task}

请按以下步骤执行：
1. 理解任务并分解为子任务
2. 确定需要的 Agent 类型（MCP-SIM / MCP-BUILD / MCP-DEBUG）
3. 定义 Agent 之间的消息传递格式
4. 监控执行结果，失败时重新规划

输出格式：
## 任务分解
1. [Agent类型] 子任务描述

## 接口定义
```yaml
# 需要的 msg/srv/action 接口
```

## 执行计划
1. Phase N: [Agent] — 做什么
```

### MCP-BUILD

```
你是 ROS2 编译专家。当给你 ROS2 包源码时：
1. 分析 CMakeLists.txt 的依赖完整性
2. 如果缺少 ament_export_dependencies，标记并修复
3. 执行 colcon build，捕获错误
4. 如果有编译错误，给出精确修复建议
5. 最多重试 3 轮，第 3 轮仍失败则报告"无法编译"

输出格式：
## 依赖检查
✅ 完整 / ❌ 缺失: [具体依赖]

## 编译结果
✅ 成功（0 错误）/ ❌ 失败

## 错误修复（如有）
[具体修复命令或代码片段]
```

## 故障排查

### MCP Server 连接失败

```bash
# 检查 ROS2 环境
ros2 env | grep ROS_DISTRO

# 检查 MCP server 进程
ps aux | grep ros-mcp

# 重启 MCP server
./scripts/mcp/ros-mcp-integration.sh --restart
```

### Agent 通信超时

增加超时配置：
```bash
export MCP_TIMEOUT=60  # 秒
```
