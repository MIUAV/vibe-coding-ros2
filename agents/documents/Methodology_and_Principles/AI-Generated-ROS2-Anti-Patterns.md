# AI-Generated-ROS2-Anti-Patterns — AI 生成代码的典型缺陷

> 基于代码评审总结的 8 类问题及修复方案。

---

## 1. CMake 依赖地狱

### ❌ 漏写 `ament_export_dependencies`

```cmake
# ❌ 错误 — 缺少 export
find_package(rclcpp REQUIRED)
add_library(${PROJECT_NAME} SHARED src/node.cpp)
ament_target_dependencies(${PROJECT_NAME} rclcpp)
# 缺了三行！

ament_package()

# 链接报错: undefined reference to 'ros2_xxx'
```

```cmake
# ✅ 正确 — 三行必须同时存在
find_package(rclcpp REQUIRED)
add_library(${PROJECT_NAME} SHARED src/node.cpp)
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)

ament_export_dependencies(rclcpp)              # 必须
ament_export_include_directories(include)           # 必须
ament_export_libraries(${PROJECT_NAME})           # 必须

ament_package()
```

### ❌ `find_package` 不带 `REQUIRED`

```cmake
# ❌ 错误 — 静默失败，链接时才报错
find_package(rclcpp)  # 找不到也不报错

# ✅ 正确
find_package(rclcpp REQUIRED)
```

---

## 2. 线程安全与锁机制

### ❌ 跨线程访问共享数据无锁保护

```cpp
// ❌ 危险 — timer 线程和主线程同时访问 shared_data
class MyNode : public rclcpp::Node {
  void timer_callback() { shared_data = "modified"; }  // 线程 A
  void other_method() { shared_data = "conflict"; }    // 线程 B
  std::string shared_data;  // 无锁保护！
};
```

```cpp
// ✅ 正确 — 使用 mutex
class MyNode : public rclcpp::Node {
  std::mutex data_mutex_;
  std::string shared_data_;

  void timer_callback() {
    std::lock_guard<std::mutex> lock(data_mutex_);
    shared_data_ = "modified";
  }
};
```

### ❌ `rclcpp::executors::SingleThreadedExecutor` 里开多线程

```cpp
// ❌ 错误 — 在单线程 executor 里创建线程，反而更慢
std::thread{[&](){ do_work(); }}.detach();
rclcpp::spin(node);  // executor 单线程，thread 独立但无同步

// ✅ 正确 — 用 MultiThreadedExecutor
rclcpp::executors::MultiThreadedExecutor executor;
executor.add_node(node);
executor.spin();  // 自动多线程
```

---

## 3. 消息类型误用

### ❌ `sensor_msgs/Image` vs `vision_msgs/Detection2D`

```cpp
// ❌ 错误 — 混淆消息类型
auto msg = std::make_shared<vision_msgs::msg::Detection2D>();
msg->bbox.center.x = 100;  // Detection2D 没有 bbox.center
// 编译可能通过，但运行时数据全错
```

```cpp
// ✅ 正确 — 明确消息结构
// sensor_msgs/Image — 原始图像
// vision_msgs/Detection2DArray — 检测结果
// geometry_msgs/TransformStamped — TF 变换
auto msg = std::make_shared<vision_msgs::msg::Detection2DArray>();
msg->header.stamp = node->now();
msg->detections.emplace_back(...);
```

---

## 4. 实时性隐患

### ❌ 定时器回调里做阻塞操作

```cpp
// ❌ 错误 — 阻塞 100ms，控制周期被破坏
void timer_callback() {
  std::this_thread::sleep_for(100ms);  // 破坏 100Hz 控制周期
  process_data();
}
```

```cpp
// ✅ 正确 — 非阻塞，async 处理
void timer_callback() {
  executor_->schedule([this](){ process_data(); });  // 异步，不阻塞
}
```

### ❌ 每次回调分配内存

```cpp
// ❌ 危险 — 每次回调 new，可能内存碎片化
void timer_callback() {
  auto msg = new std_msgs::msg::String();  // heap 分配
  pub_->publish(std::shared_ptr(msg));
}

// ✅ 正确 — 预分配，reuse
std_msgs::msg::String msg;  // 类成员，栈上预分配
void timer_callback() {
  msg.data = "tick";
  pub_->publish(msg);  // 无 heap 分配
}
```

### ❌ 在控制循环里 `std::cout` / `printf`

