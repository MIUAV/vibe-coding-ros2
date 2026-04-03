/**
 * add_two_ints_server — ROS2 Service 服务端示例
 *
 * 功能: 提供加法服务
 *
 * 对应规范 (ANTI_PATTERNS.md):
 *   ✅ rclcpp::init() / rclcpp::shutdown() 完整
 *   ✅ 使用 SharedPtr
 *
 * 运行:
 *   ros2 run add_two_ints add_two_ints_server
 */

#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>

using std::placeholders::_1;
using std::placeholders::_2;

class AddTwoIntsServer : public rclcpp::Node
{
public:
  explicit AddTwoIntsServer(const rclcpp::NodeOptions & options = rclcpp::NodeOptions{})
  : Node("add_two_ints_server", options)
  {
    // ── 创建服务 ───────────────────────────────
    service_ = this->create_service<example_interfaces::srv::AddTwoInts>(
      "/add_two_ints",
      std::bind(&AddTwoIntsServer::handle_add, this, _1, _2)
    );

    RCLCPP_INFO(get_logger(), "AddTwoInts service ready at '/add_two_ints'");
  }

private:
  void handle_add(
    const std::shared_ptr<example_interfaces::srv::AddTwoInts::Request> request,
    std::shared_ptr<example_interfaces::srv::AddTwoInts::Response> response)
  {
    response->sum = request->a + request->b;

    RCLCPP_INFO(get_logger(),
      "Received: a=%ld, b=%ld → sum=%ld",
      request->a, request->b, response->sum);
  }

  rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);

  auto node = std::make_shared<AddTwoIntsServer>();
  rclcpp::spin(node);

  rclcpp::shutdown();
  return 0;
}
