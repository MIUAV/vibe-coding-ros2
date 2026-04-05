# Vibe-Coding-ROS2

> 用 LLM 辅助编写 ROS2 代码的工具集。能实际生成可编译 ROS2 C++ 代码的工程框架。

[comment]: # (ZH: AI agent reads SOUL.md + SYSTEM.md first | EN: AI agent reads CLAUDE.md for workflow)

---

## 🔥 GitHub Stats

```

<p align="left">
    <img src="https://visitor-badge.laobi.icu/badge?page_id=MIUAV.vibe-coding-ros2" alt="Visitor Badge" />
    <img src="https://img.shields.io/badge/version-v0.0.1--beta-blue?style=flat-square" alt="Version" />
    <img src="https://img.shields.io/badge/ROS2-Humble%20%7C%20Iron%20%7C%20Jazzy-green?style=flat-square" alt="ROS2 Distros" />
    <img src="https://img.shields.io/badge/C%2B%2B-17%2B-blue?style=flat-square" alt="C++ Standard" />
    <img src="https://img.shields.io/badge/workflows-5%20CI%20jobs-blue?style=flat-square" alt="CI Status" />
</p>

## 📊 仓库活跃度

[![Star History Chart](https://api.star-history.com/svg?repos=MIUAV/vibe-coding-ros2&type=Date)](https://star-history.com/#MIUAV/vibe-coding-ros2&Date)

---



**Latest commit:** `be074f4` · 2026-04-05

[![Stars](https://img.shields.io/github/stars/MIUAV/vibe-coding-ros2?style=flat-square)](https://github.com/MIUAV/vibe-coding-ros2/stargazers)
[![Forks](https://img.shields.io/github/forks/MIUAV/vibe-coding-ros2?style=flat-square)](https://github.com/MIUAV/vibe-coding-ros2/network/members)
[![Issues](https://img.shields.io/github/issues/MIUAV/vibe-coding-ros2?style=flat-square)](https://github.com/MIUAV/vibe-coding-ros2/issues)
[![License](https://img.shields.io/github/license/MIUAV/vibe-coding-ros2?style=flat-square)](https://github.com/MIUAV/vibe-coding-ros2/blob/main/LICENSE)
[![ROS2](https://img.shields.io/badge/ROS2-Humble-blue?style=flat-square)](https://docs.ros.org/en/humble/)



## ⚡ 1 分钟快速开始

<details>
<summary><b>点击展开 — 4 步上手</b></summary>

```bash
# 第 1 步：克隆
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 第 2 步：生成一个 ROS2 包
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 第 3 步：编译验证
cd my_robot && colcon build

# 第 4 步：自动检查编译错误
bash ../scripts/ros2-build-feedback.sh .
```

> 跟着做，AI 会帮你完成剩余步骤。每完成一步问 AI：「成功了吗？」再继续。

</details>

---

## 🧪 实验性方法

<details>
<summary><b>点击展开 — Vibe-Coding 哲学 + 三个致命弱点</b></summary>

> 这是一个不断生长和自我否定的项目。AI 能力的变化可能导致当下经验失效，请保持以 AI 为主的思维，辩证地采纳。

---

### 概览

**ROS2 VibeCoding** 是将 AI 结对编程与机器人开发相结合的终极工作流程。ROS2 项目具有独特的复杂性：

| 挑战 | 说明 |
|------|------|
| 多节点通信 | Topic/Service/Action 多种通信机制 |
| 硬件驱动集成 | 相机、激光雷达、IMU、电机驱动 |
| 实时性要求 | 控制系统对延迟敏感 |
| 跨平台部署 | x86 开发机 → ARM 部署机（OrinNX/AGX/JetBot）|
| 生态依赖 | Navigation2、MoveIt、ROS2 工业应用 |

**核心理念：规划驱动 + 上下文固定 + AI 结对执行**，让机器人代码从「难以维护」变成「可审计、可迭代」。

**一句话：** VibeCoding = 规划驱动 + 上下文固定 + AI 结对执行

---

### 🔑 元方法论 (Meta-Methodology)

#### 递归优化循环

```
创生 (Bootstrap) → 自省与进化 (Self-Correction) → 创造 (Generation) → 循环与飞跃 (Recursive Loop)
```

#### α-Ω 提示词系统

| 类型 | 角色 |
|------|------|
| **α-提示词（生成器）** | 负责生成其他提示词或技能 |
| **Ω-提示词（优化器）** | 负责优化其他提示词或技能 |

---

### 核心原则

**AI 能做的，就不要人工做**
- 重复性代码生成、配置模板、文档编写
- 一切问题问 AI — 先问 AI，AI 解决不了再人工

**上下文是 VibeCoding 的第一性要素**
- 垃圾进，垃圾出
- 代码一多就切会话，保持上下文清晰

**系统性思考**
- 节点、通信、硬件三维度 — 机器人系统的核心是节点间通信和硬件交互
- 数据与函数即是编程的一切 — ROS2 消息即数据，节点即函数
- 输入→处理→输出 — 刻画整个过程，节点的本质

**代码哲学**
- 先结构，后代码 — 规划好框架，不然后面技术债还不完
- 奥卡姆剃刀定理 — 如无必要，勿增代码
- 帕累托法则 — 关注重要的 20%
- 重复，多试几次 — 实在不行重新开个窗口
- 专注 — 极致的专注可以击穿代码，一次只做一件事

---

### 开发准则

| 准则 | 说明 |
|------|------|
| 一句话目标 + 非目标 | 明确本次开发要做什么、不做什么 |
| 正交性 | 功能不要太重复，模块职责清晰 |
| 能抄不写 | 不重复造轮子，先问 AI 有没有合适的仓库 |
| 官方文档优先 | 先把官方文档喂给 AI |
| 按职责拆模块 | 感知、规划、控制、执行分离 |
| 接口先行，实现后补 | 先定义 msg/srv/action，再实现节点 |
| 一次只改一个模块 | 降低耦合风险 |
| 文档即上下文 | 不是事后补，而是开发时同步写 |

---

### Debug 法则

```
预期 vs 实际 + 最小复现 + 关键日志
```

**测试分层：** 单元测试 → 集成测试 → 硬件测试

---

### 三个致命弱点（ROS2 开发中 LLM 的）

| 弱点 | 后果 | 解法 |
|------|------|------|
| CMake 依赖地狱 | 链接失败 | `ament_export_dependencies` 三行必须同时存在 |
| QoS 静默失败 | 数据不通 | 控制命令 RELIABLE，sensor BEST_EFFORT |
| Lifecycle 状态机 | 节点卡住 | 生产环境用 LifecycleNode |

</details>

---

## 🧭 经验

<details>
<summary><b>点击展开 — CMake / QoS / Lifecycle 实战教训</b></summary>

### CMake 依赖地狱

**CMakeLists.txt 必须同时有这三行，缺一不可：**

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)           # 必须
ament_export_include_directories(include)     # 必须
ament_export_libraries(${PROJECT_NAME})      # 必须
```

