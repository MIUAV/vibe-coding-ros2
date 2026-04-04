// subscription_member_function.cpp
// 最小订阅者节点 - 演示 rclcpp 订阅者基本用法

#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

/**
 * MinimalSubscriber - 最小订阅者节点
 *
 * 演示:
 * - create_subscription + SharedPtr
 * - Lambda 回调
 * - SingleThreadedExecutor
 */
class MinimalSubscriber : public rclcpp::Node
{
public:
  MinimalSubscriber()
    : Node("minimal_subscriber")
  {
    // QoS depth=10, Reliable（默认）
    // 注意: 订阅者 QoS 不需要和发布者完全一致
    subscription_ = this->create_subscription<std_msgs::msg::String>(
      "topic", 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        RCLCPP_INFO(this->get_logger(), "收到: '%s'", msg->data.c_str());
      });

    RCLCPP_INFO(this->get_logger(), "MinimalSubscriber 已启动，订阅 /topic");
  }

private:
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  // SingleThreadedExecutor 足够用于简单订阅
  rclcpp::spin(std::make_shared<MinimalSubscriber>());
  rclcpp::shutdown();
  return 0;
}
