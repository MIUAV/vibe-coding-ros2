---
name: ros2-lifecycle
description: ROS2 生命周期管理技能 - Managed Nodes、状态转换、配置/激活/去激活
user-invocable: true
argument-hint: "生命周期" / "lifecycle" / "managed node" / "状态机" / "configure activate"
---

# ROS2 Lifecycle Skill

> ROS2 生命周期状态管理完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现 Managed Node
- 管理节点状态转换
- 处理配置和清理逻辑
- 与 lifecycle_manager 集成
- 实现优雅启动和关闭

---

## 快速参考

### 状态机

```
Unconfigured ──[configure]──> Inactive
                                     │
                                     ├──[activate]──> Active
                                     │                      │
                                     ├──[deactivate]───────┘
                                     │
                                     └──[cleanup]──> Unconfigured
```

### 状态列表

| 状态 | 说明 |
|------|------|
| Unconfigured | 初始状态，未分配资源 |
| Inactive | 已配置，未运行 |
| Active | 运行中，处理数据 |
| Finalized | 关闭完成 |

### 过渡

| 过渡 | 说明 |
|------|------|
| configure | 分配资源，初始化 |
| activate | 开始处理 |
| deactivate | 停止处理，保留资源 |
| cleanup | 释放资源 |
| shutdown | 完全关闭 |

---

## C++ LifecycleNode

### 基本实现

```cpp
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <rclcpp/rclcpp.hpp>

class ManagedNode : public rclcpp_lifecycle::LifecycleNode {
public:
    ManagedNode() : rclcpp_lifecycle::LifecycleNode("managed_node") {}

    // 配置过渡
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_configure(const rclcpp_lifecycle::State& previous_state) override {
        RCLCPP_INFO(this->get_logger(), "Configuring...");
        
        // 初始化参数、订阅者、发布者
        publisher_ = this->create_publisher<std_msgs::msg::String>("output", 10);
        subscription_ = this->create_subscription<std_msgs::msg::String>(
            "input", 10, [this](const std_msgs::msg::String::SharedPtr msg) {
                if (this->get_current_state().id() == 
                    lifecycle_msgs::msg::State::PRIMARY_STATE_ACTIVE) {
                    RCLCPP_INFO(this->get_logger(), "Received: %s", msg->data.c_str());
                }
            });
        
        RCLCPP_INFO(this->get_logger(), "Configured successfully");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }

    // 激活过渡
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_activate(const rclcpp_lifecycle::State& previous_state) override {
        RCLCPP_INFO(this->get_logger(), "Activating...");
        
        // 开始发布
        publisher_->on_activate();
        
        // 启动定时器
        timer_ = this->create_wall_timer(1s, [this]() {
            auto msg = std_msgs::msg::String();
            msg.data = "Hello";
            publisher_->publish(msg);
        });
        
        RCLCPP_INFO(this->get_logger(), "Activated successfully");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }

    // 去激活过渡
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_deactivate(const rclcpp_lifecycle::State& previous_state) override {
        RCLCPP_INFO(this->get_logger(), "Deactivating...");
        
        // 停止定时器
        timer_.reset();
        
        // 停止发布
        publisher_->on_deactivate();
        
        RCLCPP_INFO(this->get_logger(), "Deactivated successfully");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }

    // 清理过渡
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_cleanup(const rclcpp_lifecycle::State& previous_state) override {
        RCLCPP_INFO(this->get_logger(), "Cleaning up...");
        
        // 释放资源
        subscription_.reset();
        publisher_.reset();
        
        RCLCPP_INFO(this->get_logger(), "Cleaned up successfully");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }

    // 关闭过渡
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_shutdown(const rclcpp_lifecycle::State& previous_state) override {
        RCLCPP_INFO(this->get_logger(), "Shutting down...");
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }

private:
    rclcpp_lifecycle::LifecyclePublisher<std_msgs::msg::String>::SharedPtr publisher_;
    rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
    rclcpp::TimerBase::SharedPtr timer_;
};
```

### main 函数

```cpp
int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    
    auto node = std::make_shared<ManagedNode>();
    rclcpp::spin(node->get_node_base_interface());
    
    rclcpp::shutdown();
    return 0;
}
```

