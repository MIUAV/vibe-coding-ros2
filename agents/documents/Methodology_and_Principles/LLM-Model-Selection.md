# LLM-Model-Selection — 编码模型选择指导

> 不同任务选对模型，省钱又高效。LLM 输出稳定性很关键。

---

## 模型分级与适用场景

| 等级 | 模型 | 适用 ROS2 任务 | 不适用 |
|-------|------|----------------|---------|
| **L1** | GPT-4 / Claude 3.5 Sonnet / Gemini Ultra | 复杂多模块系统（Nav2 + MoveIt 集成）| 简单单文件 |
| **L2** | GPT-3.5 / Claude 3 Haiku / Gemini Pro | 标准 ROS2 包生成（publisher/lifecycle/controller）| 架构设计 |
| **L3** | DeepSeek Coder / Qwen Coder / CodeLlama | 单文件补全、代码片段生成 | 多文件协作 |
| **L4** | CodeQwen / StarCoder | 函数级补全、注释生成、错误解释 | 完整节点 |

---

## 任务 → 模型推荐

### ROS2 包生成（完整包）

→ **L2 模型**（Claude 3 Haiku / GPT-3.5）

```
任务：生成一个 wheel_odometry 包（发布 /odom，订阅 /wheel_encoders）
输入：package.xml 依赖列表 + node type
输出：完整 CMakeLists.txt + package.xml + C++ 节点
```

### 复杂导航系统（Nav2 + SLAM + 传感器融合）

→ **L1 模型**（Claude 3.5 Sonnet / GPT-4）

```
任务：设计轮式机器人导航架构，整合 Nav2、amcl、slam_toolbox
输入：机器人 URDF + 传感器列表
输出：模块划分 + 接口定义 + 关键节点代码
```

### CMakeLists.txt 错误修复

→ **L3 模型**（DeepSeek Coder / Qwen Coder）

```
任务：修复 undefined reference to 'rclcpp::Publisher::publish'
输入：colcon build 错误日志
输出：精确修复（一行改动）
```

### 代码风格审查 / 注释

→ **L4 模型**（CodeQwen / StarCoder）

```
任务：为现有节点添加 RCLCPP 日志和 Doxygen 注释
输入：现有 .cpp 文件
输出：补充注释后的文件
```

---

## 输出稳定性对比

同一任务多次生成，LLM 输出差异很大：

| 模型 | 输出一致性 | 速度 | ROS2 知识 |
|------|-----------|------|-----------|
| GPT-4 | 高 | 慢（10s+）| 强 |
| Claude 3.5 | 高 | 中（5s）| 强 |
| GPT-3.5 | 中 | 中 | 中 |
| DeepSeek Coder | 中高 | 快（2s）| 中 |
| Qwen Coder | 中 | 快 | 中 |

**结论：** 对 ROS2 特定任务，用 Claude 3.5 / GPT-4 稳定性最高。

---

## 提示链设计（Prompt Chain）

不要一次让 LLM 生成完整系统，分步骤：

```
Step 1 → 生成 msg/srv/action 接口定义
Step 2 → 生成 CMakeLists.txt + package.xml
Step 3 → 生成节点逻辑
Step 4 → 生成测试
Step 5 → colcon build → 报错回传 → 修复
```

每步用 **L2 模型**，复杂决策（Step 1）用 **L1 模型**。

---

## 固定提示词模板（提高输出稳定性）

```markdown
你是一个 ROS2 开发者。请严格按照以下格式输出。

package: {pkg_name}
node_type: {lifecycle/publisher/subscriber}
dependencies: {rclcpp, std_msgs}

输出格式:
1. package.xml（完整）
2. CMakeLists.txt（完整，三行 export 必填）
3. src/{node_name}_node.cpp（完整，可编译）

禁止:
- 省略 ament_export_dependencies
- 使用 rclcpp::Node（生产用 LifecycleNode）
- QoS 使用 BEST_EFFORT（控制命令）
```

---

## 上下文固定策略

| 策略 | 做法 |
|------|------|
| **固定 system prompt** | SOUL.md + SYSTEM.md 作为每次对话的 system prompt |
| **few-shot examples** | 提供 1-3 个已验证的代码片段作为示例 |
| **错误回传** | colcon build 错误 → 直接粘贴给 LLM 修复 |
| **角色固定** | "你是一个 ROS2 开发者，遵循 SYSTEM.md 规则" |
