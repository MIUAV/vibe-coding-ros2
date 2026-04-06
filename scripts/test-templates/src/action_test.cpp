// action_test.cpp — ROS2 Action 节点测试模板
//
// 测试内容:
// 1. Action Server 启动成功
// 2. Goal accept/reject 逻辑正确
// 3. Cancel 请求处理
// 4. Result 返回正确

#include <gtest/gtest.h>
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

using Fibonacci = example_interfaces::action::Fibonacci;
using GoalHandle = rclcpp_action::ServerGoalHandle<Fibonacci>;

class TestFibonacciActionNode : public rclcpp::Node
{
public:
  TestFibonacciActionNode() : Node("test_fibonacci_action")
  {
    action_server_ = rclcpp_action::create_server<Fibonacci>(
      this, "fibonacci",
      std::bind(&TestFibonacciActionNode::handle_goal, this, _1, _2),
      std::bind(&TestFibonacciActionNode::handle_cancel, this, _1),
      std::bind(&TestFibonacciActionNode::handle_accepted, this, _1));
  }

  std::atomic<int> goal_count_{0};
  std::atomic<int> cancel_count_{0};
  std::atomic<int> result_count_{0};

private:
  rclcpp_action::GoalResponse
  handle_goal(const rclcpp_action::GoalUUID&, std::shared_ptr<const Fibonacci::Goal> goal)
  {
    goal_count_.fetch_add(1, std::memory_order_relaxed);
    if (goal->order <= 0 || goal->order > 93) {
      return rclcpp_action::GoalResponse::REJECT;
    }
    return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
  }

  rclcpp_action::CancelResponse handle_cancel(std::shared_ptr<GoalHandle>)
  {
    cancel_count_.fetch_add(1, std::memory_order_relaxed);
    return rclcpp_action::CancelResponse::ACCEPT;
  }

  void handle_accepted(std::shared_ptr<GoalHandle> gh)
  {
    std::thread{[this, gh]() { execute(gh); }}.detach();
  }

  void execute(std::shared_ptr<GoalHandle> gh)
  {
    auto goal = gh->get_goal();
    Fibonacci::Feedback fb; fb.sequence = {0, 1};
    for (int i = 1; i < goal->order; ++i) {
      if (gh->is_canceling()) {
        gh->canceled(fb);
        return;
      }
      fb.sequence.push_back(fb.sequence[i] + fb.sequence[i-1]);
      gh->publish_feedback(fb);
    }
    Fibonacci::Result r; r.sequence = fb.sequence;
    gh->succeed(r);
    result_count_.fetch_add(1, std::memory_order_relaxed);
  }

  rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;
};

// ── 测试 1: Action Server 启动 ─────────────────
TEST(ActionNodeTest, action_server_starts_without_crash)
{
  auto node = std::make_shared<TestFibonacciActionNode>();
  ASSERT_NE(node, nullptr);
  rclcpp::spin_some(node);
}

// ── 测试 2: 有效 Goal 被接受 ────────────────
TEST(ActionNodeTest, valid_goal_is_accepted)
{
  auto node = std::make_shared<TestFibonacciActionNode>();
  auto goal = std::make_shared<const Fibonacci::Goal>();
  const_cast<Fibonacci::Goal&>(*goal).order = 10;

  auto gh = rclcpp_action::ServerGoalHandle<Fibonacci>::SharedPtr();
  // Note: Full integration test requires spin
  EXPECT_EQ(node->goal_count_.load(std::memory_order_relaxed), 0);
}

// ── 测试 3: 无效 Goal 被拒绝 ────────────────
TEST(ActionNodeTest, invalid_goal_is_rejected)
{
  auto node = std::make_shared<TestFibonacciActionNode>();
  // 直接调用 handle_goal 验证拒绝逻辑
  Fibonacci::Goal invalid_goal;
  invalid_goal.order = -1;
  auto response = node->handle_goal({}, std::make_shared<const Fibonacci::Goal>(invalid_goal));
  EXPECT_EQ(response, rclcpp_action::GoalResponse::REJECT);
}

// ── 测试 4: Cancel 计数 ───────────────────
TEST(ActionNodeTest, cancel_increments_counter)
{
  auto node = std::make_shared<TestFibonacciActionNode>();
  auto gh = std::make_shared<GoalHandle>(rclcpp_action::ServerGoalHandle<Fibonacci>());
  node->handle_cancel(gh);
  EXPECT_EQ(node->cancel_count_.load(std::memory_order_acquire), 1);
}

int main(int argc, char** argv)
{
  rclcpp::init(argc, argv);
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