---

## Python LifecycleNode

```python
import rclpy
from rclpy.lifecycle.node import LifecycleNode
from rclpy.lifecycle import State, TransitionCallbackReturn
from rclpy.publisher import Publisher
from std_msgs.msg import String

class ManagedNode(LifecycleNode):
    def __init__(self):
        super().__init__('managed_node')
        self.pub = None
        self.sub = None
        self.timer = None
    
    def on_configure(self, state: State) -> TransitionCallbackReturn:
        self.get_logger().info('Configuring...')
        self.pub = self.create_publisher(String, 'output', 10)
        self.sub = self.create_subscription(String, 'input', self.callback, 10)
        self.get_logger().info('Configured')
        return TransitionCallbackReturn.SUCCESS
    
    def on_activate(self, state: State) -> TransitionCallbackReturn:
        self.get_logger().info('Activating...')
        self.pub.on_activate()
        self.timer = self.create_timer(1.0, self.timer_callback)
        self.get_logger().info('Activated')
        return TransitionCallbackReturn.SUCCESS
    
    def on_deactivate(self, state: State) -> TransitionCallbackReturn:
        self.get_logger().info('Deactivating...')
        self.timer.cancel()
        self.pub.on_deactivate()
        self.get_logger().info('Deactivated')
        return TransitionCallbackReturn.SUCCESS
    
    def on_cleanup(self, state: State) -> TransitionCallbackReturn:
        self.get_logger().info('Cleaning up...')
        self.destroy_subscription(self.sub)
        self.destroy_publisher(self.pub)
        self.get_logger().info('Cleaned up')
        return TransitionCallbackReturn.SUCCESS
    
    def callback(self, msg):
        self.get_logger().info(f'Received: {msg.data}')
    
    def timer_callback(self):
        msg = String()
        msg.data = 'Hello'
        self.pub.publish(msg)
```

---

## Lifecycle Manager

### C++ 使用示例

```cpp
#include <rclcpp_lifecycle/lifecycle_node.hpp>
#include <rclcpp_lifecycle/lifecycle_manager.hpp>

int main(int argc, char** argv) {
    rclcpp::init(argc, argv);
    
    auto node = std::make_shared<rclcpp::Node>("lifecycle_manager_node");
    
    // 创建 LifecycleManager
    auto manager = std::make_unique<rclcpp_lifecycle::LifecycleManager>(node);
    
    // 初始化
    manager->init();
    
    // 触发状态转换
    manager->transition_by_node_name("managed_node", 
        lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
    manager->transition_by_node_name("managed_node", 
        lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);
    
    rclcpp::spin(node);
    manager->shutdown();
    rclcpp::shutdown();
    return 0;
}
```

### Launch 集成

```python
# launch/lifecycle.launch.py
from launch_ros.actions import LifecycleNode
from launch_ros.events.lifecycle import ChangeState
from launch_ros.events import OnTransitionCapture
from launch.actions import RegisterEventHandler, EmitEvent

def generate_launch_description():
    managed_node = LifecycleNode(
        package='my_package',
        executable='managed_node',
        name='managed_node',
        output='screen',
    )

    # 配置完成时自动激活
    configure_event = EmitEvent(
        event=ChangeState(
            lifecycle_node_matcher=OnTransitionCapture(managed_node),
            goal_state=lifecycle_msgs.msg.State.PRIMARY_STATE_INACTIVE,
        )
    )
    
    return LaunchDescription([managed_node, configure_event])
```

---

## 命令行工具

```bash
# 生命周期命令
ros2 lifecycle list
ros2 lifecycle set /node_name configure
ros2 lifecycle set /node_name activate
ros2 lifecycle set /node_name deactivate
ros2 lifecycle set /node_name cleanup
ros2 lifecycle get /node_name
```

---

## 最佳实践

1. **资源管理**: 在 on_configure 中分配，on_cleanup 中释放
2. **状态检查**: 在回调中检查当前状态
3. **错误处理**: 返回失败状态处理异常
4. **日志**: 记录每个状态转换
5. **发布者状态**: 使用 LifecyclePublisher 控制发布