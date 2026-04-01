---
name: ros2-package-generator
description: ROS2 功能包生成器 - 生成完整的 ROS2 包结构，包含 CMakeLists.txt、package.xml、节点代码、消息定义、Launch 文件
trigger: "创建一个 ROS2 包" / "generate ros2 package" / "创建功能包"
---

# ROS2 Package Generator Skill

> 用于生成 ROS2 功能包的完整结构

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建新的 ROS2 功能包
- 生成标准的包结构
- 初始化节点代码框架
- 创建自定义消息/服务/动作
- 设置包的依赖关系

---

## 快速参考

### 基本包结构

```
my_package/
├── CMakeLists.txt
├── package.xml
├── include/
│   └── my_package/
│       └── header.h
├── src/
│   ├── node_main.cpp
│   └── class.cpp
├── launch/
│   └── my_node.launch.py
├── config/
│   └── params.yaml
├── msg/
│   └── MyMessage.msg
├── srv/
│   └── MyService.srv
└── test/
    └── test_node.cpp
```

### C++ 节点模板

```cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <cv_bridge/cv_bridge.hpp>

class MyNode : public rclcpp::Node {
public:
    MyNode() : Node("my_node") {
        // 订阅
        subscription_ = this->create_subscription<sensor_msgs::msg::Image>(
            "input/image",
            10,
            std::bind(&MyNode::callback, this, std::placeholders::_1));
        
        // 发布
        publisher_ = this->create_publisher<sensor_msgs::msg::Image>(
            "output/image",
            10);
        
        // 定时器
        timer_ = this->create_wall_timer(
            100ms,
            std::bind(&MyNode::timer_callback, this));
        
        RCLCPP_INFO(this->get_logger(), "Node initialized");
    }

private:
    void callback(const sensor_msgs::msg::Image::SharedPtr msg) {
        // 处理图像
    }
    
    void timer_callback() {
        // 定时任务
    }
    
    rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr subscription_;
    rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<MyNode>());
    rclcpp::shutdown();
    return 0;
}
```

### CMakeLists.txt 核心配置

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_VERSION VERSION_LESS "3.10")
  cmake_policy(SET CMP0048 NEW)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)

# 头文件
include_directories(include)

# 库
add_library(my_library src/class.cpp)
ament_target_dependencies(my_library rclcpp sensor_msgs)

# 可执行文件
add_executable(my_node src/node_main.cpp)
ament_target_dependencies(my_node my_library)

# 安装
install(TARGETS my_node my_library
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY launch/ config/ 
  DESTINATION share/${PROJECT_NAME}/)

# 测试
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
```

### package.xml 模板

```xml
<?xml version="1.0"?>
<package format="3">
  <name>my_package</name>
  <version>1.0.0</version>
  <description>My ROS2 package</description>
  
  <maintainer email="user@example.com">User</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  
  <depend>rclcpp</depend>
  <depend>sensor_msgs</depend>
  
  <member_of_group>rosidl_interface_packages</member_of_group>

  <test_depend>ament_lint_auto</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

---

## 消息定义

### 标准消息格式

```msg
# MyMessage.msg
std_msgs/Header header

uint8 TYPE_A = 0
uint8 TYPE_B = 1
uint8 data_type

float32[] data
bool is_valid
```

### 服务定义

```srv
# MyService.srv
string device_id
uint8 command
---
bool success
string message
```

---

## 开发工作流

### 1. 创建包

```
用户: "帮我创建一个图像处理包 image_processor"

AI: 按照模板生成完整包结构
```

### 2. 添加依赖

```
用户: "这个包需要使用 OpenCV 和 TensorRT"

AI: 更新 CMakeLists.txt 和 package.xml
```

### 3. 实现功能

```
用户: "实现图像预处理功能：缩放到 640x480，转换为 RGB"

AI: 生成预处理代码
```

---

## 示例：创建巡检节点

```
用户: 创建一个巡检节点，功能：
- 订阅 /cmd_vel 接收运动指令
- 发布 /odom 里程计
- 使用 nav_msgs/Path 接收目标路径
- 实现状态机：IDLE -> PATROLLING -> RETURNING
```

AI 响应:

1. 创建包结构
2. CMakeLists.txt 配置
3. package.xml 依赖
4. 状态机实现代码
5. Launch 文件

---

## 最佳实践

1. **单一职责**: 每个包只负责一个功能
2. **命名规范**: 包名、节点名、话题名遵循 ROS2 规范
3. **接口稳定**: 先定义 msg/srv，再实现
4. **文档同步**: 边开发边写 README
5. **测试优先**: 编写单元测试和集成测试
