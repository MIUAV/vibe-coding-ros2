---
name: agent-skill-bootstrap
description: "智能体技能导入引导技能 - 用于重建 skill-index/skill-routing、按分类路由加载技能、处理同名技能冲突，并规范新增技能(create-skill)后的索引更新"
argument-hint: 导入技能 OR 重建索引 OR create skill OR skill routing
user-invocable: true
---

# Agent Skill Bootstrap

> 适用于技能数量较多时的统一导入、路由与索引重建流程。

---

## 何时使用

当出现以下场景时使用此技能：
- 技能库刚更新，需要重新导入最新技能
- 技能数量增多，名称冲突导致匹配不稳定
- 需要让智能体按机器人类型 + 功能域精确加载技能
- 新增技能后需要刷新索引与引导文件

---

## 标准流程

### 1. 重建导入索引

```bash
./init-agent.sh --target all
```

该命令会刷新：
- `agents/generated/skill-index.md`
- `agents/generated/skill-routing.md`
- `agents/generated/context-index.md`
- `agents/generated/agent-bootstrap.md`

### 2. 按固定顺序加载上下文

1. `agents/generated/context-index.md`
2. `agents/generated/skill-index.md`
3. `agents/generated/skill-routing.md`
4. `agents/skills/README.md`
5. `i18n/zh-CN/AGENT_IMPORT_GUIDE.md`
6. `i18n/en/AGENT_IMPORT_GUIDE.md`

### 3. 路由技能

先识别需求中的：
- 机器人/平台类型：`multi_rotor_uav` / `quadruped` / `humanoid` / `manipulator` / `wheeled_vehicle` / `edge-platforms` / `common`
- 功能域：`perception` / `localization` / `navigation` / `motion-control` / `skill-planning` / `action`

然后根据 `agents/generated/skill-routing.md` 选择完整路径技能。

### 4. 处理同名技能

如果技能名重复（例如 `localization`、`perception`），必须使用完整路径，而不是仅使用短名。

示例：
- `agents/skills/quadruped/localization/SKILL.md`
- `agents/skills/humanoid/localization/SKILL.md`

---

## 使用 Copilot /create-skill 的推荐方式

当要新增技能时，优先使用 `/create-skill` 生成初稿，再按仓库结构调整。

推荐提示词：

```text
/create-skill
创建一个名为 <skill-name> 的技能，放在 agents/skills/<taxonomy-path>/<skill-name>/SKILL.md。
要求：
1) YAML frontmatter 包含 name、description、trigger
2) description 写明 Use when 场景和关键词
3) 内容包含：何时使用、快速参考、执行步骤、常见问题
4) 符合 ROS2 场景并给出可执行命令示例
```

新增后必须执行：

```bash
./init-agent.sh --target all
```

以刷新索引并纳入导入流程。

---

## 质量检查清单

- 新技能路径是否位于 `agents/skills/` 正确分类下
- `name` 是否与目录名语义一致
- `description` 是否包含可检索关键词
- `trigger` 是否覆盖中英文高频表达
- `./init-agent.sh --target all` 是否已执行
- `agents/generated/skill-index.md` 是否已包含新技能
- `agents/generated/skill-routing.md` 是否可路由到新技能
