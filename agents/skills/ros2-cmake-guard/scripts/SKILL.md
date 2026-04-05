# SKILL — ros2_cmake_guard

> CMake 依赖守卫脚本，防止链接错误和依赖缺失

## Tools
- **cmake_guard**: 验证 CMakeLists.txt 三行 export 完整性
- **dep_checker**: 扫描 find_package 缺失的依赖
- **link_order**: 检查 target_link_libraries 库顺序

## Usage
AI 生成 ROS2 CMakeLists.txt 后，运行此脚本检查：
- `ament_export_dependencies` + `ament_export_include_directories` + `ament_export_libraries` 三行完整性
- find_package 所有依赖（避免运行时.so not found）
- target_link_libraries 顺序（被依赖者必须在后面）

## Tips
- 链接顺序问题：libA 依赖 libB → `target_link_libraries(node A B)` 顺序必须 A 在前
- 静默链接失败：.so 文件存在但符号缺失 → 检查是否遗漏 `ament_export_dependencies`
- CMake 缓存：`colcon build --cmake-clean-cache` 清除旧缓存再编译
