# Phase 3: Prototyping

## 基础包生成
```bash
# C++ 包
bash scripts/generators/ros2-package-generator.sh <pkg> cpp rclcpp,rclcpp_lifecycle,std_msgs,geometry_msgs --verify

# Python 包
bash scripts/generators/ros2-package-generator.sh <pkg> python rclpy --verify

# Nav2 包
bash scripts/generators/ros2-package-generator.sh <pkg> cpp nav2_msgs,nav2_util,nav2_core --verify
```

## 骨架验证
```bash
colcon build --packages-select <pkg>
ros2 pkg list | grep <pkg>
ros2 pkg executables <pkg>
```

## CMake 必须的三行
```cmake
ament_export_dependencies(rclcpp std_msgs)              # ← 必须
ament_export_include_directories(include)                 # ← 有include时必须
ament_export_libraries(${PROJECT_NAME})                  # ← 必须
```

## 自检检查表
- [ ] `colcon build --packages-select <pkg>` 无错误
- [ ] `ros2 pkg list | grep <pkg>` 能找到包
- [ ] `ros2 pkg executables <pkg>` 能列出可执行文件
