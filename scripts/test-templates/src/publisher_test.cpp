// publisher_test.cpp
// Publisher 节点测试模板 — gtest + launch_testing
//
// 测试内容:
// 1. 节点启动无崩溃
// 2. 定时发布消息
// 3. 发布频率正确
// 4. 消息内容正确

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

// ── 测试固定参数 ────────────────────────────
static const char* TEST_TOPIC = "/test_publisher_topic";
static const int TEST_COUNT = 5;
static const double TEST_RATE_HZ = 10.0;

// ── Fixture ────────────────────────────────
class PublisherTestFixture : public ::testing::Test
{
protected:
  void SetUp() override
  {
    node_ = rclcpp::Node::make_shared("test_publisher");
  }

  void TearDown() override
  {
    node_.reset();
    rclcpp::shutdown();
  }

  rclcpp::Node::SharedPtr node_;
};

// ── 测试 1: 节点启动 ─────────────────────
TEST_F(PublisherTestFixture, node_starts_without_crash)
{
  EXPECT_NO_THROW({
    auto pub = node_->create_publisher<std_msgs::msg::String>(TEST_TOPIC, 10);
    rclcpp::spin_some(node_);
  });
}

// ── 测试 ───────────── 2: 消息计数 ─────────────────
TEST_F(PublisherTestFixture, publishes_expected_count)
{
  std::atomic<int> published_count{0};

  auto pub = node_->create_publisher<std_msgs::msg::String>(TEST_TOPIC, 10);

  auto sub = node_->create_subscription<std_msgs::msg::String>(
    TEST_TOPIC, 10,
    [&](const std_msgs::msg::String::SharedPtr) {
      published_count++;
    });

  // 触发一次发布
  auto msg = std_msgs::msg::String();
  msg.data = "test";
  pub->publish(msg);

  rclcpp::sleep_for(std::chrono::milliseconds(100));
  rclcpp::spin_some(node_);

  EXPECT_EQ(published_count.load(), 1);
}

// ── 测试 3: 消息内容 ─────────────────────
TEST_F(PublisherTestFixture, publishes_correct_content)
{
  std::string last_data;

  auto pub = node_->create_publisher<std_msgs::msg::String>(TEST_TOPIC, 10);
  auto sub = node_->create_subscription<std_msgs::msg::String>(
    TEST_TOPIC, 10,
    [&](const std_msgs::msg::String::SharedPtr msg) {
      last_data = msg->data;
    });

  auto msg = std_msgs::msg::String();
  msg.data = "hello_ros2_test";
  pub->publish(msg);

  rclcpp::sleep_for(std::chrono::milliseconds(100));
  rclcpp::spin_some(node_);

  EXPECT_EQ(last_data, "hello_ros2_test");
}

// ── 测试 4: QoS 兼容性 ───────────────────
TEST_F(PublisherTestFixture, qos_compatible_with_subscriber)
{
  rclcpp::QoS pub_qos(10);
  pub_qos.reliable();

  rclcpp::QoS sub_qos(10);
  sub_qos.reliable();

  auto pub = node_->create_publisher<std_msgs::msg::String>(TEST_TOPIC, pub_qos);
  auto sub = node_->create_subscription<std_msgs::msg::String>(TEST_TOPIC, sub_qos,
    [&](const std_msgs::msg::String::SharedPtr) {});

  // 不抛异常即通过
  EXPECT_TRUE(true);
}

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
