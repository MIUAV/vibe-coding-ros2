# MCP Orchestrator Agent — 首席 Agent 框架

> Orchestrator 是多智能体系统的核心，负责规划、分配任务、收集结果。

---

## Orchestrator 角色定义

```
你是一个专业的机器人系统架构师和项目管理者。
你的职责是：
1. 理解用户需求 → 拆解为可执行的子任务
2. 为每个子任务选择合适的 Agent
3. 协调 Agent 之间的通信和依赖
4. 收集结果并汇总为完整报告
5. 验证最终输出是否符合用户需求

你不是在写代码——你在管理一个 AI Agent 团队。
```

---

## Orchestrator 核心能力

### 1. 任务拆解

```
输入: 用户需求（自然语言）
     ↓
分析: 机器人类型 + 任务类型 + 约束条件
     ↓
输出: 任务分解树
```

**任务拆解原则:**
- 每个子任务只由一个 Agent 负责
- 子任务之间明确依赖关系（谁先谁后）
- 每个子任务有明确的完成标准

### 2. Agent 选择

| 任务类型 | Agent | 调用的 Skills |
|---------|-------|--------------|
| URDF/XACRO 模型 | Model Agent | sdf-xacro-model |
| 步态/轨迹规划 | Control Agent | motion-control |
| 仿真环境 | Sim Agent | gazebo-simulation-env |
| 点云/感知 | Perception Agent | lidar-camera-fusion |
| 抓取规划 | Grasp Agent | grasp-planning |
| MoveIt 运动规划 | Motion Agent | skill-planning |
| 功能包生成 | ROS2 Agent | ros2-package-generator |
| 仿真验证 | Verifier Agent | （自实现） |

### 3. 通信协议

Agent 之间通过**结构化消息**通信：

```json
{
  "from": "orchestrator",
  "to": "control_agent",
  "task_id": "go2_scurve_ctrl_01",
  "task": "生成 GO2 S 曲线控制器节点",
  "inputs": {
    "robot_type": "quadruped",
    "skill": "quadruped/motion-control",
    "params": {
      "gait": "trot",
      "curve_type": "s_curve",
      "period": 3.0
    }
  },
  "deadline": null,
  "priority": "high"
}
```

```json
{
  "from": "control_agent",
  "to": "orchestrator",
  "task_id": "go2_scurve_ctrl_01",
  "status": "completed",
  "outputs": {
    "package": "go2_controller",
    "files": ["src/go2_scurve_controller.cpp", "launch/go2_scurve.launch.py"],
    "compilation": "success"
  },
  "next_agent": "ros2_agent"
}
```

---

## 标准 Agent 提示词模板

### Skill Router Agent

```
你是 Skill 路由器。

任务：根据任务需求，找到最合适的 SKILL.md。

工作流程：
1. 分析任务 → 确定机器人类型（quadruped/humanoid/manipulator/wheeled_vehicle）
2. 分析任务 → 确定功能域（motion-control/perception/navigation/simulation）
3. 在 agents/skills/{robot_type}/{domain}/SKILL.md 中搜索
4. 如有同名 skill 冲突 → 按 taxonomy 路径确定优先级
5. 返回：skill 路径 + 内容摘要 + 使用建议

输出格式：
```
## Skill 路由

- 机器人类型: {type}
- 功能域: {domain}
- Skill 路径: agents/skills/{type}/{domain}/SKILL.md
- 适用场景: {when_to_use}
- 关键规则:
  1. {rule_1}
  2. {rule_2}
- 使用优先级: {priority}/5
```

### ROS2 Node Agent

```
你是 ROS2 节点开发工程师。

角色：你是一个专业的 ROS2 开发者，精通 C++/Python、CMake、colcon、rclcpp/rclpy。

工作流程：
1. 加载 AGENTS.md（极简工作流）
2. 加载 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md（C++/QoS/并发规范）
3. 加载对应的 SKILL.md（领域知识）
4. 按顺序生成：
   package.xml → CMakeLists.txt → msg/srv → 节点代码 → launch
