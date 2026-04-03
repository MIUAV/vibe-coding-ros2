# Vibe Coding ROS2 Multilingual Project Guide

> This directory stores multilingual documentation for the vibe-coding-ros2 project, helping AI agents follow consistent and practical development workflows.

---

## Project Structure Overview

```
vibe-coding-ros2/
├── agents/                   # Agent root directory
│   ├── skills/               # Skill modules
│   │   ├── README.md         # Skill index
│   │   ├── ros2-package-generator/
│   │   ├── ros2-debugging/
│   │   └── arm64-cross-compile/
│   ├── prompts/              # Prompt templates
│   │   ├── coding_prompts/
│   │   ├── system_prompts/
│   │   └── user_prompts/
│   ├── robots/               # Robot-type guides
│   │   ├── common/
│   │   ├── wheeled_vehicle/
│   │   ├── quadruped/
│   │   ├── manipulator/
│   │   ├── humanoid/
│   │   └── multi_rotor_uav/
│   ├── documents/            # Documentation assets
│   │   ├── Methodology_and_Principles/
│   │   ├── Templates_and_Resources/
│   │   └── Tutorials_and_Guides/
│   └── memory-bank/          # Memory Bank
│       ├── project-context.md
│       ├── implementation-plan.md
│       └── progress.md
├── i18n/                     # Multilingual docs (this directory)
│   ├── README.md             # Language index
│   ├── en/                   # English docs
│   │   ├── README.md
│   │   └── CHANGELOG.md
│   └── zh-CN/                # Simplified Chinese docs
│       ├── README.md
│       └── CHANGELOG.md
└── README.md                 # Main project guide
```

---

## Skill Modules in Detail

### 1. ROS2 Package Generator (`agents/skills/ros2-package-generator/`)

**Purpose**: Generate a complete ROS2 package scaffold.

**Trigger phrases**:
- "Create a ROS2 package"
- "Create a package"
- "generate ros2 package"

**Capabilities**:
- Generate a standard `CMakeLists.txt`
- Generate `package.xml` dependency configuration
- Generate node code skeletons
- Generate custom msg/srv/action interfaces
- Generate launch files
- Generate parameter config files

**Output structure**:
```
package_name/
├── CMakeLists.txt
├── package.xml
├── include/package_name/
├── src/
├── launch/
├── config/
├── msg/
├── srv/
└── test/
```

---

### 2. ROS2 Debugging Skill (`agents/skills/ros2-debugging/`)

**Purpose**: Debug ROS2 nodes, analyze topics, and replay bags.

**Trigger phrases**:
- "Debug ROS2"
- "ros2 debug"
- "Troubleshoot issue"

**Capabilities**:
- Node debugging (`ros2 node`)
- Topic analysis (`ros2 topic`)
- Service debugging (`ros2 service`)
- Parameter debugging (`ros2 param`)
- Bag record and playback
- rqt tool usage

**Common command quick reference**:

| Category | Command | Description |
|------|------|------|
| Node | `ros2 node list` | List all nodes |
| Node | `ros2 node info /node_name` | Inspect node details |
| Topic | `ros2 topic list` | List all topics |
| Topic | `ros2 topic echo /topic_name` | Inspect topic payload |
| Topic | `ros2 topic hz /topic_name` | Check publish frequency |
| Service | `ros2 service list` | List all services |
| Param | `ros2 param list` | List all parameters |
| Bag | `ros2 bag record /topic` | Record a topic |
| Bag | `ros2 bag play bag_name` | Replay a bag |

---

### 3. ARM64 Cross-Compile (`agents/skills/arm64-cross-compile/`)

**Purpose**: Cross-compile from x86 development machines to ARM64 targets.

**Target platforms**:
- NVIDIA Jetson OrinNX
- RDK-X5 (Horizon)
- Other ARM64 embedded devices

**Trigger phrases**:
- "Cross compile ARM"
- "cross compile ARM"
- "ARM64 build"

**Toolchain configuration**:
```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_SYSROOT /opt/orin_sysroot)
```

**Docker build environment**:
```bash
docker run -d --name orin-cross \
	-v /path/to/rootfs:/opt/orin_sysroot:ro \
	-v /workspace/ros2_ws:/workspace/ros2_ws \
	ros2-humble-cross-compile sleep infinity
```

---

## Development Workflow

### 1. Environment Setup

```bash
# Clone the project
git clone https://github.com/MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2

# Install dependencies
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Source ROS2
source /opt/ros/humble/setup.bash
```

### 2. Create a New Package

```
@skills/ros2-package-generator create a perception package
```

The agent will automatically generate:
- Package structure
- `CMakeLists.txt`
- `package.xml`
- Basic node skeletons
- Launch configuration

### 3. Cross-Compile

```
Use the arm64 cross-compile skill to build the current package
```

### 4. Debug

```
Use the ros2 debugging skill to analyze /scan topic data
```

---

## Robot-Type Guides

### Wheeled Vehicles (`agents/robots/wheeled_vehicle/`)

Suitable for:
- Smart carts
- AGVs
- Cleaning robots

### Quadruped Robots (`agents/robots/quadruped/`)

Suitable for:
- Biomimetic quadrupeds
- Inspection robots

### Manipulators (`agents/robots/manipulator/`)

Suitable for:
- Industrial robot arms
- Service manipulators
- Collaborative robots (Cobots)

### Humanoid Robots (`agents/robots/humanoid/`)

Suitable for:
- Biped humanoids
- Human-like research platforms

### Multi-Rotor UAVs (`agents/robots/multi_rotor_uav/`)

Suitable for:
- Quad/hex/octo rotor aircraft
- UAV control systems
- Autonomous flight applications

---

## Contribution Convention (Apache 2.0)

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### `type` Categories

| Type | Description |
|------|------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation change |
| style | Formatting/style only (no logic change) |
| refactor | Refactoring |
| perf | Performance optimization |
| test | Test-related changes |
| chore | Build/tooling/maintenance changes |

### Example

```
feat(perception): add lidar point cloud processing node

- implement point cloud filtering
- add downsampling
- integrate PCL

Closes #123
```

### Pull Request Principles

1. **Atomic changes**: one PR should focus on one concern.
2. **Reviewability**: reviewers should understand changes quickly.
3. **Testing**: include required tests.
4. **Documentation**: update relevant docs.
5. **Sign-off**: all commits should satisfy DCO requirements.

---

## Apache 2.0 License

```
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

Copyright [2026] [MIUAV Organization]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
```

Full license text: [LICENSE](LICENSE)

---

## Quick Start

```bash
# 1. Initialize workspace
mkdir -p ~/vibe_ws/src
cd ~/vibe_ws
source /opt/ros/humble/setup.bash

# 2. Create package
# use @skills/ros2-package-generator

# 3. Build
colcon build

# 4. Run
source install/setup.bash
ros2 run <package_name> <node_name>

# 5. Debug
# use @skills/ros2-debugging
```

---

## Get Help

- Check `agents/skills/README.md` for available skills
- Check `agents/documents/Tutorials_and_Guides/` for detailed tutorials
- Check `agents/memory-bank/` for project context
- Check [Agent Import Guide](./AGENT_IMPORT_GUIDE.md) for AI tool integration
