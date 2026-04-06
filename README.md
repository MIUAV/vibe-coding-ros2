# Vibe-Coding-ROS2

> AI 辅助 ROS2 开发工具链：生成可编译的包 → 编译验证 → 错误自动修复

---

## 🔥 GitHub Stats

<p align="left">
    <img src="https://visitor-badge.laobi.icu/badge?page_id=MIUAV.vibe-coding-ros2" alt="Visitor Badge" />
    <img src="https://img.shields.io/badge/version-v0.3.0-green?style=flat-square" alt="Version" />
    <img src="https://img.shields.io/badge/ROS2-Humble%20%7C%20Iron%20%7C%20Jazzy-green?style=flat-square" alt="ROS2 Distros" />
    <img src="https://img.shields.io/badge/C%2B%2B-17%2B-blue?style=flat-square" alt="C++ Standard" />
    <img src="https://img.shields.io/badge/workflows-5%20CI%20jobs-blue?style=flat-square" alt="CI Status" />
</p>

## 🔥 痛点 → 解决 → 差异化

<details open>
<summary><b>点击展开 — 3 秒了解这个工具</b></summary>

**痛点：** 用 AI 写 ROS2 代码，CMake 链接错误调试时间比写代码还长。AI 不知道的三个坑：CMake 依赖地狱、QoS 静默失败、Lifecycle 状态机。

**解决：** 提供经过验证的模板骨架（CMakeLists 附带三行导出规则 + 正确的 LifecycleNode + 正确的 QoS），AI 在模板上迭代，编译通过后再处理业务逻辑。

**差异化：** 编译闭环 — `生成 → colcon build → 报错 → AI 修复建议 → 重试`，3 轮内解决 CMake/QoS/Lifecycle 错误。

**工具链架构：**
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

辅助工具: ros2-debug (8类错误诊断) / ros2-format (clang-format) / ros2-cmake-fix
```
</details>

---

## ⚡ 5 分钟快速开始

```bash
# 1. 生成一个 ROS2 包（自动包含正确的 CMakeLists + LifecycleNode）
bash scripts/generators/ros2-package-generator.sh my_controller cpp rclcpp,std_msgs,geometry_msgs

# 2. 编译验证（报错时自动给出修复建议，3 轮重试）
bash scripts/ros2-build-verify-loop.sh my_controller

# 3. 生成节点代码（6种类型可选）
bash scripts/generators/ros2-cpp-node.sh lifecycle my_controller rclcpp,std_msgs

# 4. 启动节点测试
cd my_controller && colcon build && source install/setup.bash
ros2 run my_controller my_controller_node
```

> 每一步都配套验证脚本。跟着做，遇到问题把报错发给 AI：「按上面的规则修复」。

---

## 🔑 核心规则（必读）

<details>
<summary><b>CMake / QoS / Lifecycle 三个致命弱点</b></summary>

### CMake 依赖地狱

ROS2 CMakeLists.txt **必须同时有这三行**，缺一不可：

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)   # 链接依赖
ament_export_dependencies(rclcpp)                             # ✅ 必须
ament_export_include_directories(include)                      # ✅ 必须
ament_export_libraries(${PROJECT_NAME})                       # ✅ 必须
```

> 缺少任意一行 → 链接错误 → 编译失败。

### QoS 静默失败

ROS2 默认 QoS 是 `RELIABLE + VOLATILE`。选错静默不通：

```cpp
// 控制命令（cmd_vel）— 必须可靠
QoS(10).reliable()   // ✅ 控制命令

// 传感器数据（camera/lidar）— 允许丢帧
QoS(10).best_effort()  // ✅ 传感器

// 生命周期状态 — 新订阅者收到最近状态
QoS(10).transient_local()  // ✅ 状态广播
```

### Lifecycle 状态机

生产机器人控制**必须用 LifecycleNode**：

```cpp
// ✅ 正确 — on_configure/on_activate/on_deactivate/on_cleanup
class RobotController : public rclcpp_lifecycle::LifecycleNode { };

// ❌ 错误 — 无法优雅关闭/重启
class RobotController : public rclcpp::Node { };
```
</details>

---

## 🧪 工具链

<details>
<summary><b>点击展开 — 所有脚本一览</b></summary>

### 生成器（scripts/generators/ — 共 22 个）

