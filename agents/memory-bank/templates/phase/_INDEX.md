# Development Phase Templates — 索引

> 自动切换：检测开发阶段关键词 → 加载对应模板
> 激活方式：`cp <file> agents/memory-bank/active-context.md`

| 阶段 | 文件 | 关键输出 |
|------|------|---------|
| 需求分析 | `1-requirements.md` | 功能清单、架构图 |
| 架构设计 | `2-architecture.md` | 包结构、Topic/Service/Action 设计 |
| 包骨架生成 | `3-prototyping.md` | 可编译的 CMakeLists + package.xml |
| 功能开发 | `4-implementation.md` | Lifecycle 节点、自测命令 |
| 集成测试 | `5-integration.md` | Gazebo 仿真、性能基准 |
| 部署运维 | `6-deployment.md` | Docker、systemd、远程调试 |

## 关键词检测规则

| 关键词 | 激活模板 |
|--------|---------|
| 需求、功能定义、要做什么 | `1-requirements.md` |
| 架构、接口定义、模块划分、设计 | `2-architecture.md` |
| 生成包、骨架、从零开始、原型 | `3-prototyping.md` |
| 实现、写代码、节点逻辑、开发 | `4-implementation.md` |
| 联调、集成、仿真验证、测试 | `5-integration.md` |
| 部署、上线、运行、交付 | `6-deployment.md` |
