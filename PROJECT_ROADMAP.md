# Vibe-Coding-ROS2 项目路线图

> 更新时间：2026-04-04 23:50
> 依据：技术评审 + 实际开发进展

---

## 完成进度（2026-04-04 晚）

| 类别 | 完成 | 总计 | 百分比 |
|------|------|------|--------|
| P0-1 MCP集成 | 1 | 3 | 33% |
| P0-2 反馈回路 | 1 | 2 | 50% |
| P0-3 404文件 | 5 | 5 | **100%** ✅ |
| P0-4 生成器 | 1 | 4 | 25% |
| P1-1 CMake规则 | 1 | 2 | 50% |
| P1-2 调试技能 | 2 | 3 | 67% |
| P1-3 Nav2知识库 | 1 | 1 | **100%** ✅ |

---

## P0 — 核心功能（必须解决）

### P0-1：ros-mcp-server 集成 ✅ 已完成
- [x] `scripts/mcp/ros-mcp-integration.sh` — 一键启动 MCP server
- [x] `scripts/mcp/mcp-agent-orchestrator.sh` — MCP 多智能体编排
- [ ] 更新 `examples/mcp-workflow/MCP_WORKFLOW.md` — 说明启用方法
- [ ] go2-scurve case Phase 0 加入 MCP 连接验证

### P0-2：colcon build 反馈回路 🔄 进行中
- [x] `scripts/ros2-build-feedback.sh` — 自动编译验证 + 错误分类 + 修复建议
- [ ] `scripts/mcp/mcp-agent-orchestrator.sh` — 加入编译验证循环（最多重试 3 次）

### P0-3：404 文件填充 ✅ 已完成
- [x] `agents/prompts/coding_prompts/(3,1)_ros2_node_implementation.md`
- [x] `agents/prompts/user_prompts/ros2-common-prompts.md`
- [x] `agents/documents/Methodology_and_Principles/development-experience.md`
- [x] `agents/documents/Tutorials_and_Guides/ros2-debug-guide.md`
- [x] `agents/documents/Tutorials_and_Guides/docker-setup-guide.md`

### P0-4：ros2-package-generator ✅ 基本完成
- [x] `scripts/generators/ros2-package-generator.sh` — 完整可执行
- [x] 自动生成 CMakeLists.txt + package.xml + C++ 骨架
- [ ] 自动处理 `ament_export_dependencies` 传递依赖（已有基础，需完善）
- [ ] 支持 Python 节点（已有 launch.py 骨架，需补充）

---

## P1 — 本月目标

### P1-1：ROS2 CMake 禁区规则库
- [x] `agents/skills/ros2-cmake-guard/SKILL.md` — 强制规则库（已验证 5 类错误）
- [ ] 常见错误自动修复脚本（自动 patch CMakeLists.txt）

### P1-2：ROS2 调试技能 ✅ 已完成
- [x] `agents/skills/ros2-debug/SKILL.md` — 编译错误/运行时崩溃/QoS/Lifecycle
- [x] `agents/skills/ros2-qos-checker/SKILL.md` — QoS 兼容性检测

### P1-3：Nav2 配置知识库 ✅ 已完成
- [x] `agents/skills/navigation/nav2-config/SKILL.md` — 50+ 参数速查 + 4 大典型场景

---

## 项目核心原则

1. **可编译 > 看起来对** — 代码必须 `colcon build` 零错误
2. **反馈回路优先** — AI 生成 → 编译验证 → 错误修正 → 重新生成
3. **强制规则 > 建议** — SKILL.md 里的禁区是零容忍的
4. **实测驱动** — 所有示例经过真实 ROS2 环境验证

## 待开发功能（降级到 P2）

### P2-1：CI/CD 验证管道
- GitHub Actions 自动构建 + 测试
- 每次 PR 执行 `colcon build` + SKILL 验证

### P2-2：NN 飞控集成
- RAPTOR 基础模型（arXiv:2509.11481）
- Aerial Gym 仿真训练流程

---

## 现状评分（vs 昨天）

| 维度 | 昨天 | 今天 | 变化 |
|------|------|------|------|
| 代码可执行性 | 1/10 | 3/10 | ↑ |
| System Prompt 质量 | 3/10 | 6/10 | ↑ |
| LLM 通点覆盖 | 2/10 | 5/10 | ↑ |
| 实用工具链 | 1/10 | 4/10 | ↑ |
| 文档完整性 | 5/10 | 7/10 | ↑ |
