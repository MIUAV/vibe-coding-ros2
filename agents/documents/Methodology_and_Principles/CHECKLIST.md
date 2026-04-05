# CHECKLIST.md — ROS2 开发质量检查清单

> 每次生成 ROS2 代码后必查。0 错误才能继续。

---

## 1. CMakeLists.txt 检查

- [ ] `find_package` 所有依赖都带 `REQUIRED`
- [ ] `ament_target_dependencies` 包含所有直接依赖
- [ ] **同时存在这三行**（缺一不可）:
  ```cmake
  ament_export_dependencies(rclcpp)          # 传递依赖
  ament_export_include_directories(include)   # 头文件
  ament_export_libraries(${PROJECT_NAME})     # 库
  ```
- [ ] `include_directories(include)` 指向正确的目录
- [ ] `install()` 安装了 `TARGETS`, `launch/`, `config/`

## 2. package.xml 检查

- [ ] `buildtool_depend: ament_cmake`
- [ ] 每个 `find_package` 的包都有对应的 `<depend>`
- [ ] `<license>` 已填写
- [ ] `<description>` 非空

## 3. C++ 代码检查

- [ ] `LifecycleNode` 用于生产环境（非 `rclcpp::Node`）
- [ ] `rclcpp::Node` 用于简单示例/测试
- [ ] QoS 策略已注明（控制命令=RELIABLE，sensor=BEST_EFFORT）
- [ ] 没有 `using namespace std` 在头文件
- [ ] `SharedPtr` 管理生命周期（不用原始指针）

## 4. 编译验证

```bash
colcon build --packages-select <package> --event-handlers console_direct+
```

- [ ] 0 error（允许 warning）
- [ ] 没有 `undefined reference` 链接错误
- [ ] 没有 `No such file or directory` 头文件错误

## 5. 运行验证（如果可以）

```bash
source install/setup.bash
ros2 run <package> <node> --ros-args --log-level debug
```

- [ ] 节点启动无崩溃
- [ ] `ros2 topic list` 能看到发布的话题
- [ ] `ros2 node info <node>` 显示正确的订阅/发布

## 6. QoS 兼容性检查

```bash
ros2 topic info /<topic> --verbose
```

- [ ] 控制命令话题：`Reliability: RELIABLE`
- [ ] Sensor 话题：`Reliability: BEST_EFFORT`
- [ ] Lifecycle 状态：`Durability: TRANSIENT_LOCAL`

---

## 快速修正命令

```bash
# 缺少 ament_export_dependencies
sed -i '/ament_package()/i ament_export_dependencies(rclcpp)' CMakeLists.txt

# 清理后重新编译
rm -rf build/ install/ log/ && colcon build

# 查看依赖树
colcon graph <package>
```

---

## 常见错误速查

| 错误信息 | 原因 | 修复 |
|---------|------|------|
| `undefined reference to 'rclcpp::Publisher::publish'` | 缺少 `ament_export_dependencies(rclcpp)` | 添加 |
| `fatal error: rclcpp/rclcpp.hpp: No such file` | 缺少 `find_package(rclcpp REQUIRED)` | 添加 |
| `ament_export_include_directories: not a directory` | `include/` 目录不存在 | 创建 |
| `QoS incompatible` | 发布/订阅 QoS 不匹配 | 见 ros2-qos-checker |
| `LifecycleNode not configured` | 未调用 `on_configure()` | 检查状态机 |
