---
name: cmake-configuration
description: CMakeLists.txt 和 package.xml 配置技能 - ROS2 CMake 复杂配置、依赖管理、组件架构、插件系统、跨平台编译
argument-hint: CMakeLists OR package.xml OR CMake配置 OR colcon编译 OR ROS2构建
user-invocable: true
---

# CMakeLists.txt 和 package.xml 配置技能

> 用于深度掌握 ROS2 项目的 CMake 构建系统和包清单配置，涵盖复杂依赖管理、组件架构、插件系统、跨平台交叉编译

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置复杂的 CMakeLists.txt（多节点、组件架构、插件）
- 正确声明 package.xml 依赖（build/export/exec 区分）
- 构建自定义消息/服务/动作
- 配置ament_cmake_components插件系统
- 实现class_loader动态插件
- 交叉编译ROS2包
- 使用ament_cmake扩展

---

## 快速参考

### package.xml 依赖类型

```xml
<!-- package.xml 四种依赖类型 -->
<build_depend>    <!-- 构建时需要 -->
<buildtool_depend> <!-- 构建工具本身 -->
<build_export_depend>  <!-- 导出给下游包 -->
<exec_depend>     <!-- 运行时需要 -->
<test_depend>     <!-- 仅测试需要 -->
<doc_depend>      <!-- 仅文档需要 -->
```

### CMakeLists.txt 核心命令

```cmake
# 依赖查找
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

# 构建类型
add_library(${PROJECT_NAME} SHARED ...)
add_executable(${PROJECT_NAME}_node src/main.cpp)

# 组件 (Composition)
rclcpp_components_register_node(${PROJECT_NAME}_component ...

# 插件 (Plugin)
pluginlib_export_plugin_description_file(...)

# 安装
install(TARGETS ... DESTINATION lib/${PROJECT_NAME})
install(DIRECTORY launch/ DESTINATION share/${PROJECT_NAME}/launch)
```

---

## package.xml 详解

### Format 2 vs Format 3

```xml
<?xml version="1.0"?>
<!-- Format 2 (ROS2 Dashing ~ Humble) -->
<package format="2">
  <name>my_robot_control</name>
  <version>1.2.3</version>
  <description>Robot control package</description>

  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <build_depend>rclcpp</build_depend>
  <build_export_depend>geometry_msgs</build_export_depend>
  <exec_depend>nav2_msgs</exec_depend>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

### Format 3 (ROS2 Iron ~ Jazzy)

```xml
<?xml version="1.0"?>
<!-- Format 3 (ROS2 Iron ~ Jazzy) -->
<package format="3">
  <name>my_robot_control</name>
  <version>1.2.3</version>
  <description>Robot control package</description>

  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>

  <!-- 统一使用 depend 标签，格式3自动分类 -->
  <depend>rclcpp</depend>           <!-- 自动映射到 build_depend + exec_depend -->
  <depend>geometry_msgs</depend>    <!-- 自动映射到 build_export_depend + exec_depend -->
  <test_depend>ament_lint_auto</test_depend>

  <!-- Format 3 独有特性 -->
  <member_of_group>rosidl_interfaces_group</member_of_group>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

### 依赖声明详解

```xml
<!-- 正确选择依赖类型的示例 -->

<!-- 场景1: 你的包需要 rclcpp 来编译 -->
<build_depend>rclcpp</build_depend>

<!-- 场景2: 你的包导出头文件供下游使用 -->
<!-- 例如: my_utils.hpp 被下游包 include -->
<build_export_depend>my_utils</build_export_depend>

<!-- 场景3: 你包里的节点运行时需要某个库 -->
<exec_depend>yaml-cpp</exec_depend>

<!-- 场景4: 使用 Format 3 的简洁写法 -->
<depend>rclcpp</depend>  <!-- 等价于 build_depend + exec_depend -->

<!-- 常见错误：用了 build_depend 但运行时报错找不到库 -->
<!-- 解决：如果运行时也需要，加 exec_depend -->
<build_depend>tf2_ros</build_depend>
<exec_depend>tf2_ros</exec_depend>
<!-- 或 Format 3: -->
<depend>tf2_ros</depend>
```

