# Examples — 复杂任务工作流

> examples/ 不是代码片段仓库，而是**基于 SKILL 的复杂机器人任务工作流**。
> 每个 example 都是一个完整的多阶段任务，包含 Phase 分解、MCP 调用、验证回路。

---

## 标准结构

每个 example 目录包含：

```
example-name/
├── README.md              # 任务描述 + Phase 分解
├── SKILL.md             # 任务专属 SKILL（引用 agents/skills/）
├── PLAN.md              # Agent 执行计划（Orchestrator 用）
└── VERIFY.md           # 验证标准（什么叫"完成"）
```

## 已有工作流

### `mcp-workflow/`
多智能体协作框架。MCP-SIM / MCP-BUILD / MCP-DEBUG 三种 Agent 协作。

### `memory-bank-example/`
项目记忆库模板。记录机器人类型、已实现模块、接口定义。

---

## 新建工作流指引

### 命名规范
- 机器人类型 + 任务：`go2-scurve`、`manipulator-pickplace`、`drone-exploration`
- 小写 + 连字符

### 必须包含

1. **SKILL.md** — 引用 agents/skills/ 中的通用技能，定义本任务专用检查项
2. **PLAN.md** — 按 Phase 分阶段的 Agent 执行计划
3. **VERIFY.md** — 通过/失败标准（量化指标）

### Phase 标准格式

```markdown
## Phase N: <阶段名称>

### 目标
<具体目标>

### Agent
<使用哪个 Agent（MCP-SIM / MCP-BUILD / MCP-DEBUG）>

### MCP 调用
```bash
mcp__ros2__topic_list
mcp__ros2__pkg_list
```

### 验证
- [ ] <验证项 1>
- [ ] <验证项 2>
```

### 禁止出现
- ❌ 裸 C++/Python 代码片段（除非作为 VERIFY 的对比示例）
- ❌ 完整的 package.xml / CMakeLists.txt（那是生成的输出，不是输入）
- ❌ 与 SKILL 无关的内容
