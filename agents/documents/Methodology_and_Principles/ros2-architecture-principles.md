# ROS2 架构设计原则

> 机器人系统架构设计的核心原则与模式

---

## 1. 架构概述

### 1.1 机器人系统层次

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  (任务规划、用户交互、监控面板)                                │
├─────────────────────────────────────────────────────────────┤
│                     Navigation Layer                         │
│  (路径规划、定位、障碍物规避)                                  │
├─────────────────────────────────────────────────────────────┤
│                     Perception Layer                         │
│  (视觉、激光雷达、IMU、深度相机)                              │
├─────────────────────────────────────────────────────────────┤
│                     Control Layer                           │
│  (电机控制、舵机控制、PID)                                    │
├─────────────────────────────────────────────────────────────┤
│                     Hardware Abstraction Layer               │
│  (驱动、传感器接口、执行器接口)                                 │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 ROS2 通信架构

```
                    ┌─────────────┐
                    │  Lifecycle  │  ← 状态管理
                    │  Manager    │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
    │  Node A │◄────►│  Topic   │◄────►│  Node B │
    │ (Pub)   │      │  Service │      │ (Sub)   │
    └─────────┘      └─────────┘      └─────────┘
                           │
                    ┌──────▼──────┐
                    │  Action     │
                    │  Server     │
                    └─────────────┘
```

---

## 2. 节点设计原则

### 2.1 单一职责原则 (SRP)

```
# Good: 每个节点职责单一
├── camera_driver_node      # 只负责相机驱动
├── image_preprocess_node  # 只负责图像预处理
├── detection_node        # 只负责目标检测
├── tracking_node         # 只负责目标跟踪

# Bad: 节点职责混杂
├── all_in_one_node       # 什么功能都塞一起
```

### 2.2 节点命名规范

```bash
# 命名规则: <modality>_<function>_<role>
# modality: sensor type or domain (camera, lidar, nav)
# function: what it does (driver, preprocess, detect)
# role: node type (publisher, subscriber, server)

# Good 命名
/helmet/camera/driver_node        # 相机驱动节点
/helmet/camera/preprocess_node    # 图像预处理
/helmet/nav/planner_node         # 规划器节点
/helmet/control/motor_node       # 电机控制节点

# Topic 命名
/helmet/camera/image_raw         # 原始图像
/helmet/camera/image_compressed  # 压缩图像
/helmet/camera/image_detected    # 检测结果
```

### 2.3 生命周期管理

```cpp
// 推荐使用 Lifecycle Node
// 原因: 
// 1. 可控的启动顺序
// 2. 优雅的降级处理
// 3. 便于调试和监控

class LifecycleNode : public rclcpp_lifecycle::LifecycleNode {
    // 状态机
    // UNCONFIGURED → INACTIVE → ACTIVE → FINALIZED
};
```

---

## 3. 消息设计

### 3.1 消息类型选择

| 场景 | 推荐类型 | 说明 |
|------|----------|------|
| 传感器数据流 | `sensor_msgs/*` | 图像、点云、IMU |
| 控制系统 | `geometry_msgs/*` | Twist、Wrench |
| 导航 | `nav_msgs/*` | Path、Odometry、Map |
| 状态机 | `std_msgs/*` | Bool、Float32、String |
| 复杂数据 | 自定义 msg | 根据需求定义 |

### 3.2 自定义消息规范

```msg
# 1. 文件头注释
# License: Apache-2.0
# Author: [姓名]
# Purpose: [用途]

# 2. 字段排序: Header > 重要字段 > 数据字段 > 数组字段

# Good
Header header              # 时间戳和坐标系
uint8 status               # 状态码
float32[] data             # 数据数组

# 3. 避免过深嵌套
# Bad: 不要嵌套超过 2 层
# NestedMsg1
#   └── NestedMsg2
#       └── NestedMsg3  # 太深，不好维护
```

### 3.3 消息兼容性

```cpp
// 添加版本字段，确保向前兼容
uint8 MSG_VERSION = 1     # 消息版本
uint8 device_id           # 设备 ID
float32[] data            # 数据

// 当需要升级时
uint8 MSG_VERSION = 2     # 升级版本
uint8 device_id           
float32[] data            
float32[] extra_data      # 新增字段，默认空数组
```

---

## 4. 通信模式

### 4.1 Topic vs Service vs Action

