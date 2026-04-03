# Memory Bank 模板

> VibeCoding 的核心是保持清晰的上下文，Memory Bank 是存储项目上下文的机制。

---

## Memory Bank 结构

```
memory-bank/
├── project-context.md        # 项目上下文 (核心)
├── implementation-plan.md     # 实施计划
├── progress.md               # 进度记录
├── architecture.md           # 架构文档
└── decisions.md             # 设计决策记录
```

---

## 使用方法

### 1. 初始化项目

当开始一个新项目时，让 AI 生成完整的 Memory Bank：

```
请帮我创建 Memory Bank 的所有文件。
项目信息：[项目描述]
```

### 2. 每次对话开始

在开始新的开发任务前，先让 AI 阅读 Memory Bank：

```
请先阅读 memory-bank 所有文档，了解项目当前状态。
```

### 3. 完成后更新

每次完成任务后，更新相关文件：

```
请更新 memory-bank/progress.md，记录我刚才完成的工作。
```

---

## 文件说明

### project-context.md

- 项目概述和技术栈
- 包结构和消息流
- 硬件配置
- 构建和部署配置

### implementation-plan.md

- 分步实施计划
- 每个步骤的具体指令
- 验证方法和预期产出

### progress.md

- 每日进度记录
- 遇到的问题和解决方案
- Git 提交记录

### architecture.md

- 系统架构图
- 节点关系
- 接口定义

### decisions.md

- 重要的设计决策
- ADR (Architecture Decision Records)
- 技术选型理由