| 脚本 | 用途 |
|------|------|
| `ros2-package-generator.sh` | 生成 ROS2 包（cpp/python/mixed） |
| `ros2-interface-generator.sh` | 生成 msg/srv/action 接口包 |
| `ros2-msg-generator.sh` | 交互式 .msg 文件向导 |
| `ros2-srv-generator.sh` | 交互式 .srv/.action 向导 |
| `ros2-launch-generator.sh` | 生成 launch.py（lifecycle/normal/component） |
| `ros2-cpp-node.sh` | 生成 C++ 节点（publisher/subscriber/lifecycle/service/action/timer） |
| `ros2-nav2-node-generator.sh` | Nav2 兼容节点（lifecycle/costmap/controller） |
| `ros2-control-node-generator.sh` | ros2_control 硬件接口（DiffDrive/JointTrajectory） |
| `ros2-moveit-generator.sh` | MoveIt2 运动规划（move_group/cartesian/pick_place） |
| `ros2-simulator-generator.sh` | Gazebo 仿真包（diff/manipulator/drone/quadruped） |
| `ros2-slam-generator.sh` | SLAM 配置（2D/3D/cartographer/lidar_imu_fusion） |
| `ros2-diagnostics-generator.sh` | 机器人诊断（general/mobile/manipulator/drone） |
| `ros2-multi-agent-generator.sh` | 多机协调（formation/auction/BOIDs/ORCA） |
| `ros2-behavior-tree-generator.sh` | 行为树（patrol/navigation/pick_place/exploration） |
| `ros2-rl-controller-generator.sh` | 强化学习控制器（DDPG/PPO/SAC/TD3） |
| `ros2-camera-calibration-generator.sh` | 相机标定（内参/外参/手眼/lidar_camera） |
| `ros2-param-generator.sh` | 参数配置（diff/arm/quadrotor/ackermann） |
| `ros2-gazebo-world-generator.sh` | Gazebo 场景（warehouse/office/outdoor/maze/factory） |
| `ros2-mission-generator.sh` | 任务脚本（patrol/survey/inspection/delivery/exploration） |
| `ros2-data-logger.sh` | 数据记录回放（full/sensors/nav） |
| `ros2-orchestrate.sh` | **统一编排器**：描述 → 完整项目 |
| `ros2-safety-generator.sh` | 机器人安全（碰撞检测/急停/地理围栏/HITL） |

### 验证与修复

| 脚本 | 用途 |
|------|------|
| `ros2-build-verify-loop.sh` | 编译 → 错误分析 → LLM 修复建议 → 重试（最多 3 轮） |
| `ros2-build-feedback.sh` | colcon build 错误解释 + 修复建议 |
| `ros2-debug.sh` | 8 类 ROS2 错误自动诊断 |
| `ros2-cmake-fix.sh` | CMake 依赖问题诊断 |
| `ros2-format.sh` | clang-format 格式检查/修复 |

### 辅助工具

| 脚本 | 用途 |
|------|------|
| `ros2-bag-tool.sh` | Bag 日志分析（录制信息 + 频率 + 错误检测） |
| `ros2-param-wizard.sh` | 参数 YAML 生成 + 验证 |
| `ros2-performance-monitor.sh` | 运行时性能监控钩子（C++ header） |

### 测试模板（test-templates/）

| 文件 | 用途 |
|------|------|
| `src/publisher_test.cpp` | gtest 发布者测试（频率 + 线程安全） |
| `src/lifecycle_test.cpp` | gtest 生命周期测试（状态机 + 原子操作） |

</details>

---

## 🗂️ 项目结构

```
vibe-coding-ros2/
├── README.md                    # 本文件
├── SOUL.md / SYSTEM.md / CLAUDE.md  # AI Agent 核心规则
│
├── agents/
│   ├── skills/                 # 276 个技能定义（SKILL.md）
│   └── documents/               # 方法论文档
│
├── scripts/
│   ├── generators/              # 包/节点/接口生成器
│   ├── validators/             # SKILL 格式验证
│   ├── debugger/               # ros2-debug.sh
│   └── ros2-*.sh              # 各类工具脚本
│
└── examples/
    └── mcp-workflow/
        └── cases/             # 12 个完整案例（PLAN+SKILL+VERIFY）
```

---

## 📋 案例索引

| 案例 | 机器人 | 任务 |
|------|--------|------|
| `wheeled-nav2/` | 轮式 | Nav2 导航 |
| `drone-exploration/` | 无人机 | 自主探索 |
| `go2-scurve/` | 四足 | S 曲线轨迹 |
| `manipulator-pickplace/` | 机械臂 | 抓取放置 |
| `lifecycle-node-demo/` | 通用 | LifecycleNode 生产规范 |
| `action-fibonacci-demo/` | 通用 | ROS2 Action 模式 |

每个案例包含 `PLAN.md`（工具链步骤）+ `SKILL.md`（技术规范）+ `VERIFY.md`（验证方法）。

---

## ⚡ 快速开始

```bash
# 第 1 步：克隆
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# 第 2 步：生成包
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 第 3 步：编译验证
bash scripts/ros2-build-verify-loop.sh my_robot

# 第 4 步：生成节点
bash scripts/generators/ros2-cpp-node.sh lifecycle my_robot rclcpp,std_msgs
```

---

## 📄 许可证

Apache-2.0 · [LICENSE](LICENSE)

---

## 🗺️ Roadmap

详见 [PROJECT_ROADMAP.md](PROJECT_ROADMAP.md)（v0.2 → v0.3 → v1.0 路线图）
