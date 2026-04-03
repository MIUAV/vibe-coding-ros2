# Agent Bootstrap

> AI Agent 启动时必须按顺序加载的文件。

## 加载顺序

1. `context-index.md` — 项目结构总览
2. `skill-index.md` — 可用技能列表
3. `skill-routing.md` — 技能路由规则
4. `skill-bootstrap.md` — 本文件

## 执行规则

- 用户请求 → 确定机器人类型 → 确定功能域 → 加载 SKILL.md
- 如 skill 重名，按 taxonomy 路径（agents/skills/{type}/{domain}/）唯一确定
- 使用 AGENTS_CONCISE.md 作为极简参考
- 使用 ANTI_PATTERNS.md 检查 C++/QoS/并发安全性
- 生成代码后用 scripts/validators/ros2-node-validator.sh 验证
