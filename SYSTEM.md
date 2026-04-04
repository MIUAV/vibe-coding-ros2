# SYSTEM.md — AI Agent 系统指令

## 强制规则（禁止违反）

### 🔴 CMake 禁区（零容忍）

LLM 生成 CMakeLists.txt 时必须包含：

```cmake
# 必须有这三行，缺一不可
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})
```

缺少 `ament_export_dependencies` 会导致依赖包无法找到头文件。

### 🔴 QoS 禁区

ROS2 默认 QoS：
- `DurabilityQoSPolicy = TRANSIENT_LOCAL` 用于 lifecycle 节点
- `ReliabilityQoSPolicy = BEST_EFFORT` 用于 sensor 数据
- `ReliabilityQoSPolicy = RELIABLE` 用于控制命令（默认）

混用会导致发布/订阅看起来成功但无数据传递。

### 🔴 Lifecycle 禁区

Production 代码必须用 `rclcpp_lifecycle::LifecycleNode`，不能用 `rclcpp::Node`。

生命周期状态机：
```
UNCONFIGURED → INACTIVE → ACTIVE → FINALIZED
```

每个状态转换必须显式调用 `on_activate()` / `on_deactivate()` / `on_cleanup()` / `on_shutdown()`。

## 生成代码质量标准

### C++ 代码模板

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>

class MyNode : public rclcpp_lifecycle::LifecycleNode {
public:
  MyNode() : LifecycleNode("my_node") {
    RCLCPP_INFO(this->get_logger(), "MyNode constructed");
  }
  // on_configure, on_activate, on_deactivate, on_cleanup, on_shutdown
};
```

### package.xml 模板

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>my_package</name>
  <version>0.1.0</version>
  <description>TODO</description>
  <maintainer email="dev@miuav.com">MIUAV</maintainer>
  <license>Apache-2.0</license>
  
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_components</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>std_msgs</depend>
  
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  
  <export><build_type>ament_cmake</build_type></export>
</package>
```

### CMakeLists.txt 最小模板

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

set(NODE_SOURCES
  src/my_node.cpp
)

add_library(${PROJECT_NAME} SHARED ${NODE_SOURCES})
ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  rclcpp_lifecycle
  std_msgs
)

# 三行必须同时存在
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

ament_package()
```

## 错误修正回路

当 `colcon build` 报错时：

1. **CMake 链接错误** → 检查 `ament_target_dependencies` 和 `ament_export_dependencies`
2. **头文件找不到** → 检查 `include_directories` 和 `target_include_directories`
3. **rclcpp 版本不兼容** → 检查 ROS2 distro 版本（Ubuntu 22.04 = Humble，20.04 = Foxy）
4. **QoS 静默失败** → 检查发布/订阅两端的 QoS profile 是否匹配

## 禁止的写法

```cpp
// ❌ 禁止：直接用 Node 而不是 LifecycleNode
auto node = std::make_shared<rclcpp::Node>("my_node");

// ❌ 禁止：在 header 里 using namespace std
using namespace std; // 在 .cpp 里可以，但 .hpp 不可以

// ❌ 禁止：CMake 里漏 ament_export_dependencies
# 少了这行会导致依赖包找不到你包里的头文件
ament_export_dependencies(rclcpp)

// ❌ 禁止：发布数据用 BEST_EFFORT，控制命令用 RELIABLE
// 控制命令必须 RELIABLE，否则丢包会导致机器人失控
```
