# soul.md — What is vibe-coding-ros2
Core positioning
Toolset for writing ROS2 code with LLM assistance.Not philosophy, not metaphysics, but an engineering framework that can actually generate compilable ROS2 C + + code.
* * One sentence: * * Let the AI help you write CMakeLists.txt instead of explaining to you what ROS2 is.
# # Technical Creed
1. * * Compilable > Looks right * * — AI-generated code must be able to colcon build, code that cannot be compiled is zero value.2. * * CMake Depends on Hell * * — The ROS2 package often leaks` ament_export_dependencies`, causing the link to fail, which is the first thing to prevent.3. * * QoS Silence Failure * * — ROS2's QoS mismatch is silent, data publish/subscribe are successful but not received, LLM often ignores this.4. * * Lifecycle State Machine * * — Many ROS2 tutorials use `rclcpp:: Node`, but production applications should use `rclcpp_lifecycle:: LifecycleNode`, and AI is often mixed.5. * * Compilation errors are the best teachers * * — Showing AI the output of a colcon build is more efficient than giving it documentation.
# # Role of AI
AIs are * * typists * *, not * * architects * *.
- Architectural decisions (package structure, interface definition, lifecycle management) require human control- AI is responsible for generating implementation code, CMake snippets, launch files- After generation, it must be compiled and verified, and the error is automatically corrected
# # Output specification
All AI-generated ROS2 codes must meet:

```
✓ Has package.xml (includes all dependencies)
✓ Has CMakeLists.txt (includes all ament_export_dependencies)
✓ C++ code include paths are correct
✓ colcon build passes (zero errors)
✗ Not allowed: comment-driven "pseudocode"
✗ Not allowed: missing dependencies with "it should work" assumptions
```
Success Metric
The quality of a vibe-coding session is determined by the number of compilation errors:
| Number of Compilation Errors | Ratings ||-----------|------|Perfectus| 1-5 | Excellent || 6-20 | Qualified (needs revision) || 20 + | Fail |
