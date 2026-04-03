# VibeCoding-ROS2 快速上手

> 从 `git clone` 到第一个 ROS2 包，5 分钟。

---

## 第一步：初始化（1 分钟）

```bash
git clone https://github.com/MIUAV/vibe-coding-ros2.git
cd vibe-coding-ros2
./init-agent.sh
```

`init-agent.sh` 会生成：
- `.gitignore`
- `.github/workflows/ros2-build.yml`
- `.vscode/settings.json`

---

## 第二步：生成第一个包（2 分钟）

```bash
# 生成 ROS2 包（自动生成 CMakeLists.txt + package.xml）
bash scripts/generators/ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs

# 查看生成的文件
ls my_robot/
```

生成的内容：
```
my_robot/
├── package.xml        ← Format 3，已声明所有依赖
├── CMakeLists.txt     ← C++17，包含 find_package / ament_target_dependencies
├── src/
│   └── my_robot_node.cpp   ← 完整节点骨架（带注释）
└── launch/
    └── my_robot.launch.py  ← LaunchDescription 结构
```

---

## 第三步：编写代码（1 分钟）

编辑 `src/my_robot_node.cpp`，参考示例：

```cpp
// 复制 examples/ros2-minimal/cpp_publisher/src/minimal_publisher.cpp 的结构
// 替换话题名和消息类型
```

参考示例（可直接复制运行）：

```bash
# 查看发布者示例
cat examples/ros2-minimal/cpp_publisher/src/minimal_publisher.cpp

# 查看订阅者示例
cat examples/ros2-minimal/py_subscriber/src/py_subscriber_node.py

# 查看 Lifecycle 示例
cat examples/ros2-lifecycle/lifecycle_sensor/src/lifecycle_sensor_node.cpp
```

---

## 第四步：编译并运行（1 分钟）

```bash
# 编译（开发用 --symlink-install，改代码不用重新编译）
colcon build --packages-select my_robot --symlink-install

# 加载 ROS2 环境
source install/setup.bash

# 运行节点
ros2 run my_robot my_robot
```

---

## 第五步：验证和调试

```bash
# 检查包结构
bash scripts/check_ros2_package.sh my_robot

# 验证代码安全（C++/QoS/并发）
bash scripts/validators/ros2-node-validator.sh src/my_robot_node.cpp

# ROS2 环境调试
bash scripts/debugger/ros2-debug.sh all
```

---

## 常见错误

### "package not found"

```bash
source install/setup.bash   # 必须 source
```

### 编译报错：Could not find a package

→ `package.xml` 缺少 `<depend>`，或 `CMakeLists.txt` 缺少 `find_package`
→ 用 `bash scripts/check_ros2_package.sh <pkg>` 检查

### 节点运行时无数据（静默失败）

→ QoS 不匹配，检查：
```bash
ros2 topic info /your_topic
```

### 编译报错：ament_target_dependencies

→ `ament_target_dependencies` 必须在 `add_library()` 之后
→ 参考 `ANTI_PATTERNS.md` 的 CMakeLists.txt 顺序

---

## 下一步：学习示例

```bash
# 构建所有示例
colcon build --packages-select cpp_publisher py_subscriber lifecycle_sensor add_two_ints --symlink-install

# 运行发布者（终端1）
ros2 run cpp_publisher minimal_publisher

# 运行订阅者（终端2）
ros2 run py_subscriber py_subscriber

# 查看话题
ros2 topic list
ros2 topic echo /chatter
```

---

## 文档地图

| 你要做什么 | 去哪里 |
|-----------|--------|
| 快速参考规则 | `AGENTS_CONCISE.md` |
| C++/QoS/并发规范 | `ANTI_PATTERNS.md` |
| 生成 ROS2 包 | `bash scripts/generators/ros2-package-generator.sh` |
| 调试 ROS2 | `bash scripts/debugger/ros2-debug.sh` |
| 部署到 ARM | `DEPLOYMENT.md` |
| 查找技能 | `agents/generated/skill-index.md` |
| 完整文档 | `README.md` |
