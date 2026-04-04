// publisher_member_function.cpp
// 最小发布者节点 - 演示 rclcpp 发布者基本用法
// 编译: ament_auto_add_executable(demo_publisher src/publisher_member_function.cpp)

#include <chrono>
#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

/**
 * MinimalPublisher - 最小发布者节点
 *
 * 演示:
 * - rclcpp::Node 继承
 * - create_publisher + SharedPtr
 * - create_wall_timer
 * - RCLCPP_INFO 日志
 * - MultiThreadedExecutor
 */
class MinimalPublisher : public rclcpp::Node
{
public:
  MinimalPublisher()
    : Node("minimal_publisher"), count_(0)
  {
    // QoS depth=10, Reliable（默认，适合通用命令）
    // 注意: 传感器数据用 sensor_dataQoS()
    publisher_ = this->create_publisher<std_msgs::msg::String>("topic", 10);

    // wall_timer 是非阻塞的，比 rate.sleep() 更好
    timer_ = this->create_wall_timer(
      500ms, [this]() { this->publish_callback(); });

    RCLCPP_INFO(this->get_logger(), "MinimalPublisher 已启动，发布到 /topic");
  }

private:
  void publish_callback()
  {
    auto message = std_msgs::msg::String();
    message.data = "Hello ROS2 #" + std::to_string(count_++);
    // 日志输出到 /rosout，可通过 ros2 run rqt_console rqt_console 查看
    RCLCPP_INFO(this->get_logger(), "发布: '%s'", message.data.c_str());
    publisher_->publish(message);
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

int main(int argc, char * argv[])
{
  // rclcpp::init 必须只调用一次
  rclcpp::init(argc, argv);

  // MultiThreadedExecutor 让回调可以并发执行
  rclcpp::executors::MultiThreadedExecutor executor;
  auto node = std::make_shared<MinimalPublisher>();
  executor.add_node(node);
  executor.spin();

  rclcpp::shutdown();
  return 0;
}
