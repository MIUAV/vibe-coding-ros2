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

- `scripts/ros2-build-verify-loop.sh` — build → fix → retry (3 rounds)
- `scripts/ros2-debug.sh` — 8-category error diagnosis
- `scripts/ros2-package-generator.sh` — full package generator
- `scripts/ros2-cpp-node.sh` — node type: publisher/subscriber/lifecycle/service/action

Always verify: `colcon build --packages-select <pkg>` → 0 errors.
