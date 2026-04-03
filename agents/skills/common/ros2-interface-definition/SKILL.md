---
name: ros2-interface-definition
description: ROS2 接口定义技能 - MSG/SRV/Action 自定义类型、字段类型、嵌套定义、依赖管理
user-invocable: true
argument-hint: 创建 msg OR 创建 srv OR 创建 action OR 自定义消息 OR interface definition
---

# ROS2 Interface Definition Skill

> ROS2 自定义消息/服务/动作完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 定义自定义消息类型
- 创建服务请求/响应结构
- 设计动作的Goal/Feedback/Result
- 嵌套使用已有消息类型
- 管理接口依赖关系

---

## 快速参考

### 接口文件位置

```
my_package/
├── msg/
│   ├── MyMessage.msg
│   └── ComplexMessage.msg
├── srv/
│   ├── MyService.srv
│   └── Compute.srv
└── action/
    ├── MyAction.action
    └── Navigate.action
```

### 基本类型

| 类型 | 说明 |
|------|------|
| bool | 布尔值 |
| byte, uint8 | 8位无符号 |
| int8, uint8 | 有符号/无符号8位 |
| int16, uint16 | 16位整数 |
| int32, uint32 | 32位整数 |
| int64, uint64 | 64位整数 |
| float32 | 32位浮点 |
| float64 | 64位浮点 |
| string | 字符串 |
| time | 时间 (sec, nanosec) |
| duration | 时长 (sec, nanosec) |

---

## MSG 定义

### 基本消息

```yaml
# Color.msg
uint8 RED = 0
uint8 GREEN = 1
uint8 BLUE = 2

uint8 color
string name
float64[] rgb
```

### 嵌套消息

```yaml
# RobotState.msg
geometry_msgs/Pose pose
geometry_msgs/Twist velocity
sensor_msgs/JointState joint_state
string robot_name
time timestamp
```

### 数组消息

```yaml
# PointCloud.msg
std_msgs/Header header
geometry_msgs/Point32[] points
float64[] intensities
```

---

## SRV 定义

### 基本服务

```yaml
# SetBool.srv
---
# Response
bool success
string message
---
# Request
bool data
```

### 复杂服务

```yaml
# GetMap.srv
---
# Response
nav_msgs/OccupancyGrid map
bool valid
string message
---
# Request
string map_name
bool use_cache
float64 resolution
```

---

## Action 定义

### 运动控制 Action

```yaml
# ExecuteTrajectory.action
---
# Request
trajectory_msgs/JointTrajectory trajectory
float64 speed_factor
---
# Feedback
float64 progress
string current_joint
time elapsed
---
# Result
bool success
string message
float64 final_error
```

### 导航 Action

```yaml
# NavigateToPose.action
---
# Request
geometry_msgs/PoseStamped pose
string planner_id
---
# Feedback
geometry_msgs/PoseStamped current_pose
float64 distance_remaining
---
# Result
bool success
string message
```

---

## CMakeLists.txt 配置

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_VERSION VERSION_LESS "3.10")
  cmake_policy(SET CMP0048 NEW)
endif()

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)

# 定义接口
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/RobotState.msg"
  "srv/ExecuteTrajectory.srv"
  "action/Navigate.action"
  "action/ExecuteTrajectory.action"
  DEPENDENCIES geometry_msgs sensor_msgs nav_msgs trajectory_msgs
)

# C++ 接口支持
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
```

### 依赖已有消息

```cmake
# 依赖多个包
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/MyMsg.msg"
  DEPENDENCIES 
    std_msgs
    geometry_msgs
    sensor_msgs
    nav_msgs
)
```

---

## package.xml 配置

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>my_package</name>
  <version>0.1.0</version>
  <description>Custom interfaces</description>
  
  <maintainer email="user@example.com">User</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>sensor_msgs</depend>
  
  <member_of_group>rosidl_interface_packages</member_of_group>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

---

## 使用接口

### C++ 中使用

```cpp
#include <my_package/msg/robot_state.hpp>
#include <my_package/srv/execute_trajectory.hpp>
#include <my_package/action/navigate.hpp>

// 使用消息
auto msg = my_package::msg::RobotState();
msg.pose.position.x = 1.0;
msg.robot_name = "robot1";

// 使用服务请求
auto request = my_package::srv::ExecuteTrajectory::Request();
request.trajectory = trajectory;

// 使用 Action Goal
auto goal = my_package::action::Navigate::Goal();
goal.pose = target_pose;
```

### Python 中使用

```python
from my_package.msg import RobotState
from my_package.srv import ExecuteTrajectory
from my_package.action import Navigate

# 使用消息
msg = RobotState()
msg.pose.position.x = 1.0
msg.robot_name = 'robot1'

# 使用服务
request = ExecuteTrajectory.Request()
request.trajectory = trajectory
```

---

## 命令行工具

```bash
# 列出所有接口
ros2 interface list

# 查看接口详情
ros2 interface show std_msgs/msg/String

# 查看自定义接口
ros2 interface show my_package/msg/RobotState

# 列出包的接口
ros2 interface packages sensor_msgs

# 查找接口所在包
ros2 interface packages std_msgs
```

---

## 最佳实践

1. **命名规范**: 使用 CamelCase（如 MyMessage），字段使用 snake_case
2. **版本控制**: 在 msg 中添加版本或 API 字段
3. **兼容性**: 避免删除或修改已有字段，使用可选字段
4. **文档**: 在 msg 文件中添加注释说明字段含义
5. **依赖最小化**: 只依赖必要的消息类型