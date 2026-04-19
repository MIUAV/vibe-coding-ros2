# AGENTS.md — AI Agent Development Rules
Project position
vibe-coding-ros2 is a set of tools to write ROS2 code with LLM assistance, and the target user is the ROS2 robot developer.
Core issues
Three critical weaknesses of LLM in ROS2 development:1. * * CMake Depends on Hell * * — Often misspells' ament_export_dependencies`2. * * QoS silence failed * * — data clearly released but not received by subscribers3. * * Lifecycle State Machine * * — Frequently use `rclcpp:: Node` instead of `LifecycleNode`
Solution
| Tools | Role ||------|------|| `cmake-guard` skill | Enforce rules to block CMake errors || `ros2-qos-checker` skills | QoS compatibility testing || `ros2-debug` skill | Compile/runtime troubleshooting || `colcon build` feedback | Automatic verification after AI generates code |
Programme structure

```
vibe-coding-ros2/
├── README.md              # Quick start + toolchain index
├── AGENTS.md             # This file — AI Agent workflow rules
├── CLAUDE.md              # AI Agent Development Guide
├── SOUL.md               # Project philosophy
├── PROJECT_ROADMAP.md    # Technical roadmap
│
├── agents/
│   ├── skills/           # 19 skill directories (SKILL.md)
│   ├── robots/           # Robot type guides
│   ├── memory-bank/      # AI Agent context memory (project overview/standards/templates)
│   └── prompts/          # Prompt templates
│
├── scripts/
│   ├── generators/       # 21 ROS2 package generators
│   ├── validators/       # SKILL format validation
│   ├── debugger/         # ros2-debug.sh 8-class error diagnosis
│   └── ros2-*.sh         # Various tool scripts
│
└── examples/
    └── mcp-workflow/
        └── cases/        # 12 complete cases (PLAN+SKILL+VERIFY)
```
# # AI Agent workflow

```
User requirement → Interface definition (msg/srv/action)
         → Generate CMakeLists.txt + C++ code
         → colcon build verification
         → If error → analyze → fix → regenerate
```
# # LLM prompt word design principles
1. * * Mandatory rules come first * * — Tell AI what not to do, not what to recommend2. * * Specific Code Template * * — Gives the complete compilable code snippet3. * * Validation loop * * — compilation validation must be performed after code generation4. * * Auto-fix bugs * * — Compile bugs directly to tell the AI how to fix them
# # Key Rules
- All ROS2 C + + nodes must use `rclcpp:: Node:: SharedPtr` instead of the naked pointer- `ament_export_dependencies` must be followed by `ament_target_dependencies`- `QoS` combination must match: `best_effort` for sensor, `reliable` for control, `transient_local` for state- Lifecycle nodes must implement all 5 callbacks: `on_configure/on_activate/on_deactivate/on_cleanup/on_shutdown`
