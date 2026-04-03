# Anti-Patterns - Common AI Mistakes

> These are the most common ROS2 development mistakes made by AI assistants. Treat each `[DO NOT]` item as a mandatory check before generating code.

---

## CMakeLists.txt

```
[DO NOT] Omit find_package(rclcpp REQUIRED)
  -> Always declare every required dependency first.

[DO NOT] Omit ament_target_dependencies()
  -> Targets must be linked after add_library()/add_executable().

[DO NOT] Omit install(TARGETS ...)
  -> Build may pass, but runtime install will fail.

[DO NOT] Omit ament_package()
  -> Package cannot be discovered correctly.

[DO NOT] Mix up ament_cmake and ament_python
  -> C++ packages must use ament_cmake.

[DO NOT] Use add_executable where add_library is required by your architecture
  -> Shared libraries are needed when other packages link against your target.
```

---

## package.xml

```
[DO NOT] Use a package without declaring <depend>
  -> Build error: package 'xxx' not found.

[DO NOT] Omit rosidl_default_generators for interface packages
  -> Message/service generation fails.

[DO NOT] Add build_depend but forget exec_depend
  -> Runtime cannot find shared libraries.

[DO NOT] Use old format without proper export/dependency metadata
  -> Downstream packages fail to resolve dependencies.

[DO NOT] Omit <buildtool_depend>ament_cmake</buildtool_depend>
  -> Package will not compile.
```

---

## Python Nodes

```
[DO NOT] Use rclpy.init() with MultiThreadedExecutor without clean shutdown logic
  -> Ctrl+C may not terminate process.

[DO NOT] Run package before sourcing install/setup.bash
  -> package not found.

[DO NOT] Forget if __name__ == '__main__':
  -> Node executes unintentionally on import.

[DO NOT] Mix rclpy and rclcpp in the same process
  -> Unsupported process model.
```

---

## C++ Nodes

```
[DO NOT] Mix raw node object and Node::SharedPtr types incorrectly
  -> Type mismatch and lifecycle bugs.

[DO NOT] Perform long blocking operations inside callbacks
  -> Main executor loop stalls.
  -> Use timer/offloaded worker/callback groups instead.

[DO NOT] Omit rclcpp::init() / rclcpp::shutdown()
  -> Resource initialization/cleanup is broken.

[DO NOT] Create SharedPtr cyclic references
  -> Memory leaks.
  -> Use std::weak_ptr to break cycles.
```

---

## Launch Files

```
[DO NOT] Omit LaunchDescription([...])
  -> Launch startup fails.

[DO NOT] Create Node entries without required fields
  -> package, executable, name, output are mandatory.

[DO NOT] Skip remappings/parameters when behavior depends on runtime config
  -> Defaults may be wrong.

[DO NOT] Run os.system("source ...") inside launch.py expecting shell effect
  -> Does not affect current launch environment.

[DO NOT] Put multiple packages in one launch file without namespace strategy
  -> Topic and node-name collisions.
```

---

## Message / Service / Action

```
[DO NOT] Add malformed spacing/format in .msg/.srv/.action files
  -> Interface generation fails.

[DO NOT] Omit --- separator in .srv definition
  -> Request/response parsing breaks.

[DO NOT] Leave action result/feedback types invalid
  -> Action server can crash.
```

---

## Naming Conventions

```
[DO NOT] Use invalid package naming style for ROS2
  -> Keep package names lowercase and underscore-safe.

[DO NOT] Use camelCase topic names
  -> Prefer snake_case topics, e.g. /cmd_vel.

[DO NOT] Use identifiers conflicting with language keywords
  -> class/public/private, etc.

[DO NOT] Hardcode namespaces in source code
  -> Use launch arguments or parameters.
```

---

## Build and Run

```
[DO NOT] source workspace before running colcon build
  -> Artifacts do not exist yet.

[DO NOT] skip --symlink-install during iterative development
  -> Every edit requires full rebuild.

[DO NOT] ignore ROS_DOMAIN_ID / network config on multi-machine setups
  -> Discovery and communication fails.

[DO NOT] run stale binaries after source edits without rebuilding
  -> Behavior does not match current code.
```

---

## Quick Check Commands

```bash
# CMakeLists.txt checks
grep -c "find_package" CMakeLists.txt
grep -c "ament_target_dependencies" CMakeLists.txt
grep -c "install(TARGETS" CMakeLists.txt
grep -c "ament_package" CMakeLists.txt

# package.xml checks
grep -c "<depend>" package.xml

# Python checks
grep -c "rclpy.shutdown" my_node.py
grep -c "if __name__" my_node.py

# Launch checks
grep -c "LaunchDescription" my.launch.py
```

---

ANTI_PATTERNS.md must be reviewed before every code generation session.

---

# C++ and ROS2 Concurrency Safety Rules

> These are the highest-risk failure points in ROS2 C++ code. Follow all `[OK]` and `[DO NOT]` constraints.

---

## 1. Smart Pointers (Required)

