# Project Panorama — 项目全景

## 项目定位

**vibe-coding-ros2** — AI 辅助 ROS2 开发工具链。目标用户：机器人开发者。核心理念：用 LLM 生成 ROS2 代码时，用经过验证的模板骨架把 CMake/QoS/Lifecycle 三个坑先堵住，再处理业务逻辑。

愿景：输入自然语言描述 → 输出可编译的 ROS2 包。

## 版本状态

- 当前版本：**v0.3.0**（2026-04-07）
- 目标版本：v1.0（用户无需修改生成的代码即可编译运行）

## 技术栈

| 层级 | 技术 |
|------|------|
| 机器人框架 | ROS2 Humble / Iron / Jazzy |
| 编程语言 | C++17 / Python3 |
| 构建系统 | colcon + ament_cmake |
| 仿真 | Gazebo / Isaac Sim / Mujoco / Carla |
| 运动规划 | MoveIt2 / Nav2 |
| 飞控 | PX4（MAVLink） |
| 推理 | OpenVINO / TensorRT / RKNN |
| 视觉 | OpenCV |

## 工具链架构

```
接口定义 ──→ 包骨架生成 ──→ 编译验证 ──→ 错误修复
(可选)        (必选)           (自动)
   │             │              │
   ▼             ▼              ▼
ros2-      ros2-package-  ros2-build-
msg-gen     generator.sh    verify-loop.sh
              │              │
              ▼              ▼
          ros2-cpp-node.sh ←──┘
              │
              ▼
          ros2-launch-gen / ros2-srv-gen / ros2-param-wizard
```

## 目录结构

```
vibe-coding-ros2/
├── README.md / SOUL.md / CLAUDE.md / AGENTS.md / PROJECT_ROADMAP.md  # 核心文档
├── agents/
│   ├── skills/          # 276 个技能定义（SKILL.md）
│   ├── robots/          # 机器人类型指南（uav/humanoid/quadruped...）
│   ├── prompts/         # 提示词模板
│   └── memory-bank/     # AI Agent 上下文记忆（本目录）
├── scripts/
│   ├── generators/      # 22 个生成器脚本
│   ├── translator/      # 多语言翻译脚本
│   │   └── translate-docs.sh   # i18n 翻译工作流
│   ├── debugger/        # ros2-debug.sh
│   ├── validators/      # SKILL 格式验证
│   └── ros2-*.sh        # 各类工具
└── examples/
    └── mcp-workflow/
        └── cases/       # 12 个完整案例（PLAN+SKILL+VERIFY）
```

## 与上游仓库关系

- GitHub: `git@github.com:MIUAV/vibe-coding-ros2.git`
- 分支策略：所有开发在 `latest`，feature 分支按需创建
