# Scripts — 可执行工具目录

> v0.0.1-beta 提供的命令行工具

## 快速开始

```bash
# 1. 生成 ROS2 包
bash scripts/generators/ros2-package-generator.sh <name> cpp rclcpp,std_msgs

# 2. 检查生成的包结构
bash scripts/check_ros2_package.sh <pkg_dir>

# 3. 验证 C++ 代码的 QoS/指针/并发安全性
bash scripts/validators/ros2-node-validator.sh <node.cpp>

# 4. 调试 ROS2 环境
bash scripts/debugger/ros2-debug.sh all
```

## 目录结构

```
scripts/
├── generators/
│   └── ros2-package-generator.sh   # 一键生成 ROS2 包
├── validators/
│   └── ros2-node-validator.sh      # C++/QoS/并发安全验证
├── debugger/
│   └── ros2-debug.sh               # ROS2 环境调试工具
└── check_ros2_package.sh           # 包结构完整性检查
```

## 工具说明

### ros2-package-generator.sh

生成标准 ROS2 C++ 包，包含：
- `package.xml` (Format 3)
- `CMakeLists.txt` (C++17)
- 节点骨架（带 SharedPtr + rclcpp::init/shutdown）
- Launch 骨架（带 LaunchDescription）
- 自动检测 msg/srv/action → 自动添加 rosidl

```bash
# 示例
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs
```

### ros2-node-validator.sh

验证节点代码的 C++/ROS2 安全性：
- 智能指针（禁止裸 new/delete）
- QoS 声明
- rclcpp 生命周期
- Executor 并发安全
- Lifecycle 状态机
- 服务调用超时

```bash
bash scripts/validators/ros2-node-validator.sh src/my_node.cpp
```

### ros2-debug.sh

ROS2 环境调试工具：
- `check` — ROS2 安装、DOCKER、DOMAIN_ID
- `topic` — 活跃话题、带宽、QoS
- `node` — 运行节点列表
- `qos` — QoS 匹配检查
- `diag` — CMakeLists.txt + package.xml 快速诊断

```bash
bash scripts/debugger/ros2-debug.sh all      # 全部检查
bash scripts/debugger/ros2-debug.sh qos      # 仅 QoS 检查
bash scripts/debugger/ros2-debug.sh diag      # 仅 CMake 诊断
```

### check_ros2_package.sh

快速验证包结构完整性：
- package.xml 存在 + Format 3
- CMakeLists.txt 存在
- find_package / ament_target_dependencies / install / ament_package

```bash
bash scripts/check_ros2_package.sh <pkg_dir>
```