> 缺少任意一行 → 链接错误 → 编译失败。

---

### QoS 静默失败

ROS2 默认 QoS 是 `RELIABLE + VOLATILE`。选错静默不通：

```cpp
// 控制命令 — 必须可靠
auto pub = this->create_publisher<JointCommand>("/arm/command",
    QoS(10).reliable());  // 禁止 BEST_EFFORT

// Sensor 数据 — 允许丢帧
auto sub = this->create_subscription<LaserScan>("/scan",
    QoS(10).best_effort());  // 匹配 lidar 驱动

// Lifecycle 状态 — 新订阅者收到最近状态
auto pub = this->create_publisher<RobotState>("/state",
    QoS(10).transient_local());
```

---

### Lifecycle 状态机

**生产机器人控制必须用 `rclcpp_lifecycle::LifecycleNode`：**

```cpp
// ❌ 错误 — 无法优雅关闭/重启
auto node = std::make_shared<rclcpp::Node>("controller");

// ✅ 正确 — 带状态机，支持 configure/activate/deactivate/cleanup
class RobotController : public rclcpp_lifecycle::LifecycleNode {
  rclcpp_lifecycle::CallbackReturn
  on_configure(const State&) override { ... }  // 初始化资源
  rclcpp_lifecycle::CallbackReturn
  on_activate(const State&) override { ... }   // 开始发布
  rclcpp_lifecycle::CallbackReturn
  on_deactivate(const State&) override { ... } // 停止发布
};
```

</details>

---

## 📋 工具与资源

<details>
<summary><b>点击展开 — 生成器 + 验证工具 + MCP</b></summary>

### 生成器

```bash
# 包生成器（最常用）
bash scripts/generators/ros2-package-generator.sh <pkg> cpp <deps>   # C++ 包
bash scripts/generators/ros2-package-generator.sh <pkg> python     # Python 包

# 节点生成器（7 种类型）
bash scripts/generators/ros2-cpp-node.sh publisher  <pkg> <deps>  # 发布者
bash scripts/generators/ros2-cpp-node.sh subscriber <pkg> <deps>  # 订阅者
bash scripts/generators/ros2-cpp-node.sh lifecycle  <pkg> <deps>  # 生命周期节点
bash scripts/generators/ros2-cpp-node.sh service   <pkg> <deps>  # 服务节点
bash scripts/generators/ros2-cpp-node.sh action    <pkg> <deps>  # Action 节点
bash scripts/generators/ros2-cpp-node.sh timer     <pkg> <deps>  # 定时器节点
bash scripts/generators/ros2-cpp-node.sh parameters <pkg> <deps> # 参数节点
```

### 验证工具

```bash
bash scripts/ros2-build-feedback.sh .                              # 编译错误分析
bash scripts/ros2-env-check.sh                                   # 环境 7 项检查
bash scripts/ros2-monitor.sh                                    # 运行时监控
bash scripts/ros2-bag-tool.sh record /scan                     # bag 录制
bash scripts/validators/skill-frontmatter-validator.sh agents/skills  # SKILL 格式验证
```

