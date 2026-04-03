# AGENTS - VibeCoding-ROS2 Workflow

## Execution Order (Mandatory)

```
1. Read AGENTS_CONCISE.md first
2. Read ANTI_PATTERNS.md second
3. Read skill-index.md to find the right SKILL.md
4. Read the selected SKILL.md for implementation details
5. Write code
6. Run the self-checklist
7. Update ROS2_MEMORY.md
```

## Core Principles

### Interface-First

```
ROS2 development order (must not be reversed):
1. Define .msg / .srv / .action (or use standard interfaces)
2. Configure CMakeLists.txt: rosidl_generate_interfaces
3. Configure package.xml: rosidl dependencies
4. Implement node code
5. Implement launch files
6. Run colcon build
7. Remind users to source install/setup.bash
```

### File Structure Rules

```
pkg_name/
|- package.xml          # Dependency declarations
|- CMakeLists.txt       # Build configuration
|- src/                 # C++ source files
|- msg/                 # .msg definitions
|- srv/                 # .srv definitions
|- action/              # .action definitions
|- launch/              # .launch.py
`- config/              # YAML parameters
```

### Forbidden Items (See ANTI_PATTERNS.md)

- Missing `find_package` in CMakeLists.txt
- Missing `<depend>` in package.xml
- Launch files without `LaunchDescription`
- Not reminding users to `source install/setup.bash`
- Python using `rclpy.init()` without proper shutdown handling

## Memory Convention

```
Workspace temporary memory: /tmp/vibe-ros2-memory.md
Project persistent memory: memory-bank/ROS2_MEMORY.md (project root)

Format:
## Implemented Modules
- pkg_name: [one-line description]

## TODO
- [pkg_name/feature]: [description]

## Known Issues
- [pkg]: [issue description]

At session start -> read
After feature completion -> update
```

## Supported Distros

| Distro | Recommendation |
|--------|----------------|
| Humble | Preferred |
| Iron   | Supported |
| Jazzy  | Supported |
| Foxy   | Use with caution |

## Abbreviations

```
FP  = Frontmatter (YAML header in SKILL.md)
KB  = Knowledge Base (SKILL.md)
AP  = Anti-Patterns (ANTI_PATTERNS.md)
MEM = ROS2_MEMORY.md
```

## Quality Self-Check (Required)

```
[ ] package.xml: all <depend> declared
[ ] CMakeLists.txt: find_package + ament_target_dependencies
[ ] CMakeLists.txt: install(TARGETS ...) + ament_package
[ ] Launch: valid LaunchDescription() structure
[ ] C++: rclcpp::init + rclcpp::shutdown
[ ] Python: rclpy.shutdown() or executor shutdown handled
[ ] User reminded to source install/setup.bash
[ ] Code compiles successfully
```

## Quick Commands

```bash
# Create ROS2 package
ros2 pkg create pkg_name --dependencies rclcpp std_msgs

# Inspect interfaces
ros2 interface show sensor_msgs/msg/LaserScan

# Build (recommended for development)
colcon build --symlink-install

# Quick checks
ros2 pkg list | grep pkg_name
ros2 pkg executables pkg_name
```

---

Full guide: AGENTS_CONCISE.md and relevant SKILL.md files.
