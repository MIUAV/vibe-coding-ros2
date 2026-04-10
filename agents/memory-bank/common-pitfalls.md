# Common Pitfalls — 常见错误与规避

## 🔴 CMake 依赖地狱（最常见）

### 症状
```
/usr/bin/ld: cannot find -lxxx
undefined reference to `ros2::Node::Node()'
```
**原因**：漏写 `ament_export_dependencies` 或 `ament_export_libraries`。

### 规避
生成 CMakeLists.txt 时，**必须同时包含**：
```cmake
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs geometry_msgs)
ament_export_dependencies(rclcpp)                  # ← 必加
ament_export_include_directories(include)           # ← 必加（仅有include时）
ament_export_libraries(${PROJECT_NAME})             # ← 必加
```

### 自检命令
```bash
# 漏了 ament_export_dependencies 的典型错误特征
grep -n "ament_export_dependencies\|ament_export_libraries" CMakeLists.txt
```

---

## 🔴 QoS 静默失败

### 症状
`ros2 topic echo` 看不到数据，但 `ros2 topic list` 显示 topic 存在。
**原因**：发布者/订阅者 QoS 不匹配，ROS2 静默丢弃数据。

### 常见 QoS 冲突组合
| 发布者 | 订阅者 | 结果 |
|--------|--------|------|
| `reliable` | `best_effort` | ❌ 不通 |
| `best_effort` | `reliable` | ❌ 不通 |
| `keep_last(1)` | `keep_all` | ❌ 不通 |

### 规避规则
```cpp
// sensor 数据流 — best_effort
auto sensor_qos = rclcpp::SensorDataQoS();

// control cmd_vel — reliable
auto cmd_qos = rclcpp::SystemDefaultsQoS();
cmd_qos.reliable();

// lifecycle 状态 — transient_local
auto lifecycle_qos = rclcpp::ParametersQoS();
lifecycle_qos.transient_local();
```

### 自检命令
```bash
ros2 topic info /scan --verbose  # 查看两端 QoS 是否兼容
```

---

## 🔴 Lifecycle 节点状态机错误

### 症状
- 节点启动后 topic 无数据输出
- `ros2 lifecycle get /node_name` 显示 `unconfigured`

**原因**：未正确实现或调用状态转换。

### 规避
```cpp
class MyNode : public rclcpp_lifecycle::LifecycleNode {
public:
  // 全部5个回调必须实现
  rcl_lifecycle_transition_callback_service::SharedPtr callback_service_;
  
  // 在 on_configure 中设置 topic QoS
  // 在 on_activate 中发布初始数据
  // 在 on_deactivate 中停止发布
  
  // 状态转换示例（构造函数中注册）
  callback_service_ = this->create_callback(
    rclcpp_lifecycle::create_callback_interface());
};
```

---

## 🔴 TF2 坐标系未发布

### 症状
Rviz2 中模型碎片化，或 `TransformBroadcaster` 报错 "frame does not exist"。
**原因**：未发布 `tf_static_transform` 或父子 frame 不匹配。

### 规避
```cpp
#include <tf2_ros/static_transform_broadcaster.h>

tf2_ros::StaticTransformBroadcaster static_broadcaster(this);
geometry_msgs::msg::TransformStamped t;

t.header.frame_id = "world";   // 父 frame
t.child_frame_id = "base_link"; // 子 frame
t.transform.translation.x = 0.0;
// ...
static_broadcaster.sendTransform(t);
```

---

## 🔴 action server/client 类型不匹配

### 症状
`Goal was rejected by server` 无额外错误信息。
**原因**：`action_msgs/msg/GoalInfo` 与 Server 定义不匹配。

### 规避
```cpp
// 客户端发送前先检查 server 是否存在
auto action_client = rclcpp_action::create_client<MyAction>(this, "my_action");
if (!action_client->wait_for_action_server(10s)) {
  RCLCPP_ERROR(this->get_logger(), "Action server not available");
  return;
}
```

---

## 🔴 colcon build 常见错误

| 错误 | 原因 | 解决方法 |
|------|------|---------|
| `package 'xxx' not found` | dependency 未声明 | 在 `package.xml` 添加 `<depend>xxx</depend>` |
| `ament_cmake_python` 报错 | Python 包用了 CMake 构建 | 用 `ament_cmake_auto` 或纯 Python `setup.py` |
| `Could not find a package configuration` | ROS2 环境未 source | `source /opt/ros/${ROS_DISTRO}/setup.bash` |
| `No module named 'xxx'` | PYTHONPATH 问题 | 检查 `setup.py` 的 `install_requires` |

---

## 🟡 参数类型不匹配

### 症状
`Parameter 'xxx' is not of type double`。
**原因**：声明时类型与使用时不匹配。

### 规避
```cpp
// 声明时明确类型
this->declare_parameter<double>("Kp", 1.0);
this->declare_parameter<int>("history_size", 10);
this->declare_parameter<std::string>("frame_id", "base_link");
```

---

## 🟡 循环引用（shared_from_this）

### 症状
`std::bad_weak_ptr` 在 node 相关代码中。
**原因**：在构造函数中调用 `shared_from_this()`。

### 规避
```cpp
// ❌ 错误
MyNode::MyNode() : Node("my_node") {
  auto timer = create_wall_timer(1s, [this]() { ... });
}

// ✅ 正确 — 在 on_configure 中初始化 timer
void MyNode::on_configure(const rclcpp_lifecycle::State&) {
  timer_ = create_wall_timer(1s, [this]() { ... });
}
```
