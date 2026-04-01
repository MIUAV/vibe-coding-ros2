# 版本日志

本项目的所有重要变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/spec/v2.0.0.html)。

---

## [Unreleased] - 2026-04-01

### 新增

- **贡献指南**: 添加双语的 `CONTRIBUTING.md` 贡献指南文档
- **发布流程优化**: 重构 `publish.sh` 脚本以支持 PR 工作流

### 文档更新

- **AGENT_IMPORT_GUIDE.md**: 新增 AI 智能体加载指南，详细说明技能和提示词的加载方式

---

## [0.0.1] - 2026-04-01

### 新增

- **技能模块**
  - `ros2-package-generator`: 完整的 ROS2 功能包生成器
  - `ros2-debugging`: 节点调试、话题分析、bag 回放
  - `arm64-cross-compile`: x86 到 ARM64 交叉编译支持

- **提示词模板**
  - `coding_prompts/`: ROS2 项目上下文、包创建、节点实现
  - `system_prompts/`: ROS2 开发者系统提示词
  - `user_prompts/`: 常用用户提示词

- **机器人类型指南**
  - `wheeled_vehicle/`: 智能小车、AGV、清洁机器人
  - `quadruped/`: 四足巡检机器人
  - `manipulator/`: 工业机械臂、服务机器人、协作机器人
  - `humanoid/`: 双足人形机器人
  - `multi_rotor_uav/`: 多旋翼无人机控制系统

- **文档资料**
  - `Methodology_and_Principles/`: 开发经验、架构原则
  - `Templates_and_Resources/`: 记忆银行模板、ROS2 项目模板
  - `Tutorials_and_Guides/`: 交叉编译、Docker 配置、调试指南

- **记忆银行**
  - `project-context.md`: 项目上下文文档
  - `implementation-plan.md`: 实施计划
  - `progress.md`: 进度追踪

- **国际化支持**
  - `zh-CN/`: 简体中文文档

### 开源协议

- 基于 Apache License 2.0 开源
- 版权所有 [2026] [MIUAV Organization]
