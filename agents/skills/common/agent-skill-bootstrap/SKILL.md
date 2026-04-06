---
name: agent-skill-bootstrap
description: "AI Agent 技能引导 — 加载上下文、路由技能、创建新技能"
argument-hint: 导入技能 OR 创建新技能 OR skill routing OR 重建索引
user-invocable: true
---

# Agent Skill Bootstrap

> AI Agent 工作规则：如何加载上下文、路由到正确技能、创建新技能。

---

## 何时使用

- 技能库需要重新导入时
- 需要按机器人类型 + 功能域精确加载技能时
- 新增技能后需要刷新索引时

---

## 标准流程

### 1. 加载上下文（按顺序）

按以下顺序加载（只读存在的文件）：

1. `AGENTS.md` — AI Agent 开发规则（必读）
2. `CLAUDE.md` — 核心规则（三大致命弱点 + 关键工具）
3. `PROJECT_ROADMAP.md` — 项目路线图
4. `agents/skills/README.md` — 技能目录索引

### 2. 路由技能

先识别需求中的：
- **机器人/平台类型**：`multi_rotor_uav` / `quadruped` / `humanoid` / `manipulator` / `wheeled_vehicle` / `edge-platforms` / `common`
- **功能域**：`perception` / `localization` / `navigation` / `motion-control` / `skill-planning` / `action`

然后按 `agents/skills/` 目录结构选择技能。

### 3. 处理同名技能

如果技能名重复（例如 `localization`、`perception`），必须使用完整路径，而不是仅使用短名。

示例：
- ✅ `agents/skills/quadruped/localization/SKILL.md`
- ❌ `agents/skills/localization/SKILL.md`（歧义）

### 4. 创建新技能

```bash
# 1. 创建目录结构
mkdir -p agents/skills/<robot>/<domain>/<skill-name>/

# 2. 创建 SKILL.md
cat > agents/skills/<robot>/<domain>/<skill-name>/SKILL.md <<'EOF'
---
name: <skill-name>
description: "<一句话描述>"
argument-hint: <触发关键词>
user-invocable: true
---

# <Skill Name>

## 何时使用

<使用场景>

## 核心规则

<强制规则>

## 代码模板

\`\`\`cpp
// 示例代码
\`\`\`

## 错误处理

<常见错误及解决>
EOF

# 3. 提交
git add -A
git commit -m "feat(skills): add <robot>/<domain>/<skill-name>"
```