### 条件依赖

```xml
<!-- ROS2 Iron (API level 3) 支持条件依赖 -->
<depend condition="$ROS_DISTRO == humble">nav2_msgs</depend>

<!-- 多条件 -->
<depend condition="$ROS_DISTRO in [foxy, galactic]">legacy_package</depend>

<!-- 版本约束 -->
<build_depend condition="$ROS_DISTRO >= humble">builtin_interfaces</build_depend>
```

### ROS2 发行版兼容性

```xml
<!-- 如果包只支持某个版本范围 -->
<depend condition="$ROS_DISTRO >= humble">nav2_msgs</depend>

<!-- 或者排除某个版本 -->
<depend condition="$ROS_DISTRO != noetic">some_ros1_bridge</depend>
```

---

## CMakeLists.txt 详解

### 最小完整结构

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_robot_control)

# 必须是 3.8+(ROS2 Humble及以下) 或 3.10+(Iron/Jazzy)
# 推荐 3.16 兼容性最好

# 必须的 CMake 策略
if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

# 项目级别设置
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)  # ROS2 Humble+ 要求 C++17
endif()
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 1. 查找依赖包
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(PluginLib REQUIRED)  # pluginlib 插件

# 2. 定义包内容
set(PACKAGE_DEPENDENCIES
  rclcpp
  std_msgs
  geometry_msgs
)

# 3. 包含消息/服务/动作生成
rosidl_get_typesupport_target(TYPESUPPORT_LIBS
  ${PROJECT_NAME} "rosidl_typesupport_cpp")

# 4. 创建库/可执行文件
add_library(${PROJECT_NAME} SHARED
  src/my_node.cpp
  src/my_component.cpp
)
ament_target_dependencies(${PROJECT_NAME}
  ${PACKAGE_DEPENDENCIES}
)

# 5. 注册为 ROS2 组件
rclcpp_components_register_node(${PROJECT_NAME}node
  PLUGIN "${PROJECT_NAME}::MyComponent"
  EXECUTABLE my_executable
)

# 6. 安装
install(TARGETS ${PROJECT_NAME} ${PROJECT_NAME}node
  ARCHIVE DESTINATION lib/${PROJECT_NAME}
  LIBRARY DESTINATION lib/${PROJECT_NAME}
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}/
)

ament_package()
```

---

## 消息/服务/动作生成

### 完整配置

```cmake
# CMakeLists.txt 中消息生成

# 1. 查找消息生成依赖
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)  # 消息生成器
find_package(std_msgs REQUIRED)  # 依赖的消息包

# 2. 设置包依赖
set(msg_deps
  std_msgs
  geometry_msgs
  action_msgs  # action 需要
)

# 3. 声明要生成的消息/服务/动作
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/MyMessage.msg"
  "msg/MyService.service"
  "action/MyAction.action"
  DEPENDENCIES ${msg_deps}
)

# 4. 完整示例
rosidl_generate_interfaces(${PROJECT_NAME}
  FILES
    msg/MyMessage.msg
    srv/MyService.srv
    action/MyAction.action
  DEPENDENCIES
    std_msgs
    action_msgs
)
```

### package.xml 消息依赖

```xml
<!-- Format 3 -->
<depend>std_msgs</depend>
<depend>geometry_msgs</depend>
<depend>action_msgs</depend>  <!-- action 需要 -->

<!-- 消息生成工具 -->
<buildtool_depend>rosidl_default_generators</buildtool_depend>

