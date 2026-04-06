// service_test.cpp — ROS2 Service 节点测试模板
//
// 测试内容:
// 1. Service Server 启动成功
// 2. 正确响应 AddTwoInts 请求
// 3. 线程安全（并发请求）

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>
#include <thread>

class TestServiceNode : public rclcpp::Node
{
public:
  TestServiceNode() : Node("test_service")
  {
    service_ = this->create_service<example_interfaces::srv::AddTwoInts>(
      "add_two_ints",
      std::bind(&TestServiceNode::handle_service, this, std::placeholders::_1, std::placeholders::_2));
    call_count_.store(0);
    RCLCPP_INFO(get_logger(), "Test service ready");
  }

  std::atomic<int> call_count_{0};
  int last_a_{0}, last_b_{0};

private:
  void handle_service(
    const std::shared_ptr<example_interfaces::srv::AddTwoInts::Request> request,
    const std::shared_ptr<example_interfaces::srv::AddTwoInts::Response> response)
  {
    call_count_.fetch_add(1, std::memory_order_relaxed);
    last_a_ = request->a;
    last_b_ = request->b;
    response->sum = request->a + request->b;
  }

  rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

// ── 测试 1: Service 启动 ─────────────────────
TEST(ServiceNodeTest, service_starts_without_crash)
{
  auto node = std::make_shared<TestServiceNode>();
  ASSERT_NE(node, nullptr);
  rclcpp::spin_some(node);
}

// ── 测试 2: 正确响应请求 ──────────────────
TEST(ServiceNodeTest, responds_correctly_to_add_request)
{
  auto node = std::make_shared<TestServiceNode>();

  // 模拟客户端请求
  auto request = std::make_shared<example_interfaces::srv::AddTwoInts::Request>();
  request->a = 3;
  request->b = 7;

  auto response = std::make_shared<example_interfaces::srv::AddTwoInts::Response>();
  response->sum = 0;

  // 直接调用 service callback
  node->handle_service(request, response);

  EXPECT_EQ(response->sum, 10);
  EXPECT_EQ(node->last_a_, 3);
  EXPECT_EQ(node->last_b_, 7);
}

// ── 测试 3: 并发请求线程安全 ──────────────
TEST(ServiceNodeTest, concurrent_requests_are_thread_safe)
{
  auto node = std::make_shared<TestServiceNode>();
  const int num_threads = 4;
  const int requests_per_thread = 100;

  std::vector<std::thread> threads;
  for (int t = 0; t < num_threads; ++t) {
    threads.emplace_back([&node, t, requests_per_thread]() {
      for (int i = 0; i < requests_per_thread; ++i) {
        auto req = std::make_shared<example_interfaces::srv::AddTwoInts::Request>();
        req->a = t * requests_per_thread + i;
        req->b = 1;
        auto res = std::make_shared<example_interfaces::srv::AddTwoInts::Response>();
        node->handle_service(req, res);
        EXPECT_EQ(res->sum, req->a + req->b);
      }
    });
  }

  for (auto& t : threads) { t.join(); }

  // 4 threads × 100 requests = 400 calls
  EXPECT_EQ(node->call_count_.load(std::memory_order_acquire),
            num_threads * requests_per_thread);
}

// ── 测试 4: 负数处理 ─────────────────────
TEST(ServiceNodeTest, handles_negative_numbers)
{
  auto node = std::make_shared<TestServiceNode>();

  auto req = std::make_shared<example_interfaces::srv::AddTwoInts::Request>();
  req->a = -5;
  req->b = -3;
  auto res = std::make_shared<example_interfaces::srv::AddTwoInts::Response>();

  node->handle_service(req, res);
  EXPECT_EQ(res->sum, -8);
}

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
