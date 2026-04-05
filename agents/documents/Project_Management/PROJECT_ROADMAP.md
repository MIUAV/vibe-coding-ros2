# Vibe-Coding-ROS2 项目路线图

> 更新时间：2026-04-05 00:15
> 依据：实际开发进展

---

## 完成进度（2026-04-05 凌晨）

| 类别 | 完成 | 总计 | 百分比 |
|------|------|------|--------|
| P0-1 MCP集成(脚本) | 2 | 3 | 67% |
| P0-2 反馈回路 | 1 | 2 | 50% |
| P0-3 404文件 | 5 | 5 | **100%** ✅ |
| P0-4 生成器 | 2 | 4 | 50% |
| P1-1 CMake规则 | 1 | 2 | 50% |
| P1-2 调试技能 | 2 | 3 | 67% |
| P1-3 Nav2知识库 | 1 | 1 | **100%** ✅ |
| P2-1 CI/CD | 1 | 2 | 50% |

---

## P0 — 核心功能

### P0-1：ros-mcp-server 集成 🔄 进行中（脚本已完成）
- [x] `scripts/mcp/ros-mcp-integration.sh` — MCP server 检查/启动/验证
- [x] `scripts/mcp/mcp-agent-orchestrator.sh` — 多 Agent 编排（go2-scurve/manipulator-pickplace）
- [ ] 真实 ROS2 Humble 环境验证（MCP 调用 `ros2 topic list` 等）

### P0-2：colcon build 反馈回路 🔄 进行中
- [x] `scripts/ros2-build-feedback.sh` — 编译错误解析 + 7 类错误修复建议
- [ ] 集成到 MCP 编排器（最多 3 轮重试）

### P0-3：404 文件填充 ✅ 已完成
- [x] 所有声明的文件均已创建真实内容

### P0-4：ros2-package-generator ✅ 基本完成
- [x] `scripts/generators/ros2-package-generator.sh` — 完整可执行
- [x] `scripts/generators/ros2-cpp-node.sh` — 节点生成器（publisher/subscriber/lifecycle/service/timer）
- [ ] 传递依赖自动展开（已有基础，需完善）

---

## P1 — 本月目标 ✅

### P1-1：ROS2 CMake 禁区规则库
- [x] `agents/skills/ros2-cmake-guard/SKILL.md` — 5 条绝对禁区 + 自动修复策略

### P1-2：ROS2 调试技能 ✅
- [x] `agents/skills/ros2-debug/SKILL.md` — 编译/运行/QoS/Lifecycle 调试
- [x] `agents/skills/ros2-qos-checker/SKILL.md` — QoS 兼容性矩阵

### P1-3：Nav2 配置知识库 ✅
- [x] `agents/skills/navigation/nav2-config/SKILL.md` — 50+ 参数速查

---

## P2 — 下季度目标

### P2-1：CI/CD 验证管道 🔄 进行中
- [x] `.github/workflows/ros2-build.yml` — GitHub Actions (ubuntu-22.04 + ros:humble)
- [ ] 每次 PR 自动执行 colcon build + SKILL 验证

### P2-2：NN 飞控集成
- [ ] RAPTOR 基础模型（arXiv:2509.11481）集成调研
- [ ] Aerial Gym 仿真训练流程文档化

---

## 项目核心文件清单（本轮新增）

| 文件 | 作用 |
|------|------|
| `CLAUDE.md` | AI Agent 开发指南（CMake/QoS/Lifecycle 强制规则）|
| `CHECKLIST.md` | 开发质量检查清单（6步法）|
| `CONTRIBUTING.md` | 贡献指南 |
| `SOUL.md` | 项目哲学 |
| `SYSTEM.md` | AI 强制规则 + 代码模板 |
| `scripts/ros2-env-check.sh` | ROS2 环境诊断 |
| `scripts/ros2-build-feedback.sh` | 编译自动验证 |
| `scripts/generators/ros2-cpp-node.sh` | C++ 节点生成器 |
| `examples/lifecycle_controller/` | 可编译 LifecycleNode 示例 |
| `.vscode/tasks.json` | VSCode 构建/测试任务 |
| `.github/pull_request_template.md` | PR 模板 |
| `.github/workflows/ros2-build.yml` | CI 流水线 |

---

## 质量评分变化

| 维度 | 第一天 | 今天 | 变化 |
|------|--------|------|------|
| 代码可执行性 | 1/10 | 5/10 | ↑ |
| System Prompt 质量 | 3/10 | 7/10 | ↑ |
| LLM 通点覆盖 | 2/10 | 6/10 | ↑ |
| 实用工具链 | 1/10 | 6/10 | ↑ |
| 文档完整性 | 5/10 | 8/10 | ↑ |
| CI/CD 成熟度 | 0/10 | 4/10 | ↑ |

---

## 核心原则

1. **可编译 > 看起来对** — colcon build 零错误是唯一标准
2. **反馈回路优先** — AI 生成 → 编译验证 → 错误修正 → 重新生成
3. **强制规则 > 建议** — SYSTEM.md 的禁区零容忍
4. **持续交付** — 每次迭代都有可用的推送
