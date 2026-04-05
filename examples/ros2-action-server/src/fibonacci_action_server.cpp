// fibonacci_action_server.cpp
// Fibonacci Action Server — 演示 ROS2 Action 回调组（CallbackGroup）
//
// Action 类型: example_interfaces/action/Fibonacci
// Goal: 计算 Fibonacci 序列
// Result: 返回完整序列
// Feedback: 实时返回当前计算的序列

#include <functional>
#include <memory>
#include <thread>
#include <vector>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

using Fibonacci = example_interfaces::action::Fibonacci;
using GoalHandleFibonacci = rclcpp_action::ServerGoalHandle<Fibonacci>;
using namespace std::placeholders;

// ── Fibonacci Action Server ───────────────────────────────────────
class FibonacciActionServer : public rclcpp::Node {
public:
  explicit FibonacciActionServer(const rclcpp::NodeOptions& options = rclcpp::NodeOptions{})
  : Node("fibonacci_action_server", options)
  {
    using namespace std::placeholders;

    // ── 创建 Action Server ────────────────────────
    action_server_ = rclcpp_action::create_server<Fibonacci>(
      this,
      "fibonacci",
      std::bind(&FibonacciActionServer::handle_goal, this, _1, _2),
      std::bind(&FibonacciActionServer::handle_cancel, this, _1),
      std::bind(&FibonacciActionServer::handle_accepted, this, _1)
    );

    RCLCPP_INFO(this->get_logger(), "Fibonacci Action Server ready: /fibonacci");
  }

private:
  // ── Goal 接收回调 ────────────────────────────────
  rclcpp_action::GoalResponse handle_goal(
    const rclcpp_action::GoalUUID& uuid,
    std::shared_ptr<const Fibonacci::Goal> goal)
  {
    RCLCPP_INFO(this->get_logger(), "Received goal request with order: %d", goal->order);

    // 订单验证（1-100）
    if (goal->order < 1) {
      RCLCPP_WARN(this->get_logger(), "Goal rejected: order must be >= 1");
      return rclcpp_action::GoalResponse::REJECT;
    }
    if (goal->order > 100) {
      RCLCPP_WARN(this->get_logger(), "Goal rejected: order must be <= 100");
      return rclcpp_action::GoalResponse::REJECT;
    }

    RCLCPP_INFO(this->get_logger(), "Goal accepted");
    (void)uuid;  // suppress unused warning
    return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
  }

  // ── Cancel 接收回调 ──────────────────────────────
  rclcpp_action::CancelResponse handle_cancel(
    std::shared_ptr<GoalHandleFibonacci> goal_handle)
  {
    RCLCPP_INFO(this->get_logger(), "Received cancel request");
    (void)goal_handle;
    return rclcpp_action::CancelResponse::ACCEPT;
  }

  // ── Goal 开始执行 ────────────────────────────────
  void handle_accepted(std::shared_ptr<GoalHandleFibonacci> goal_handle)
  {
    // 在新线程中执行，避免阻塞主线程
    std::thread{std::bind(&FibonacciActionServer::execute, this, goal_handle)}.detach();
  }

  // ── 执行线程 ────────────────────────────────────
  void execute(std::shared_ptr<GoalHandleFibonacci> goal_handle)
  {
    const auto goal = goal_handle->get_goal();
    auto feedback = std::make_shared<Fibonacci::Feedback>();
    auto result = std::make_shared<Fibonacci::Result>();

    RCLCPP_INFO(this->get_logger(), "Executing Fibonacci order=%d", goal->order);

    rclcpp::Rate loop_rate(10ms);  // 10ms 间隔 = 100 Hz

    // 初始化 Fibonacci 序列
    feedback->sequence = {0, 1};
    result->sequence = {0, 1};

    for (size_t i = 1; i < static_cast<size_t>(goal->order); ++i) {
      // 检查是否被取消
      if (goal_handle->is_canceling()) {
        result->sequence = feedback->sequence;
        goal_handle->canceled(result);
        RCLCPP_INFO(this->get_logger(), "Goal canceled");
        return;
      }

      // 计算下一个 Fibonacci 数
      feedback->sequence.push_back(
        feedback->sequence[i] + feedback->sequence[i-1]
      );

      // 发布 Feedback
      goal_handle->publish_feedback(feedback);
      RCLCPP_INFO(this->get_logger(), "Published feedback: %zu", feedback->sequence.size());

      loop_rate.sleep();
    }

    // 计算完成，设置 Result
    result->sequence = feedback->sequence;
    goal_handle->succeed(result);
    RCLCPP_INFO(this->get_logger(), "Goal succeeded. Sequence size: %zu", result->sequence.size());
  }

  rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);

  auto action_server = std::make_shared<FibonacciActionServer>();

  rclcpp::spin(action_server);

  rclcpp::shutdown();
  return 0;
}
