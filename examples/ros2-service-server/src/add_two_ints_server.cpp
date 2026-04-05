// add_two_ints_server.cpp
// Service Server 示例 — 同步/异步两种调用模式
//
// 服务类型: example_interfaces/srv/AddTwoInts
// 请求: a (int64), b (int64)
// 响应: sum (int64)

#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>

// ── 同步 Service Server ────────────────────────────────────────────
class AddTwoIntsServer : public rclcpp::Node {
public:
  AddTwoIntsServer() : Node("add_two_ints_server")
  {
    // ── 方式1: 绑定回调 (推荐) ────────────────────
    service_ = this->create_service<example_interfaces::srv::AddTwoInts>(
      "add_two_ints",
      std::bind(&AddTwoIntsServer::add_callback, this,
                std::placeholders::_1, std::placeholders::_2));

    RCLCPP_INFO(this->get_logger(), "Service ready: /add_two_ints");
  }

private:
  void add_callback(
    const std::shared_ptr<example_interfaces::srv::AddTwoInts::Request> request,
    std::shared_ptr<example_interfaces::srv::AddTwoInts::Response> response)
  {
    response->sum = request->a + request->b;

    RCLCPP_INFO(this->get_logger(),
      "Incoming: %ld + %ld = %ld",
      request->a, request->b, response->sum);
  }

  rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

// ── 主函数 ─────────────────────────────────────────────────────────
int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<AddTwoIntsServer>();

  RCLCPP_INFO(node->get_logger(), "AddTwoInts server node spinning...");
  rclcpp::spin(node);

  rclcpp::shutdown();
  return 0;
}
