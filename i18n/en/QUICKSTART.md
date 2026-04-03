# VibeCoding-ROS2 Quickstart

> From `git clone` to your first ROS2 package in 5 minutes.

---

## Step 1: Initialize (1 min)

```bash
git clone https://github.com/MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2
./init-agent.sh
```

`init-agent.sh` generates:
- `.gitignore`
- `.github/workflows/ros2-build.yml`
- `.vscode/settings.json`

---

## Step 2: Generate Your First Package (2 min)

```bash
# Generate a ROS2 package (includes CMakeLists.txt + package.xml)
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# Inspect generated files
ls my_robot/
```

Generated structure:
```
my_robot/
|- package.xml        <- Format 3 with dependencies
|- CMakeLists.txt     <- C++17 + find_package + ament_target_dependencies
|- src/
|  `- my_robot_node.cpp
`- launch/
   `- my_robot.launch.py
```

---

## Step 3: Implement Code (1 min)

Edit `src/my_robot_node.cpp` based on examples:

```cpp
// Copy examples/ros2-minimal/cpp_publisher/src/minimal_publisher.cpp
// Replace topic name and message type
```

Useful examples:

```bash
cat examples/ros2-minimal/cpp_publisher/src/minimal_publisher.cpp
cat examples/ros2-minimal/py_subscriber/src/py_subscriber_node.py
cat examples/ros2-lifecycle/lifecycle_sensor/src/lifecycle_sensor_node.cpp
```

---

## Step 4: Build and Run (1 min)

```bash
# Build (--symlink-install avoids full rebuild for source-only changes)
colcon build --packages-select my_robot --symlink-install

# Load ROS2 environment
source install/setup.bash

# Run node
ros2 run my_robot my_robot
```

---

## Step 5: Validate and Debug

```bash
# Validate package structure
bash scripts/check_ros2_package.sh my_robot

# Validate code safety (C++/QoS/concurrency)
bash scripts/validators/ros2-node-validator.sh src/my_robot_node.cpp

# Debug ROS2 environment
bash scripts/debugger/ros2-debug.sh all
```

---

## Common Errors

### "package not found"

```bash
source install/setup.bash
```

### Build error: Could not find a package

- `package.xml` is missing `<depend>`, or
- `CMakeLists.txt` is missing `find_package`

Use:
```bash
bash scripts/check_ros2_package.sh <pkg>
```

### Node runs but no data (silent failure)

Likely QoS mismatch:
```bash
ros2 topic info /your_topic
```

### Build error around ament_target_dependencies

`ament_target_dependencies` must be after `add_library()` or `add_executable()`.

---

## Next: Learn from Examples

```bash
# Build all examples
colcon build --packages-select cpp_publisher py_subscriber lifecycle_sensor add_two_ints --symlink-install

# Run publisher (terminal 1)
ros2 run cpp_publisher minimal_publisher

# Run subscriber (terminal 2)
ros2 run py_subscriber py_subscriber

# Inspect topics
ros2 topic list
ros2 topic echo /chatter
```

---

## Documentation Map

| Goal | Where to go |
|------|-------------|
| Quick workflow rules | `AGENTS_CONCISE.md` |
| C++/QoS/concurrency rules | `ANTI_PATTERNS.md` |
| Generate ROS2 package | `bash scripts/generators/ros2-package-generator.sh` |
| Debug ROS2 | `bash scripts/debugger/ros2-debug.sh` |
| Deploy to ARM | `DEPLOYMENT.md` |
| Find skills | `agents/generated/skill-index.md` |
| Full docs | `README.md` |
