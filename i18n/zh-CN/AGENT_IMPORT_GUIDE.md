# AI 智能体加载 VibeCoding 技能与提示词指南

> 本教程详细说明如何让 AI 智能体正确加载和使用 vibe-coding-ros2 项目中的 Skills（技能）和 Prompts（提示词），以实现高效的 ROS2 开发工作流。

---

## 0. 一键初始化（推荐）

在项目根目录执行：

```bash
./init-agent.sh --target all
```

可选参数：
- `--target all`：同时初始化 VS Code Copilot 与 Cursor
- `--target copilot`：仅初始化 VS Code Copilot
- `--target cursor`：仅初始化 Cursor

初始化后会自动生成：
- `.github/copilot-instructions.md`（Copilot 项目级守则）
- `.cursor/rules/vibe-coding-ros2.mdc`（Cursor 全局规则）
- `.vscode/mcp.json` 与 `.cursor/mcp.json`（MCP 配置模板）
- `agents/generated/skill-index.md`（全量技能索引）
- `agents/generated/context-index.md`（准则/提示词/指南索引）
- `agents/generated/agent-bootstrap.md`（统一引导入口）

---

## 1. 项目资源概览

### 1.1 技能（Skills）

技能是模块化的能力定义，采用 **分类体系** 组织：

#### 技能分类维度

| 维度 | 说明 |
|------|------|
| **机器人类型** | multi_rotor_uav / quadruped / humanoid / manipulator / wheeled_vehicle |
| **功能领域** | perception / localization / navigation / motion-control / skill-planning / action |
| **通用技能** | ros2基础、交叉编译、调试等 |

#### 技能目录结构

```
agents/skills/
├── common/                    # 通用 ROS2 开发技能
│   ├── ros2-package-generator/      # 包生成器
│   ├── ros2-debugging/               # 调试技能
│   ├── arm64-cross-compile/         # ARM64交叉编译
│   ├── ros2-action-communication/   # Action通信
│   ├── ros2-component/              # 组件开发
│   ├── ros2-topic-communication/     # Topic通信
│   └── ... (更多通信、生命周期等技能)
│
├── edge-platforms/            # 边缘计算平台
│   ├── rockchip-rknn/               # 瑞芯微 RKNN
│   │   ├── rknn-model-conversion/  # 模型转换
│   │   ├── rknn-inference-runtime/ # 推理运行时
│   │   ├── rknn-camera-driver/      # 相机驱动
│   │   └── rknn-npu-profiling/      # NPU性能分析
│   ├── nvidia-cuda/                 # CUDA编程
│   │   ├── cuda-programming/        # 编程基础
│   │   ├── cuda-optimization/       # 性能优化
│   │   ├── cuda-libraries/          # 加速库
│   │   └── cuda-profiling/          # 性能分析
│   ├── nvidia-jetpack/              # Jetson开发
│   │   ├── jetpack-setup/           # 环境配置
│   │   ├── deepstream/              # 视频分析
│   │   ├── tensorrt/                # 推理优化
│   │   └── ros2-integration/        # ROS2集成
│   └── digiwheel-sunrise/           # 地瓜旭日 (已移除)
│
├── multi_rotor_uav/           # 多旋翼无人机 (PX4)
│   ├── perception/            # 感知类
│   │   ├── px4-sensor-config/       # 传感器配置
│   │   └── px4-vision-nav/          # 视觉导航
│   ├── localization/          # 定位类
│   │   └── px4-multicopter-dev/    # 多旋翼开发
│   ├── navigation/            # 导航类
│   │   ├── px4-debug-logging/      # 日志调试
│   │   ├── px4-flight-mode/        # 飞行模式
│   │   └── px4-mc-tuning/          # 多旋翼调参
│   ├── skill-planning/        # 技能规划类
│   │   └── px4-ros2/                # PX4-ROS2集成
│   └── action/                # 执行类
│       ├── px4-firmware-build/     # 固件编译
│       ├── px4-airframe/            # 机身配置
│       ├── px4-dev-env/              # 开发环境
│       ├── px4-module-dev/          # 模块开发
│       └── px4-mavlink/             # MAVLink通信
│
├── quadruped/                 # 四足机器人
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── navigation/            # 导航类
│   ├── motion-control/        # 运动控制类
│   ├── skill-planning/        # 技能规划类
│   ├── deeprobotics-quadruped/     # 宇树四足
│   └── unitree-quadruped/          # 深潮四足
│
├── humanoid/                  # 人形机器人
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── navigation/            # 导航类
│   └── skill-planning/        # 技能规划类
│
├── manipulator/               # 机械臂
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── motion-control/        # 运动控制类
│   └── skill-planning/        # 技能规划类
│
└── wheeled_vehicle/           # 轮式车辆
    ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── navigation/            # 导航类
│   └── action/                # 执行类
```

#### 触发词示例

