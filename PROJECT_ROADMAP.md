# Vibe-Coding-ROS2 项目路线图

> 更新时间：2026-04-04
> 依据：技术评审 2026-04-04（评分 1.8/10）

---

## 完成进度（2026-04-04）

| 类别 | 完成 | 总计 | 百分比 |
|------|------|------|--------|
| P0-1 MCP集成 | 0 | 3 | 0% |
| P0-2 反馈回路 | 0 | 2 | 0% |
| P0-3 404文件 | 5 | 5 | **100%** ✅ |
| P0-4 生成器 | 0 | 4 | 0% |
| P1-1 CMake规则 | 1 | 2 | 50% |
| P1-2 调试技能 | 1 | 3 | 33% |
| P1-3 Nav2知识库 | 0 | 1 | 0% |

---

## 现状定位

| 维度 | 评分 | 说明 |
|------|------|------|
| 代码可执行性 | 1/10 | 大量 404 文件，无可执行内容 |
| System Prompt 质量 | 3/10 | 有框架但缺 ROS2 专属规则 |
| LLM 通点覆盖 | 2/10 | 避开了所有硬骨头（QoS/Lifecycle/CMAKE） |
| 实用工具链 | 1/10 | 零工具、零 CI、零验证 |
| 文档完整性 | 5/10 | 框架全但落地内容残缺 |

---

## P0 — 必须立即解决（1-2周）

### P0-1：ros-mcp-server 集成
**问题**：AI 看不到真实 ROS2 运行时，只能对着静态 markdown 盲目生成。

**目标**：让 AI Agent 能通过 MCP 协议执行 `ros2 topic list`、`ros2 pkg list`、`colcon build` 等。

**交付物**：
- [x] `scripts/mcp/ros-mcp-integration.sh` — 一键启动 MCP server（TODO: 待实现）
- [ ] 更新 `examples/mcp-workflow/MCP_WORKFLOW.md` 说明启用方法
- [ ] 在 go2-scurve case Phase 0 加入 MCP 连接验证

**参考**：https://github.com/robotmcp/ros-mcp-server

---

### P0-2：colcon build 反馈回路
**问题**：AI 不知道代码对不对，没有验证机制。

**目标**：AI 生成代码后自动执行 `colcon build`，捕获错误并反馈修正。

**交付物**：
- [x] `scripts/ros2-build-feedback.sh` — 捕获编译错误，提取关键缺失依赖（TODO: 待实现）
- [ ] `scripts/mcp/mcp-agent-orchestrator.sh` — 加入编译验证循环（最多重试 3 次）

---

### P0-3：404 文件填充
**问题**：大量声明存在但内容为空的 404 文件。

**交付物**：以下文件必须创建真实可用内容：
- [x] `agents/prompts/coding_prompts/(3,1)_ros2_node_implementation.md` — 节点实现完整提示词
- [x] `agents/prompts/user_prompts/ros2-common-prompts.md` — 常用开发提示词模板
- [x] `agents/documents/Methodology_and_Principles/development-experience.md` — 开发经验总结
- [x] `agents/documents/Tutorials_and_Guides/ros2-debug-guide.md` — 调试完整指南
- [x] `agents/documents/Tutorials_and_Guides/docker-setup-guide.md` — Docker 环境配置

---

### P0-4：ros2-package-generator 可执行化
**问题**：只是 markdown 模板，不是真正可执行的脚本。

**交付物**：
- [x] `scripts/generators/ros2-package-generator.sh` — 接收包名/语言/依赖，生成完整 ROS2 包
- [ ] 自动处理 `ament_export_dependencies`、传递依赖
- [ ] 支持 C++ 和 Python 两种语言
- [ ] 生成后自动执行 `colcon build` 验证

---

## P1 — 本月目标

### P1-1：ROS2 CMake 禁区规则库
- [x] `agents/skills/ros2-cmake-guard/SKILL.md` — CMake 依赖检查规则（禁止省略 ament_export_dependencies 等）
- [ ] 包含常见错误及自动修复策略

### P1-2：ROS2 调试技能
- [x] `agents/skills/ros2-debug/SKILL.md` — 编译错误诊断、QoS 调试、rclcpp 崩溃处理
- [ ] `agents/skills/ros2-qos-checker/SKILL.md` — QoS 兼容性检测

### P1-3：Nav2 配置知识库
- [ ] `agents/skills/navigation/nav2-config/SKILL.md` — Nav2 参数知识库（50+ 参数的物理含义/调节范围）

---

## P2 — 下季度目标

### P2-1：NN 飞控集成（长期）
- [ ] 集成 RAPTOR 基础模型（arXiv:2509.11481）到项目
- [ ] Aerial Gym 仿真训练流程文档化

### P2-2：CI/CD 验证管道
- [ ] GitHub Actions 自动构建 + 测试
- [ ] 每次 PR 自动执行 `colcon build` + SKILL 验证

---

## 核心原则

1. **反馈回路优先**：任何 AI 生成代码的功能，都必须能验证正确性
2. **ROS2 原生**：不发明新运行时，充分利用 ROS2 生态（rclcpp、rclpy、nav2）
3. **实测驱动**：所有示例必须经过真实 ROS2 环境验证
4. **持续迭代**：没有一次性完美的方案，通过用户反馈不断改进

---

## 评审驱动

详见 `CRITICAL_ISSUES.md` — 由 vibe-reviewer 持续维护关键问题追踪。
