# CHANGELOG.md — Vibe-Coding-ROS2

All notable changes to this project are documented here.

---

## [Unreleased] — Latest Development

### Examples (Complex Task Workflows)

examples/ now follows a strict structure: `SKILL.md` + `PLAN.md` + `VERIFY.md` for complex multi-phase tasks. Code snippets belong in `agents/skills/`, not here.

- `examples/mcp-workflow/` — MCP multi-agent orchestration framework (MCP-SIM/MCP-BUILD/MCP-DEBUG)
- `examples/memory-bank-example/` — Project memory bank template
- `examples/go2-scurve/` — Quadruped S-curve trajectory (5 phases, quantitative verification)
- `examples/manipulator-pickplace/` — Arm pick-place task (5 phases, ≥80% success rate)
- `examples/drone-exploration/` — UAV autonomous exploration (5 phases, Octomap + RRT*)

### Tools & Scripts

- `scripts/ros2-build-feedback.sh` — Auto-build verifier with error classification
- `scripts/ros2-env-check.sh` — ROS2 environment diagnostic (7 checks)
- `scripts/ros2-monitor.sh` — Runtime node/topic/service monitor
- `scripts/ros2-bag-tool.sh` — ROS2 bag record/play/info
- `scripts/generators/ros2-package-generator.sh` — ROS2 package generator
- `scripts/generators/ros2-cpp-node.sh` — C++ node generator (6 types)
- `scripts/mcp/ros-mcp-integration.sh` — MCP server launcher
- `scripts/mcp/mcp-agent-orchestrator.sh` — Multi-agent orchestrator
- `scripts/validators/skill-frontmatter-validator.sh` — SKILL.md validation (276 files, 0 errors)

### Core Docs

- `SOUL.md` — Project philosophy (vibe-coding is engineering, not magic)
- `SYSTEM.md` — Mandatory AI rules (CMake/QoS/Lifecycle)
- `CLAUDE.md` — AI agent development instructions
- `AGENTS.md` — Project overview and structure
- `CHECKLIST.md` — 6-step development quality checklist
- `QUICKREF.md` — ROS2 single-page quick reference card
- `CONTRIBUTING.md` — Contribution guide + SKILL.md format
- `ANTI_PATTERNS.md` — ROS2 common anti-patterns (CMake/QoS/Lifecycle/C++)
- `PROJECT_ROADMAP.md` — Technical roadmap + P0/P1/P2 status
- `ARCHITECTURE_REPORT.md` — Project architecture health report
- `CRITICAL_ISSUES.md` — Issue tracker

### CI/CD

- `.github/workflows/ros2-build.yml` — GitHub Actions (ubuntu-22.04 + ros:humble)
- `.github/pull_request_template.md` — PR checklist template
- `.vscode/tasks.json` — VSCode build/test/validate tasks

### Skills (P1 Complete)

- `agents/skills/ros2-debug/` — compile/runtime/QoS/Lifecycle debugging
- `agents/skills/ros2-qos-checker/` — QoS compatibility checker
- `agents/skills/ros2-cmake-guard/` — CMake dependency rules
- `agents/skills/navigation/nav2-config/` — Nav2 50+ parameter cheatsheet

---

## [0.1.0] — Initial Project Setup

### Added
- 272 SKILL.md files across 77 skill categories
- `agents/prompts/` — coding prompts and user prompts
- `agents/documents/` — development methodology, tutorials, guides
- `examples/mcp-workflow/` — MCP multi-agent workflow documentation
- `examples/memory-bank-example/` — project memory bank template

---

## Project Stats

| Metric | Value |
|--------|-------|
| Total Commits | 170+ |
| SKILL.md Files | 276 |
| Skill Categories | 77 |
| ROS2 Distro | Humble |
