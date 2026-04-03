# 进度记录

> 项目: ros-humble-<pkgname>
> 开始日期: 2026-04-01

---

## 2026-04-01

### 完成的工作

| 日期 | 功能 | 状态 | 产出 |
|------|------|------|------|
| 04-01 | 配置项目级 Copilot 开发守则 | ✅ 完成 | `.github/copilot-instructions.md` |
| 04-01 | 搭建 MCP 基础配置与启动脚本 | ✅ 完成 | `.vscode/mcp.json`, `scripts/mcp/*.sh` |
| 04-01 | 建立 MCP 开发流程文档与入口 | ✅ 完成 | `docs/mcp-workflow.md`, `README.md` |

### 遇到的问题

| 日期 | 问题 | 解决方案 |
|------|------|----------|
| 04-01 | 指令文件 frontmatter 含不支持字段 `version` | 删除该字段，仅保留 `name` 和 `description` |
| 04-01 | 守则文档中的相对链接触发路径不存在告警 | 改为纯文本路径说明，避免错误链接 |

### 代码变更

```bash
# 本地修改（未提交）
.github/copilot-instructions.md
.vscode/mcp.json
docs/mcp-workflow.md
scripts/mcp/start-filesystem.sh
scripts/mcp/start-github.sh
scripts/mcp/start-fetch.sh
scripts/mcp/check_env.sh
.env.mcp.example
README.md
vibe-coding-ros2/agents/memory-bank/progress.md
```

### 明日计划

- [ ] 在开发机完成一次 MCP 全链路联调（filesystem/fetch/github）
- [ ] 根据团队权限策略收敛 GitHub PAT scope
- [ ] 如流程稳定，补充 architecture.md / decisions.md
