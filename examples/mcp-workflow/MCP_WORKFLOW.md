# MCP 多智能体自主开发流程

> 使用 MCP (Model Context Protocol) 连接 AI Agent 与真实 ROS2/Gazebo 环境，让多个 AI Agent 协作完成完整的机器人开发任务。

---

## 架构

```
┌─────────────────────────────────────────────────────────┐
│                    Orchestrator Agent                   │
│         (首席 Agent，负责规划 + 分配 + 汇总)              │
└────────────────────┬────────────────────────────────────┘
                     │ MCP Tool Calls
          ┌──────────┼──────────┬─────────────┐
          │          │          │             │
    ┌─────▼────┐ ┌──▼────┐ ┌─▼──────┐ ┌──▼─────┐
    │  Skill   │ │ ROS2  │ │ Gazebo │ │ Deploy │
    │  Router  │ │ Node  │ │  Env   │ │  Agent │
    │  Agent   │ │ Agent │ │ Agent  │ │        │
    └──────────┘ └───────┘ └────────┘ └────────┘
         ↓           ↓          ↓          ↓
    agents/skills  colcon    gz sim   ssh/scp
                   build
```

---

## MCP Tools (Agent 可调用的工具)

### Skill Router Agent

```
skill_router.search(robot_type, task_type) → SKILL.md path
skill_router.list_skills(robot_type) → skill list
skill_router.validate_skill(skill_path) → verified/draft/concept
```

### ROS2 Node Agent

```
ros2.create_package(name, type, deps) → package created
ros2.generate_cpp_node(package, topic, msg_type, qos) → .cpp file
ros2.generate_launch(package, nodes) → .launch.py
ros2.build(package) → success/fail + error output
ros2.run(node, params) → process started
ros2.topic_echo(topic) → message stream
ros2.topic_list() → active topics
ros2.param_get(node, param) → value
ros2.param_set(node, param, value) → success
```

### Gazebo Environment Agent

```
gazebo.create_world(world_file, config) → .world file
gazebo.spawn_model(model_name, urdf, pose) → model spawned
gazebo.set_model_state(model, pose, twist) → state set
gazebo.create_trajectory(model, waypoints, duration) → trajectory executed
gazebo.record_trajectory(model, trajectory) → bag file saved
gazebo.reset_world() → world reset
```

### Deploy Agent

```
deploy.ssh_exec(host, command) → output
deploy.scp_upload(local_file, remote_path) → success
deploy.ssh_tunnel(local_port, remote_port, host) → tunnel active
deploy.install_deps(host, ros_distro) → deps installed
```

---

## 标准工作流

### Phase 1: 规划 (Orchestrator)

```
Orchestrator:
  1. 读取 AGENTS_CONCISE.md
  2. 读取 ANTI_PATTERNS.md
  3. 分析用户需求 → 拆解为子任务
  4. 为每个子任务分配专业 Agent
  5. 收集结果并汇总
  6. 输出完整报告
```

### Phase 2: Skill 路由 (Skill Router)

```
Skill Router:
  1. 确定机器人类型 → quadruped / humanoid / manipulator / wheeled_vehicle
  2. 确定任务类型 → motion-control / perception / navigation / sim
  3. 搜索对应 SKILL.md → 返回路径 + 内容摘要
  4. 如有同名 skill 冲突 → 按 taxonomy 路径确定优先级
  5. 返回技能清单及使用顺序
```

### Phase 3: 代码生成 (ROS2 Node Agent)

```
ROS2 Node Agent:
  1. 加载 SKILL.md 获取领域知识
  2. 按 AGENTS_CONCISE.md 顺序生成:
     package.xml → CMakeLists.txt → msg/srv → 节点代码 → launch
  3. 运行 ros2-node-validator.sh 自检
  4. colcon build 编译验证
  5. 如编译失败 → 读错误输出 → 修复 → 重新编译
  6. 返回编译成功的包路径
```

### Phase 4: 仿真验证 (Gazebo Agent)

```
Gazebo Agent:
  1. 加载 gazebo-simulation-env SKILL.md
  2. 创建/配置 .world 文件
  3. 加载机器人 URDF/XACRO 模型
  4. spawn 到 Gazebo 仿真环境
  5. 运行目标任务（走S曲线/抓取/导航）
  6. 记录数据
  7. 评估结果 → PASS/FAIL
```

### Phase 5: 部署 (Deploy Agent)

```
Deploy Agent:
  1. 打包工作区（install/ + src/）
  2. scp 到目标机器
  3. ssh 安装依赖（rosdep install）
  4. 远程编译
  5. 验证运行
```

---

## 输出格式

每个任务完成后，Orchestrator 输出：

```markdown
# 开发报告

## 任务
描述

## 执行流程

### Phase 1: 规划
- 拆解: [子任务列表]

### Phase 2: Skill 路由
- 使用技能: [skill路径]

### Phase 3: 代码生成
- 生成包: [路径]
- 编译结果: ✅/❌

### Phase 4: 仿真验证
- Gazebo 世界: [路径]
- 仿真结果: ✅/❌

### Phase 5: 部署
- 部署目标: [host]
- 运行结果: ✅/❌

## 完整代码清单
- [文件路径]: [说明]
```

---

## 配置要求

### MCP Server 配置

```json
// mcp.json（在用户的 VS Code / Cursor 中）
{
  "mcpServers": {
    "skill-router": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/vibe-coding-ros2/agents/skills"]
    },
    "ros2": {
      "command": "python3",
      "args": ["/path/to/mcp-ros2-server.py"]
    },
    "gazebo": {
      "command": "python3",
      "args": ["/path/to/mcp-gazebo-server.py"]
    }
  }
}
```

### 环境要求

- ROS2 Humble + Gazebo Harmonic（对于宇树 GO2）
- 或 ROS2 Humble + Gazebo Classic（对于早期版本）
- colcon + rosdep 已安装
- SSH 访问目标机器人（如需部署）

---

## 案例入口

| 案例 | 路径 |
|------|------|
| 宇树 GO2 机器狗 S 曲线 | `cases/go2-scurve/README.md` |
| 机械臂自主抓取 | `cases/manipulator-pickplace/README.md` |
