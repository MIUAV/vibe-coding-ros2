# ROS2 开发经验总结

> 基于实际 ROS2 项目开发中积累的血泪教训

---

## 一、最常见的致命错误

### 1. CMakeLists.txt 漏写 ament_export_dependencies

**错误**：
```cmake
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
# 漏了ament_export_dependencies

ament_target_dependencies(my_node rclcpp std_msgs)  # 编译可能通过
# 但运行时依赖缺失
```

**正确**：
```cmake
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
ament_export_dependencies(rclcpp std_msgs)  # 必须加

ament_auto_find_build_dependencies()  # 或用这个自动处理
```

### 2. QoS 不匹配导致静默丢数据

**场景**：相机节点发布图像，RViz2 订阅看不到画面。

**诊断**：
```bash
ros2 topic info /image_raw --verbose
# 看 Reliability 和 Durability 是否匹配
```

**解决**：发布端显式设置 QoS：
```cpp
rclcpp::QoS qos(10);
qos.best_effort();           // 传感器数据用 BestEffort
qos.transient_local();        // 迟到订阅者也要收到
publisher_ = this->create_publisher<sensor_msgs::msg::Image>("/image_raw", qos);
```

### 3. rclpy 节点无法用 Ctrl+C 退出

**原因**：`rclpy.shutdown()` 没有在 finally 块中调用。

**正确写法**：
```python
def main():
    rclpy.init()
    node = MyNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()  # 必须有
```

---

## 二、最佳实践

### 1. 用 ament_auto 而非手写

```cmake
# 手写（容易出错）
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
ament_export_dependencies(rclcpp std_msgs)

# 自动（推荐）
ament_auto_find_build_dependencies()
ament_auto_add_library(${PROJECT_NAME} SHARED src/my_node.cpp)
ament_auto_package()
```

### 2. Launch 文件用 Python 而非 XML

**XML（不推荐）**：
```xml
<launch>
  <node pkg="demo_cpp" exec="minimal_publisher"/>
</launch>
```

**Python（推荐）**：
```python
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='demo_cpp',
            executable='minimal_publisher',
            name='my_publisher',
            output='screen',
            parameters=[{'use_sim_time': True}]
        )
    ])
```

### 3. 多用 Lifecycle 节点

对于传感器驱动、相机等需要配置/激活/停用的组件，Lifecycle 节点是标准：

```cpp
class SensorDriver : public rclcpp_lifecycle::LifecycleNode {
    // on_configure: 创建 publisher, 初始化硬件
    // on_activate: 开始发布数据
    // on_deactivate: 停止发布
    // on_cleanup: 释放资源
    // on_shutdown: 清理
};
```

### 4. 用 component 而非单独节点（进程内通信）

```cpp
// 组件写法（零拷贝）
#include <rclcpp_components/register_node_macro.hpp>

class MyComponent : public rclcpp::Node {
public:
    MyComponent(const rclcpp::NodeOptions & options)
        : Node("my_component", options) {
        // 直接通过 shared_ptr 传递数据，无拷贝
    }
};

RCLCPP_COMPONENTS_REGISTER_NODE(MyComponent)
```

### 5. 参数服务优于全局变量

**错误**：
```cpp
// 全局变量（不好）
double g_kp = 1.0;
```

**正确**：
```cpp
// 参数服务（好）
this->declare_parameter("kp", 1.0);
double kp;
this->get_parameter("kp", kp);
```

---

## 三、性能优化

### 1. 高频消息用 BestEffort

```cpp
// 激光扫描 10Hz+，用 BestEffort 避免带宽问题
rclcpp::QoS qos(10);
qos.best_effort();
```

### 2. 用 image_transport 压缩图像

```bash
# 不压缩
ros2 topic pub /image sensor_msgs/msg/Image ...

# 压缩（节省带宽）
ros2 run image_transport republish compressed --ros-args -r in:=/image raw out:=/image/compressed
```

### 3. MultiThreadedExecutor 并发处理

```cpp
// 单线程（回调串行执行）
rclcpp::executors::SingleThreadedExecutor executor;

// 多线程（回调并发执行）
rclcpp::executors::MultiThreadedExecutor executor;
executor.add_node(node);
executor.spin();
```

### 4. 耗时操作用线程池

```cpp
#include <rclcpp/executors.hpp>

// 在回调中执行 CPU 密集操作会阻塞
// 正确做法：用 AsyncParametersClient 或独立线程

auto future = std::async(std::launch::async, [this]() {
    // 耗时计算
});
```

---

## 四、调试技巧

### 1. 快速定位话题 QoS 问题

```bash
# 列出所有话题的 QoS
ros2 topic list -v

# 看两个特定话题的 QoS 是否兼容
ros2 topic info /scan --verbose
ros2 topic info /scan_subscriber --verbose
```

### 2. 用 rqt_console 实时过滤日志

```bash
rqt_console
# 过滤：/node_name.*WARN
```

### 3. 快速测试 Service

```bash
ros2 service call /add_two_ints example_interfaces/srv/AddTwoInts "{a: 2, b: 3}"
```

### 4. 用 ros2 bag 分析历史数据

```bash
# 录制
ros2 bag record /scan /tf /odom -o my_bag

# 回放
ros2 bag play my_bag

# 分析
ros2 bag info my_bag
```

---

## 五、CI/CD 实践

### 基础 CI（GitHub Actions）

```yaml
name: ROS2 Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-22.04
    container: osrf/ros:humble-desktop
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          source /opt/ros/humble/setup.bash
          colcon build --packages-select ${{ github.event.repository.name }}
      - name: Test
        run: |
          source /opt/ros/humble/setup.bash
          colcon test --packages-select ${{ github.event.repository.name }}
          colcon test-result --verbose
```

### 构建后自动格式化检查

```bash
# 检查代码风格
ament_lint auto --lint-cmake --cmake-format

# 格式化代码
ament_autoformat .
```
