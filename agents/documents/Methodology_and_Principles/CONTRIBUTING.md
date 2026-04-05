# Contributing to Vibe-Coding-ROS2

## 快速开始

```bash
# 克隆
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 创建功能分支
git checkout -b feat/my-new-skill

# 开发...
# 编译测试
colcon build --packages-select <your_package>

# 验证 SKILL 文件
bash scripts/validators/skill-frontmatter-validator.sh agents/skills

# 提交
git add . && git commit -m "feat: add ..."

# 推送并创建 PR
git push origin feat/my-new-skill
```

## 添加新技能（SKILL.md）

### 必需格式

```yaml
---
name: my-skill-name
description: 简短描述技能的作用（1-2句话）
argument-hint: 触发关键词1 OR 触发关键词2
user-invocable: true
---

# My Skill

## 目的
...
```

### 字段说明

| 字段 | 要求 | 说明 |
|------|------|------|
| `name` | 必须 | 技能唯一标识（小写+连字符） |
| `description` | 必须 | AI 看到的一行描述 |
| `argument-hint` | 推荐 | 触发技能的关键词（用 OR 分隔） |
| `user-invocable` | 推荐 | 是否可通过用户命令调用 |

### 验证

```bash
# 本地验证
bash scripts/validators/skill-frontmatter-validator.sh agents/skills

# 应该输出: Result: 0 errors
```

## 添加新脚本

1. 放在 `scripts/` 对应子目录
2. 添加执行权限: `chmod +x scripts/xxx.sh`
3. 在顶部添加 shebang: `#!/bin/bash`
4. 包含使用说明（--help 或开头注释）
5. 优先使用 `set -e` 错误退出

## 代码风格

### Shell 脚本

- 使用 `find` + `while read` 处理文件列表
- 颜色变量: `RED`, `GREEN`, `YELLOW`, `NC`
- 错误退出: `exit 1`

### C++ 代码

- C++17 标准
- 遵循 ROS2 C++ style
- 使用 `LifecycleNode` 而非 `rclcpp::Node`（生产环境）

## Commit Message 格式

```
<type>: <简短描述>

<可选详细说明>

<可选 Footer>
```

**Type:**
- `feat:` — 新功能
- `fix:` — Bug 修复
- `docs:` — 文档
- `refactor:` — 重构
- `chore:` — 维护任务

## 分支策略

- `latest` — 主分支，所有功能合并到这里
- `feat/*` — 功能分支
- `fix/*` — 修复分支

## 问题反馈

GitHub Issues: https://github.com/MIUAV/vibe-coding-ros2/issues
