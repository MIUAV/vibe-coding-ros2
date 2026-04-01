# Changelog

All notable changes to the English documentation are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-04-01

### Added

- **Contributing Guide**: Added bilingual `CONTRIBUTING.md` contribution guide document
- **Release Process Optimization**: Refactored `publish.sh` to support PR workflow

### Documentation Updates

- **AGENT_IMPORT_GUIDE.md**: Added AI agent import guide explaining how to load skills and prompts

---


## [0.0.1] - 2026-04-01

### Added

- **Skills Modules**
  - `ros2-package-generator`: Complete ROS2 package structure generator
  - `ros2-debugging`: Node debugging, topic analysis, bag playback
  - `arm64-cross-compile`: x86 to ARM64 cross-compilation support

- **Prompts Templates**
  - `coding_prompts/`: ROS2 project context, package creation, node implementation
  - `system_prompts/`: ROS2 developer system prompts
  - `user_prompts/`: Common user prompts

- **Robot Type Guides**
  - `wheeled_vehicle/`: Smart vehicles, AGV, cleaning robots
  - `quadruped/`: Quadruped robots for inspection
  - `manipulator/`: Industrial arms, service robots, Cobots
  - `humanoid/`: Bipedal humanoid robots
  - `multi_rotor_uav/`: Multi-rotor UAV control systems

- **Documents**
  - `Methodology_and_Principles/`: Development experience, architecture principles
  - `Templates_and_Resources/`: Memory bank template, ROS2 project template
  - `Tutorials_and_Guides/`: Cross-compile, Docker setup, debugging guides

- **Memory Bank**
  - `project-context.md`: Project context documentation
  - `implementation-plan.md`: Implementation planning
  - `progress.md`: Progress tracking

- **I18n Support**
  - `zh-CN/`: Simplified Chinese documentation

### License

- Licensed under Apache License 2.0
- Copyright [2026] [MIUAV Organization]
