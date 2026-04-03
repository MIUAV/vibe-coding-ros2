# (2,1) ROS2 功能包创建 Prompt

> AI 辅助创建 ROS2 功能包的完整结构

---

## 触发条件

当用户需要以下帮助时使用此 Prompt：
- 创建新的 ROS2 功能包
- 生成包的基础结构
- 设置 CMakeLists.txt 和 package.xml
- 初始化节点代码框架

---

## 输入信息

用户需要提供：
- 包名称
- 编程语言 (C++/Python)
- 核心依赖
- 主要功能

---

## 输出模板

### 1. 目录结构

```
{package_name}/
├── CMakeLists.txt
├── package.xml
├── include/
│   └── {package_name}/
│       └── {header}.h
├── src/
│   ├── {node}_main.cpp
│   └── {class}.cpp
├── launch/
│   └── {node}.launch.py
├── config/
│   └── params.yaml
├── msg/
│   └── {CustomMessage}.msg
├── srv/
│   └── {CustomService}.srv
└── test/
    └── test_{node}.cpp
```

---

## CMakeLists.txt 模板

```cmake
cmake_minimum_required(VERSION 3.8)
project({package_name})

if(CMAKE_VERSION VERSION_LESS "3.10")
  cmake_policy(SET CMP0048 NEW)
endif()

# C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)
# 添加其他依赖...

# 头文件
include_directories(
  include
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 库
add_library({library_name}
  src/{class}.cpp
)
ament_target_dependencies({library_name}
  rclcpp
  std_msgs
)

# 可执行文件
add_executable({node_name} src/{node}_main.cpp)
ament_target_dependencies({node_name}
  rclcpp
  {library_name}
)

# 安装
install(TARGETS {node_name} {library_name}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY launch/ config/
  DESTINATION share/${PROJECT_NAME}/)

install(DIRECTORY include/
  DESTINATION include)

# 测试
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
```

---

## package.xml 模板

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">

  <name>{package_name}</name>
  <version>1.0.0</version>
  <description>{description}</description>

  <maintainer email="user@example.com">User</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>

  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  <!-- 添加其他依赖 -->

  <member_of_group>rosidl_interface_packages</member_of_group>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>launch</test_depend>
  <test_depend>launch_testing</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>

</package>
```

---

## 节点代码模板

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <std_msgs/msg/string.hpp>

class {NodeName}Node : public rclcpp::Node {
public:
    {NodeName}Node() : Node("{node_name}") {
        // 订阅
        subscription_ = this->create_subscription<sensor_msgs::msg::Image>(
            "input/image",
            10,
            std::bind(&{NodeName}Node::imageCallback, this, std::placeholders::_1));

        // 发布
        publisher_ = this->create_publisher<sensor_msgs::msg::Image>(
            "output/image",
            10);

        // 定时器 (可选)
        timer_ = this->create_wall_timer(
            100ms,
            std::bind(&{NodeName}Node::timerCallback, this));

        // 参数 (可选)
        this->declare_parameter<int>("queue_size", 10);
        this->declare_parameter<double>("threshold", 0.5);

        RCLCPP_INFO(this->get_logger(), "{NodeName}Node initialized");
    }

private:
    void imageCallback(const sensor_msgs::msg::Image::SharedPtr msg) {
        // 处理图像
        RCLCPP_DEBUG(this->get_logger(), "Received image");
    }

    void timerCallback() {
        // 定时任务
    }

    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr subscription_;
    rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    RCLCPP_INFO(rclcpp::get_logger("main"), "Starting {node_name}");
    rclcpp::spin(std::make_shared<{NodeName}Node>());
    rclcpp::shutdown();
    return 0;
}
```

---

## Launch 文件模板

```python
# launch/{node}.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
import os
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():

    # 参数文件
    param_file = DeclareLaunchArgument(
        'param_file',
        default_value=os.path.join(
            get_package_share_directory('{package_name}'),
            'config', 'params.yaml'),
        description='Full path to param file')

    # 节点
    node = Node(
        package='{package_name}',
        executable='{node_name}',
        name='{node_name}',
        parameters=[LaunchConfiguration('param_file')],
        remappings=[
            ('input/image', '/camera/image_raw'),
            ('output/image', '/processed/image'),
        ],
        output='screen',
        emulate_tty=True,
    )

    return LaunchDescription([
        param_file,
        node
    ])
```

---

## 参数文件模板

```yaml
{node_name}:
  ros__parameters:
    # 整数参数
    queue_size: 10
    timeout_ms: 100

    # 浮点参数
    threshold: 0.75
    scale: 1.0

    # 布尔参数
    enable_debug: false
    use_gpu: true

    # 字符串参数
    frame_id: "base_link"
    topic_name: "/scan"

    # 数组参数
    target_ids: [1, 2, 3, 4, 5]
```

---

## 使用说明

1. **触发**: 用户说"创建一个 ROS2 包"或类似需求
2. **收集信息**: 包名、语言、依赖、功能
3. **生成结构**: 按照模板生成所有文件
4. **输出**: 完整的可编译包结构

---

## 示例对话

**用户**: "帮我创建一个图像处理包，接受原始图像，输出处理后的图像"

**AI**: 
- 包名: image_processor
- 依赖: rclcpp, sensor_msgs, cv_bridge, image_transport
- 生成完整的包结构和代码模板
