---
name: ros2-action-communication
description: ROS2 Action 通讯技能 - ActionServer/ActionClient 实现、目标执行、反馈获取、任务取消
user-invocable: true
argument-hint: "创建 action" / "ros2 action" / "动作客户端" / "action server client"
---

# ROS2 Action Communication Skill

> ROS2 Action 异步任务执行完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现长时间运行的任务
- 需要进度反馈的操作
- 任务取消和抢占
- 异步目标执行
- 任务状态跟踪

---

## 快速参考

### 基础架构

```
Goal (目标) ──> ActionServer <─── Execution
     ^              |
     │              v
Feedback <────── Progress
     ^
     │
Result <──────── Completion
```

### 应用场景

- 导航 (Nav2)
- 机械臂运动控制
- 无人机起飞/降落
- 摄像头标定
- 数据采集任务

---

## C++ ActionServer

### 基本服务端

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

class FibonacciServer : public rclcpp::Node {
public:
    using Fibonacci = example_interfaces::action::Fibonacci;
    using GoalHandle = rclcpp_action::ServerGoalHandle<Fibonacci>;

    FibonacciServer() : Node("fibonacci_server") {
        // 创建 ActionServer
        action_server_ = rclcpp_action::create_server<Fibonacci>(
            this,
            "fibonacci",
            std::bind(&FibonacciServer::handle_goal, this, std::placeholders::_1, std::placeholders::_2),
            std::bind(&FibonacciServer::handle_cancel, this, std::placeholders::_1),
            std::bind(&FibonacciServer::handle_accepted, this, std::placeholders::_1));
        
        RCLCPP_INFO(this->get_logger(), "Action server ready");
    }

private:
    rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;

    // 处理新目标
    rclcpp_action::GoalResponse handle_goal(
        const rclcpp_action::GoalUUID& uuid,
        std::shared_ptr<const Fibonacci::Goal> goal) {
        RCLCPP_INFO(this->get_logger(), "Received goal with order: %d", goal->order);
        return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
    }

    // 处理取消请求
    rclcpp_action::CancelResponse handle_cancel(
        const std::shared_ptr<GoalHandle> goal_handle) {
        RCLCPP_INFO(this->get_logger(), "Received cancel request");
        return rclcpp_action::CancelResponse::ACCEPT;
    }

    // 处理接受的目标
    void handle_accepted(const std::shared_ptr<GoalHandle> goal_handle) {
        // 在新线程执行
        std::thread([this, goal_handle]() { execute(goal_handle); }).detach();
    }

    // 执行目标
    void execute(const std::shared_ptr<GoalHandle> goal_handle) {
        RCLCPP_INFO(this->get_logger(), "Executing goal");
        
        auto feedback = std::make_shared<Fibonacci::Feedback>();
        auto& sequence = feedback->partial_sequence;
        sequence.push_back(0);
        sequence.push_back(1);

        auto result = std::make_shared<Fibonacci::Result>();

        for (int i = 1; i < goal_handle->get_goal()->order; ++i) {
            // 检查取消
            if (goal_handle->is_canceling()) {
                result->sequence = sequence;
                goal_handle->canceled(result);
                RCLCPP_INFO(this->get_logger(), "Goal canceled");
                return;
            }

            // 更新序列
            sequence.push_back(sequence[i] + sequence[i-1]);
            
            // 发布反馈
            goal_handle->publish_feedback(feedback);
            RCLCPP_INFO(this->get_logger(), "Published feedback");

            // 模拟耗时操作
            std::this_thread::sleep_for(1s);
        }

        // 完成
        result->sequence = sequence;
        goal_handle->succeed(result);
        RCLCPP_INFO(this->get_logger(), "Goal succeeded");
    }
};
```

---

## C++ ActionClient

### 基本客户端

```cpp
class FibonacciClient : public rclcpp::Node {
public:
    using Fibonacci = example_interfaces::action::Fibonacci;
    using GoalHandle = rclcpp_action::ClientGoalHandle<Fibonacci>;

    FibonacciClient() : Node("fibonacci_client") {
        // 创建 ActionClient
        action_client_ = rclcpp_action::create_client<Fibonacci>(
            this,
            "fibonacci");
        
        // 等待服务可用
        if (!action_client_->wait_for_action_server(10s)) {
            RCLCPP_ERROR(this->get_logger(), "Action server not available");
            return;
        }
        
        send_goal();
    }