<!-- 类型支持库 -->
<build_export_depend>rosidl_typesupport_cpp</build_export_depend>
```

### 消息命名规范

```cmake
# 推荐：在同一行列出所有文件，依赖写在 DEPENDENCIES
rosidl_generate_interfaces(${PROJECT_NAME}
  FILES
    msg/RobotState.msg
    msg/SensorData.msg
    srv/Query.srv
    action/Navigate.action
  DEPENDENCIES
    std_msgs
    geometry_msgs
)
```

---

## 组件架构 (rclcpp_components)

### 组件原理

```
组件 = 共享库中的类
     = 可被 dlopen 动态加载
     = 可被 NodeExecutor 组合进一个进程

优点:
- 减少进程间通信开销
- 允许多个节点在同一进程
- 动态加载/卸载组件
```

### 组件实现

```cpp
// my_component.hpp
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

namespace my_package
{

class MyComponent : public rclcpp::Node
{
public:
  // 组件必须有一个构造函数接受 rclcpp::NodeOptions
  explicit MyComponent(const rclcpp::NodeOptions & options)
  : Node("my_component", options)
  {
    // 发布者
    pub_ = create_publisher<std_msgs::msg::String>("output", 10);

    // 订阅者
    sub_ = create_subscription<std_msgs::msg::String>(
      "input", 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        RCLCPP_INFO(get_logger(), "Got: %s", msg->data.c_str());
      }
    );
  }

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr sub_;
};

}  // namespace my_package

// 关键宏：注册为组件
#include <rclcpp_components/register_node_macro.hpp>
RCLCPP_COMPONENTS_REGISTER_NODE(my_package::MyComponent)
```

### CMakeLists.txt 组件配置

```cmake
# CMakeLists.txt

# 1. 查找组件支持
find_package(rclcpp_components REQUIRED)

# 2. 构建共享库
add_library(my_component SHARED
  src/my_component.cpp
)
ament_target_dependencies(my_component
  "rclcpp"
  "std_msgs"
)

# 3. 注册组件
rclcpp_components_register_node(my_component
  PLUGIN "my_package::MyComponent"
  EXECUTABLE my_executable_name  # 可选：提供默认可执行文件入口
)

# 4. 安装
install(TARGETS my_component
  ARCHIVE DESTINATION lib/${PROJECT_NAME}
  LIBRARY DESTINATION lib/${PROJECT_NAME}
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

# 5. 安装组件描述文件 (让其他包能发现你的组件)
rclcpp_components_register_node(my_component
  PLUGIN "my_package::MyComponent"
  EXECUTABLE my_executable_name
  PACKAGE_EXPORT "components"
)
```

### 组件使用 (Composition)

```cpp
// 方式1: 静态组合 (编译时确定)
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_components/executor.hpp>

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);

  rclcpp::executors::SingleThreadedExecutor executor;
  rclcpp::NodeOptions options;

  // 添加组件
  auto component = std::make_shared<my_package::MyComponent>(options);
  executor.add_node(component);

  executor.spin();
  rclcpp::shutdown();
}
```

### 动态加载组件 (dlopen)

```xml
<!-- 组件描述文件 -->
<!-- component_registry.cpp -->
#include <rclcpp_components/component_manager.hpp>
#include <rclcpp_components/node_factory.hpp>
#include <rclcpp_components/node_instance_wrapper.hpp>

// 自动注册
#include <ament_index_cpp/get.hpp>
#include <pluginlib/class_loader.hpp>

// 导出到组件包
#include "my_component/export.hpp"

PLUGINLIB_EXPORT_CLASS(my_package::MyComponent, rclcpp::Node)
```

---

## 插件系统 (pluginlib / class_loader)

### pluginlib 原理

```
pluginlib:
- 动态加载 C++ 类，无需链接
- 通过 XML 描述文件声明可用插件
- 支持运行时发现和加载

class_loader:
- pluginlib 的底层实现
- 管理 dlopen/dlsym 调用
- 支持库搜索路径
```

### 插件接口定义

```cpp
// base/include/base/polygon_base.hpp
#ifndef POLYGON_BASE_HPP
#define POLYGON_BASE_HPP

