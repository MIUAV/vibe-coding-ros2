// lifecycle_node.cpp
// Lifecycle 节点 - 演示 rclcpp_lifecycle 状态机
// Lifecycle 节点用于需要优雅启停的组件（传感器、相机驱动等）

#include <memory>
#include <vector>
#include <string>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>

using rclcpp_lifecycle::LifecycleNode;
using lifecycle_msgs::msg::State;
using lifecycle_msgs::msg::Transition;

/**
 * LifecycleDemoNode - 演示 Lifecycle 状态机
 *
 * 状态转换:
 *   UNCONFIGURED → on_configure → INACTIVE
 *   INACTIVE → on_activate → ACTIVE
 *   ACTIVE → on_deactivate → INACTIVE
 *   INACTIVE/ACTIVE → on_cleanup → UNCONFIGURED
 *   任意状态 → on_shutdown → FINALIZED
 *
 * 禁止使用 rclcpp::Node，必须用 rclcpp_lifecycle::LifecycleNode
 */
class LifecycleDemoNode : public LifecycleNode
{
public:
  LifecycleDemoNode()
  : LifecycleNode("lifecycle_demo_node")
  {
    RCLCPP_INFO(get_logger(), "LifecycleDemoNode 构造完成");
  }

  // ── 状态回调（必须全部实现）─────────────────
  LifecycleNode::CallbackReturn
  on_configure(const LifecycleNode::State &) override
  {
    RCLCPP_INFO(get_logger(), "on_configure: 初始化资源...");

    // 在 configure 阶段创建 publisher（此时不能发布）
    publisher_ = this->create_publisher<std_msgs::msg::String>("lifecycle_topic", 10);

    // 初始化定时器（但不启动）
    timer_ = this->create_wall_timer(1s, [this]() { this->publish_callback(); });
    timer_->cancel();  // 先取消，激活时再启用

    RCLCPP_INFO(get_logger(), "on_configure 完成 → INACTIVE");
    return LifecycleNode::CallbackReturn::SUCCESS;
  }

  LifecycleNode::CallbackReturn
  on_activate(const LifecycleNode::State &) override
  {
    RCLCPP_INFO(get_logger(), "on_activate: 激活发布者...");
    // 必须先调用 publisher->on_activate() 才能发布
    publisher_->on_activate();

    // 启动定时器
    timer_->reset();

    RCLCPP_INFO(get_logger(), "on_activate 完成 → ACTIVE");
    return LifecycleNode::CallbackReturn::SUCCESS;
  }

  LifecycleNode::CallbackReturn
  on_deactivate(const LifecycleNode::State &) override
  {
    RCLCPP_INFO(get_logger(), "on_deactivate: 停用发布者...");
    publisher_->on_deactivate();
    timer_->cancel();
    RCLCPP_INFO(get_logger(), "on_deactivate 完成 → INACTIVE");
    return LifecycleNode::CallbackReturn::SUCCESS;
  }

  LifecycleNode::CallbackReturn
  on_cleanup(const LifecycleNode::State &) override
  {
    RCLCPP_INFO(get_logger(), "on_cleanup: 清理资源...");
    timer_.reset();
    publisher_.reset();
    RCLCPP_INFO(get_logger(), "on_cleanup 完成 → UNCONFIGURED");
    return LifecycleNode::CallbackReturn::SUCCESS;
  }

  LifecycleNode::CallbackReturn
  on_shutdown(const LifecycleNode::State &) override
  {
    RCLCPP_INFO(get_logger(), "on_shutdown: 关闭节点...");
    timer_.reset();
    publisher_.reset();
    RCLCPP_INFO(get_logger(), "on_shutdown 完成 → FINALIZED");
    return LifecycleNode::CallbackReturn::SUCCESS;
  }

private:
  void publish_callback()
  {
    auto message = std_msgs::msg::String();
    message.data = "Lifecycle tick at " + std::to_string(
      this->now().nanoseconds() / 1000000000);
    publisher_->publish(message);
    RCLCPP_INFO_ONCE(get_logger(), "首次发布 lifecycle_topic");
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);

  // Lifecycle 节点必须用 get_node_base_interface() 添加到 executor
  rclcpp::executors::MultiThreadedExecutor executor;
  auto lifecycle_node = std::make_shared<LifecycleDemoNode>();
  executor.add_node(lifecycle_node->get_node_base_interface());

  executor.spin();
  rclcpp::shutdown();
  return 0;
}
