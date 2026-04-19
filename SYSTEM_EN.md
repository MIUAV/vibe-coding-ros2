# SYSTEM.md — AI Agent Mandatory Rules
> This document is the highest priority instruction for the AI Agent.* * Violations stop generating * * and no code is output until the rules are met.
---
# # 🚨 Zero Tolerance Rule (Violation = Stop Now)
# # # Rule 0: Templates go first
* * Any ROS2 package generation must start with `scripts/generators/ros2-package-generator.sh` * *:

```bash
bash scripts/generators/ros2-package-generator.sh PKG_NAME cpp rclcpp,std_msgs
```
Creation of CMakeLists.txt/package.xml from scratch is prohibited.After it is generated, it will be appended to its base and will not be overwritten.
# # # Rule 1: CMake three-line export (zero exceptions)
* * Must be followed by * * after all `ament_target_dependencies`:

```cmake
ament_export_dependencies(rclcpp std_msgs ...)   # dependency tree export
ament_export_include_directories(include)          # header path (required when include/ exists)
ament_export_libraries(${PROJECT_NAME})            # library link
```
* * No exceptions.* * Do Not Write These Three = Link Failure = Code Not Available.
# # # Rule 2: LifecycleNode Production Specification
Robot control class node, * * must use * * `rclcpp_lifecycle:: LifecycleNode`:

```cpp
class RobotController : public rclcpp_lifecycle::LifecycleNode {
public:
    RobotController() : rclcpp_lifecycle::LifecycleNode("robot_controller") {}
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_configure(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Configuring");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    // on_activate / on_deactivate / on_cleanup / on_shutdown apply the same
};
```
# # # Rule 3: QoS Portfolio Mandatory Checks
| Data Type | QoS Composition | Consequences of Errors ||---------|---------|---------|| Control commands (cmd_vel) | `QoS (10) .reliable ()` | Not working = robot out of control || Sensors (camera/lidar) | `QoS (10) .best_effort ()` | Blocking = Data Backlog || Lifecycle Status | `QoS (10) .transient_local ()` | No data for new subscribers |
# # # Rule 4: File creation order

```
package.xml → CMakeLists.txt → include/*.hpp → src/*.cpp → launch/*.py → test/*
```
Out-of-order → dependency missing → compilation failed.
---
# # ⚙️ Toolchain binding
All node generation * * must * * use the following script to disallow manual creation:
| Task | Script ||------|------|| Create ROS2 package | `scripts/generators/ros2-package-generator.sh` || Create a C + + node | `scripts/generators/ros2-cpp-node.sh` || Create a Lifecycle Node | `scripts/generators/ros2-cpp-node.sh lifecycle` || Create Nav2 node | `scripts/generators/ros2-nav2-node-generator.sh` || Create ros2_control node | `scripts/generators/ros2-control-node-generator.sh` || Create a MoveIt2 node | `scripts/generators/ros2-moveit-generator.sh` || Compile Validation Loop | `scripts/ros2-build-verify-loop.sh` || Bug Diagnostics | `scripts/debugger/ros2-debug.sh` |
---
# # 🔒 Safety Red Lines
- * * Do not generate * * ROS2 node code for naked pointer management- * * Do not generate * * array index operations with unchecked bounds- * * Do not generate * * code to do `spin ()` outside of `on_configure'- * * Don't generate * * polling loops over 10Hz (with timer callback)
---
# # 📋 AI Workflows
1. * * read * * `CLAUDE.md` (mandatory rule)→ read `soul.md` (project philosophy)2. * * Check the relevant macros in * * `memory-bank/` (architecture-decisions/common-pitfalls)3. * * Generate * * using toolchain scripts without handwriting CMakeLists.txt4. * * Verify * * closed loop with `ros2-build-verify-loop.sh`5. * * Submit * * per `CONTRIBUTING.md` commit specification
---
* The content of this document takes precedence over all other documents.AI reloads each time it starts. *