```cpp
// ❌ 错误 — I/O 阻塞，破坏实时性
void control_callback() {
  std::cout << "control tick\n";  // 阻塞 1ms+

// ✅ 正确 — 用 RCLCPP_INFO_THROTTLE
RCLCPP_INFO_THROTTLE(get_logger(), *get_clock(), 1000, "tick");  // 每秒最多1次
}
```

---

## 5. 内存泄漏

### ❌ `rclcpp::Node` 裸指针管理

```cpp
// ❌ 危险 — 生命周期不清晰
class A {
  Node* node_;  // 谁管理内存？
};

// ✅ 正确 — shared_ptr
class A {
  rclcpp::Node::SharedPtr node_;
};
```

### ❌ 不清理 `rclcpp::Subscription`

```cpp
// ❌ 危险 — subscription 持有 callback，callback 持有大数据
auto sub = create_subscription("/large_topic", 10,
  [&](const LargeMsg::SharedPtr msg) {
    this->big_buffer_ = msg->data;  // 每次 callback 都持有引用
  });
// 订阅永远不清理，buffer 持续增长

// ✅ 正确 — 及时 reset
auto sub = create_subscription("/large_topic", 10,
  [&](const LargeMsg::SharedPtr msg) { process(msg); });
// 在不需要时: sub.reset();
```

---

## 6. 缺乏日志策略

### ❌ 不用日志宏，用 `std::cout`

```cpp
// ❌ 错误 — 无日志级别控制，生产环境无法关闭
std::cout << "debug info" << std::endl;  // 始终输出

// ✅ 正确 — RCLCPP_*
RCLCPP_INFO(get_logger(), "Node started");           // INFO 级别
RCLCPP_WARN(get_logger(), "Rate %.1f Hz", rate);   // WARN 级别
RCLCPP_ERROR(get_logger(), "Connection failed");       // ERROR 级别
RCLCPP_DEBUG_THROTTLE(get_logger(), *get_clock(), 1000, "tick"); // DEBUG 节流
```

### ❌ 错误信息无上下文

```cpp
// ❌ 错误 — "error" 无意义
RCLCPP_ERROR(logger, "error");

// ✅ 正确 — 结构化错误信息
RCLCPP_ERROR(logger, "Failed to publish to %s: %s",
    topic_name.c_str(), strerror(errno));
```

---

## 7. QoS 静默失败

### ❌ 控制命令用 `BEST_EFFORT`

```cpp
// ❌ 危险 — 机器人抖动失控
auto pub = create_publisher<JointCommand>("/arm/cmd",
    QoS(10).best_effort());  // 命令可能丢包！

// ✅ 正确
auto pub = create_publisher<JointCommand>("/arm/cmd",
    QoS(10).reliable());
```

### ❌ laser scan 订阅用默认 `RELIABLE`

```python
# ❌ 静默不通 — lidar 驱动用 BEST_EFFORT 发布，订阅端默认 RELIABLE
sub = self.create_subscription(LaserScan, '/scan', self.callback)  # 默认 RELIABLE

# ✅ 正确
sub = self.create_subscription(LaserScan, '/scan',
    QoSProfile(reliability=ReliabilityPolicy.BEST_EFFORT, depth=10))
```

---

## 8. 输入校验缺失

### ❌ 不校验输入范围

```cpp
// ❌ 危险 — 恶意/错误数据导致越界
void set_joint_angle(double angle) {
  joints_[selected_joint_].angle = angle;  // 无范围检查！
}

// ✅ 正确
void set_joint_angle(int joint_idx, double angle) {
  if (joint_idx < 0 || joint_idx >= joints_.size()) return;
  if (angle < joints_[joint_idx].min_angle ||
      angle > joints_[joint_idx].max_angle) {
    RCLCPP_WARN(logger, "Angle %.2f out of range [%.2f, %.2f]",
                 angle, joints_[joint_idx].min_angle, joints_[joint_idx].max_angle);
    return;
  }
  joints_[joint_idx].angle = angle;
}
```

---

## 检查清单

生成代码后，逐项检查：

- [ ] `ament_export_dependencies` 三行齐全
- [ ] 跨线程共享数据有 `std::mutex`
- [ ] 消息类型名称完全匹配（不能凭记忆写）
- [ ] 定时器回调无阻塞操作、无 heap 分配
- [ ] 控制命令用 `reliable()` QoS
- [ ] 使用 `RCLCPP_*` 日志宏而非 `std::cout`
- [ ] 订阅者在不需要时 `reset()`
- [ ] 输入参数有范围校验