```
[OK] Prefer smart pointers in ROS2 C++:
  - std::make_shared<T>() for SharedPtr
  - std::make_unique<T>() for UniquePtr

[DO NOT] Use raw new/delete for nodes and managed entities.
  Bad: Node::SharedPtr node = new Node();
  Good: Node::SharedPtr node = std::make_shared<Node>();

[DO NOT] Keep unmanaged callback ownership patterns.
  Keep subscription/publisher/service handles as SharedPtr members.
```

### Capturing `this` in callbacks

```cpp
auto sub = create_subscription<std_msgs::msg::String>(
    "/topic", 10,
    [this](const std_msgs::msg::String::SharedPtr msg) {
        RCLCPP_INFO(get_logger(), "Got: %s", msg->data.c_str());
    }
);
```

```
[DO NOT] perform lifetime-unsafe operations such as deleting self from callbacks.

[DO NOT] create SharedPtr cycles:
  class A { std::shared_ptr<B> b_; };
  class B { std::shared_ptr<A> a_; };
  -> leak
[OK] Use std::weak_ptr to break cycles.
```

---

## 2. QoS Configuration (Required)

### QoS principles

```
QoS is a communication contract, not a minor tuning knob.

Reliability:
  - BEST_EFFORT: may drop packets (sensor streams)
  - RELIABLE: guaranteed delivery (control commands)

History:
  - KEEP_LAST(n)
  - KEEP_ALL (use carefully)

Depth:
  - queue size coupled with history strategy

Durability:
  - VOLATILE
  - TRANSIENT_LOCAL
```

### Common QoS scenarios

```cpp
// Sensor stream
rclcpp::QoS qos_sensor(5);
qos_sensor.best_effort();

// Command stream (/cmd_vel)
rclcpp::QoS qos_cmd(1);
qos_cmd.reliable();

// Service-like request/reply channel
rclcpp::QoS qos_svc(1);
qos_svc.reliable();

// Lifecycle status publication
rclcpp::QoS qos_state(10);
qos_state.reliable().transient_local();
```

### Frequent QoS mismatch issue

```
[DO NOT] publish with RELIABLE and subscribe with BEST_EFFORT (or reverse)
  -> silent failure (no data, often no explicit error)

[OK] Check:
  ros2 topic info /topic_name
```

---

## 3. Executor Concurrency Model (Choose one)

```
ROS2 executor choices:
1) SingleThreadedExecutor (safest default)
2) MultiThreadedExecutor (requires thread safety design)
3) StaticSingleThreadedExecutor (specialized optimization)
4) Experimental/static variants

[DO NOT] mix incompatible spinning models in one control flow.
```

### Thread safety rules

```
[DO NOT] call rclcpp::shutdown() in callbacks
[DO NOT] block callbacks for long durations
[DO NOT] write shared state from multiple callbacks without synchronization
[DO NOT] instantiate core communication entities in unsafe callback paths

[OK] Protect shared state with mutex/atomic.
```

```cpp
std::mutex data_mutex_;
std::atomic<bool> ready_{false};

auto sub = create_subscription<std_msgs::msg::String>(
    "/topic", 10,
    [this](const std_msgs::msg::String::SharedPtr msg) {
      std::lock_guard<std::mutex> lock(data_mutex_);
      latest_msg_ = msg;
    }
);
```

---

## 4. Lifecycle Nodes

```
[DO NOT] implement critical control nodes as plain nodes when deterministic lifecycle is needed.
[OK] Use LifecycleNode with explicit configure/activate/deactivate/cleanup transitions.
```

Lifecycle skeleton:

```cpp
#include <rclcpp_lifecycle/lifecycle_node.hpp>

class MyLifecycleNode : public rclcpp_lifecycle::LifecycleNode {
public:
  using CallbackReturn =
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn;

  MyLifecycleNode() : LifecycleNode("my_lifecycle_node") {}

  CallbackReturn on_configure(const rclcpp_lifecycle::State &) {
    pub_ = create_publisher<std_msgs::msg::String>("/output", 10);
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_activate(const rclcpp_lifecycle::State &) {
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_deactivate(const rclcpp_lifecycle::State &) {
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_cleanup(const rclcpp_lifecycle::State &) {
    pub_.reset();
    return CallbackReturn::SUCCESS;
  }

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
};
```

---

## 5. WaitSet and Guard Conditions

```
[DO NOT] use busy-wait/sleep polling for high-performance async flows.
[OK] use rclcpp::WaitSet for event-driven waiting.
```

```cpp
rclcpp::WaitSet wait_set{};
wait_set.add_subscription(sub1_);
wait_set.add_subscription(sub2_);
wait_set.add_timer(timer_);

auto result = wait_set.wait(std::chrono::seconds(1));
```

---

## 6. Timers and Callback Period

```
[DO NOT] run heavy tasks directly in timer callbacks.
  -> callback backlog and timing drift

[OK] offload heavy work to callback groups/thread pools/async workers.
```

---

## 7. Cross-Node Deadlock Detection

```
[WARNING] Mutual waiting between nodes can deadlock.

[OK] enforce timeout on async service calls:
```

