# CHANGELOG.md — Vibe-Coding-ROS2

All notable changes to this project are documented here.

---

## [Unreleased] — Latest Development

### Added
- `scripts/ros2-env-check.sh` — ROS2 environment diagnostic tool (7 checks)
- `examples/lifecycle_controller/` — compilable LifecycleNode example with state machine
- `CHECKLIST.md` — 6-step development quality checklist
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