namespace polygon_base
{

class Polygon
{
public:
  using Ptr = std::shared_ptr<Polygon>;

  virtual ~Polygon() = default;

  virtual void initialize(double width, double height) = 0;
  virtual double area() const = 0;
  virtual std::string getName() const = 0;
};

}  // namespace polygon_base

#endif
```

### 插件实现

```cpp
// triangle/src/triangle.cpp
#include "base/polygon_base.hpp"
#include <cmath>

namespace polygon_plugins
{

class Triangle : public polygon_base::Polygon
{
public:
  void initialize(double width, double height) override
  {
    width_ = width;
    height_ = height;
  }

  double area() const override
  {
    return 0.5 * width_ * height_;
  }

  std::string getName() const override
  {
    return "Triangle";
  }

private:
  double width_{0}, height_{0};
};

}  // namespace polygon_plugins

// 关键宏：导出插件类
#include <pluginlib/plugin_export.hpp>
PLUGINLIB_EXPORT_CLASS(polygon_plugins::Triangle, polygon_base::Polygon)
```

### 插件 XML 描述文件

```xml
<!-- triangle/plugins.xml -->
<library path="libpolygon_plugins">
  <!-- class: 完全限定类名 -->
  <!-- type: 基类完全限定名 -->
  <!-- description: 插件描述 -->
  <class name="polygon_plugins/Triangle"
          type="polygon_plugins::Triangle"
          base_class_type="polygon_base::Polygon">
    <description>Triangle polygon plugin</description>
  </class>
</library>
```

### CMakeLists.txt 插件配置

```cmake
# CMakeLists.txt
find_package(pluginlib REQUIRED)

add_library(polygon_plugins SHARED
  src/triangle.cpp
)
ament_target_dependencies(polygon_plugins
  pluginlib
)

# 导出插件描述文件 (关键!)
pluginlib_export_plugin_description_file(
  polygon_base
  "plugins.xml"  # 相对于 share/${PROJECT_NAME} 的路径
)

install(TARGETS polygon_plugins
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)

