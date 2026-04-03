/**
 * add_two_ints_client — ROS2 Service 客户端示例（带超时）
 *
 * 功能: 异步调用加法服务，带超时保护
 *
 * 对应规范 (ANTI_PATTERNS.md):
 *   ✅ async_send_request + wait_for() 超时保护
 *   ✅ 避免死锁
 *   ⚠️ 不要在回调中调用 rclcpp::shutdown()
 *
 * 运行:
 *   ros2 run add_two_ints add_two_ints_client
 */

#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>

class AddTwoIntsClient : public rclcpp::Node
{
public:
  explicit AddTwoIntsClient(const rclcpp::NodeOptions & options = rclcpp::NodeOptions{})
  : Node("add_two_ints_client", options)
  {
    client_ = this->create_client<example_interfaces::srv::AddTwoInts>("/add_two_ints");

    RCLCPP_INFO(get_logger(), "Client started, waiting for service...");
  }

  void send_request(int64_t a, int64_t b)
  {
    // ── 1. 等待服务上线 ──────────────────────
    if (!client_->wait_for_service(std::chrono::seconds(5))) {
      RCLCPP_WARN(get_logger(), "Service not available after 5s, giving up");
      return;
    }

    // ── 2. 发送异步请求 ──────────────────────
    auto request = std::make_shared<example_interfaces::srv::AddTwoInts::Request>();
    request->a = a;
    request->b = b;

    auto future = client_->async_send_request(request);
    RCLCPP_INFO(get_logger(), "Request sent: a=%ld, b=%ld", a, b);

    // ── 3. 等待响应（带超时）──────────────────
    // ⚠️ 超时必须设置，否则服务无响应时会永远等待（死锁）
    auto wait_result = future.wait_for(std::chrono::seconds(10));

    if (wait_result == std::future_status::ready) {
      // ── 成功 ─────────────────────────────
      auto response = future.get();
      RCLCPP_INFO(get_logger(), "Result: %ld + %ld = %ld", a, b, response->sum);
    } else if (wait_result == std::future_status::timeout) {
      // ── 超时 ─────────────────────────────
      RCLCPP_WARN(get_logger(), "Service call timed out after 10s");
    } else {
      // ── 错误 ─────────────────────────────
      RCLCPP_ERROR(get_logger(), "Service call failed");
    }
  }

private:
  rclcpp::Client<example_interfaces::srv::AddTwoInts>::SharedPtr client_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);

  auto node = std::make_shared<AddTwoIntsClient>();

  // 发送几次测试请求
  node->send_request(10, 20);
  node->send_request(100, -50);

  rclcpp::shutdown();
  return 0;
}
