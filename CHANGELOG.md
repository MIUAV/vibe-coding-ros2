# CHANGELOG.md — Vibe-Coding-ROS2

All notable changes to this project are documented here.

---

## [Unreleased] — Latest Development

### Added
### Examples Added
- `examples/ros2-action-server/` — Fibonacci Action Server (Goal/Feedback/Result)
- `examples/ros2-service-server/` — AddTwoInts sync service server
- `examples/ros2-composable-node/` — rclcpp_components dynamic loading (Zero-Copy)
- `examples/ros2-param-service/` — Dynamic parameter node (on_parameter_changed callback)
- `examples/ros2-launch-params/` — Launch argument passthrough (namespace/remapping)
- `examples/ros2-tf2/` — TF2 broadcaster (static + dynamic transforms)
- `examples/ros2-robot-description/` — Complete URDF (base_link + wheels + caster + laser)
- `examples/ros2-imu-sensor/` — IMU publisher (BEST_EFFORT QoS, 200Hz)
- `examples/lifecycle_controller/` — LifecycleNode with state machine
- `examples/wheeled_diff_drive/` — Diff drive controller (cmd_vel → wheel velocity)

### Tools & Scripts Added
- `scripts/ros2-env-check.sh` — ROS2 environment diagnostic (7 checks)
- `scripts/ros2-monitor.sh` — Runtime node/topic/service monitor
- `scripts/ros2-bag-tool.sh` — ROS2 bag record/play/info
- `scripts/generators/ros2-cpp-node.sh` — C++ node generator (6 types)
- `CLAUDE.md` — AI agent development instructions
- `CONTRIBUTING.md` — contribution guide
- `.github/workflows/ros2-build.yml` — GitHub Actions CI (ubuntu-22.04 + ros:humble)
- `.github/pull_request_template.md` — PR checklist template
- `.vscode/tasks.json` — VSCode build/test/validate tasks
- `scripts/generators/ros2-cpp-node.sh` — C++ node generator (publisher/subscriber/lifecycle/service/timer)
- `scripts/validators/skill-frontmatter-validator.sh` — SKILL.md validation (276 files)
- `SOUL.md` — project philosophy (vibe-coding is engineering, not magic)
- `SYSTEM.md` — mandatory AI rules (CMake/QoS/Lifecycle)
- `AGENTS.md` — project overview and structure

### Skills Added (P1 Complete)
- `agents/skills/ros2-debug/` — compile/runtime/QoS/Lifecycle debugging
- `agents/skills/ros2-qos-checker/` — QoS compatibility checker with matrix
- `agents/skills/navigation/nav2-config/` — Nav2 50+ parameter cheatsheet
- `agents/skills/ros2-cmake-guard/` — CMake dependency rules

### Scripts Added
- `scripts/ros2-build-feedback.sh` — auto-build verifier with error classification
- `scripts/mcp/ros-mcp-integration.sh` — MCP server launcher
- `scripts/mcp/mcp-agent-orchestrator.sh` — multi-agent orchestrator
- `scripts/generators/ros2-package-generator.sh` — ROS2 package generator

---

## [0.1.0] — Initial Project Setup

### Added
- 272 SKILL.md files across 77 skill categories
- `agents/prompts/` — coding prompts and user prompts
- `agents/documents/` — development methodology, tutorials, guides
- `examples/mcp-workflow/` — MCP multi-agent workflow documentation
- `examples/memory-bank-example/` — project memory bank template
- `examples/rclcpp-minimal/` — compilable C++ ROS2 node examples

---

## Project Stats

| Metric | Value |
|--------|-------|
| Total Commits | 27+ |
| SKILL.md Files | 276 |
| Skill Categories | 77 |
| GitHub Stars | (see repo) |
| ROS2 Distro | Humble |
