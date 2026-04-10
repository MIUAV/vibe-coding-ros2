# Memory Bank — ROS2 开发记忆库

> AI Agent 工作时的上下文记忆。按需读取，避免重复提问和重复踩坑。

---

## 文件索引

| 文件 | 内容 |
|------|------|
| `project-panorama.md` | 项目定位、愿景、技术栈总览 |
| `architecture-decisions.md` | 已确认的技术选型和架构决策 |
| `coding-standards.md` | 代码规范、命名约定、可编译模板 |
| `common-pitfalls.md` | 常见错误模式和规避方案 |
| `toolchain-guide.md` | 工具链使用记忆（生成器、验证器、i18n） |

---

## 🎯 自动切换模板（`templates/`）

AI Agent 启动时，根据上下文自动加载对应模板：

### 模板类型

| 类型 | 说明 | 激活方式 |
|------|------|---------|
| `robot-type/` | 按机器人类型（7种） | 检测到对应机器人关键词时 |
| `task-type/` | 按任务类型（7种） | 检测到对应任务关键词时 |
| `phase/` | 按开发阶段（6个） | 检测到对应阶段关键词时 |

### Robot-Type 模板（7种）

| 机器人 | 文件 | 关键内容 |
|--------|------|---------|
| 轮式移动机器人 | `robot-type/wheeled-vehicle.md` | DiffDrive/Ackermann、Nav2、cmd_vel |
| 无人机 | `robot-type/multi-rotor-uav.md` | PX4/MAVROS、Offboard、安全规则 |
| 四足机器人 | `robot-type/quadruped.md` | 步态类型、LowCmd/HighCmd |
| 机械臂 | `robot-type/manipulator.md` | MoveIt2、IK、抓取规划 |
| 人形机器人 | `robot-type/humanoid.md` | CoM/ZMP、 WBC、全身运动学 |
| 水下机器人 | `robot-type/underwater.md` | AUV/ROV、水声通信、压力密封 |
| 多机器人系统 | `robot-type/multi-robot.md` | 编队/ORCA/拍卖算法 |

### Task-Type 模板（7种）

| 任务 | 文件 | 关键内容 |
|------|------|---------|
| 导航/路径规划 | `task-type/navigation.md` | Nav2 组件、Lifecycle、故障排查 |
| 感知/目标检测 | `task-type/perception.md` | YOLO/PCL/OpenCV、推理加速 |
| 运动控制 | `task-type/motion-control.md` | PID/MPC/WBC、控制频率 |
| 仿真/数字孪生 | `task-type/simulation.md` | Gazebo/Isaac/Mujoco、plugin |
| 多机协同 | `task-type/multi-agent.md` | ORCA/BOIDs、Auction |
| 强化学习控制 | `task-type/reinforcement-learning.md` | DDPG/PPO/SAC、Sim2Real |
| 建图/SLAM | `task-type/slam-mapping.md` | Cartographer/ORB-SLAM3、VINS |

### Phase 模板（6阶段）

| 阶段 | 文件 | 关键内容 |
|------|------|---------|
| 需求分析 | `phase/1-requirements.md` | 检查清单、输出格式 |
| 架构设计 | `phase/2-architecture.md` | 包结构、Topic/Service/Action 设计 |
| 包骨架生成 | `phase/3-prototyping.md` | 生成命令、CMake 三行必须 |
| 功能开发 | `phase/4-implementation.md` | Lifecycle 模板、自测命令 |
| 集成测试 | `phase/5-integration.md` | Gazebo/Nav2 验证、性能基准 |
| 部署运维 | `phase/6-deployment.md` | Docker、systemd、远程调试 |

---

## 🔄 模板激活方式

### 方式 1：手动复制（推荐）
```bash
# 激活无人机开发模板
cp agents/memory-bank/templates/robot-type/multi-rotor-uav.md \
   agents/memory-bank/active-context.md

# 激活导航任务模板
cp agents/memory-bank/templates/task-type/navigation.md \
   agents/memory-bank/active-context.md
```

### 方式 2：自动切换脚本
```bash
bash agents/memory-bank/templates/auto-switch.sh "我想做一个无人机导航包"
# 输出：
# [Robot] Detected: multi-rotor-uav
# [Task] Detected: navigation
# 复制对应模板到 active-context.md
```

### 方式 3：多模板组合
```bash
# 同时激活机器人类型 + 任务类型
cat agents/memory-bank/templates/robot-type/multi-rotor-uav.md \
    agents/memory-bank/templates/task-type/navigation.md \
    > agents/memory-bank/active-context.md
```

---

## 📖 使用流程

1. **读取项目全景**（首次）：`memory-bank/project-panorama.md`
2. **读取开发阶段**（按需）：`templates/phase/` 对应阶段
3. **读取机器人类型**（按需）：`templates/robot-type/` 对应机器人
4. **读取任务类型**（按需）：`templates/task-type/` 对应任务
5. **读取通用规则**（按需）：`coding-standards.md`、`common-pitfalls.md`

---

## i18n 多语言文档

翻译工具：`scripts/translator/translate-docs.sh`

```bash
# 翻译单个文件
bash scripts/translator/translate-docs.sh README.md ja-JP --deepl

# 翻译目录
bash scripts/translator/translate-docs.sh agents/memory-bank/ zh-CN --deepl
```
