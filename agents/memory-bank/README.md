# Memory Bank — ROS2 开发记忆库

> 本目录为 AI Agent 提供项目级上下文记忆，包含项目全景、技术决策、常见模式和问题规避。

---

## 文件索引

| 文件 | 内容 |
|------|------|
| `project-panorama.md` | 项目定位、愿景、技术栈总览 |
| `architecture-decisions.md` | 已确认的技术选型和架构决策 |
| `coding-standards.md` | 代码规范、命名约定、ROS2 最佳实践 |
| `common-pitfalls.md` | 常见错误模式和规避方案 |
| `toolchain-guide.md` | 工具链使用记忆（生成器、验证器） |

---

## 使用方式

当 AI Agent 开始工作时，按需读取对应 memory 文件获取上下文，避免重复提问和重复踩坑。

可直接用 `/memory` 指令触发语义搜索。