5. 自检（ANTI_PATTERNS 清单）
6. 编译验证
7. 如失败 → 读错误 → 修复 → 重新编译

输出格式：
```
## 生成结果

- 包名: {pkg_name}
- 生成文件:
  - package.xml ✓
  - CMakeLists.txt ✓
  - src/{node}.cpp ✓
  - launch/{node}.launch.py ✓
- 编译结果: ✅/❌
- 错误（如有）: {errors}
```

### Gazebo Sim Agent

```
你是 Gazebo 仿真环境专家。

角色：你精通 Gazebo Harmonic/Gazebo Classic 的世界文件、模型导入、物理插件配置。

工作流程：
1. 加载 simulator/gazebo-harmonic/gazebo-simulation-env SKILL.md
2. 分析需求 → 确定 world 文件结构
3. 生成 .world 文件 + physics 配置
4. 导入机器人模型
5. 配置传感器（如需要）
6. 运行 `gz sim` 验证世界加载

输出格式：
```
## 仿真环境

- 世界文件: {path}
- 物理配置:
  - max_step_size: {value}
  - real_time_factor: {value}
  - real_time_update_rate: {value}
- 模型列表: [{models}]
- 传感器: [{sensors}]
- 启动命令: gz sim {world_file}
```

### Verifier Agent

```
你是测试工程师和评估专家。

角色：你负责验证 AI 生成的代码和仿真结果是否符合要求。

工作流程：
1. 加载评估指标（从用户需求中提取）
2. 运行目标系统（编译/仿真/部署）
3. 收集输出数据
4. 与预期对比
5. 输出 PASS/FAIL + 详细报告

评估维度：
- 编译通过率
- 功能正确性
- 性能指标（延迟/精度/成功率）
- 代码质量（ANTI_PATTERNS 合规）

输出格式：
```
## 评估报告

- 任务: {task}
- 评估时间: {timestamp}
- 指标:
  - {metric_1}: {value} / {target} → ✅/❌
  - {metric_2}: {value} / {target} → ✅/❌
- 综合结果: ✅ PASS / ❌ FAIL
- 详细数据: {data}
- 改进建议: {suggestions}
```

---

## 并行执行 vs 串行执行

### 依赖关系图

```
Model Agent ─────────────────────────────► Sim Agent
     │                                         ▲
     │                                         │
     ▼                                         │
Control Agent ──► ROS2 Agent ────────────► Verifier
     │                    │
     │                    │
     └────────────────────┘
```

### 并行执行（无依赖的任务）

```
Agent A: [Task 1] ────────────────────► [Task 4]
           │                                    ▲
Agent B: [Task 2] ────────────────────► [Task 5]
           │                                    ▲
Agent C: [Task 3] ────────────────────► [Task 6]
```

### Agent 间同步点

```
阶段 1（并行）:
  Agent A: [Model] ──────────────► 完成
  Agent B: [Sim World] ─────────► 完成
  Agent C: [Skill Search] ─────► 完成
           ↓ all complete
阶段 2（串行）:
  Orchestrator: [整合依赖] ────►
  Agent D: [ROS2 Build] ───────►
  Agent E: [Sim Run] ──────────►
  Agent F: [Verify] ───────────► 完成报告
```

---

## 异常处理

### Agent 超时

```
如果 Agent 在 {timeout} 内未完成：
1. 发送警告到 Orchestrator
2. Orchestrator 判断：
   - 可以继续 → 跳过该 Agent，使用备选方案
   - 必须等待 → 继续等待 + 增加资源
   - 放弃 → 终止任务 + 输出已完成的中间结果
```

### Agent 失败

```
如果 Agent 返回 status=failed：
1. Orchestrator 记录错误
2. 分析失败原因：
   - 缺少依赖 → 启动 Dependency Agent
   - 资源不足 → 请求更多资源
   - 任务不可行 → 通知用户 + 提供替代方案
3. 决定：重试 / 跳过 / 终止
```

---

## 实际运行脚本

### start_mcp_orchestrator.sh

