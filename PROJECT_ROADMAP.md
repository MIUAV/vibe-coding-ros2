# PROJECT_ROADMAP — Vibe-Coding-ROS2

> 项目路线图。v0.x 阶段目标：成为 ROS2 Vibe Coding 的标准工具链。

---

## 当前版本: v0.1.x

### 已完成 ✅

**工具链（Toolchain）**
- `ros2-package-generator` — 标准包生成（cpp/python/mixed）+ `--verify` 标志
- `ros2-interface-generator` — msg/srv/action 接口包生成
- `ros2-msg-generator` — 交互式 CLI 向导生成 .msg 文件
- `ros2-launch-generator` — launch.py 生成（lifecycle/normal/component）
- `ros2-cpp-node` — C++ 节点骨架生成
- `ros2-build-verify-loop` — 编译验证 + LLM 修复闭环
- `ros2-build-feedback` — 编译错误解释 + 修复建议
- `ros2-debug` — 8类 ROS2 错误自动诊断
- `ros2-format` — clang-format 格式化
- `ros2-cmake-fix` — CMake 依赖问题诊断
- `ros2-performance-monitor` — 运行时性能监控钩子
- `ros2-bag-tool` — Bag 日志分析（录制信息 + 频率分析 + 错误检测）
- `ros2-param-wizard` — 参数声明验证 + YAML 生成向导

**示例包（Examples — 纯文档）**
- 12 个案例全部包含 PLAN.md + SKILL.md + VERIFY.md
- 不在 examples/ 目录存放 C++ 代码（案例为文档化流程）

**CI/CD**
- `ros2-ci.yml` — Matrix build（humble/iron/jazzy）+ clang-format + ament_lint

**文档（Docs）**
- CLAUDE.md / SOUL.md / SYSTEM.md — AI Agent 核心规则
- AI-Generated-ROS2-Anti-Patterns.md — 8类错误反模式
- TDD-for-ROS2.md — 测试驱动开发流程
- LLM-Model-Selection.md — 模型选择指导

---

## v0.2.x 目标（下一个冲刺）

### 🔧 工具链增强

| 功能 | 描述 | 状态 |
|------|------|--------|
| `ros2-srv-generator` | 交互式 .srv / .action 生成向导 | TODO |
| `ros2-param-wizard` | 参数声明验证 + YAML 生成 | ✅ |
| `ros2-bag-analyzer` | ros2 bag 日志分析脚本（错误聚合） | ✅ |

### 📦 案例包

| 案例 | 状态 |
|------|------|
| wheeled-nav2 | ✅ PLAN+SKILL+VERIFY |
| drone-exploration | ✅ PLAN+SKILL+VERIFY |
| go2-scurve | ✅ PLAN+SKILL+VERIFY |
| manipulator-pickplace | ✅ PLAN+SKILL+VERIFY |
| multi-robot-swarm | ✅ PLAN+SKILL+VERIFY |
| underwater-nav | ✅ PLAN+SKILL+VERIFY |
| industrial-integration | ✅ PLAN+SKILL+VERIFY |
| aerial-photography | ✅ PLAN+SKILL+VERIFY |
| sensor-fusion-locate | ✅ PLAN+SKILL+VERIFY |
| biped-walk | ✅ PLAN+SKILL+VERIFY |
| lifecycle-node-demo | ✅ PLAN+SKILL+VERIFY |
| action-fibonacci-demo | ✅ PLAN+SKILL+VERIFY |

### 🧪 测试覆盖

- 所有 scripts/ 有 bash -n 语法验证 ✅
- 单元测试：C++ GoogleTest 模板（`test-templates/`）
- CI 脚本语法验证 ✅

---

## v0.3.x 目标

### AI 集成层

| 功能 | 描述 |
|------|------|
| **MCP Server** | 提供 ROS2 工具的 MCP 协议接口 |
| **LLM Context Injector** | 自动注入 ROS2 编译上下文给 LLM |
| **Auto-Fix Pipeline** | colcon build error → LLM fix → verify → PR |

### 知识库增强

- `agents/skills/ros2-nav2/` — Nav2 行为树 + 规划器 SKILL
- `agents/skills/ros2-control/` — ros2_control + 硬件接口 SKILL
- `agents/skills/ros2-moveit/` — MoveIt2 运动规划 SKILL

---

## v1.0 目标

**愿景：输入自然语言描述 → 输出可编译的 ROS2 包**

```
用户: "帮我生成一个订阅 /scan 激光雷达，检测到障碍物时停车的节点"
AI Agent:
  1. 调用 ros2-package-generator 创建包
  2. 调用 ros2-msg-generator 定义消息格式
  3. 生成节点代码
  4. 调用 ros2-build-verify-loop 验证
  5. 通过 → 完成
```

**里程碑：**
- 用户无需修改生成的代码即可编译运行
- CI/CD 通过率 > 95%
- 至少 3 个真实机器人项目使用本工具链开发

---

## 版本历史

| 版本 | 日期 | 主要内容 |
|------|------|---------|
| v0.1.x | 2026-04 | 工具链完善 + CI 升级 + 案例文档化 |
| v0.1.0 | 2026-04 | 初始版本：工具链 + CI + 示例包 |
| v0.0.x | 2026-03 | 实验阶段 |
