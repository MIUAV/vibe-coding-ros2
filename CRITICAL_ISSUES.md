# 关键问题追踪

> 更新时间：2026-04-04
> 评审依据：技术评审报告 2026-04-04（评分 1.8/10）

---

## 🔴 P0 — 必须立即修复

### 问题 1：缺少 ros-mcp-server 集成
- **现象**：README 和 MCP_WORKFLOW.md 未提及 MCP 协议
- **影响**：AI 无法获取真实 ROS2 运行时上下文，只能对着静态模板盲目生成
- **建议**：参考 https://github.com/robotmcp/ros-mcp-server 实现，让 AI 能执行 `ros2 topic list`、`colcon info` 等
- **状态**：未解决

### 问题 2：缺少 colcon build 反馈回路
- **现象**：没有任何机制验证 AI 生成的代码是否能编译
- **影响**：AI 生成 CMakeLists.txt 后不知道是否正确，错误会传递到用户
- **建议**：在 orchestrator 中加入编译循环，捕获 stderr 并反馈给 AI 修正
- **状态**：未解决

### 问题 3：大量 404 文件（已修复 5/5 ✅
- **现象**：`agents/prompts/coding_prompts/(3,1)_ros2_node_implementation.md` 等 10+ 文件声明存在但内容为空
- **影响**：用户点击文档得到 404，信任度归零
- **建议**：优先填充最核心的 5 个文件（见 PROJECT_ROADMAP.md P0-3）
- **状态**：未解决

### 问题 4：ros2-package-generator 只是模板不是可执行脚本
- **现象**：`scripts/generators/ros2-package-generator.sh` 是 bash 脚本但功能只是写 markdown
- **影响**：用户无法真正生成可编译的 ROS2 包
- **建议**：重写为真正的 bash 脚本，接收参数并生成完整 ROS2 包
- **状态**：未解决

---

## 🟡 P1 — 重要但非紧急

### 问题 5：没有 CMake 依赖检查规则
- **现象**：SKILL.md 中没有针对 CMake 高频错误的防御规则
- **影响**：AI 生成的 CMakeLists.txt 经常漏写 `ament_export_dependencies`
- **建议**：建立 `ros2-cmake-guard` 技能库，列出绝对禁区清单
- **状态**：未解决

### 问题 6：没有 QoS 兼容性检测
- **现象**：文档中没有 QoS 相关指导
- **影响**：相机节点发布 /image 使用默认 QoS，rviz2 订阅使用 Transient Local，静默丢数据
- **建议**：建立 `ros2-qos-checker` 技能库
- **状态**：未解决

### 问题 7：没有 Lifecycle 状态机指导
- **现象**：没有 LifecycleNode 实现规范
- **影响**：AI 生成的节点无法优雅关闭，不符合 ROS2 标准
- **建议**：在 node-implementation.md 中加入 Lifecycle 模板
- **状态**：未解决

---

## 🟢 P2 — 改进建议

### 问题 8：文档与代码脱节
- **现象**：`agents/robots/` 目录大量存在但内容为模板占位
- **影响**：用户期待看到真实机器人代码，实际只有框架
- **建议**：要么填充真实内容，要么删除这些目录不误导

### 问题 9：没有 Sim2Real 指导
- **现象**：Aerial Gym 等仿真工具链完全没有文档
- **影响**：用户无法利用最新 RL 训练方法
- **建议**：建立仿真→实飞部署流程文档

### 问题 10：没有性能基准
- **现象**：没有任何关于 NN 飞控（嵌入式端到端控制）的实用指南
- **影响**：项目与 2025-2026 年最新研究（RAPTOR、Aerial Gym）完全脱节
- **建议**：建立 NN 飞控技能库，跟踪最新研究

---

## 更新记录

| 日期 | 更新内容 |
|------|----------|
| 2026-04-04 | 初始版本，基于技术评审创建 |
