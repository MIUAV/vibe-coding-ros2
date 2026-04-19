# CHECKLIST.md — Development Quality Checklist
> Pass before each submission to ensure code is available, documents are synchronized, and CI is unblocked.
---
# # ✅ Code Submission Process
# # # CMakeLists.txt (Required)
- [] `ament_target_dependencies (${PROJECT_NAME}...)` followed by a * * three-line export
  ```cmake
  ament_export_dependencies(rclcpp std_msgs ...)
  ament_export_include_directories(include)  # [REQUIRED when include/ exists]
  ament_export_libraries(${PROJECT_NAME})
  ```- [] `find_package (rclcpp components...)` is consistent with the `ament_target_dependencies` component- [] `add_action_library`/`add_service_library` also exports three rows- [] `ament_package ()` at the end of the file
# # # C + + Node (Required)
- [] Production nodes use `rclcpp_lifecycle:: LifecycleNode`, temporary tools use `rclcpp:: Node`- [] `on_configure/on_activate/on_deactivate/on_cleanup/on_shutdown` Virtual function declared correctly- [] QoS combinations are correct:- Control command → `.reliable ()`- Sensor data → `.best_effort ()`- Status broadcast → `.transient_local ()`- [] `rclcpp:: spin_some (node)` or `rclcpp:: executors:: MultiThreadedExecutor`- [] The header file include guard is correct: `# ifndef node_NAME_HPP_`
# # # package.xml (Required)
- [] `<exec_depend>rclcpp</exec_depend>` corresponds to CMake's `find_package`- [] `<depend>std_msgs</depend>` corresponds to the actual message packets used- [] `<export><build_type>ament_cmake</build_type></export>` present
# # # Launch documents (required)
- [] Parameter name matches` declare_parameter `in code- [] Lifecycle node has` compartment `parameter
---
# # ✅ CI Checklist
- [] `colcon build --packages-select PKG` locally via- [] `bash scripts/validators/skill-frontmatter-validator.sh` No error (when skill is involved)- [] `shellcheck scripts/* .sh` No errors (when new scripts are involved)- [] No `clang-tidy` warning added
---
# # ✅ Document Sync Checklist
- [] New generator: `scripts/generators/* .sh` is registered in the `README.md` toolchain form- [] Added case: `examples/mcp-workflow/cases/name/` contains` PLAN.md + SKILL.md + VERIFY.md `- [] Added skill: `agents/skills/name/SKILL.md` frontmatter full (name/description/tools/usage)- [] `PROJECT_ROADMAP.md` update version status- [] Specification added in `CONTRIBUTING.md` (if any)
---
# # ✅ Commit Check
- [] Commit message format: `<type>(<scope>):'- [] No more than 72 character titles- [] Code submitted separately from documentation: `docs:` vs` feat: `vs` fix: `- [] Running `git diff --stat' confirms scope of changes
---
# # ⚠️ High Frequency Error Comparison
| Error Message | Cause | Fix ||---------|------|------|| `undefined reference to...` | CMake three-line export missing | plus` ament_export_* `|| `QoS incompatible` | Publish/Subscribe QoS Mismatch | Diagnose with `ros2 topic info/topic -v` || `Lifecycle transition invalid` | Wrong state machine transition order | Check `on_configure→ activate` order || `Failed to load library` | `dlopen` failed | Check if `ament_target_dependencies` contains all dependencies || `node not discovered` | Namespace conflict | Confirm with `ros2 node list` || `segmentation fault` | Pointer not initialized | Check `shared_from_this ()` usage |
