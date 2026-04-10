# Memory Bank — ROS2 开发记忆库

> AI Agent 工作时的上下文记忆。按需读取，避免重复踩坑。
> 使用方式：复制对应模板到 `active-context.md`，或直接引用。

---

## 核心文件（必读）

| 文件 | 内容 |
|------|------|
| `project-panorama.md` | 项目定位、愿景、技术栈 |
| `architecture-decisions.md` | CMake/QoS/Lifecycle/Nav2/MoveIt 决策 |
| `coding-standards.md` | 命名规范 + 可编译代码模板 |
| `common-pitfalls.md` | 常见错误 + 规避方案 |
| `toolchain-guide.md` | 工具链用法 + i18n 翻译工作流 |

---

## 🔀 自动切换模板（`templates/`）

AI Agent 启动时，根据上下文自动加载对应模板。

### 三维度切换

| 维度 | 数量 | 用途 |
|------|------|------|
| `robot-type/` | 7 种机器人 | 机器人专用 Topic、依赖包、参数 |
| `task-type/` | 7 种任务 | 任务专用算法、工具链、代码模式 |
| `phase/` | 6 个阶段 | 开发阶段检查清单、里程碑 |

详细索引：
- **`templates/robot-type/_INDEX.md`** — 7 个机器人模板一览
- **`templates/task-type/_INDEX.md`** — 7 个任务模板一览
- **`templates/phase/_INDEX.md`** — 6 个阶段模板一览

### Robot-Type 模板（7种）

| 机器人 | 文件 | 关键内容 |
|--------|------|---------|
| 轮式移动机器人 | `robot-type/wheeled-vehicle.md` | DiffDrive/Ackermann、Nav2、cmd_vel |
| 无人机 | `robot-type/multi-rotor-uav.md` | PX4/MAVROS、Offboard、安全规则 |
| 四足机器人 | `robot-type/quadruped.md` | 步态类型、LowCmd/HighCmd |
| 机械臂 | `robot-type/manipulator.md` | MoveIt2、IK、抓取规划 |
| 人形机器人 | `robot-type/humanoid.md` | CoM/ZMP、WBC、全身运动学 |
| 水下机器人 | `robot-type/underwater.md` | AUV/ROV、水声通信、压力密封 |
| 多机器人系统 | `robot-type/multi-robot.md` | ORCA/BOIDs/拍卖算法 |

### Task-Type 模板（7种）

| 任务 | 文件 | 关键内容 |
|------|------|---------|
| 导航/路径规划 | `task-type/navigation.md` | Nav2 组件、Lifecycle、故障排查 |
| 感知/目标检测 | `task-type/perception.md` | YOLO/PCL/OpenCV、推理加速 |
| 运动控制 | `task-type/motion-control.md` | PID/MPC/WBC、控制频率 |
| 仿真/数字孪生 | `task-type/simulation.md` | Gazebo/Isaac/Mujoco、plugin |
| 多机协同 | `task-type/multi-agent.md` | ORCA/BOIDs、Auction |
| 强化学习控制 | `task-type/reinforcement-learning.md` | DDPG/PPO/SAC、Sim2Real |
| 建图/SLAM | `task-type/slam-mapping.md` | Cartographer/VINS、LIO-SAM |

### Phase 模板（6阶段）

| 阶段 | 文件 | 关键内容 |
|------|------|---------|
| 需求分析 | `phase/1-requirements.md` | 检查清单、输出格式 |
| 架构设计 | `phase/2-architecture.md` | 包结构、Topic/Service/Action |
| 包骨架生成 | `phase/3-prototyping.md` | 生成命令、CMake 三行必须 |
| 功能开发 | `phase/4-implementation.md` | Lifecycle 模板、自测命令 |
| 集成测试 | `phase/5-integration.md` | Gazebo/Nav2 验证、性能基准 |
| 部署运维 | `phase/6-deployment.md` | Docker、systemd、远程调试 |

---

## 🔄 激活方式

### 方式 1：手动复制（推荐）
```bash
# 激活单个模板
cp agents/memory-bank/templates/robot-type/multi-rotor-uav.md \
   agents/memory-bank/active-context.md

# 组合多个维度
cat agents/memory-bank/templates/robot-type/multi-rotor-uav.md \
    agents/memory-bank/templates/task-type/navigation.md \
    > agents/memory-bank/active-context.md
```

### 方式 2：自动切换脚本
```bash
bash agents/memory-bank/templates/auto-switch.sh "做一个无人机导航包"
# 输出：
# [Robot] Detected: multi-rotor-uav
# [Task] Detected: navigation
```

---

## 📖 使用流程

```
1. 读取项目全景（首次）→ project-panorama.md
2. 确定开发阶段 → templates/phase/N-xxx.md
3. 确定机器人类型 → templates/robot-type/xxx.md
4. 确定任务类型 → templates/task-type/xxx.md
5. 按需查规范 → coding-standards.md / common-pitfalls.md
```

---

## 🌐 i18n 多语言文档

翻译工具：`i18n/translate-docs.sh`

```bash
# 设置 API Key
export DEEPL_API_KEY=xxx  # 或 Google Translate (无需key)

# 翻译单个文件
bash i18n/translate-docs.sh README.md ja-JP --deepl

# 批量翻译目录
bash i18n/translate-docs.sh agents/memory-bank/ zh-CN --deepl
```
