# Vibe-Coding-ROS2
> AI-assisted ROS2 development toolchain: Generate → compilable package compilation validation → errors Auto-fix
---
# 🔥 GitHub Stats
<p align="left"><img src="https://visitor-badge.laobi.icu/badge?page_id=MIUAV.vibe-coding-ros2" alt="Visitor Badge" /><img src="https://img.shields.io/badge/version-v0.3.0-green?style=flat-square" alt="Version" /><img src="https://img.shields.io/badge/ROS2-Humble%20%7C%20Iron%20%7C%20Jazzy-green?style=flat-square" alt="ROS2 Distros" /><img src="https://img.shields.io/badge/C%2B%2B-17%2B-blue?style=flat-square" alt="C++ Standard" /><img src="https://img.shields.io/badge/workflows-5%20CI%20jobs-blue?style=flat-square" alt="CI Status" /></p>
# 🔥 Pain → Resolution → Differentiation
<details open><summary><b>Click to expand — 3 seconds to learn about this tool</b></summary>
* * Pain points: * * Writing ROS2 code with AI, CMake link error debugging takes longer than writing code.Three pits the AI doesn't know about: CMake's dependence on hell, QoS silence failure, and the Lifecycle state machine.
* * Resolution: * * Provide a validated template skeleton (CMakeLists comes with three rows of export rules + correct LifecycleNode + correct QoS), AI iterates on the template, compiles and processes business logic after passing.
* * Differentiation: * * Compile closed loop — `Generate → colcon build error → report → AI repair suggestion → retry`, solve CMake/QoS/Lifecycle error in 3 rounds.
* * Toolchain Architecture: * *
```
Interface Definition ──→ Package Skeleton Generation ──→ Build Verification ──→ Error Fixing
(optional)        (required)           (automatic)
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

Auxiliary tools: ros2-debug (8 error diagnostics) / ros2-format (clang-format) / ros2-cmake-fix
```</details>
---
# ⚡ 5 minutes Quick start

```bash
bash scripts/generators/ros2-package-generator.sh my_controller cpp rclcpp,std_msgs,geometry_msgs

bash scripts/ros2-build-verify-loop.sh my_controller

bash scripts/generators/ros2-cpp-node.sh lifecycle my_controller rclcpp,std_msgs

cd my_controller && colcon build && source install/setup.bash
ros2 run my_controller my_controller_node
```
> Each step is accompanied by a validation script.Follow and send the error to the AI if you encounter an issue: “Fix it according to the rules above”.
---
# 🔑 Core Rules (Required Reading)
<details><summary><b>Three Critical Weaknesses in CMake/QoS/Lifecycle</b></summary>
# CMake Depends on Hell
ROS2 CMakeLists.txt * * must have three lines at the same time * *, one of which is indispensable:

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})
```
> Missing any one line → link error → compilation failed.
# QoS silence failed
ROS2 default QoS is` reliable + volatile `.Mispicked silence:

```cpp
// Control commands (cmd_vel) — must be reliable
QoS(10).reliable()   // ✅ Control commands

// Sensor data (camera/lidar) — allow dropped frames
QoS(10).best_effort()  // ✅ Sensors

// Lifecycle state — new subscribers receive latest state
QoS(10).transient_local()  // ✅ State broadcast
```
# Lifecycle State Machine
Production robot control * * must use LifecycleNode * *:

```cpp
// ✅ Correct — on_configure/on_activate/on_deactivate/on_cleanup
class RobotController : public rclcpp_lifecycle::LifecycleNode { };

