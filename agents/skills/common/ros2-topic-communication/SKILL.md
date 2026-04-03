---
name: ros2-topic-communication
description: ROS2 Topic 通讯技能 - 发布者/订阅者实现、QoS 策略、数据同步与过滤
user-invocable: true
argument-hint: 创建 topic OR ros2 topic OR 发布订阅 OR publisher subscriber
---

# ROS2 Topic Communication Skill

> ROS2 Topic 发布/订阅通讯完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建发布者/订阅者节点
- 理解 ROS2 QoS 策略
- 实现数据同步和过滤
- 处理高频数据流
- 跨进程/跨机器通讯

---

## 快速参考

### 基础架构

```
Publisher (发布者)  ──[Topic]──>  Subscriber (订阅者)
     │                              │
     └──> msg type                 └──> msg type
     └──> QoS policy               └──> QoS policy
```

### C++ 发布者

```cpp
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class PublisherNode : public rclcpp::Node {
public:
    PublisherNode() : Node("publisher_node") {
        // 创建发布者
        publisher_ = this->create_publisher<std_msgs::msg::String>("chatter", 10);
        
        // 定时发布
        timer_ = this->create_wall_timer(1s, [this]() {
            auto msg = std_msgs::msg::String();
            msg.data = "Hello, ROS2!";
            publisher_->publish(msg);
        });
    }

private:
    rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
};
```

### C++ 订阅者

```cpp
class SubscriberNode : public rclcpp::Node {
public:
    SubscriberNode() : Node("subscriber_node") {
        subscription_ = this->create_subscription<std_msgs::msg::String>(
            "chatter",
            10,
            [this](const std_msgs::msg::String::SharedPtr msg) {
                RCLCPP_INFO(this->get_logger(), "Received: %s", msg->data.c_str());
            });
    }

private:
    rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
};
```

### Python 发布者

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class PublisherNode(Node):
    def __init__(self):
        super().__init__('publisher_node')
        self.publisher = self.create_publisher(String, 'chatter', 10)
        self.timer = self.create_timer(1.0, self.timer_callback)
    
    def timer_callback(self):
        msg = String()
        msg.data = 'Hello, ROS2!'
        self.publisher.publish(msg)
```

### Python 订阅者

```python
class SubscriberNode(Node):
    def __init__(self):
        super().__init__('subscriber_node')
        self.subscription = self.create_subscription(
            String, 'chatter', self.listener_callback, 10)
    
    def listener_callback(self, msg):
        self.get_logger().info(f'Received: {msg.data}')
```

---

## QoS 策略详解

### QoS 策略组合

| 策略 | 选项 | 说明 |
|------|------|------|
| History | KEEP_LAST, KEEP_ALL | 保留历史消息数量 |
| Depth | 队列大小 | 配合 KEEP_LAST 使用 |
| Reliability | RELIABLE, BEST_EFFORT | 可靠传输 vs 尽力而为 |
| Durability | TRANSIENT_LOCAL, VOLATILE | 持久性 |
| Deadline | 时间间隔 | 预期发布频率 |
| Liveliness | AUTOMATIC, MANUAL | 节点存活检测 |
| Priority | 优先级 | 消息优先级 |

### 典型 QoS 配置

#### 传感器数据 (BEST_EFFORT)

```cpp
rclcpp::QoS sensor_qos(10);
sensor_qos.best_effort()
       .durability_volatile()
       .deadline(rclcpp::Duration(0.1));
```

#### 命令/控制 (RELIABLE)

```cpp
rclcpp::QoS cmd_qos(10);
cmd_qos.reliable()
       .durability_volatile();
```

#### 状态/配置 (TRANSIENT_LOCAL)

```cpp
rclcpp::QoS state_qos(10);
state_qos.reliable()
         .transient_local()
         .keep_last(5);
```

---

## 高级模式

### 回调组 (Callback Groups)

```cpp
// 创建独立回调组
auto callback_group = this->create_callback_group(
    rclcpp::CallbackGroupType::MutuallyExclusive);

// 在回调组中创建订阅
auto sub_options = rclcpp::SubscriptionOptions();
sub_options.callback_group = callback_group;
subscription_ = this->create_subscription<...>(
    "topic", qos, callback, sub_options);
