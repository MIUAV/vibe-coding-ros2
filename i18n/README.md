# i18n — 多语言文档

> vibe-coding-ros2 项目的多语言翻译文档目录。

---

## 项目简介

**vibe-coding-ros2** — AI 辅助 ROS2 开发工具链。

用 LLM 辅助编写 ROS2 代码的工具集，让 AI 生成的代码可以直接编译运行，无需人工修复 CMake/QoS/Lifecycle 错误。

**一句话总结：** 输入自然语言 → 输出可编译的 ROS2 包。

---

## 核心功能

### 🎯 痛点解决

用 AI 写 ROS2 代码有三个常见坑，本工具链全部堵住：

| 痛点 | 问题 | 解决 |
|------|------|------|
| CMake 依赖地狱 | 经常漏写 `ament_export_dependencies` | 模板自动包含导出三行 |
| QoS 静默失败 | 发布/订阅成功但收不到数据 | 强制规范 QoS 组合 |
| Lifecycle 状态机 | 用普通 Node 而非 LifecycleNode | 生产环境强制 LifecycleNode |

### 🛠️ 工具链

```
接口定义 ──→ 包骨架生成 ──→ 编译验证 ──→ 错误修复
   可选          必选             自动

22 个生成器：包 / 节点 / Nav2 / MoveIt / SLAM / 仿真 / RL / ...
验证闭环：colcon build → 错误分析 → AI 修复 → 重试（3轮）
```

### 📦 已包含

- **22 个生成器** — 覆盖 ROS2 全场景开发
- **12 个完整案例** — PLAN + SKILL + VERIFY
- **19 个技能目录** — AI Agent 专用技能定义
- **20 个 Memory-Bank 模板** — 机器人/任务/阶段三维自动切换
- **CI/CD 流水线** — Humble / Iron / Jazzy 多版本编译

---

## 目录结构

```
vibe-coding-ros2/
├── i18n/                    # 多语言文档（本目录）
│   ├── translate-docs.sh     # 翻译脚本
│   └── README.zh-CN.md      # 中文版
│       README.ja-JP.md      # 日文版
│       CLAUDE.zh-CN.md      # 中文版 CLAUDE
│       ...
│
├── agents/
│   ├── memory-bank/         # AI Agent 上下文记忆
│   │   ├── templates/       # 自动切换模板（20个）
│   │   └── ...
│   ├── skills/              # 技能定义
│   └── prompts/             # 提示词模板
│
├── scripts/
│   └── generators/          # 22 个生成器脚本
│
└── examples/
    └── mcp-workflow/
        └── cases/           # 12 个案例
```

---

## 快速开始

```bash
# 1. 生成 ROS2 包
bash scripts/generators/ros2-package-generator.sh my_controller cpp rclcpp,std_msgs

# 2. 编译验证（自动修复错误）
bash scripts/ros2-build-verify-loop.sh my_controller

# 3. 生成节点代码
bash scripts/generators/ros2-cpp-node.sh lifecycle my_controller rclcpp,std_msgs
```

---

## 翻译工作流

### 环境准备

```bash
# DeepL API（推荐）
export DEEPL_API_KEY=your_key_here

# 或 Google Translate（无需 key）
```

### 翻译文档

```bash
# 翻译单个文件
bash i18n/translate-docs.sh README.md ja-JP --deepl

# 批量翻译
bash i18n/translate-docs.sh agents/memory-bank/ ja-JP --deepl
```

---

## 支持语言

| 代码 | 语言 | 状态 |
|------|------|------|
| `zh-CN` | 简体中文 | ✅ 原文 |
| `zh-TW` | 繁体中文 | 待翻译 |
| `ja-JP` | 日语 | 待翻译 |
| `ko-KR` | 韩语 | 待翻译 |
| `en-US` | 英语 | 参考 |
| `de-DE` | 德语 | 待翻译 |

---

## 翻译术语表

| 英文 | 中文 | 日文 | 韩文 |
|------|------|------|------|
| Lifecycle Node | 生命周期节点 | ライフサイクルノード | 라이프사이클 노드 |
| CMake | CMake | CMake | CMake |
| QoS | 服务质量 | QoS | QoS |
| Nav2 | Nav2 | Nav2 | Nav2 |
| MoveIt | MoveIt | MoveIt | MoveIt |
| Gazebo | Gazebo | Gazebo | Gazebo |
| colcon | colcon | colcon | colcon |
| ament_export | ament导出 | amentエクスポート | ament 내보내기 |
| odometry | 里程计 | オドメトリ |里程계 |
| SLAM | SLAM | SLAM | SLAM |
| TF2 | TF2 变换 | TF2 座標変換 | TF2 좌표 변환 |
