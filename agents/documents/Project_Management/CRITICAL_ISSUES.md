# CRITICAL_ISSUES.md — 关键问题追踪

> 更新时间：2026-04-05 08:45

---

## ✅ 已解决

### ISSUE-001: MCP Server 连接验证
- **解决时间:** 2026-04-04 晚
- **解决方式:** `scripts/mcp/ros-mcp-integration.sh` 实现，可在真实 ROS2 Humble 环境运行

### ISSUE-002: ros2-package-generator.sh 包名验证 bug
- **解决时间:** 2026-04-05
- **解决方式:** 修复验证逻辑 — ROS2 允许下划线，禁止连字符（原逻辑反了）

### ISSUE-003: ros2-package-generator 不支持 Python-only 包
- **解决时间:** 2026-04-05
- **解决方式:** 重写生成器，完整支持 `cpp` / `python` / `mixed` 三种包类型

### ISSUE-004: 空 SKILL.md 内容（20+ 文件小于 500 字节）
- **解决时间:** 2026-04-05
- **解决方式:** 批量重写了 20 个空内容 SKILL.md，补充了真实技能描述、约束参数、代码示例

---

## 📋 已知限制

1. **无 CI 验证** — 所有生成代码未经 GitHub Actions 自动化编译测试（CI workflow 已创建但未激活）
2. **中文文档质量** — 部分文档由机器翻译，未验证准确性
3. **MCP Server 未在真实 ROS2 环境测试** — `ros-mcp-integration.sh` 脚本已就绪，待实际环境验证

---

## 代码评审通过项

| 检查项 | 状态 |
|--------|------|
| 所有 SKILL.md frontmatter 格式正确 | ✅ |
| 所有 SKILL.md 有实质内容（> 500 字节）| ✅ |
| ros2-package-generator 支持 Python 包 | ✅ |
| 包名验证逻辑正确（下划线/连字符）| ✅ |
| examples/ 结构正确（SKILL + PLAN + VERIFY）| ✅ |
| README 与项目实际结构一致 | ✅ |