| 技能 | 触发词 |
|------|--------|
| ros2-package-generator | "创建 ROS2 包" / "生成 ROS2 包" |
| ros2-debugging | "调试 ROS2" / "ROS2 问题排查" |
| arm64-cross-compile | "交叉编译 ARM" / "ARM64 编译" |
| px4-ros2 | "PX4 ROS2 集成" / "无人机开发" |
| rknn-model-conversion | "RKNN 模型转换" / "瑞芯微 AI 部署" |
| cuda-optimization | "CUDA 优化" / "GPU 加速" |
| tensorrt | "TensorRT 优化" / "Jetson 推理" |

### 1.2 提示词（Prompts）

提示词是预定义的指令模板，帮助 AI 理解任务上下文：

```
agents/prompts/
├── coding_prompts/         # 编码任务提示词
│   ├── (1,1)_ros2_project_context_generation.md
│   ├── (2,1)_ros2_package_creation.md
│   └── (3,1)_ros2_node_implementation.md
├── system_prompts/         # 系统级提示词
│   └── ros2-developer-system.md
└── user_prompts/           # 用户提示词模板
    └── ros2-common-prompts.md
```

### 1.3 记忆银行（Memory Bank）

上下文文档，维持项目的长期记忆：

```
agents/memory-bank/
├── project-context.md      # 项目上下文
├── implementation-plan.md  # 实施计划
└── progress.md            # 进度追踪
```

### 1.4 机器人指南

针对不同机器人类型的开发指南：

```
agents/robots/
├── multi_rotor_uav/        # 多旋翼无人机指南
├── quadruped/             # 四足机器人指南
├── humanoid/              # 人形机器人指南
├── manipulator/           # 机械臂指南
└── wheeled_vehicle/      # 轮式车辆指南
```

### 1.5 边缘平台知识

针对不同边缘计算平台的开发知识：

```
agents/skills/edge-platforms/
├── rockchip-rknn/          # 瑞芯微 RKNN
├── nvidia-cuda/            # NVIDIA CUDA
└── nvidia-jetpack/         # NVIDIA JetPack (已移除)
```

---

## 2. AI 工具加载方式

### 2.1 技能定位规则

由于技能采用 **分类体系** 组织，AI 需要根据用户需求定位正确的技能：

#### 定位步骤

1. **识别机器人类型**: 从需求中判断是无人机、四足、人形、机械臂还是轮式车辆
2. **确定功能领域**: 判断属于感知、定位、导航、运动控制还是技能规划
3. **匹配具体技能**: 根据上述维度定位具体的 SKILL.md 文件

#### 示例

```
用户需求: "帮我开发一个无人机目标跟踪功能"
定位:
  1. 机器人类型: multi_rotor_uav (多旋翼无人机)
  2. 功能领域: perception (感知)
  3. 具体技能: px4-vision-nav
  4. 技能文件: agents/skills/multi_rotor_uav/perception/px4-vision-nav/SKILL.md
```

### 2.2 VS Code Copilot / GitHub Copilot

**加载技能**：
```
@skills/multi_rotor_uav/perception/px4-vision-nav 开发无人机视觉导航
```

**加载边缘平台技能**：
```
@skills/edge-platforms/rockchip-rknn/rknn-model-conversion 转换YOLO模型
@skills/edge-platforms/nvidia-jetpack/tensorrt 优化推理引擎
```

**加载提示词**：
```
请阅读 agents/prompts/coding_prompts/(2,1)_ros2_package_creation.md
帮我创建一个 ROS2 功能包，包名为 image_processor
```

### 2.3 Cursor

**使用快捷命令**：
```
/ros2-create-pkg    # 创建 ROS2 包
/ros2-debug        # 调试 ROS2
/ros2-cross-compile # 交叉编译
/px4-vision-nav    # 无人机视觉导航
/rknn-convert      # RKNN模型转换
```

**加载提示词文件**：
```
阅读 agents/prompts/system_prompts/ros2-developer-system.md
然后按照系统提示词的方式帮我开发节点
```

### 2.4 Claude CLI / Codex CLI

**通过文件路径引用**：
```bash
# 在对话中直接引用技能文件
cat agents/skills/multi_rotor_uav/perception/px4-vision-nav/SKILL.md

# 让 AI 学习技能格式 - 边缘平台
cat agents/skills/edge-platforms/rockchip-rknn/rknn-model-conversion/SKILL.md

# 让 AI 根据分类定位技能
请先阅读 agents/skills/README.md 了解技能分类
然后帮我开发一个四足机器人的步态控制
```

---

## 3. 智能体正确加载流程

### 3.1 首次交互引导词

当智能体首次处理任务时，使用以下引导词：

```
你好！我是 vibe-coding-ros2 项目助手。

在开始开发之前，请先了解项目资源结构：

1. 技能模块位置：agents/skills/
   - common/        : 通用 ROS2 开发技能
   - edge-platforms/: 边缘计算平台 (RKNN, CUDA, JetPack, 旭日)
   - multi_rotor_uav/: 多旋翼无人机 (PX4)
   - quadruped/     : 四足机器人
   - humanoid/      : 人形机器人
   - manipulator/   : 机械臂
   - wheeled_vehicle/: 轮式车辆

2. 提示词模板位置：agents/prompts/
3. 机器人指南位置：agents/robots/
4. 记忆银行位置：agents/memory-bank/

请先阅读以下关键文件，了解项目的技能分类体系：
- agents/skills/README.md
- agents/prompts/system_prompts/ros2-developer-system.md

阅读完成后，我会告诉你我的开发需求，请按照项目规范提供帮助。
```