// ❌ Wrong — cannot gracefully shutdown/restart
class RobotController : public rclcpp::Node { };
```</details>
---
Tool chain
<details><summary><b>Click to expand — all scripts at a glance</b></summary>
# Generators (scripts/generators/— 22 in total)
| Script | Purpose ||------|------|| `ros2-package-generator.sh` | Generate ROS2 package (cpp/python/mixed) || `ros2-interface-generator.sh` | Generate msg/srv/action interface package || `ros2-msg-generator.sh` | Interactive .msg File Wizard || `ros2-srv-generator.sh` | Interactive .srv/.action Wizard || `ros2-launch-generator.sh` | Generate launch.py (lifecycle/normal/component) || `ros2-cpp-node.sh` | Generate C + + nodes (publisher/subscriber/lifecycle/service/action/timer) || `ros2-nav2-node-generator.sh` | Nav2 compatible nodes (lifecycle/costmap/controller) || `ros2-control-node-generator.sh` | ros2_control Hardware Interface (DiffDrive/JointTrajectory) || `ros2-moveit-generator.sh` | MoveIt2 Movement Planning (move_group/cartesian/pick_place) || `ros2-simulator-generator.sh` | Gazebo simulation package (diff/manipulator/drone/quadruped) || `ros2-slam-generator.sh` | slam configuration (2D/3D/cartographer/lidar_imu_fusion) || `ros2-diagnostics-generator.sh` | Robotic Diagnostics (general/mobile/manipulator/drone) || `ros2-multi-agent-generator.sh` | Multi-Machine Coordination (formation/auction/BOIDs/Orca) || `ros2-behavior-tree-generator.sh` | Behavior tree (patrol/navigation/pick_place/exploration) || `ros2-rl-controller-generator.sh` | Reinforcement Learning Controller (DDPG/PPO/SAC/TD3) || `ros2-camera-calibration-generator.sh` | Camera calibration (internal/external/hand-eye/lidar_camera) || `ros2-param-generator.sh` | Parameter Configuration (diff/arm/quadrotor/ackermann) || `ros2-gazebo-world-generator.sh` | Gazebo Scene (warehouse/office/outdoor/maze/factory) || `ros2-mission-generator.sh` | Task script (patrol/survey/inspection/delivery/exploration) || `ros2-data-logger.sh` | Data Log Playback (full/sensors/nav) || `ros2-orchestrate.sh` | * * Unified Orchestrator * *: Describe the → full project || `ros2-safety-generator.sh` | Robot Safety (Crash Detection/Emergency Stop/Geofencing/Hitl) |
# Verification and Repair
| Script | Purpose ||------|------|| `ros2-build-verify-loop.sh` | Compile → Error Analysis → LLM Fix Recommended → Retry (up to 3 rounds) || `ros2-build-feedback.sh` | colcon build Bug Interpretation + Fix Suggestions || `ros2-debug.sh` | Class 8 ROS2 Error Auto Diagnostics || `ros2-cmake-fix.sh` | CMake Dependency Diagnostics || `ros2-format.sh` | clang-format format check/repair |
● Assistive devices
| Script | Purpose ||------|------|| `ros2-bag-tool.sh` | Bag log analysis (recording information + frequency + error detection) || `ros2-param-wizard.sh` | Parameters YAML Generation + Validation || `ros2-performance-monitor.sh` | Runtime Performance Monitoring Hook (C + + header) |
# Test templates (test-templates/)
| Document | Purpose ||------|------|| `src/publisher_test.cpp` | gtest publisher test (frequency + thread safety) || `src/lifecycle_test.cpp` | gtest lifecycle testing (state machine + atomic operation) |
</details>
---
# 🗂️ Project Structure

```
vibe-coding-ros2/
├── README.md
├── SOUL.md / SYSTEM.md / CLAUDE.md
│
├── agents/
│   ├── skills/
│   ├── memory-bank/
│   └── prompts/
│
├── scripts/
│   ├── generators/
│   ├── validators/
│   ├── debugger/               # ros2-debug.sh
│   └── ros2-*.sh
│
└── examples/
    └── mcp-workflow/
        └── cases/
```
---
# 📋 Case Index
| Case | Robot | Task ||------|--------|------|| `wheeled-nav2/` | Wheeled | Nav2 Navigation || `drone-exploration/` | Drone | Explore || `go2-scurve/` | Quadruped | S-curve trajectory || `manipulator-pickplace/` | robotic arm | grab-and-place || `lifecycle-node-demo/` | General | LifecycleNode Production Specification || `action-fibonacci-demo/` | Generic | ROS2 Action Mode |
Each case contains` PLAN.md '(toolchain step) +` SKILL.md '(technical specification) +` VERIFY.md `(verification method).
---
PLAY

```bash
git clone git@github.com:MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

bash scripts/ros2-build-verify-loop.sh my_robot

bash scripts/generators/ros2-cpp-node.sh lifecycle my_robot rclcpp,std_msgs
```
---
LICENSES
Apache-2.0 · [license] (license)
---
# 🗺️ Roadmap
See [PROJECT_ROADMAP.md] (PROJECT_ROADMAP.md) for details (v0.2 → v0.3 → v1.0 Roadmap)
