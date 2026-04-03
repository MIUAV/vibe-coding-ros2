---
name: ros2-time-management
description: ROS2 时间管理技能 - 时钟源、Time/Duration、时间同步、模拟时间
user-invocable: true
argument-hint: 时间 OR clock OR time OR 模拟时间 OR sim time OR duration
---

# ROS2 Time Management Skill

> ROS2 时间系统完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 使用系统时钟和时间函数
- 切换模拟时间/真实时间
- 定时器和延时处理
- 时间同步和超时
- 时间戳和数据时序

---

## 快速参考

### 时间类型

| 类型 | 说明 |
|------|------|
| rclcpp::Time | 时间点 (sec, nanosec) |
| rclcpp::Duration | 时长 (sec, nanosec) |
| builtin_interfaces::msg::Time | ROS 消息时间 |
| builtin_interfaces::msg::Duration | ROS 消息时长 |

### 时钟源

```bash
# 使用系统时钟
ros2 run pkg node --ros-args -p use_sim_time:=false

# 使用模拟时间
ros2 run pkg node --ros-args -p use_sim_time:=true
```

---

## C++ 时间使用

### 获取当前时间

```cpp
#include <rclcpp/rclcpp.hpp>

class TimeNode : public rclcpp::Node {
public:
    TimeNode() : Node("time_node") {
        // 获取当前时间
        auto now = this->now();
        RCLCPP_INFO(this->get_logger(), "Current time: %f", now.seconds());
        
        // 检查是否使用模拟时间
        if (this->get_clock()->ros_time_is_available()) {
            RCLCPP_INFO(this->get_logger(), "Using simulation time");
        }
        
        // 创建定时器
        timer_ = this->create_wall_timer(1s, [this]() {
            auto now = this->now();
            RCLCPP_INFO(this->get_logger(), "Timer fired at: %.3f", now.seconds());
        });
    }

private:
    rclcpp::TimerBase::SharedPtr timer_;
};
```

### 时间计算

```cpp
// 时间差
auto now = this->now();
auto past = some_timestamp;
auto diff = now - past;  // rclcpp::Duration
RCLCPP_INFO("Diff: %.3f s", diff.seconds());

// 加上时长
auto future = now + rclcpp::Duration(5, 0);  // 5秒后

// 转换为不同格式
rclcpp::Time time_now = this->now();
builtin_interfaces::msg::Time ros_time = time_now;

// 从消息创建
builtin_interfaces::msg::Time msg_time;
msg_time.sec = 100;
msg_time.nanosec = 500000000;
rclcpp::Time cpp_time(msg_time);
```

---

## Python 时间使用

```python
import rclpy
from rclpy.node import Node
from rclpy.time import Time, Duration

class TimeNode(Node):
    def __init__(self):
        super().__init__('time_node')
        
        now = self.get_clock().now()
        self.get_logger().info(f'Current time: {now.nanoseconds} ns')
        
        # 检查模拟时间
        if self.get_clock().ros_time_is_available():
            self.get_logger().info('Using simulation time')
        
        # 定时器
        self.timer = self.create_timer(1.0, self.timer_callback)
    
    def timer_callback(self):
        now = self.get_clock().now()
        self.get_logger().info(f'Timer at: {now.nanoseconds} ns')


def main(args=None):
    rclpy.init(args=args)
    node = TimeNode()
    rclpy.spin(node)
    rclpy.shutdown()
```

---

## 模拟时间

### 启用模拟时间

```cpp
// 声明参数
this->declare_parameter<bool>("use_sim_time", false);

// 检查参数
if (this->get_parameter("use_sim_time").as_bool()) {
    RCLCPP_INFO(this->get_logger(), "Using simulation time");
}
```

### 等待时间可用

```cpp
// 等待模拟时间启动
auto clock = this->get_clock();
while (rclcpp::ok() && !clock->ros_time_is_available()) {
    rclcpp::sleep_for(100ms);
    RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 
        1000, "Waiting for simulation time...");
}
```

### 发布时钟话题

```bash
# 使用 clock_publisher
ros2 run rosgraph_ros clock

# 或者通过 launch
Node(
    package='rosgraph_ros',
    executable='clock',
    name='clock_publisher',
)
```

---

## 定时器进阶

### 一次性定时器

```cpp
// 创建后手动触发
auto timer = this->create_wall_timer(
    10s, []() { /* 只执行一次 */ });
timer->cancel();  // 取消

// 使用 Timer 构造函数
rclcpp::TimerBase::SharedPtr timer(
    this->create_wall_callback([this]() {
        // 一次性逻辑
        timer->cancel();
    }), false);  // false = 不重复
```

### 动态周期

```cpp
class DynamicTimerNode : public rclcpp::Node {
public:
    DynamicTimerNode() : Node("dynamic_timer"), period_(1.0) {
        timer_ = this->create_wall_timer(
            std::chrono::duration<double>(period_),
            [this]() { timer_callback(); });
    }
    
    void timer_callback() {
        // 调整周期
        period_ = new_period;
        timer_->reset();  // 重置定时器
    }

private:
    double period_;
    rclcpp::TimerBase::SharedPtr timer_;
};
```

### 时间同步

```cpp
class SyncNode : public rclcpp::Node {
public:
    SyncNode() : Node("sync_node") {
        // 使用消息头的时间戳同步
        sub_ = this->create_subscription<sensor_msgs::msg::Image>(
            "/camera/image", 10,
            [this](const sensor_msgs::msg::Image::SharedPtr msg) {
                // 使用消息的时间戳
                rclcpp::Time msg_time(msg->header.stamp);
                auto now = this->now();
                auto diff = now - msg_time;
                
                // 处理时间同步
            });
    }
};
```

---

## 命令行工具

```bash
# 查看时间源
ros2 param get /node_name use_sim_time

# 手动发布模拟时间
ros2 topic pub /clock builtin_interfaces/msg/Clock "{clock: {sec: 1000}}"

# 检查时间
ros2 run rclpy time drift

# 时钟话题
ros2 topic info /clock

# 设置域时间
export ROS_DOMAIN_ID=0
```

---

## 最佳实践

1. **时序一致性**: 使用消息头时间戳保持数据时序
2. **模拟时间**: 在仿真启动时启用，与真实时间区分
3. **超时处理**: 使用 Duration 处理超时和等待
4. **时钟选择**: 根据场景选择系统时钟或模拟时钟
5. **日志时间**: 记录时间戳便于调试分析