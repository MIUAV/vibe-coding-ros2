// lifecycle_test.cpp
// Lifecycle 节点测试模板 — GoogleTest
//
// 测试内容:
// 1. 节点创建成功
// 2. 状态转换正确: UNCONFIGURED→INACTIVE→ACTIVE
// 3. on_configure/on_activate 不阻塞
// 4. 节点在 ACTIVE 状态发布消息
// 5. 线程安全: 使用 atomic/protected 访问共享状态

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>
#include <atomic>

using State = rcl_lifecycle::State;
using LifecycleNode = rclcpp_lifecycle::LifecycleNode;

class TestLifecycleNode : public LifecycleNode
{
public:
  TestLifecycleNode() : LifecycleNode("test_lifecycle_node") {}

  // ── 使用 atomic 保护状态标志 ─────────────────────
  std::atomic<bool> configure_called{false};
  std::atomic<bool> activate_called{false};
  std::atomic<bool> deactivate_called{false};
  std::atomic<bool> cleanup_called{false};
  std::atomic<int> publish_count{0};

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override
  {
    configure_called.store(true, std::memory_order_relaxed);
    publisher_ = this->create_publisher<std_msgs::msg::String>("output", 10);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override
  {
    activate_called.store(true, std::memory_order_relaxed);
    publisher_->on_activate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State&) override
  {
    deactivate_called.store(true, std::memory_order_relaxed);
    publisher_->on_deactivate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State&) override
  {
    cleanup_called.store(true, std::memory_order_relaxed);
    publisher_.reset();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State&) override
  {
    publisher_.reset();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ── 线程安全的发布计数 ────────────────────────────
  void publish_one()
  {
    if (publisher_ && rclcpp::ok()) {
      std_msgs::msg::String msg;
      msg.data = "tick";
      publisher_->publish(msg);
      publish_count.fetch_add(1, std::memory_order_relaxed);
    }
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
};

// ── 测试 1: 初始状态 ─────────────────────
TEST(LifecycleNodeTest, initial_state_is_unconfigured)
{
  auto node = std::make_shared<TestLifecycleNode>();
  auto state = node->get_current_state();
  EXPECT_EQ(state.label(), "unconfigured");
}

// ── 测试 2: configure 转换 ──────────────
TEST(LifecycleNodeTest, configure_transitions_to_inactive)
{
  auto node = std::make_shared<TestLifecycleNode>();
  auto transition = lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE;
  node->trigger_transition(transition);

  rclcpp::sleep_for(std::chrono::milliseconds(100));

  auto state = node->get_current_state();
  EXPECT_EQ(state.label(), "inactive");
  EXPECT_TRUE(node->configure_called.load(std::memory_order_acquire));
}

// ── 测试 3: activate 转换 ──────────────
TEST(LifecycleNodeTest, activate_transitions_to_active)
{
  auto node = std::make_shared<TestLifecycleNode>();
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));

  auto state = node->get_current_state();
  EXPECT_EQ(state.label(), "active");
  EXPECT_TRUE(node->activate_called.load(std::memory_order_acquire));
}

// ── 测试 4: deactivate 回到 INACTIVE ───
TEST(LifecycleNodeTest, deactivate_returns_to_inactive)
{
  auto node = std::make_shared<TestLifecycleNode>();
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_DEACTIVATE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));

  auto state = node->get_current_state();
  EXPECT_EQ(state.label(), "inactive");
  EXPECT_TRUE(node->deactivate_called.load(std::memory_order_acquire));
}

// ── 测试 5: cleanup 重置资源 ────────────
TEST(LifecycleNodeTest, cleanup_resets_resources)
{
  auto node = std::make_shared<TestLifecycleNode>();
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_DEACTIVATE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CLEANUP);
  rclcpp::sleep_for(std::chrono::milliseconds(100));

  auto state = node->get_current_state();
  EXPECT_EQ(state.label(), "unconfigured");
  EXPECT_TRUE(node->cleanup_called.load(std::memory_order_acquire));
  EXPECT_TRUE(node->publisher_ == nullptr);  // publisher 已 reset
}

// ── 测试 6: 发布计数线程安全 ─────────────
TEST(LifecycleNodeTest, publish_count_thread_safe)
{
  auto node = std::make_shared<TestLifecycleNode>();
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
  node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);
  rclcpp::sleep_for(std::chrono::milliseconds(100));

  // 模拟多线程发布
  std::vector<std::thread> threads;
  for (int i = 0; i < 4; ++i) {
    threads.emplace_back([&node]() {
      for (int j = 0; j < 100; ++j) {
        node->publish_one();
      }
    });
  }
  for (auto& t : threads) { t.join(); }

  // 4 threads × 100 publishes = 400
  EXPECT_EQ(node->publish_count.load(std::memory_order_acquire), 400);
}

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