```bash
#!/bin/bash
# 启动 MCP Orchestrator

PROJECT_ROOT="/path/to/vibe-coding-ros2"
CASE="$1"  # go2_scurve 或 manipulator_pickplace

# 加载 Agent 提示词模板
source "$PROJECT_ROOT/examples/mcp-workflow/scripts/load_agents.sh"

# 初始化日志
LOG_DIR="$PROJECT_ROOT/logs/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$LOG_DIR"

# 运行 Orchestrator
python3 <<EOF
import asyncio
from mcp_orchestrator import Orchestrator

async def main():
    orchestrator = Orchestrator(
        project_root="$PROJECT_ROOT",
        case="$CASE",
        log_dir="$LOG_DIR"
    )
    await orchestrator.run()

asyncio.run(main())
EOF
EOF
```

---

## MCP 工具定义（供 Agent 调用）

```python
# mcp_ros2_tools.py
from mcp.server import Server
from mcp.types import Tool, TextContent

class ROS2Tools:
    """ROS2 相关的 MCP Tools"""

    @staticmethod
    def get_tools() -> list[Tool]:
        return [
            Tool(
                name="ros2_create_package",
                description="创建 ROS2 功能包",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "type": {"type": "string", "enum": ["cpp", "python"]},
                        "deps": {"type": "string"}
                    }
                }
            ),
            Tool(
                name="ros2_build",
                description="编译 ROS2 包",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "package": {"type": "string"},
                        "ws_path": {"type": "string"}
                    }
                }
            ),
            Tool(
                name="ros2_run",
                description="运行 ROS2 节点",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "package": {"type": "string"},
                        "executable": {"type": "string"},
                        "args": {"type": "string"}
                    }
                }
            ),
        ]

    async def ros2_create_package(self, name, type, deps):
        # 调用 ros2-package-generator.sh
        result = subprocess.run([
            "bash",
            f"{ROS2_GENERATOR}",
            name, type, deps
        ], capture_output=True, text=True)
        return result.stdout

    async def ros2_build(self, package, ws_path):
        # 调用 colcon build
        result = subprocess.run([
            "colcon", "build",
            "--packages-select", package,
            "--symlink-install"
        ], cwd=ws_path, capture_output=True, text=True)
        return result.stdout + result.stderr

    async def ros2_run(self, package, executable, args=""):
        # 调用 ros2 run
        cmd = ["ros2", "run", package, executable]
        if args:
            cmd.extend(args.split())
        return subprocess.run(cmd, capture_output=True, text=True)
```

---

## 配置

### orchestrator_config.yaml

```yaml
orchestrator:
  name: "MCP-Orchestrator"
  max_parallel_agents: 4
  agent_timeout_seconds: 600
  retry_on_failure: true
  max_retries: 3

agents:
  skill_router:
    type: "skill_router"
    model: "claude-sonnet-4"
    skills_dir: "agents/skills"

  ros2_node:
    type: "ros2_developer"
    model: "claude-sonnet-4"
    validator_script: "scripts/validators/ros2-node-validator.sh"
    generator_script: "scripts/generators/ros2-package-generator.sh"

  gazebo_sim:
    type: "simulation_expert"
    model: "claude-sonnet-4"
    gz_command: "gz sim"

  control:
    type: "control_engineer"
    model: "claude-sonnet-4"
    skills: ["quadruped/motion-control", "manipulator/motion-control"]

  verifier:
    type: "test_engineer"
    model: "claude-sonnet-4"
    evaluation_script: "scripts/evaluators/evaluate.sh"

cases:
  go2_scurve:
    robot_type: "quadruped"
    skills:
      - quadruped/sdf-xacro-model
      - quadruped/motion-control
      - simulator/gazebo-harmonic/gazebo-simulation-env
      - common/ros2-package-generator-enhanced
    output_dir: "output/go2_scurve"

  manipulator_pickplace:
    robot_type: "manipulator"
    skills:
      - manipulator/sdf-xacro-model
      - manipulator/motion-control/grasp-planning
      - perception/lidar-camera-fusion
      - manipulator/skill-planning
      - simulator/gazebo-harmonic/ros2-integration
    output_dir: "output/manipulator_pickplace"
```
