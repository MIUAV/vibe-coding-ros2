# Coding Standards — ROS2 代码规范

## 命名约定

| 元素 | 约定 | 示例 |
|------|------|------|
| 包名 | 全小写 + 下划线 | `my_controller`, `lidar_processor` |
| 节点名 | 全小写 + 下划线 | `scan_filter_node` |
| Topic 名 | 全小写 + 下划线 | `/scan`, `/cmd_vel` |
| Service 名 | 全小写 + 下划线 | `/reset_odom` |
| Action 名 | 全小写 + 下划线 | `/move_base` |
| 类名 | PascalCase | `ScanFilterNode`, `LidarProcessor` |
| 变量/函数 | 全小写 + 下划线 | `publish_filtered_scan()`, `obstacle_distance` |
| 常量 | 全大写 + 下划线 | `MAX_SCAN_RANGE`, `QUEUE_DEPTH` |
| 参数名 | 全小写 + 下划线 | `detection_threshold`, `frame_id` |
| 命名空间 | 全小写 + 下划线 | `vision_utils`, `nav_utils` |
| msg/srv 文件 | PascalCase | `ScanData.msg`, `ResetOdom.srv` |

## C++ 代码模板

### 最小可编译节点
```cpp
#include <rclcpp/rclcpp.hpp>

class MinimalNode : public rclcpp::Node {
public:
  MinimalNode() : Node("minimal_node") {
    RCLCPP_INFO(this->get_logger(), "MinimalNode started");
  }
};

int main(int argc, char ** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MinimalNode>());
  rclcpp::shutdown();
  return 0;
}
```

### Lifecycle 节点模板（生产级）
```cpp
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>

class RobotController : public rclcpp_lifecycle::LifecycleNode {
public:
  RobotController() : LifecycleNode("robot_controller") {}

  // ── 5个必须回调 ──────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State &) override {
    RCLCPP_INFO(get_logger(), "on_configure");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State &) override {
    RCLCPP_INFO(get_logger(), "on_activate");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State &) override {
    RCLCPP_INFO(get_logger(), "on_deactivate");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State &) override {
    RCLCPP_INFO(get_logger(), "on_cleanup");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State &) override {
    RCLCPP_INFO(get_logger(), "on_shutdown");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

private:
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
};

// main 中用 create_client<rclcpp::Node> 而不是直接 spin
```

### QoS 使用规范
```cpp
// 传感器发布
rclcpp::SensorDataQoS sensor_qos;
auto pub = create_publisher<sensor_msgs::msg::PointCloud2>("/scan", sensor_qos);

// 控制命令
rclcpp::SystemDefaultsQoS cmd_qos;
cmd_qos.reliable();
auto pub = create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", cmd_qos);

// 建图数据
rclcpp::QoS map_qos(10);
map_qos.transient_local().reliable();
auto pub = create_publisher<nav_msgs::msg::OccupancyGrid>("/map", map_qos);
```

## CMakeLists.txt 模板
```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_CXX_STANDARD GREATER_EQUAL 17)
  set(CMAKE_CXX_STANDARD 17)
endif()

# ── 依赖 ──────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

# ── 头文件目录 ──────────────────────
include_directories(include)

# ── 库 ──────────────────────────────
add_library(${PROJECT_NAME} SHARED
  src/my_node.cpp
)
target_compile_definitions(${PROJECT_NAME} PRIVATE "RCPPCLC_LIFECYCLE_PUBLIC=__attribute__((visibility(\"default\")))")

# ── 必须的导出（防止链接错误）─────────
ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  std_msgs
  geometry_msgs
)
ament_export_dependencies(rclcpp std_msgs geometry_msgs)    # ← 必须
ament_export_include_directories(include)                      # ← 必须
ament_export_libraries(${PROJECT_NAME})                        # ← 必须

# ── install ─────────────────────────
install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME}/)

ament_package()
```

## package.xml 模板
```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>my_package</name>
  <version>0.1.0</version>
  <description>My ROS2 package</description>
  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>

  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>lifecycle_msgs</depend>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export><build_type>ament_cmake</build_type></export>
</package>
```

## 日志规范
```cpp
// 级别：DEBUG < INFO < WARN < ERROR < FATAL
RCLCPP_DEBUG(logger, "Debug info: %d", value);
RCLCPP_INFO(logger, "Node started successfully");        // 一般信息
RCLCPP_WARN(logger, "Low battery: %d%%", battery);     // 警告
RCLCPP_ERROR(logger, "Sensor timeout after %d ms", ms);// 错误
RCLCPP_FATAL(logger, "FATAL: emergency stop!");         // 致命
```

## 多线程规范
```cpp
// 多线程 executor（用于 IO 密集型）
rclcpp::executors::MultiThreadedExecutor executor;
executor.add_node(node1);
executor.add_node(node2);
executor.spin();

// 或使用回调组
auto callback_group = create_callback_group(rclcpp::CallbackGroup::MutuallyExclusive);
auto sub = create_subscription<...>(..., [this](...) { /* ... */ });
```
