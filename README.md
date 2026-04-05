# Vibe-Coding-ROS2

> 用 LLM 辅助编写 ROS2 代码的工具集。不是哲学，不是玄学，是能实际生成可编译 ROS2 C++ 代码的工程框架。

---

## 一句话介绍

**Vibe-Coding-ROS2** 是一个以「AI 为主」的开发框架，帮你用自然语言驱动、让 LLM 生成大部分代码，专攻 ROS2 机器人开发中 CMake 依赖地狱、QoS 静默失败、Lifecycle 状态机错误三大痛点。

---

## ⚡ 1 分钟快速开始

```bash
# 第 1 步：克隆项目
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 第 2 步：生成一个 ROS2 包（AI 帮你写代码）
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 第 3 步：编译验证
cd my_robot && colcon build

# 第 4 步：自动检查编译错误
bash ../scripts/ros2-build-feedback.sh .
```

> 跟着做，AI 会帮你完成剩余步骤。每完成一步问 AI：「成功了吗？」再继续。

---

## 核心理念

```
AI 是打字员，不是架构师
AI 生成 → 编译验证 → 错误修正 → 重新生成

可编译 > 看起来对
```

**三个致命弱点，ROS2 开发中 LLM 的：**

| 弱点 | 后果 | 解法 |
|------|------|------|
| CMake 依赖地狱 | 链接失败 | `ros2-cmake-guard` 强制规则 |
| QoS 静默失败 | 数据不通 | `ros2-qos-checker` 兼容性检测 |
| Lifecycle 状态机 | 节点卡住 | `ros2-debug` 调试指南 |

---

## 工具链

| 工具 | 做什么 |
|------|--------|
| `ros2-package-generator.sh` | 一键生成可编译 ROS2 包 |
| `ros2-build-feedback.sh` | 编译后自动分析错误，给出修复建议 |
| `ros2-cpp-node.sh` | 生成 publisher/subscriber/lifecycle/service/timer 节点 |
| `ros2-env-check.sh` | 诊断 ROS2 环境问题（7 项检查）|
| `ros2-monitor.sh` | 运行时节点/话题/服务监控 |
| `ros2-bag-tool.sh` | ROS2 bag 录制与回放 |
| `skill-frontmatter-validator.sh` | 验证 276 个 SKILL.md 格式正确 |
| `ros2-qos-checker` | QoS 兼容性判断（附代码模板）|
| `nav2-config` | Nav2 50+ 参数速查 + 4 大调优场景 |

---

## 项目结构

```
vibe-coding-ros2/
├── SOUL.md                          # 项目哲学
├── SYSTEM.md                        # AI Agent 系统指令（强制规则）
├── CLAUDE.md                        # AI 开发指南
├── CHECKLIST.md                     # 开发质量检查清单
├── QUICKREF.md                      # ROS2 命令速查卡
├── ANTI_PATTERNS.md                 # 反模式文档
│
├── agents/
│   ├── skills/                      # 276 个技能定义（强制规则库）
│   │   ├── ros2-cmake-guard/       # CMake 禁区
│   │   ├── ros2-qos-checker/       # QoS 兼容性
│   │   ├── ros2-debug/             # 调试指南
│   │   └── navigation/nav2-config/ # Nav2 参数
│   │
│   ├── prompts/                    # AI 提示词模板
│   ├── documents/                   # 开发文档
│   └── robots/                     # 机器人类型
│
├── scripts/
│   ├── generators/                  # 代码生成器
│   │   ├── ros2-package-generator.sh
│   │   └── ros2-cpp-node.sh
│   ├── mcp/                         # MCP 多智能体
│   │   ├── ros-mcp-integration.sh
│   │   └── mcp-agent-orchestrator.sh
│   ├── validators/                 # 验证工具
│   └── ros2-build-feedback.sh      # 编译验证
│
└── examples/
    └── mcp-workflow/
        └── cases/                   # 10 个复杂任务案例
            ├── go2-scurve/          # 四足 S 曲线
            ├── manipulator-pickplace/ # 机械臂抓取
            ├── drone-exploration/    # 无人机探索
            ├── wheeled-nav2/        # 轮式导航
            ├── multi-robot-swarm/  # 多机器人蜂群
            ├── biped-walk/         # 双足步行
            ├── underwater-nav/     # 水下 AUV
            ├── sensor-fusion-locate/ # 传感器融合
            ├── aerial-photography/  # 无人机航拍
            └── industrial-integration/ # 工业集成
```

---

## AI Agent 使用指南

**第一步：** 克隆本仓库，AI 阅读 `SOUL.md` + `SYSTEM.md` 了解项目哲学和强制规则。

**第二步：** 选择你要做的任务类型（对应 `examples/mcp-workflow/cases/` 中的 case）。

**第三步：** 用 `ros2-package-generator.sh` 生成代码框架，AI 在 `SYSTEM.md` 规则下填充实现。

**第四步：** `ros2-build-feedback.sh` 自动验证编译错误，AI 修正直到零错误。

---

## 质量保证

- **276 个 SKILL.md** 全部通过 frontmatter 格式验证
- 所有生成代码必须 `colcon build` 零错误
- 违反 `SYSTEM.md` 规则 = 编译失败

---

## 快速链接

| 资源 | 说明 |
|------|------|
| `SOUL.md` | 项目哲学（必读）|
| `SYSTEM.md` | AI 强制规则（必读）|
| `CHECKLIST.md` | 开发质量清单 |
| `ANTI_PATTERNS.md` | 常见反模式 |
| `QUICKREF.md` | ROS2 命令速查 |
| `examples/mcp-workflow/` | MCP 案例库 |

---

## 许可证

Apache-2.0