### MCP 多智能体

```bash
./scripts/mcp/ros-mcp-integration.sh              # 启动 MCP Server
./scripts/mcp/mcp-agent-orchestrator.sh <case>  # 编排多 Agent 协作
```

</details>

---

## 🏁 编码模型性能分级参考

<details>
<summary><b>点击展开 — L1~L4 模型分级</b></summary>

| 等级 | 模型 | 适用场景 |
|------|------|---------|
| **L1** | GPT-4 / Claude 3.5 / Gemini Ultra | 复杂多模块系统设计、架构决策 |
| **L2** | GPT-3.5 / Claude 3 / Gemini Pro | 标准 ROS2 包生成、代码实现 |
| **L3** | Gemini / DeepSeek / Qwen | 单文件代码生成、代码补全 |
| **L4** | 小模型（CodeQwen 等）| 简单函数、错误解释、代码注释 |

> 等级越高，复杂任务成功率越高。但即便是 L1 模型，也必须遵循 `SYSTEM.md` 的强制规则。

</details>

---

## 🗂️ 项目目录结构概览

<details>
<summary><b>点击展开 — 完整目录树</b></summary>

```
vibe-coding-ros2/
├── SOUL.md              # 项目哲学
├── SYSTEM.md            # AI 强制规则（CMake/QoS/Lifecycle）
├── CLAUDE.md           # AI 开发指南
├── README.md            # 本文件
│
├── agents/
│   ├── skills/         # 276 个技能定义（强制规则）
│   │   ├── ros2-cmake-guard/     # CMake 禁区
│   │   ├── ros2-qos-checker/     # QoS 兼容性
│   │   ├── ros2-debug/          # 调试指南
│   │   ├── ros2-cpp-node/      # 节点生成器
│   │   └── navigation/nav2-config/ # Nav2 参数
│   │
│   ├── prompts/        # AI 提示词模板
│   ├── documents/       # 项目文档
│   │   ├── Methodology_and_Principles/  # 开发方法论
│   │   ├── Tutorials_and_Guides/       # 教程指南
│   │   └── Project_Management/           # 项目管理
│   └── robots/          # 机器人类型
│
├── scripts/
│   ├── generators/      # ros2-package-generator / ros2-cpp-node
│   ├── mcp/           # MCP 多智能体
│   ├── validators/     # SKILL 验证器
│   └── ros2-build-feedback.sh  # 编译验证
│
└── examples/
    └── mcp-workflow/
        └── cases/      # 10 个复杂任务案例
            ├── go2-scurve/
            ├── manipulator-pickplace/
            ├── drone-exploration/
            ├── wheeled-nav2/
            ├── multi-robot-swarm/
            ├── biped-walk/
            ├── underwater-nav/
            ├── sensor-fusion-locate/
            ├── aerial-photography/
            └── industrial-integration/
```

</details>

---

## 📺 演示与产出

<details>
<summary><b>点击展开 — 工具表 + 10 个 case</b></summary>

### 已有工具产出

| 工具 | 状态 | 说明 |
|------|------|------|
| `ros2-package-generator.sh` | ✅ 可用 | 生成 C++/Python ROS2 包 |
| `ros2-build-feedback.sh` | ✅ 可用 | 编译错误自动分析 |
| `ros2-cpp-node.sh` | ✅ 可用 | 7 种节点类型生成 |
| `ros2-env-check.sh` | ✅ 可用 | 环境诊断 |
| `ros2-monitor.sh` | ✅ 可用 | 运行时监控 |
| `skill-frontmatter-validator.sh` | ✅ 可用 | 276 SKILL 格式验证 |
| `ros2-bag-tool.sh` | ✅ 可用 | bag 录制回放 |

### 复杂任务案例（10 个）

| Case | 机器人 | 任务 |
|------|--------|------|
| `go2-scurve/` | 四足 | S 曲线轨迹规划 |
| `manipulator-pickplace/` | 机械臂 | 抓取放置 |
| `drone-exploration/` | 无人机 | 自主探索 |
| `wheeled-nav2/` | 轮式 | Nav2 导航 |
| `multi-robot-swarm/` | 多机 | 蜂群协同 |
| `biped-walk/` | 双足 | 步行控制 |
| `underwater-nav/` | AUV | 水下导航 |
| `sensor-fusion-locate/` | 通用 | 传感器融合 |
| `aerial-photography/` | 无人机 | 航拍任务 |
| `industrial-integration/` | 工业 | ROS2-PLC 集成 |

</details>

---

## 🎯 原仓库翻译

本项目从 [tukuaiai/vibe-coding-cn](https://github.com/tukuaiai/vibe-coding-cn) 的 Vibe Coding 哲学衍生而来，专注文 ROS2 机器人开发领域，将通用 Vibe Coding 方法论落地为可编译的代码和工具。

> **一句话目标：** 让 AI 帮你写 ROS2 代码，先做出能跑的，再慢慢优化。

---

## 📄 许可证

Apache-2.0 · [LICENSE](LICENSE)