```cpp
auto future = client->async_send_request(request);
if (future.wait_for(std::chrono::seconds(5)) != std::future_status::ready) {
  RCLCPP_WARN(logger, "Service call timeout");
}
```

---

## Fast Self-Check

```
[ ] replace raw new/delete with make_shared/make_unique
[ ] callback ownership/lifetime is safe
[ ] QoS is explicit (sensor=best_effort, cmd=reliable)
[ ] shared variables are mutex/atomic guarded in multi-thread mode
[ ] lifecycle callbacks implemented when using LifecycleNode
[ ] timer callbacks remain lightweight
[ ] service calls have timeout guards
[ ] SharedPtr cycles broken by weak_ptr
[ ] launch files include LaunchDescription()
[ ] remind users to source install/setup.bash
```

---

# QoS Quick Card (Most frequent silent failures)

```
QoS mismatch => silent failure (no explicit error, no data)

Publisher QoS         Subscriber QoS        Communicates?
----------------------------------------------------------
reliable(10)       -> reliable(10)          YES
best_effort(5)     -> best_effort(5)        YES
reliable(10)       -> best_effort(5)        NO
best_effort(5)     -> reliable(10)          NO
```

## Scenario -> QoS choice

| Scenario | Reliability | History | Depth | Durability |
|----------|-------------|---------|-------|------------|
| Raw sensor stream | best_effort | KEEP_LAST | 5 | VOLATILE |
| Control command (/cmd_vel) | reliable | KEEP_LAST | 1 | VOLATILE |
| Config sync | reliable | KEEP_LAST | 1 | TRANSIENT_LOCAL |
| Map/state publication | reliable | KEEP_LAST | 10 | TRANSIENT_LOCAL |
| Logging/debug info | best_effort | KEEP_LAST | 5 | VOLATILE |
| Service call | reliable | KEEP_LAST | 1 | VOLATILE |

## C++ QoS examples

```cpp
rclcpp::QoS qos_sensor(5);
qos_sensor.best_effort();

rclcpp::QoS qos_cmd(1);
qos_cmd.reliable();

rclcpp::QoS qos_state(10);
qos_state.reliable().transient_local();
```

## QoS debug commands

```bash
ros2 topic info /topic_name
ros2 topic pub /chatter std_msgs/msg/String "{data: 'test'}" --qos-reliability reliable
ros2 topic echo /chatter --qos-reliability reliable
```

## Common silent-failure situations

```
[DO NOT] camera publisher uses reliable while simulation subscriber expects best_effort.
[DO NOT] lidar publisher uses best_effort while navigation subscriber expects reliable.
[DO NOT] assume same-machine success implies cross-machine success without matching QoS and ROS_DOMAIN_ID.
```

---

# CMakeLists.txt and colcon build Error Quick Reference

> Build error -> likely reason -> fix

| Error | Reason | Fix |
|------|--------|-----|
| `Could not find a package configuration file` | missing find_package | add `find_package(xxx REQUIRED)` |
| `target link libraries without target` | wrong dependency-link order | move `ament_target_dependencies` after target definition |
| `ament_package() must be called once` | duplicate invocation | keep a single `ament_package()` |
| `No CMake file named ament_cmake` | ament_cmake not found | add `find_package(ament_cmake REQUIRED)` |
| `Unable to find package 'rclcpp'` | ROS env not sourced | `source /opt/ros/humble/setup.bash` |
| `package 'xxx' not found in workspace` | package not built | `colcon build --packages-select xxx` |
| `ament_target_dependencies: Cannot find target` | dependency call before target creation | reorder CMake blocks |
| `Unknown CMake command` for ament | dependency/config issue | ensure `ament_cmake` package is installed and found |
| install target/file errors | invalid install path spelling | verify ARCHIVE/LIBRARY/RUNTIME paths |
| module/package not found | missing system package | `sudo apt install ros-humble-xxx` |

## Recommended colcon/CMake order

```
1. cmake_minimum_required(VERSION 3.16)
2. project(pkg_name)
3. find_package(ament_cmake REQUIRED)
4. find_package(rclcpp REQUIRED)
5. find_package(other dependencies REQUIRED)
6. rosidl_generate_interfaces (if custom interfaces exist)
7. add_library or add_executable
8. ament_target_dependencies
9. install(TARGETS ...)
10. install(DIRECTORY ...)
11. ament_package()
```

## package.xml <-> CMakeLists.txt dependency mapping

| package.xml | CMakeLists.txt |
|------------|----------------|
| `<depend>rclcpp</depend>` | `find_package(rclcpp REQUIRED)` |
| `<depend>geometry_msgs</depend>` | `find_package(geometry_msgs REQUIRED)` |
| `<depend>rosidl_default_runtime</depend>` | no direct find_package needed |
| `<exec_depend>xxx</exec_depend>` | runtime only, no build find_package |
| `<buildtool_depend>ament_cmake</buildtool_depend>` | `find_package(ament_cmake REQUIRED)` |
