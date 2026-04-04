## Pull Request — Vibe-Coding-ROS2

### 描述

<!--简要说明这个 PR 做什么-->

### 变更类型

- [ ] 新技能 (SKILL.md)
- [ ] 新工具/脚本
- [ ] 新示例
- [ ] 文档更新
- [ ] CI/CD 更新
- [ ] 代码重构
- [ ] Bug 修复

### 检查清单

- [ ] `colcon build --packages-select <changed_package>` 编译通过（0 error）
- [ ] SKILL.md 验证通过: `bash scripts/validators/skill-frontmatter-validator.sh agents/skills`
- [ ] 新增 SKILL.md 有完整的 frontmatter (name/description/argument-hint/user-invocable)
- [ ] 新脚本有执行权限 (`chmod +x`)
- [ ] C++ 代码符合 SYSTEM.md 规则（LifecycleNode / QoS / CMake 三行）
- [ ] Git commit message 符合 conventional commits 格式

### 测试截图/日志（可选）

<!--如果有编译输出或运行截图，粘贴在这里-->

### 相关 Issue

<!-- 关联的 Issue 编号，如: Closes #123 -->

---

### CI 检查

| 检查项 | 状态 |
|--------|------|
| GitHub Actions (ros:humble build) | CI 自动运行 |
| SKILL.md frontmatter 验证 | 自动运行 |
| 编译验证 | 自动运行 |

---

### Notes for Reviewer

<!--给 reviewer 的备注（如果有）-->