```

### 消息过滤器

#### 时间戳过滤

```cpp
class TimestampFilter : public rclcpp::Node {
public:
    TimestampFilter() : Node("timestamp_filter") {
        sub_ = this->create_subscription<sensor_msgs::msg::Image>(
            "/camera/image_raw", 10,
            [this](const sensor_msgs::msg::Image::SharedPtr msg) {
                auto now = this->now();
                auto msg_time = rclcpp::Time(msg->header.stamp);
                if ((now - msg_time).seconds() < 1.0) {
                    // 消息足够新
                    process_image(msg);
                }
            });
    }
};
```

#### 主题多路复用

```cpp
// 订阅多个主题，使用同一个回调
std::vector<std::string> topics = {"/camera/left", "/camera/right"};
for (const auto& topic : topics) {
    subs_.push_back(this->create_subscription<sensor_msgs::msg::Image>(
        topic, 10,
        [this](const sensor_msgs::msg::Image::SharedPtr msg) {
            process_image(msg);
        }));
}
```

---

## 同步多个 Topic

### ApproximateTimeSynchronizer (C++)

```cpp
#include <message_filters/subscriber.h>
#include <message_filters/synchronizer.h>
#include <message_filters近似时间同步器.h>

using namespace message_filters;

class SyncedNode : public rclcpp::Node {
public:
    SyncedNode() : Node("synced_node") {
        sub1_.subscribe(this, "/camera/image");
        sub2_.subscribe(this, "/depth/image");
        
        sync_ = std::make_shared<Synchronizer<SyncPolicy>>(
            SyncPolicy(10), sub1_, sub2_);
        sync_->registerCallback(&SyncedNode::sync_callback, this);
    }
    
    void sync_callback(const sensor_msgs::msg::Image::SharedPtr img,
                       const sensor_msgs::msg::Image::SharedPtr depth) {
        // 同时处理两个话题的数据
    }
    
private:
    Subscriber<sensor_msgs::msg::Image> sub1_, sub2_;
    std::shared_ptr<Synchronizer<SyncPolicy>> sync_;
};
```

### Python 时间同步

```python
from message_filters import Subscriber, ApproximateTimeSynchronizer

class SyncedNode(Node):
    def __init__(self):
        super().__init__('synced_node')
        self.img_sub = Subscriber(self, Image, '/camera/image')
        self.depth_sub = Subscriber(self, Image, '/depth/image')
        
        self.sync = ApproximateTimeSynchronizer(
            [self.img_sub, self.depth_sub], queue_size=10, slop=0.1)
        self.sync.registerCallback(self.sync_callback)
    
    def sync_callback(self, img, depth):
        self.get_logger().info('Synced!')
```

---

## 常见问题排查

### 查看话题信息

```bash
# 列出所有话题
ros2 topic list

# 查看话题类型
ros2 topic type /scan

# 查看发布/订阅信息
ros2 topic info /scan

# 查看实时频率
ros2 topic hz /scan

# 查看带宽
ros2 topic bw /scan

# 查看数据
ros2 topic echo /scan

# 查看消息定义
ros2 interface show sensor_msgs/msg/LaserScan
```

### 手动发布测试

```bash
# 发布字符串
ros2 topic pub /chatter std_msgs/msg/String "data: 'test'" -1

# 发布激光扫描
ros2 topic pub /scan sensor_msgs/msg/LaserScan "{header: {stamp: {sec: 0}, frame_id: 'laser'}, angle_min: -3.14, angle_max: 3.14, angle_increment: 0.01, time_increment: 0.0, scan_time: 0.1, range_min: 0.1, range_max: 30.0, ranges: [1.0, 2.0]}"

# 持续发布
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}}" -r 10
```

### 问题诊断

```bash
# 检查节点连接
ros2 node info /node_name

# 启动 rqt_graph 可视化
ros2 run rqt_graph rqt_graph

# 查看详细信息
ros2 run rqt_graph rqt_graph --args -t
```

---

## 最佳实践

1. **QoS 匹配**: 确保发布者和订阅者的 QoS 策略兼容
2. **消息类型**: 使用标准消息类型或明确定义的自定义消息
3. **命名规范**: 话题名使用下划线，如 `/robot/arm/joint_states`
4. **错误处理**: 添加超时处理和重连机制
5. **资源清理**: 使用智能指针管理生命周期