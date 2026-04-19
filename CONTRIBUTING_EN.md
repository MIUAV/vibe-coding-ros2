# Contributing to vibe-coding-ros2
> How to contribute high quality code and documentation.
---
# # SKILL.md Writing specifications
Each SKILL.md must contain:
# # # 4 sections that must be included

```markdown
# SKILL — <topic>

<one-sentence description of what this skill solves>

## Tools
- <tool 1>: <specific use>
- <tool 2>: <specific use>

## Usage
<usage scenario description>

## Tips
- <practical tip 1>
- <practical tip 2>
```
Quality specification
Requirements/instructions|------|------|| * * ≥ 1 actual combat case * * | Must include specific error case + comparison before and after fixing || * * Code examples * * | At least one piece of code that can be used directly || * * Expected output * * | Expected output interception of a command || * * Chinese + English Mixing * * | Concepts in Chinese, technical terms in English |
       Prohibited
- ❌ Pure concept description, no specific code- ❌ Copy and paste templates, no real-world content- ❌ Link an external document instead of the body
# # # Example: Pass vs. Fail
* *❌ Nonconforming (template filled): * *
```markdown
# SKILL — ros2-cmake-guard

CMake is important. Make sure to export the three lines.

## Usage
Write CMakeLists.txt according to the rules.
```
* *✅ Qualified (with real-world cases): * *
```markdown
# SKILL — ros2-cmake-guard

Missing CMake export three lines leads to linker errors.

## Tools
- `ament_export_dependencies`: export dependencies
- `ament_target_dependencies`: link dependencies

## Usage
Add three lines at the end of CMakeLists.txt.

## Tips
- All three lines must exist simultaneously — no exceptions
- Verify: `colcon build --packages-select PKG` shows no undefined reference

## Real Error Case
```/usr/bin/ld: CMakeFiles/publisher.dir/src/publisher_node.cpp.o:undefined reference to `rclcpp:: Publisher:: publish (...)'
```
Fix: Add the following at the end of CMakeLists.txt:
```cmake ..ament_export_dependencies (rclcpp)ament_export_include_directories (include)ament_export_libraries (${PROJECT_NAME})
```
```
---
# # Submit Specification
# # # Commit Message Format

```
<type>(<scope>): <short description>

<optional detailed description>
```
* * Type: * * feat | fix | docs | refactor | test | chore
Example
```
feat(scripts): add ros2-tf2-broadcaster.sh

Add TF2 broadcast node generator for robot URDF integration.
Includes quaternion setup and dynamic parameter updates.
```
# # # Script specifications
- All `* .sh` must pass` bash -n `- Add `#!/bin/bash` shebang- Exit with `set -e` error- Define color variables: `red green yellow blue NC`- Use `|| true` for non-zero exit codes to avoid accidental exit
Document Specification
- README → Addressing Pain Points → Differentiated Structural Organizations- Toolchain documents are presented in tables- Code block callout language (bash/cpp/python)
