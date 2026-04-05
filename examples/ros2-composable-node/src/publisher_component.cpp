// publisher_component.cpp
// Composable Node — rclcpp_components 动态加载的组件
//
// 组件优势:
// 1. 运行时加载，不需要重新编译
// 2. 可以在同一个进程内组合多个节点（Zero-Copy）
// 3. 适合嵌入式/资源受限场景
//
// 使用方式:
//   ros2 run rclcpp_components component_container
//   ros2 component load /NodeName rclcpp_components:<PackageName>:<ComponentClass>

#include <chrono>
#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_components/node_factory.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

namespace ros2_composable_node {

/**
 * PublisherComponent — 可组合的发布者节点
 *
 * 通过 rclcpp_components_register_node 注册为可加载组件
 * 使用 PLUGINLIB_EXPORT_NODE 宏导出
 */
class PublisherComponent : public rclcpp::Node {
public:
  PublisherComponent(const rclcpp::NodeOptions& options = rclcpp::NodeOptions{})
  : Node("publisher_component", options), count_(0)
  {
    // QoS: RELIABLE — 通用控制命令
    publisher_ = this->create_publisher<std_msgs::msg::String>(
      "component_topic", QoS(10).reliable());

    timer_ = this->create_wall_timer(
      500ms, std::bind(&PublisherComponent::timer_callback, this));

    RCLCPP_INFO(this->get_logger(), "PublisherComponent started. Publishing to: component_topic");
  }

  ~PublisherComponent() override
  {
    RCLCPP_INFO(this->get_logger(), "PublisherComponent destroyed");
  }

private:
  void timer_callback()
  {
    auto msg = std_msgs::msg::String();
    msg.data = "Component tick: " + std::to_string(count_++);
    publisher_->publish(msg);
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

}  // namespace ros2_composable_node

// ── 组件注册 ─────────────────────────────────────────────────
// 这是关键宏，让这个类可以被 rclcpp_components 动态加载
#include <rclcpp_components/node_factory.hpp>
#include <rclcpp_components/register_node_macro.hpp>

// 注册为 ros2_composable_node 包的 PublisherComponent 组件
// 使用方法: ros2 component load /Container ros2_composable_node::PublisherComponent
RCLCPP_COMPONENTS_REGISTER_NODE(ros2_composable_node::PublisherComponent)
