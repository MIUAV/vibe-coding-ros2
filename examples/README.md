# ROS2 Examples — 实战示例目录

> 所有示例均可通过 `colcon build --packages-select <pkg> --symlink-install` 编译

## 目录结构

```
examples/
├── ros2-minimal/
│   ├── cpp_publisher/         ✅ C++ 发布者（定时发布 + QoS）
│   └── py_subscriber/         ✅ Python 订阅者（rclpy 规范）
├── ros2-lifecycle/
│   └── lifecycle_sensor/       ✅ Lifecycle 节点（状态机）
└── ros2-service/
    └── add_two_ints/          ✅ Service + Client（超时保护）
```

## 快速运行

```bash
# 构建所有示例
colcon build --packages-select cpp_publisher py_subscriber lifecycle_sensor add_two_ints --symlink-install

# 运行发布者 + 订阅者（两个终端）
ros2 run cpp_publisher minimal_publisher
ros2 run py_subscriber py_subscriber

# 运行 Lifecycle 节点
ros2 run lifecycle_sensor lifecycle_sensor
ros2 lifecycle list /lifecycle_sensor    # 查看状态
ros2 lifecycle set /lifecycle_sensor configure
ros2 lifecycle set /lifecycle_sensor activate

# 运行 Service
ros2 run add_two_ints add_two_ints_server
ros2 run add_two_ints add_two_ints_client
```

## 示例规范遵循

| 示例 | SmartPtr | QoS | Lifecycle | 超时保护 | rclpy shutdown |
|------|----------|-----|-----------|---------|----------------|
| cpp_publisher | ✅ | ✅ | — | — | — |
| py_subscriber | — | ✅ | — | — | ✅ |
| lifecycle_sensor | ✅ | ✅ | ✅ | — | — |
| add_two_ints | ✅ | — | — | ✅ | — |
