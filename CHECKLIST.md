# CHECKLIST.md — 开发质量清单

> 每次提交前过一遍，确保代码可用、文档同步、CI 畅通。

---

## ✅ 代码提交流程

### CMakeLists.txt（必查）

- [ ] `ament_target_dependencies(${PROJECT_NAME} ...)` 后**紧跟**三行导出
  ```cmake
  ament_export_dependencies(rclcpp std_msgs ...)
  ament_export_include_directories(include)  # 有 include 时
  ament_export_libraries(${PROJECT_NAME})
  ```
- [ ] `find_package(rclcpp COMPONENTS ...)` 与 `ament_target_dependencies` 组件一致
- [ ] `add_action_library` / `add_service_library` 同样加导出三行
- [ ] `ament_package()` 在文件末尾

### C++ 节点（必查）

- [ ] 生产节点用 `rclcpp_lifecycle::LifecycleNode`，临时工具用 `rclcpp::Node`
- [ ] `on_configure/on_activate/on_deactivate/on_cleanup/on_shutdown` 虚函数声明正确
- [ ] QoS 组合正确：
  - 控制命令 → `.reliable()`
  - 传感器数据 → `.best_effort()`
  - 状态广播 → `.transient_local()`
- [ ] `rclcpp::spin_some(node)` 或 `rclcpp::executors::MultiThreadedExecutor` 用上
- [ ] 头文件 include guard 正确：`#ifndef NODE_NAME_HPP_`

### package.xml（必查）

- [ ] `<exec_depend>rclcpp</exec_depend>` 与 CMake 的 `find_package` 对应
- [ ] `<depend>std_msgs</depend>` 对应实际用到的消息包
- [ ] `<export><build_type>ament_cmake</build_type></export>` 存在

### Launch 文件（必查）

- [ ] 参数名与代码中 `declare_parameter` 一致
- [ ] Lifecycle 节点有 ` compartment` 参数

---

## ✅ CI 检查清单

- [ ] `colcon build --packages-select PKG` 本地通过
- [ ] `bash scripts/validators/skill-frontmatter-validator.sh` 无报错（涉及 SKILL 时）
- [ ] `shellcheck scripts/*.sh` 无报错（涉及新脚本时）
- [ ] 无新增 `clang-tidy` 警告

---

## ✅ 文档同步清单

- [ ] 新增生成器：`scripts/generators/*.sh` 已在 `README.md` 工具链表格登记
- [ ] 新增案例：`examples/mcp-workflow/cases/NAME/` 包含 `PLAN.md + SKILL.md + VERIFY.md`
- [ ] 新增 SKILL：`agents/skills/NAME/SKILL.md` frontmatter 完整（name/description/tools/usage）
- [ ] `PROJECT_ROADMAP.md` 更新版本状态
- [ ] `CONTRIBUTING.md` 中新增规范（如有）

---

## ✅ Commit 检查

- [ ] Commit message 格式：`<type>(<scope>): <描述>`
- [ ] 不超过 72 字符标题
- [ ] 代码与文档分开提交：`docs:` vs `feat:` vs `fix:`
- [ ] 已运行 `git diff --stat` 确认改动范围

---

## ⚠️ 高频错误对照

| 错误信息 | 原因 | 修复 |
|---------|------|------|
| `undefined reference to ...` | CMake 三行导出缺失 | 加 `ament_export_*` |
| `QoS incompatible` | 发布/订阅 QoS 不匹配 | 用 `ros2 topic info /topic -v` 诊断 |
| `Lifecycle transition invalid` | 状态机转换顺序错 | 检查 `on_configure→activate` 顺序 |
| `Failed to load library` | `dlopen` 失败 | 检查 `ament_target_dependencies` 是否包含所有依赖 |
| `node not discovered` | 命名空间冲突 | 用 `ros2 node list` 确认 |
| `segmentation fault` | 指针未初始化 | 检查 `shared_from_this()` 用法 |