    void send_goal() {
        auto goal = Fibonacci::Goal();
        goal.order = 10;

        // 发送目标
        auto send_goal_options = 
            rclcpp_action::Client<Fibonacci>::SendGoalOptions();
        
        // 目标响应回调
        send_goal_options.goal_response_callback = [this](
            std::shared_ptr<GoalHandle> handle) {
            if (!handle) {
                RCLCPP_ERROR(this->get_logger(), "Goal was rejected");
            } else {
                RCLCPP_INFO(this->get_logger(), "Goal accepted");
                goal_handle_ = handle;
            }
        };

        // 反馈回调
        send_goal_options.feedback_callback = [this](
            std::shared_ptr<GoalHandle> handle,
            const std::shared_ptr<Fibonacci::Feedback> feedback) {
            RCLCPP_INFO(this->get_logger(), "Feedback: %ld", 
                feedback->partial_sequence.size());
        };

        // 结果回调
        send_goal_options.result_callback = [this](
            const rclcpp_action::ClientGoalHandle<Fibonacci>::WrappedResult& result) {
            switch (result.code) {
                case rclcpp_action::ResultCode::SUCCEEDED:
                    RCLCPP_INFO(this->get_logger(), "Goal succeeded");
                    break;
                case rclcpp_action::ResultCode::CANCELED:
                    RCLCPP_INFO(this->get_logger(), "Goal canceled");
                    break;
                case rclcpp_action::ResultCode::ABORTED:
                    RCLCPP_INFO(this->get_logger(), "Goal aborted");
                    break;
            }
        };

        action_client_->async_send_goal(goal, send_goal_options);
    }

private:
    rclcpp_action::Client<Fibonacci>::SharedPtr action_client_;
    std::shared_ptr<GoalHandle> goal_handle_;
};
```

### 取消目标

```cpp
void cancel_goal() {
    if (goal_handle_) {
        auto future = goal_handle_->async_cancel();
        if (rclcpp::spin_until_future_complete(this->get_node_base_interface(), 
                                                future) == rclcpp::FutureReturnCode::SUCCESS) {
            RCLCPP_INFO(this->get_logger(), "Cancel request sent");
        }
    }
}
```

---

## Python 实现

### 服务端

```python
import rclpy
from rclpy.node import Node
from rclpy.action import ActionServer
from rclpy.action.server import GoalResponse, CancelResponse
from example_interfaces.action import Fibonacci

class FibonacciServer(Node):
    def __init__(self):
        super().__init__('fibonacci_server')
        self._action_server = ActionServer(
            self, Fibonacci, 'fibonacci',
            self.execute_callback,
            goal_callback=self.goal_callback,
            cancel_callback=self.cancel_callback)
    
    def goal_callback(self, goal_handle):
        self.get_logger().info(f'Received goal: {goal_handle.request.order}')
        return GoalResponse.ACCEPT_AND_EXECUTE
    
    def cancel_callback(self, goal_handle):
        self.get_logger().info('Received cancel request')
        return CancelResponse.ACCEPT
    
    def execute_callback(self, goal_handle):
        self.get_logger().info('Executing goal')
        feedback = Fibonacci.Feedback()
        feedback.partial_sequence = [0, 1]
        
        for i in range(1, goal_handle.request.order):
            if goal_handle.is_canceling():
                goal_handle.canceled()
                return Fibonacci.Result()
            
            feedback.partial_sequence.append(
                feedback.partial_sequence[i] + feedback.partial_sequence[i-1])
            goal_handle.publish_feedback(feedback)
        
        goal_handle.succeed()
        result = Fibonacci.Result()
        result.sequence = feedback.partial_sequence
        return result
```

### 客户端

```python
class FibonacciClient(Node):
    def __init__(self):
        super().__init__('fibonacci_client')
        self._action_client = ActionClient(self, Fibonacci, 'fibonacci')
    
    def send_goal(self, order=10):
        goal = Fibonacci.Goal()
        goal.order = order
        
        self._action_client.wait_for_server()
        self._send_goal_future = self._action_client.send_goal_async(
            goal, feedback_callback=self.feedback_callback)
        self._send_goal_future.add_done_callback(self.goal_response_callback)
    
    def goal_response_callback(self, future):
        goal_handle = future.result()
        if not goal_handle.accepted:
            self.get_logger().info('Goal rejected')
            return
        
        self.get_logger().info('Goal accepted')
        self._result_future = goal_handle.get_result_async()
        self._result_future.add_done_callback(self.result_callback)
    
    def feedback_callback(self, feedback_msg):
        self.get_logger().info(f'Feedback: {feedback_msg.feedback.partial_sequence}')
    
    def result_callback(self, future):
        result = future.result().result
        self.get_logger().info(f'Result: {result.sequence}')
```

---

## Action 定义

### 自定义 Action 文件

```yaml
# my_action.action
# Request (请求)
geometry_msgs/Pose target_pose  # 目标位置
float64 speed                   # 运行速度
---
# Feedback (反馈)
float64 progress                # 进度 0.0-1.0
string status                   # 当前状态
---
# Result (结果)
bool success                    # 是否成功
string message                  # 消息
geometry_msgs/Pose final_pose   # 最终位置
```

### CMakeLists.txt

```cmake
rosidl_generate_interfaces(${PROJECT_NAME}
  "action/MyAction.action"
)
```

### package.xml

```xml
<member_of_group>rosidl_interface_packages</member_of_group>
```

---

## 命令行工具

```bash
# 列出 action
ros2 action list

# 查看 action 类型
ros2 action type /fibonacci

# 发送 goal
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}"

# 查看 action 信息
ros2 action info /fibonacci
```

---

## 最佳实践

1. **异步处理**: Action 任务应在独立线程执行
2. **取消支持**: 实现取消回调支持任务中断
3. **进度反馈**: 定期发布反馈让客户端了解进度
4. **超时处理**: 设置合理的超时时间
5. **状态追踪**: 记录目标状态变化便于调试