```
┌──────────────────────────────────────────────────────────────┐
│                        Topic (发布-订阅)                     │
│  用途: 持续数据流                                             │
│  特点: 异步、单向、实时性高                                    │
│  例: /scan, /image_raw, /cmd_vel                            │
├──────────────────────────────────────────────────────────────┤
│                       Service (请求-响应)                     │
│  用途: 一次性请求、状态查询                                    │
│  特点: 同步、短时、双向                                       │
│  例: /get_map, /reset_odom, /set_param                      │
├──────────────────────────────────────────────────────────────┤
│                       Action (目标-反馈-结果)                │
│  用途: 长时间任务、可取消、需反馈                              │
│  特点: 异步、长期、可监控进度                                  │
│  例: /navigate_to_pose, /pick_object, /patrol                 │
└──────────────────────────────────────────────────────────────┘
```

### 4.2 QoS 配置

```cpp
// 传感器数据: 高可靠性
rclcpp::SensorDataQoS qos;
qos.reliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
qos.durability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
qos.keep_last(10);

// 控制指令: 持久化 + 可靠性
rclcpp::ParametersQoS qos;
qos.reliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
qos.durability(RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL);
qos.liveliness(RMW_QOS_POLICY_LIVELINESS_AUTOMATIC);

// 实时数据: 尽最大努力
rclcpp::BestEffortQoS qos;
qos.reliability(RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT);
```

---

## 5. Launch 系统设计

### 5.1 Launch 文件结构

```python
# launch/node.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # 1. 参数声明
        DeclareLaunchArgument('config_file', ...),
        DeclareLaunchArgument('device', ...),
        
        # 2. 条件加载
        IfCondition(...),
        
        # 3. 节点启动
        Node(
            package='my_package',
            executable='my_node',
            parameters=[...],
            remappings=[...],
        ),
    ])
```

### 5.2 启动顺序

```python
# 正确顺序: 驱动 → 感知 → 规划 → 控制
[
    # 底层驱动 (需要最先启动)
    Node(package='lidar_driver', ...),
    Node(package='camera_driver', ...),
    
    # 中间层 (依赖驱动)
    Node(package='perception', ...),
    
    # 上层 (依赖中间层)
    Node(package='navigation', ...),
    Node(package='control', ...),
]
```

### 5.3 参数管理

```yaml
# config/default.yaml
my_node:
  ros__parameters:
    # 整数参数
    queue_size: 10
    timeout_ms: 100
    
    # 浮点参数
    threshold: 0.75
    
    # 布尔参数
    enable_debug: false
    
    # 字符串参数
    device_name: "/dev/video0"
    
    # 数组参数
    topics: ["topic1", "topic2"]
```

---

## 6. 包结构设计

### 6.1 功能包划分原则

| 包类型 | 职责 | 依赖 |
|--------|------|------|
| `*_driver` | 硬件驱动 | rclcpp, 硬件 SDK |
| `*_perception` | 感知算法 | cv_bridge, tensorrt |
| `*_navigation` | 导航规划 | nav2, slam |
| `*_control` | 运动控制 | geometry_msgs, controller |
| `*_bringup` | 启动集合 | 其他所有包 |
| `*_msgs` | 消息定义 | rosidl_default_generators |
| `*_utils` | 工具库 | 无或 minimal |

### 6.2 推荐目录结构

```
my_robot/
├── my_robot_driver/           # 驱动包
│   ├── src/
│   ├── include/
│   ├── config/
│   ├── launch/
│   ├── CMakeLists.txt
│   └── package.xml
│
├── my_robot_perception/       # 感知包
│   ├── msg/
│   ├── src/
│   ├── test/
│   ├── CMakeLists.txt
│   └── package.xml
│
├── my_robot_navigation/       # 导航包
│   ├── param/
│   ├── launch/
│   ├── maps/
│   ├── CMakeLists.txt
│   └── package.xml
│
└── my_robot_bringup/         # 启动包 (最小依赖)
    ├── launch/
    ├── config/
    ├── rviz/
    ├── CMakeLists.txt
    └── package.xml
```

---

## 7. 跨平台设计

### 7.1 CMake 条件编译