### 3.2 任务分发引导词

每个任务开始前，引导智能体根据分类体系定位正确的技能：

```
请先加载以下资源，然后开始任务：

1. 机器人类型：[multi_rotor_uav / quadruped / humanoid / manipulator / wheeled_vehicle / edge-platforms]
2. 功能领域：[perception / localization / navigation / motion-control / skill-planning / action / common]
3. 具体技能：[根据上述维度定位具体 SKILL.md]
4. 提示词：[选择相关提示词]
5. 上下文：[选择相关 memory-bank 或 robot guide]

定位示例:
- 无人机视觉 → multi_rotor_uav/perception/px4-vision-nav
- 四足步态 → quadruped/motion-control
- Jetson推理 → edge-platforms/nvidia-jetpack/tensorrt

加载完成后，请确认你已经理解：
- 技能在分类体系中的位置和作用
- 技能的使用方式和触发条件
- 项目的开发规范和提交要求
```

---

## 4. 技能与提示词协作模式

### 4.1 技能定位流程 (新)

```
用户需求 → 分类体系定位 → 加载对应 SKILL.md → 执行技能
```

定位示例：
```
用户："帮我开发无人机目标跟踪"
定位：
  1. 机器人类型: multi_rotor_uav
  2. 功能领域: perception
  3. 具体技能: px4-vision-nav
  4. 技能执行: 加载 SKILL.md，按指南开发视觉导航功能
```

```
用户："在RK3588上部署YOLO"
定位：
  1. 平台: edge-platforms
  2. 具体平台: rockchip-rknn
  3. 具体技能: rknn-model-conversion
  4. 技能执行: 加载 SKILL.md，按流程转换和部署模型
```

### 4.2 提示词增强流程

```
技能执行 + 提示词模板 → 更精确的输出
```

示例：
```
基础：使用 multi_rotor_uav/skill-planning/px4-ros2 生成PX4-ROS2桥接
增强：同时应用 coding_prompts/(3,1)_ros2_node_implementation.md 中的模板
结果：生成的节点不仅功能完整，还符合项目编码规范
```

### 4.3 Memory Bank 上下文保持

```
每个任务 → 更新 Memory Bank → 保持项目上下文连续性
```

示例：
```
1. 任务开始：加载 agents/memory-bank/project-context.md
2. 开发过程中：在 agents/memory-bank/progress.md 中记录进度
3. 任务完成：更新 memory-bank 文件，保持上下文
```

---

## 5. 最佳实践

### 5.1 智能体端操作规范

1. **先加载，后执行**  
   不要直接开始编码，先加载相关技能和提示词

2. **保持上下文**  
   每个会话开始时读取 memory-bank，项目开发期间持续更新

3. **遵循触发词约定**  
   使用预定义的触发词与技能交互，避免自定义指令

4. **及时保存进度**  
   完成关键步骤后，更新 memory-bank 文件

### 5.2 用户端操作规范

1. **提供清晰需求**  
   明确说明：要做什么、不做什么、目标平台是什么

2. **指定参考资源**  
   如果有特定技能或提示词需要使用，请明确指出文件路径

3. **验证输出**  
   AI 生成代码后，用户应验证其符合项目规范

---

## 6. 故障排查

### 6.1 技能未触发

**问题**：AI 没有识别到触发词  
**解决**：明确告知使用哪个技能，例如："请使用 ros2-package-generator 技能"

### 6.2 提示词未加载

**问题**：AI 忽略提示词模板  
**解决**：直接提供提示词内容，例如："请按照以下模板生成代码：[粘贴模板]"

### 6.3 上下文丢失

**问题**：AI 不记得之前讨论的内容  
**解决**：重新加载 memory-bank，例如："请先阅读 agents/memory-bank/progress.md 了解当前进度"

---

## 7. 快速参考卡

```
┌─────────────────────────────────────────────────────────┐
│                    快速触发词                            │
├─────────────────────────────────────────────────────────┤
│ 创建包      │ @skills/ros2-package-generator            │
│ 调试        │ @skills/ros2-debugging                    │
│ 交叉编译    │ @skills/arm64-cross-compile               │
│ 项目上下文  │ agents/memory-bank/project-context.md      │
│ 实施计划    │ agents/memory-bank/implementation-plan.md  │
│ 进度追踪    │ agents/memory-bank/progress.md             │
└─────────────────────────────────────────────────────────┘
```

---

## 8. 相关文档

- [技能索引](./agents/skills/README.md)
- [提示词库](./agents/prompts/)
- [Memory Bank 模板](./agents/memory-bank/)
- [机器人类型指南](./agents/robots/)
- [贡献指南](../i18n/zh-CN/CONTRIBUTING.md)

---

*本项目遵循 Apache License 2.0 开源协议*