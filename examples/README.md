# Examples — 案例索引

> 每个案例包含 `PLAN.md` + `SKILL.md` + `VERIFY.md`，说明如何用工具链生成对应的 ROS2 代码。

---

## 案例目录

| 案例 | 类型 | 描述 |
|------|------|------|
| `mcp-workflow/cases/lifecycle-node-demo/` | 节点 | 生产级 LifecycleNode 生成流程 |
| `mcp-workflow/cases/action-fibonacci-demo/` | Action | ROS2 Action Server 生成流程 |
| `mcp-workflow/cases/wheeled-nav2/` | 导航 | 轮式机器人 Nav2 导航 |
| `mcp-workflow/cases/drone-exploration/` | 导航 | 无人机自主探索 |
| `mcp-workflow/cases/go2-scurve/` | 控制 | 四足机器人 S 曲线轨迹 |
| `mcp-workflow/cases/manipulator-pickplace/` | 机械臂 | 机械臂抓取任务 |
| `mcp-workflow/cases/multi-robot-swarm/` | 协同 | 多机器人编队 |
| `mcp-workflow/cases/industrial-integration/` | 集成 | 工业机器人集成 |
| `mcp-workflow/cases/aerial-photography/` | 应用 | 航测摄影 |

## 快速开始

每个案例结构一致：

```
cases/<name>/
├── PLAN.md     # 工具链使用步骤 + 生成的代码
├── SKILL.md     # 关键技术点 + 规范
└── VERIFY.md    # 验证步骤 + 预期结果
```

按以下顺序使用：

```bash
# 1. 阅读 PLAN.md，按步骤执行
# 2. 生成包骨架
bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp <deps> --verify

# 3. 按 PLAN.md 生成代码
# 4. 按 VERIFY.md 验证
bash scripts/ros2-build-verify-loop.sh <pkg_name>

# 5. 运行测试
ros2 run <pkg_name> <node_name>
```

## 案例贡献指南

新增案例需包含：
- `PLAN.md`：使用工具链的完整步骤，代码块可直接复制
- `SKILL.md`：核心技术点，规范和常见错误
- `VERIFY.md`：编译/运行验证命令，预期输出表格
