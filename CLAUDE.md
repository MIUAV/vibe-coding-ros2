# CLAUDE.md — AI Agent 开发指南

> **目的**：让 AI Agent 生成的 ROS2 代码可直接编译运行，无需人工修复 CMake/QoS/Lifecycle。
> **核心原则**：模板优先、验证闭环、错误不过夜。

---

## 🚨 强制规则（违反 = 代码不可用）

### 规则 1：CMake 导出三合一

每次写 `ament_target_dependencies` 后，**必须**紧接着写：

```cmake
ament_export_dependencies(rclcpp std_msgs)              # 必须
ament_export_include_directories(include)                 # 有 include 时必须
ament_export_libraries(${PROJECT_NAME})                  # 必须
```

**缺失后果**：`undefined reference` 链接错误，100% 编译失败。

### 规则 2：生产节点用 LifecycleNode

| 场景 | 节点类型 | 原因 |
|------|---------|------|
| 机器人控制、导航、传感器管理 | `rclcpp_lifecycle::LifecycleNode` | 需要优雅启停 |
| 临时工具节点、一次性脚本 | `rclcpp::Node` | 快速开发 |

### 规则 3：QoS 组合正确

```cpp
// 控制命令（cmd_vel）→ 必须可靠
QoS(10).reliable()              // ✅

// 传感器数据（camera/lidar）→ 允许丢帧
QoS(10).best_effort()           // ✅

// 生命周期状态广播 → 新订阅者收到最近值
QoS(10).transient_local()       // ✅
```

### 规则 4：文件创建顺序

```
package.xml → CMakeLists.txt → include/*.hpp → src/*.cpp → launch/*.py
```

---

## 📁 项目结构速查

```
vibe-coding-ros2/
├── CLAUDE.md              # 本文件 — AI 必读
├── AGENTS.md              # 项目定位 + Agent 工作流
├── SOUL.md                # 项目哲学
├── PROJECT_ROADMAP.md     # v0.3 → v1.0 路线图
│
├── agents/
│   ├── memory-bank/       # ⭐ AI 工作记忆（按需读取）
│   │   ├── project-panorama.md        # 项目全景
│   │   ├── architecture-decisions.md   # 技术决策
│   │   ├── coding-standards.md         # 代码规范 + 模板
│   │   ├── common-pitfalls.md          # 常见错误 + 修复
│   │   ├── toolchain-guide.md          # 工具链用法
│   │   └── templates/                  # memory-bank 模板
│   │       ├── robot-type/             # 按机器人类型切换
│   │       ├── task-type/              # 按任务类型切换
│   │       └── phase/                  # 按开发阶段切换
│   │
│   ├── skills/            # 276 个技能定义（SKILL.md）
│   ├── robots/            # 机器人类型指南
│   └── prompts/           # 提示词模板
│
├── scripts/
│   ├── generators/        # 22 个生成器
│   ├── translator/         # i18n 翻译工作流
│   │   └── translate-docs.sh
│   └── ros2-*.sh          # 工具脚本
│
└── examples/
    └── mcp-workflow/
        └── cases/         # 12 个完整案例
```

---

## 🛠️ 工具链使用决策树

```
需求是什么？
│
├─ "生成一个 ROS2 包" → ros2-package-generator.sh
├─ "生成一个节点" → ros2-cpp-node.sh（选类型）
├─ "生成 Nav2 节点" → ros2-nav2-node-generator.sh
├─ "生成 MoveIt2 节点" → ros2-moveit-generator.sh
├─ "生成仿真环境" → ros2-simulator-generator.sh
├─ "生成 SLAM 配置" → ros2-slam-generator.sh
├─ "生成诊断节点" → ros2-diagnostics-generator.sh
├─ "生成多机协调" → ros2-multi-agent-generator.sh
├─ "生成行为树" → ros2-behavior-tree-generator.sh
├─ "生成 RL 控制器" → ros2-rl-controller-generator.sh
├─ "生成 launch 文件" → ros2-launch-generator.sh
├─ "生成接口定义" → ros2-interface-generator.sh
└─ "不知道用什么" → ros2-orchestrate.sh（统一编排器）
```

---

## 🔧 标准工作流

### 工作流 A：新建包（最常见）

