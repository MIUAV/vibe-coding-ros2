# CLAUDE.md — AI Agent Instructions for vibe-coding-ros2

> LLM-assisted ROS2 coding toolkit. Goal: generate C++ code that compiles.

---

## 🚨 Three Fatal Rules

### CMake: ALL THREE export lines required

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)   # link
ament_export_dependencies(rclcpp)        # ✅ mandatory
ament_export_include_directories(include) # ✅ mandatory
ament_export_libraries(${PROJECT_NAME})   # ✅ mandatory
```
Missing any line → link error.

### Node Type: Production = LifecycleNode

| Use | Node Type | Why |
|-----|-----------|-----|
| Production control | `rclcpp_lifecycle::LifecycleNode` | State machine |
| Sensor data | `rclcpp::Node` + `best_effort()` | Lower latency |
| Control commands | `rclcpp::Node` + `reliable()` | No drops |

### QoS: Control = reliable, Sensor = best_effort

```cpp
QoS(10).reliable()    // cmd_vel, lifecycle state ✅
QoS(10).best_effort() // camera, lidar ✅
QoS(10).transient_local() // state broadcast ✅
```

---

## File Creation Order

`package.xml` → `CMakeLists.txt` → `src/*.cpp`

---

## Prohibited

- ❌ `rclcpp::Node` for robot control → use `LifecycleNode`
- ❌ Skip `ament_export_dependencies` even if "it works"
- ❌ `best_effort()` for control commands

---

## Key Tools

**Package generators** (scripts/generators/):
- `ros2-package-generator.sh` — standard package (cpp/python/mixed) + `--verify`
- `ros2-nav2-node-generator.sh` — Nav2 compatible nodes (lifecycle/costmap/controller)
- `ros2-control-node-generator.sh` — ros2_control hardware interface (DiffDrive/JointTrajectory)
- `ros2-moveit-generator.sh` — MoveIt2 (move_group/cartesian/pick_place/mobile_manipulator)
- `ros2-simulator-generator.sh` — Gazebo simulation (diff/manipulator/drone/quadruped/ackermann)
- `ros2-slam-generator.sh` — SLAM configs (2D/3D/cartographer/lidar_imu_fusion/visual)
- `ros2-diagnostics-generator.sh` — robot diagnostics (general/mobile/manipulator/drone)
- `ros2-multi-agent-generator.sh` — multi-robot coordination (formation/auction/BOIDs/ORCA)
- `ros2-behavior-tree-generator.sh` — Behavior Tree (patrol/navigation/pick_place/exploration)
- `ros2-rl-controller-generator.sh` — Deep RL controller (DDPG/PPO/SAC/TD3)
- `ros2-camera-calibration-generator.sh` — camera calibration (intrinsics/extrinsics/hand_eye/lidar_camera)
- `ros2-orchestrate.sh` — **unified orchestrator**: input description → full project

**Verification & debugging:**
- `scripts/ros2-build-verify-loop.sh` — build → fix → retry (3 rounds)
- `scripts/ros2-debug.sh` — 8-category error diagnosis
- `scripts/ros2-cpp-node.sh` — node type: publisher/subscriber/lifecycle/service/action
- `scripts/ros2-format.sh` — clang-format check + auto-format
- `scripts/ros2-cmake-fix.sh` — CMake dependency diagnosis + fix

**Analysis:**
- `scripts/ros2-bag-tool.sh` — ros2 bag log analysis

Always verify: `colcon build --packages-select <pkg>` → 0 errors.
