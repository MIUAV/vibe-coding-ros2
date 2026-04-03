# 项目贡献指南

> 本指南面向所有希望参与 vibe-coding-ros2 项目开发的贡献者，说明如何通过规范的开源协作方式提交代码和文档。

---

## 协作流程

```
[个人仓库 (Fork)] → [本地修改] → [提交 Pull Request] → [Maintainer 审核] → [合并到主仓库]
```

### 1. Fork 项目

点击 GitHub 仓库页面的 "Fork" 按钮，将项目复制到你的个人仓库。

```bash
# 克隆你的 Fork 仓库
git clone https://github.com/YOUR_USERNAME/vibe-coding-ros2.git
cd vibe-coding-ros2
```

### 2. 创建功能分支

禁止在 main 分支上直接开发，请基于 main 创建功能分支。

```bash
# 同步上游最新代码
git remote add upstream https://github.com/MIUAV/vibe-coding-ros2.git
git fetch upstream
git checkout -b feat/your-feature-name upstream/main
```

### 3. 开发与提交

按照项目的提交规范编写 commit message，确保每次提交都有实际的内容变更。

```bash
# 提交你的修改
git add .
git commit -m "feat(scope): description of your feature"
```

### 4. 提交 Pull Request

将你的功能分支推送到你的 Fork 仓库，然后在 GitHub 页面创建 PR。

- PR 标题格式：`feat: 简要描述`
- PR 内容应包含：
  - 改动概述
  - 涉及的模块或文件
  - 测试验证结果（如有）
  - 是否关联 Issue

### 5. 代码审核

Maintainer 会 review 你的 PR，可能会提出修改建议。请及时响应并在分支上更新。

审核通过后，Maintainer 将你的代码合并到主仓库。

---

## 提交规范

### Commit Message 格式

```
<type>(<scope>): <subject>

<body> (可选)

<footer> (可选)
```

### Type 类型

| Type | 说明 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档变更 |
| style | 代码格式（不影响功能） |
| refactor | 重构 |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/工具变更 |

### 示例

```
feat(perception): 添加激光雷达点云处理节点

- 实现点云滤波
- 添加降采样功能
- 集成 PCL 库

Closes #123
```

### 提交要求

- **必须有实际内容变更**：禁止仅修改文档格式、空行、注释等无意义提交
- **一个提交对应一个功能**：不要在一个提交里混合多个不相关的改动
- **保持清晰的上下文**：提交信息应能让人快速理解改动目的

---

## Pull Request 要求

### 基本要求

1. **目标分支**：PR 必须指向 `latest` 分支
2. **无冲突**：确保分支与目标分支无冲突，必要时先 rebase
3. **通过基础测试**：如果有测试，请确保本地通过

### PR 内容模板

```markdown
## 改动概述
[简要描述本次改动]

## 改动详情
- 模块 A: 改动内容
- 模块 B: 改动内容

## 测试验证
[说明你是如何测试的]

## 关联 Issue
[如有，关联 Issue 编号]
```

### 审核标准

Maintainer 会从以下方面审核：

- [ ] 改动是否符合项目架构和设计原则
- [ ] 代码质量、风格是否一致
- [ ] 是否有必要的测试或文档
- [ ] 提交信息是否规范

---

## 许可证

参与本项目即表示你同意你的代码贡献将基于 Apache License 2.0 开源。

---

## 联系方式

- 提交 Issue: https://github.com/MIUAV/vibe-coding-ros2/issues
- 项目维护者: MIUAV Organization