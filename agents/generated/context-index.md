# Context Index — 项目上下文

> 由 init-agent.sh 自动生成。

## 项目结构

```
vibe-coding-ros2/
├── agents/
│   ├── skills/          # 技能定义（270+ SKILL.md）
│   ├── robots/          # 机器人类型指南
│   ├── prompts/         # 提示词模板
│   ├── memory-bank/    # 项目记忆
│   └── generated/       # 自动生成的索引
├── scripts/
│   ├── generators/      # 包生成器
│   ├── validators/      # 代码验证器
│   └── deployers/       # 部署脚本
└── i18n/
    ├── zh-CN/           # 中文文档
    └── en/              # 英文文档
```

## 关键文件

| 文件 | 用途 |
|------|------|
| AGENTS_CONCISE.md | 极简工作流指令卡（<500 tokens） |
| ANTI_PATTERNS.md | C++/QoS/并发安全规则 |
| init-agent.sh | 初始化脚本 |
| scripts/generators/ros2-package-generator.sh | 一键生成 ROS2 包 |