```cmake
# 检查目标平台
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    message(STATUS "Building for ARM64 (Jetson)")
    set(PLATFORM_ARM64 TRUE)
else()
    message(STATUS "Building for x86_64")
    set(PLATFORM_ARM64 FALSE)
endif()

# 平台特定配置
if(PLATFORM_ARM64)
    find_package(TensorRT REQUIRED)
    # ARM64 特定依赖
endif()
```

### 7.2 条件代码

```cpp
// 运行时平台检测
#ifdef __aarch64__
    // ARM64 特定代码
    initializeArm64Features();
#else
    // x86 特定代码
    initializeX86Features();
#endif

// 或运行时检测
std::string getPlatform() {
    #ifdef __aarch64__
        return "arm64";
    #else
        return "x86_64";
    #endif
}
```

---

## 8. 状态管理

### 8.1 节点状态机

```
                    ┌─────────────────┐
                    │   UNCONFIGURED  │  ← 初始状态
                    └────────┬────────┘
                             │ on_configure
                             ▼
                    ┌─────────────────┐
            ┌───────│    INACTIVE     │
            │       └────────┬────────┘
            │                │ on_activate
            │                ▼
            │       ┌─────────────────┐
            │       │     ACTIVE      │  ← 工作状态
            │       └────────┬────────┘
            │                │ on_deactivate
            │                ▼
            │       ┌─────────────────┐
            │       │   INACTIVE      │
            │       └────────┬────────┘
            │                │ on_cleanup
            │                ▼
            │       ┌─────────────────┐
            │       │   UNCONFIGURED  │
            │       └─────────────────┘
            │
            │       ┌─────────────────┐
            └──────►│    FINALIZED    │  ← 结束状态
                    └─────────────────┘
```

### 8.2 系统状态机

```cpp
// 多节点协调状态机
enum class SystemState {
    INIT,           // 系统初始化
    STANDBY,        // 待机
    CALIBRATING,    // 标定中
    OPERATING,      // 运行中
    ERROR,          // 错误
    SHUTDOWN        // 关机
};

// 状态转换规则
bool canTransition(SystemState from, SystemState to) {
    // 定义合法的状态转换
    switch(from) {
        case INIT:       return to == STANDBY || to == ERROR;
        case STANDBY:    return to == CALIBRATING || to == SHUTDOWN;
        case CALIBRATING: return to == OPERATING || to == STANDBY || to == ERROR;
        case OPERATING:  return to == STANDBY || to == ERROR;
        case ERROR:      return to == STANDBY || to == SHUTDOWN;
        default:         return false;
    }
}
```

---

## 9. 错误处理

### 9.1 错误分类

| 等级 | 说明 | 处理 |
|------|------|------|
| FATAL | 致命错误，节点必须退出 | 记录日志，退出节点 |
| ERROR | 操作失败，但可重试 | 重试或降级 |
| WARN | 警告，异常但不影响功能 | 记录日志，继续执行 |
| INFO | 信息，正常运行日志 | 调试用 |

### 9.2 错误传播

```cpp
// 使用 Result 类型返回错误
#include <tl_expected/expected.hpp>  // 或自定义

struct Error {
    int code;
    std::string message;
};

tl::expected<Result, Error> doOperation() {
    if (failed) {
        return tl::unexpected({E_CODE, "operation failed"});
    }
    return Result{...};
}

// 调用处
auto result = doOperation();
if (!result) {
    RCLCPP_ERROR(this->get_logger(), "Error: %s", 
                 result.error().message.c_str());
    // 处理错误
}
```

---

## 10. 性能考量

### 10.1 带宽控制

```cpp
// 问题: 高速传感器数据淹没系统
// 解决: 降采样或门控

void callback(const sensor_msgs::msg::Image::SharedPtr msg) {
    static auto last_time = this->get_clock()->now();
    auto now = this->get_clock()->now();
    
    // 只处理 30Hz 的数据
    if ((now - last_time).seconds() < 0.033) {
        return;
    }
    last_time = now;
    
    process(msg);
}
```

### 10.2 内存管理

```cpp
// 预分配缓冲区
class Node {
    std::vector<float> buffer_;  // 预分配
    sensor_msgs::msg::Image cached_image_;  // 复用
    
    void callback(const sensor_msgs::msg::Image::SharedPtr msg) {
        // 复用缓存，不要每次都分配
        cached_image_ = *msg;
        process(cached_image_);
    }
};
```

---

*本文档定义 ROS2 机器人项目的架构设计标准*