# 安装插件描述文件
install(FILES plugins.xml
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
```

### package.xml 插件依赖

```xml
<depend>pluginlib</depend>
```

### 运行时使用插件

```cpp
#include <pluginlib/class_loader.hpp>
#include <base/polygon_base.hpp>

int main()
{
  // 创建类加载器
  pluginlib::ClassLoader<polygon_base::Polygon> loader(
    "polygon_base", "polygon_base::Polygon"
  );

  try {
    // 动态创建插件实例
    auto poly = loader.createSharedInstance("polygon_plugins/Triangle");
    poly->initialize(3.0, 4.0);
    RCLCPP_INFO(logger, "Area: %.2f", poly->area());

  } catch (pluginlib::PluginlibException & ex) {
    RCLCPP_ERROR(logger, "Failed to load plugin: %s", ex.what());
  }
}
```

---

## 条件编译和平台检测

### ROS2 版本检测

```cmake
# CMakeLists.txt 中检测 ROS2 版本
include(G `${rmf_utils}/cmake/get_ros2_version.cmake`)
get_ros2_version(version)

if(version VERSION_LESS "humble")
  message(FATAL_ERROR "This package requires ROS2 Humble or newer")
endif()

# 或者直接检查宏
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.0")
    message(WARNING "GCC < 9.0 may cause issues")
  endif()
endif()
```

### 平台条件编译

```cmake
# CMakeLists.txt
include(CMakeParseArguments)

# 检测目标架构
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
  set(PLATFORM_SUFFIX "_aarch64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
  set(PLATFORM_SUFFIX "_x86")
else()
  set(PLATFORM_SUFFIX "")
endif()

# 有条件的源文件
if(ENABLE_SIMULATION)
  list(APPEND MY_SOURCES
    src/sim/sim_node.cpp
    src/sim/physics_engine.cpp
  )
endif()

add_library(${PROJECT_NAME} SHARED ${MY_SOURCES})
```

### 依赖可选配置

```cmake
# CMakeLists.txt
option(BUILD_WITH_TF2 "Enable TF2 support" ON)

if(BUILD_WITH_TF2)
  find_package(tf2 REQUIRED)
  list(APPEND PACKAGE_DEPS tf2)
  target_compile_definitions(${PROJECT_NAME} PUBLIC WITH_TF2=1)
endif()
```

---

## 交叉编译

### ARM64 (Jetson / Raspberry Pi)

```cmake
# toolchain-aarch64.cmake
include(CMakeForceCompiler)

# 设置目标系统
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR aarch64)

# 交叉编译器路径
SET(CMAKE_C_COMPILER /opt/ros2-humble/aarch64/bin/aarch64-linux-gnu-gcc)
SET(CMAKE_CXX_COMPILER /opt/ros2-humble/aarch64/bin/aarch64-linux-gnu-g++)

# 搜索模式
SET(CMAKE_FIND_ROOT_PATH /opt/ros2-humble/aarch64)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

```bash
# 构建命令
colcon build \
  --cmake-toolchain-overlay /path/to/toolchain-aarch64.cmake \
  --merge-install \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

# 或使用 ament_tools
ament_tools \
  --cmake-toolchain /opt/ros2-humble/aarch64-linux-gnu/cmake/toolchain.cmake \
  build
```

### ROS2 交叉编译最佳实践

```bash
# 1. 安装 ROS2 SDK (目标架构)
export ROS2_SDK=/opt/ros2-humble
export CMAKE_PREFIX_PATH=$ROS2_SDK:$CMAKE_PREFIX_PATH

# 2. 使用镜像仓库 (避免从源码编译)
export OVERLAY_WS=~/ros2_overlay
mkdir -p $OVERLAY_WS/src
colcon graph | grep ros_base

# 3. 交叉编译命令
cd $OVERLAY_WS
colcon build \
  --cmake-args \
    -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake \
    -DCMAKE_PREFIX_PATH=/opt/ros/iron \
    -DCMAKE_BUILD_TYPE=Release \
  --merge-install
```

---

## 测试配置

```cmake
# 测试依赖 (package.xml)
<test_depend>ament_lint_auto</test_depend>
<test_depend>ament_lint_common</test_depend>
<test_depend>launch</test_depend>
<test_depend>launch_testing_ament_cmake</test_depend>

# CMakeLists.txt 测试
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()

  # GTest 单元测试
  find_package(ament_gtest REQUIRED)

  ament_add_gtest(test_my_node
    test/test_my_node.cpp
  )
  ament_target_dependencies(test_my_node
    rclcpp
    std_msgs
  )

  # Launch 测试
  find_package(launch_testing_ament_cmake REQUIRED)
  add_launch_test(test/launch/test_my_node.launch.py)
endif()
```

---

## 常用 CMake 模板

### 完整 CMakeLists.txt 模板

```cmake
cmake_minimum_required(VERSION 3.16)
project(my_awesome_robot)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

# C++ 标准
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

# 警告处理
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ============================================================
# 依赖包
# ============================================================
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(pluginlib REQUIRED)
find_package(nav2_msgs REQUIRED)
find_package(tf2 REQUIRED)

# 消息生成
find_package(rosidl_default_generators REQUIRED)

# ============================================================
# 包接口
# ============================================================
set(PACKAGE_DEPENDENCIES
  rclcpp
  std_msgs
  geometry_msgs
  nav2_msgs
  tf2
)

# ============================================================
# 库
# ============================================================
add_library(${PROJECT_NAME} SHARED
  src/my_node.cpp
  src/my_component.cpp
)
ament_target_dependencies(${PROJECT_NAME} ${PACKAGE_DEPENDENCIES})

# 组件注册
rclcpp_components_register_node(${PROJECT_NAME}_component
  PLUGIN "${PROJECT_NAME}::MyComponent"
  EXECUTABLE ${PROJECT_NAME}_executable
)

# 插件 (如果需要)
pluginlib_export_plugin_description_file(
  ${PROJECT_NAME}
  "plugins.xml"
)

# ============================================================
# 消息/服务/动作
# ============================================================
rosidl_generate_interfaces(${PROJECT_NAME}
  FILES
    msg/MyMessage.msg
    srv/MyService.srv
    action/MyAction.action
  DEPENDENCIES std_msgs geometry_msgs action_msgs
)

# ============================================================
# 安装
# ============================================================
install(
  TARGETS ${PROJECT_NAME} ${PROJECT_NAME}_component ${PROJECT_NAME}_executable
  ARCHIVE DESTINATION lib/${PROJECT_NAME}
  LIBRARY DESTINATION lib/${PROJECT_NAME}
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

install(DIRECTORY
  launch/
  config/
  rviz/
  urdf/
  DESTINATION share/${PROJECT_NAME}/
)

install(FILES
  plugins.xml
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
```

### package.xml 完整模板

```xml
<?xml version="1.0"?>
<!-- Format 3 (ROS2 Iron / Jazzy) -->
<package format="3">
  <name>my_awesome_robot</name>
  <version>1.0.0</version>
  <description>My awesome robot control package</description>

  <maintainer email="dev@example.com">Developer Name</maintainer>
  <license>Apache-2.0</license>

  <!-- Format 3 统一 depend (自动推断类型) -->
  <depend>rclcpp</depend>
  <depend>rclcpp_components</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>pluginlib</depend>
  <depend>nav2_msgs</depend>
  <depend>tf2</depend>

  <!-- 消息生成 -->
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <depend>action_msgs</depend>

  <!-- 测试 -->
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <test_depend>launch</test_depend>
  <test_depend>launch_testing_ament_cmake</test_depend>

  <!-- 条件依赖 -->
  <depend condition="$ROS_DISTRO >= humble">nav2_controller_interface</depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| `Could not find package xxx` | 依赖未安装或未 source | `source /opt/ros2/setup.bash` |
| `ament_target_dependencies: Unknown keyword` | CMake 版本太旧 | 升级 CMake 到 3.16+ |
| 插件加载失败 | plugins.xml 路径错误 | 确认 `pluginlib_export_plugin_description_file` 路径 |
| 组件找不到 | 未安装组件描述文件 | 检查 `rclcpp_components_register_node` 的 `PACKAGE_EXPORT` |
| 消息头文件找不到 | 未正确 include ament_index | 确认 `rosidl_get_typesupport_target` 已调用 |
| 交叉编译失败 | 工具链路径错误 | 检查 CMAKE_PREFIX_PATH 包含 ROS2 SDK |
| 库链接失败 | `-Wl,--no-as-needed` 问题 | 添加 `target_link_options` 或调整链接顺序 |

### 调试命令

```bash
# 查看包依赖树
rosdep depends my_package

# 查看包内容
ros2 pkg executables my_package
ros2 pkg libraries my_package

# 检查 CMake 配置
colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cat build/my_package/CMakeFiles/my_node.dir/flags.make

# 列出可用组件
ros2 component list

# 加载插件测试
ros2 pkg prefix my_package
ament_index_print

# 查看包安装路径
ros2 pkg prefix my_package
```

---

## 相关技能

- `common/ros2-package-generator` — ROS2 包生成器
- `common/ros2-component` — ROS2 组件架构
- `common/ros2-launch-advanced` — Launch 高级配置
- `common/ros2-lifecycle` — 生命周期节点
- `edge-platforms/arm64-cross-compile` — ARM64 交叉编译
