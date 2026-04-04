# CLAUDE.md — AI Coding Agent Instructions

You are working on **vibe-coding-ros2**, a ROS2 development toolkit that helps AI agents generate compilable ROS2 code.

## Project Overview

This is a **LLM-assisted ROS2 coding toolkit**, not a robot application. The goal is to generate C++ ROS2 code that actually compiles with `colcon build`.

## Critical Rules

### 1. CMake Dependency Chain (MOST IMPORTANT)

When writing `CMakeLists.txt`, you MUST have ALL THREE of these:

```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)  # Link deps
ament_export_dependencies(rclcpp)                             # Export to dependents
ament_export_include_directories(include)                       # Export headers
ament_export_libraries(${PROJECT_NAME})                        # Export library
```

Without all three `ament_export_*` lines, dependent packages cannot find your headers/libraries.

### 2. Node Type Selection

| Use Case | Node Type | Reason |
|----------|-----------|--------|
| Simple publisher/subscriber | `rclcpp::Node` | Quick and simple |
| Production robot control | `rclcpp_lifecycle::LifecycleNode` | Proper state machine |
| Sensor data | `rclcpp::Node` + `BEST_EFFORT` QoS | Lower latency |
| Control commands | `rclcpp::Node` + `RELIABLE` QoS | No dropped commands |

### 3. QoS Defaults

ROS2 default QoS is `RELIABLE + VOLATILE`. Most cases work fine with defaults.

Common explicit QoS:
```cpp
// Sensor data — allow dropped frames
QoS(10).best_effort()

// Control commands — never drop
QoS(10).reliable()

// Lifecycle state — new subscriber gets last value
QoS(10).transient_local()
```

## File Creation Order

When creating a new ROS2 package, create files in this order:

1. `package.xml` — declare all dependencies first
2. `CMakeLists.txt` — find_package + target + export
3. `src/*.cpp` — implement the node

## Common CMake Errors

| Error | Fix |
|-------|-----|
| `undefined reference to ros2_xxx` | Add `ament_export_dependencies(rclcpp)` |
| `fatal error: rclcpp/rclcpp.hpp: No such file` | Add `find_package(rclcpp REQUIRED)` |
| `ament_export_include_directories: not a directory` | Create `include/<package>/` directory |

## Directory Structure

```
package_name/
├── package.xml              # Dependencies (buildtool_depend, depend)
├── CMakeLists.txt           # Build configuration
├── include/
│   └── package_name/        # Public headers here
├── src/                     # C++ source files
├── launch/                  # .launch.py files
└── config/                  # YAML parameter files
```

## Verification

After writing code, ALWAYS verify:
1. `colcon build --packages-select <package>` runs with 0 errors
2. If errors occur, read them and apply fixes from `agents/skills/ros2-debug/SKILL.md`

## Key Skills

- `agents/skills/ros2-cmake-guard/` — CMake rules (mandatory)
- `agents/skills/ros2-qos-checker/` — QoS compatibility
- `agents/skills/ros2-debug/` — Compile/runtime debugging
- `scripts/ros2-build-feedback.sh` — Auto-build verifier

## Prohibited

- Do NOT use `rclcpp::Node` for production robot control (use LifecycleNode)
- Do NOT skip `ament_export_dependencies` even if it "seems to work"
- Do NOT use `BEST_EFFORT` for control commands