```bash
# 1. 生成包骨架（C++，自动 --verify）
bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp <deps> --verify

# 2. 生成节点代码
bash scripts/generators/ros2-cpp-node.sh <node_type> <pkg_name> <deps>
# node_type: publisher | subscriber | lifecycle | service | action | timer | parameters

# 3. 编译验证（3轮自动修复）
bash scripts/ros2-build-verify-loop.sh <pkg_name>

# 4. 运行测试
cd <pkg_name> && colcon build && source install/setup.bash
ros2 run <pkg_name> <node_name>
```

### 工作流 B：Nav2 导航包

```bash
# 1. 生成包 + Nav2 依赖
bash scripts/generators/ros2-package-generator.sh my_nav cpp nav2_msgs,nav2_util,nav2_core --verify

# 2. 生成 Nav2 兼容节点
bash scripts/generators/ros2-nav2-node-generator.sh lifecycle my_nav nav2_msgs

# 3. 生成 Nav2 配置
bash scripts/generators/ros2-param-generator.sh nav2

# 4. 生成 launch
bash scripts/generators/ros2-launch-generator.sh nav2_bringup my_nav
```

### 工作流 C：Gazebo 仿真

```bash
# 1. 生成仿真包
bash scripts/generators/ros2-simulator-generator.sh drone my_drone_sim

# 2. 生成 Gazebo world
bash scripts/generators/ros2-gazebo-world-generator.sh outdoor

# 3. 生成 SITL 启动
bash scripts/generators/ros2-launch-generator.sh gazebo_drone my_drone_sim
```

---

## 📦 依赖速查表

| 功能 | 依赖包 | CMake | package.xml |
|------|--------|-------|-------------|
| 基础节点 | `rclcpp` | `find_package(rclcpp REQUIRED)` | `<depend>rclcpp</depend>` |
| 生命周期 | `rclcpp_lifecycle` | `find_package(rclcpp_lifecycle REQUIRED)` | `<depend>rclcpp_lifecycle</depend>` |
| 消息类型 | `std_msgs`, `geometry_msgs` | `find_package(std_msgs REQUIRED)` | `<depend>std_msgs</depend>` |
| Nav2 | `nav2_msgs`, `nav2_util` | `find_package(nav2_msgs REQUIRED)` | `<depend>nav2_msgs</depend>` |
| MoveIt2 | `moveit_ros_planning_interface` | `find_package(moveit_ros_planning_interface REQUIRED)` | `<depend>moveit_ros_planning_interface</depend>` |
| 变换 | `tf2_ros`, `tf2_geometry_msgs` | `find_package(tf2_ros REQUIRED)` | `<depend>tf2_ros</depend>` |
| 点云 | `pcl_ros`, `sensor_msgs` | `find_package(pcl_ros REQUIRED)` | `<depend>pcl_ros</depend>` |
| 图像 | `image_transport`, `cv_bridge` | `find_package(image_transport REQUIRED)` | `<depend>image_transport</depend>` |
| 动作 | `action_msgs`, `rclcpp_action` | `find_package(action_msgs REQUIRED)` | `<depend>action_msgs</depend>` |
| 参数 | `rclcpp_components` | `find_package(rclcpp_components REQUIRED)` | `<depend>rclcpp_components</depend>` |

---

## 🐛 错误自诊断流程

```
编译报错？
├─ "undefined reference" → 缺 ament_export_dependencies → 加那三行
├─ "package not found" → package.xml 缺 <depend> → 补上
├─ "No rule to make target" → CMakeLists.txt target 名称写错
├─ "QoS" 相关 → ros2 topic info /xxx --verbose 查两端 QoS
└─ "lifecycle" 状态不对 → on_configure/activate/deactivate 必须实现

运行时报错？
├─ 收不到数据 → QoS 不匹配 或 topic 名称不匹配
├─ TF 异常 → 查看 tf_tree：ros2 run tf2_tools view_frames
├─ 参数读不到 → declare_parameter 必须在使用前
└─ 节点崩溃 → 查看 dmesg 或 ros2 run rclcpp component_container --ros-args --log-level debug
```

---

## 🎯 AI Agent 行为准则

1. **先生成再优化** — 先生成能编译的代码，再改善逻辑
2. **不自创模板** — 优先使用 `scripts/generators/` 中的生成器
3. **每步验证** — `colcon build --packages-select <pkg>` 确认编译通过
4. **错误不过夜** — 编译错误必须当场修，不留到下次
5. **CMake 三行必须** — 任何时候不省略 `ament_export_dependencies/include/libraries`
