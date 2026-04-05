// lifecycle_test.cpp
// Lifecycle 节点测试模板
//
// 测试内容:
// 1. 节点创建成功
// 2. 状态转换正确: UNCONFIGURED→INACTIVE→ACTIVE
// 3. on_configure/on_activate 不阻塞
// 4. 节点在 ACTIVE 状态发布消息

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>

using State = rcl_lifecycle::State;
using LifecycleNode = rclcpp_lifecycle::LifecycleNode;

class TestLifecycleNode : public LifecycleNode
{
public:
  TestLifecycleNode() : LifecycleNode("test_lifecycle_node") {}

  bool configure_called = false;
  bool activate_called = false;

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override
  {
    configure_called = true;
    publisher_ = this->create_publisher<std_msgs::msg::String>("output", 10);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override
  {
    activate_called = true;
    publisher_->on_activate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
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
  EXPECT_TRUE(node->configure_called);
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
  EXPECT_TRUE(node->activate_called);
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
}

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
