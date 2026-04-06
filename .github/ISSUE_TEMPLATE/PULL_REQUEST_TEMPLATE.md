## Pull Request Template

---

## 描述 / Description
简要说明你的改动。

## 改动类型 / Change Type
- [ ] 新增 Skill（`agents/skills/`）
- [ ] 改进现有 Skill
- [ ] 新增/改进脚本（`scripts/`）
- [ ] 新增示例（`examples/`）
- [ ] 文档修正
- [ ] Bug 修复
- [ ] CI/CD 改进

## 关联 Issue / Related Issue
Closes #

## 自检清单 / Checklist
- [ ] 新 Skill 有完整 Frontmatter（`name`/`description`/`argument-hint`/`user-invocable`）
- [ ] 代码示例遵循 agents/documents/Methodology_and_Principles/ANTI_PATTERNS.md（C++: SharedPtr / QoS / Lifecycle）
- [ ] `scripts/check_ros2_package.sh` 验证通过
- [ ] `scripts/validators/ros2-node-validator.sh` 验证通过（如果改动代码）
- [ ] `colcon build` 编译通过（如果添加了 ROS2 包）
- [ ] Commit message 符合规范（`feat:` / `fix:` / `docs:` 等）

## 测试 / Testing
描述你如何测试这个改动。

```bash
# 测试命令
```

## 截图 / Screenshots（如有）
<!-- paste screenshots here -->

---

**提示 / Tips**:
- 运行 `./init-agent.sh` 可以自动生成本地配置文件
- 使用 `scripts/validators/skill-frontmatter-validator.sh` 检查 Skill 格式
- 参考 `CONTRIBUTING.md` 了解贡献规范
