# (3,1) 节点实现 Prompt

> AI 辅助实现 ROS2 节点的具体功能代码

---

## 触发条件

当用户需要以下帮助时使用此 Prompt：
- 实现节点的具体功能
- 编写订阅/发布逻辑
- 添加定时器回调
- 实现服务/动作服务器
- 添加参数处理

---

## 实现指南

### 1. 订阅者实现

```cpp
// 基本订阅
rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr sub_;
sub_ = this->create_subscription<sensor_msgs::msg::Image>(
    "input/topic",
    10,  // QoS depth
    [this](const sensor_msgs::msg::Image::SharedPtr msg) {
        // 处理消息
    });

// 带 QoS 的订阅
rclcpp::SensorDataQoS qos;
qos.keep_last(10);
sub_ = this->create_subscription<sensor_msgs::msg::Image>(
    "input/topic", qos, callback);
```

### 2. 发布者实现

```cpp
// 基本发布
rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr pub_;
pub_ = this->create_publisher<sensor_msgs::msg::Image>(
    "output/topic", 10);

// 发布消息
auto msg = sensor_msgs::msg::Image();
msg.header.stamp = this->get_clock()->now();
msg.header.frame_id = "camera";
msg.height = 480;
msg.width = 640;
msg.encoding = "rgb8";
msg.step = 640 * 3;
msg.data.resize(640 * 480 * 3);
pub_->publish(msg);
```

### 3. 定时器实现

```cpp
// wall timer (固定间隔)
rclcpp::TimerBase::SharedPtr timer_;
timer_ = this->create_wall_timer(
    100ms,  // 100 毫秒
    [this]() {
        // 定时任务
    });

// steady timer (更精确)
rclcpp::TimerBase::SharedPtr steady_timer_;
steady_timer_ = this->create_steady_timer_for_each_node(
    std::chrono::milliseconds(100),
    [this]() {
        // 任务
    });
```

### 4. 参数实现

```cpp
// 声明参数
this->declare_parameter<int>("queue_size", 10);
this->declare_parameter<double>("threshold", 0.5);
this->declare_parameter<std::string>("frame_id", "base_link");
this->declare_parameter<bool>("enable_debug", false);

// 获取参数
int queue_size;
this->get_parameter("queue_size", queue_size);

// 参数回调
auto param_callback = [this](std::vector<rclcpp::Parameter> params) {
    for (auto& param : params) {
        if (param.get_name() == "threshold") {
            RCLCPP_INFO(this->get_logger(), 
                       "threshold changed to %f", 
                       param.as_double());
        }
    }
    return rclcpp::node_interfaces::NodeParametersInterface::CallbackReturn::SUCCESS;
};
this->set_on_parameters_set_callback(param_callback);
```

### 5. 服务服务器

```cpp
// 服务定义 (.srv)
// MyService.srv
// ---
// bool success
// string message

// 服务器
rclcpp::Service<example_interfaces::srv::Trigger>::SharedPtr service_;
service_ = this->create_service<example_interfaces::srv::Trigger>(
    "my_service",
    [this](const std::shared_ptr<example_interfaces::srv::Trigger::Request> request,
          std::shared_ptr<example_interfaces::srv::Trigger::Response> response) {
        RCLCPP_INFO(this->get_logger(), "Service called");
        response->success = true;
        response->message = "Done";
    });
```

### 6. 动作服务器

```cpp
// 动作定义 (.action)
// MyAction.action
// ---
// ---
// float32 progress
// ---
// bool success

rclcpp_action::Server<MyAction>::SharedPtr action_server_;
action_server_ = rclcpp_action::create_server<MyAction>(
    this,
    "my_action",
    [this](const rclcpp_action::GoalUUID& uuid,
          std::shared_ptr<const MyAction::Goal> goal) {
        RCLCPP_INFO(this->get_logger(), "Received goal");
        return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
    },
    [this](const rclcpp_action::GoalUUID& uuid) {
        return rclcpp_action::CancelResponse::ACCEPT;
    },
    [this](const rclcpp_action::GoalUUID& uuid,
          std::shared_ptr<MyAction::Feedback> feedback) {
        // 发布反馈
    },
    [this](const rclcpp_action::GoalUUID& uuid,
          const std::shared_ptr<MyAction::Result> result) {
        result->success = true;
    });
```

---

## 状态机模板

```cpp
enum class State { IDLE, PROCESSING, ERROR };

class MyNode : public rclcpp::Node {
public:
    MyNode() : Node("my_node"), state_(State::IDLE) {
        // 初始化...
    }

private:
    void handleIdle() {
        // IDLE 状态处理
    }
    
    void handleProcessing() {
        // PROCESSING 状态处理
    }
    
    void handleError() {
        // ERROR 状态处理
    }
    
    void transitionTo(State new_state) {
        if (state_ != new_state) {
            RCLCPP_INFO(this->get_logger(), 
                       "State: %d -> %d", 
                       (int)state_, (int)new_state);
            state_ = new_state;
        }
    }
    
    State state_;
};
```

---

## 多线程执行器

```cpp
int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    
    // 多线程执行器
    rclcpp::executors::MultiThreadedExecutor executor;
    
    // 创建多个节点
    auto node1 = std::make_shared<PublisherNode>();
    auto node2 = std::make_shared<SubscriberNode>();
    
    executor.add_node(node1);
    executor.add_node(node2);
    
    executor.spin();
    
    rclcpp::shutdown();
    return 0;
}
```

---

## Lifecycle 节点

```cpp
#include <rclcpp_lifecycle/lifecycle_node.hpp>

class LifecycleNode : public rclcpp_lifecycle::LifecycleNode {
public:
    LifecycleNode() : rclcpp_lifecycle::LifecycleNode("my_lifecycle_node") {}
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_configure(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Configuring...");
        // 初始化资源
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_activate(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Activating...");
        // 开始工作
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_deactivate(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Deactivating...");
        // 停止工作
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_cleanup(const rclcpp_lifecycle::State&) override {
        RCLCPP_INFO(get_logger(), "Cleaning up...");
        // 释放资源
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
};
```

---

## 最佳实践

1. **使用智能指针**: `std::make_shared` 代替 `new`
2. **避免阻塞**: 定时器回调不要做耗时操作
3. **线程安全**: 多线程访问共享数据要用 mutex
4. **错误处理**: 始终检查返回值和异常
5. **日志适当**: INFO 初始化，DEBUG 数据，WARN 异常，ERROR 错误
