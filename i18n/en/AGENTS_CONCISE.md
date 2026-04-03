# Vibe-Coding-ROS2 - Concise Instruction Card

> Every AI agent must follow this order. Do not skip steps.

---

## Core Rules (Non-Negotiable)

### Execution Order (Mandatory)

```
1. Read AGENTS_CONCISE.md (this document)
2. Read ANTI_PATTERNS.md (C++/Python/QoS/concurrency rules)
3. Read matching examples in examples/ (real code first)
4. Generate code
5. Run self-checklist
6. Update memory-bank/ROS2_MEMORY.md
```

### File Generation Order (Mandatory)

```
Interface definitions (.msg/.srv) -> package.xml -> CMakeLists.txt -> node code -> launch -> build
```

---

## Anti-Patterns Quick View (Forbidden)

```
[DO NOT] Omit find_package(rclcpp REQUIRED)
[DO NOT] Omit ament_target_dependencies
[DO NOT] Omit install(TARGETS ...)
[DO NOT] Omit ament_package()
[DO NOT] Use dependencies in package.xml without matching <depend>
[DO NOT] Add rosidl interfaces without rosidl_default_generators
[DO NOT] Use rclpy.init() without try/finally and rclpy.shutdown()
[DO NOT] Create launch files without LaunchDescription([...])
[DO NOT] Use raw pointers in C++ nodes (use SharedPtr)
[DO NOT] Ignore QoS mismatch (sensor=best_effort, cmd=reliable)
[DO NOT] Sleep/block/call rclcpp::shutdown() inside callbacks
[DO NOT] Use MultiThreadedExecutor without mutex protection
[DO NOT] Make service calls without timeout wait_for()
[DO NOT] Assume install/setup.bash is already sourced
```

Full rules: ANTI_PATTERNS.md

---

## Runnable Example Code

```
examples/
|- ros2-minimal/
|  |- cpp_publisher/      # C++ publisher + QoS + wall_timer
|  `- py_subscriber/      # Python subscriber + rclpy pattern
|- ros2-lifecycle/
|  `- lifecycle_sensor/   # Lifecycle node state machine
`- ros2-service/
   `- add_two_ints/       # Service + client + timeout guard
```

All examples are buildable:
```bash
colcon build --packages-select <pkg> --symlink-install
ros2 run <pkg> <node>
```

---

## Node Templates

### C++ (Standard)

```cpp
#include <rclcpp/rclcpp.hpp>

class MyNode : public rclcpp::Node {
public:
  MyNode() : Node("my_node") {
    pub_ = create_publisher<std_msgs::msg::String>("/topic", 10);
    RCLCPP_INFO(get_logger(), "Started");
  }
private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MyNode>());
  rclcpp::shutdown();
  return 0;
}
```

### Python

```python
def main():
    rclpy.init(args=args)
    try:
        rclpy.spin(node)
    finally:
        rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---

## Memory Convention

```
File: /tmp/vibe-ros2-memory.md or memory-bank/ROS2_MEMORY.md
At start: read
After each completed module: update
```

---

## Quality Self-Checklist

```
[ ] package.xml includes all <depend>
[ ] CMakeLists.txt includes find_package + ament_target_dependencies + install + ament_package
[ ] C++ uses SharedPtr (no raw new/delete)
[ ] QoS: sensor=best_effort, cmd=reliable
[ ] Python has rclpy.shutdown() in try/finally
[ ] launch has complete LaunchDescription() structure
[ ] service calls use timeout wait_for()
[ ] reminder to source install/setup.bash is included
[ ] colcon build passes
```

---

See AGENTS.md for the full workflow and ANTI_PATTERNS.md for detailed constraints.
