// ros2-action-demo — ROS2 Action Server 完整示例
// Fibonacci Action: 计算斐波那契数列第 N 项
//
// 测试:
//   ros2 action list
//   ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 5}"

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

using Fibonacci = example_interfaces::action::Fibonacci;
using GoalHandle = rclcpp_action::ServerGoalHandle<Fibonacci>;
using namespace std::placeholders;

class FibonacciActionServer : public rclcpp::Node
{
public:
  FibonacciActionServer()
  : Node("fibonacci_action_server")
  {
    // ── 创建 Action Server ──────────────────────────────────
    action_server_ = rclcpp_action::create_server<Fibonacci>(
      this,
      "fibonacci",
      std::bind(&FibonacciActionServer::handle_goal, this, _1, _2),
      std::bind(&FibonacciActionServer::handle_cancel, this, _1),
      std::bind(&FibonacciActionServer::handle_accepted, this, _1));

    RCLCPP_INFO(get_logger(), "Fibonacci Action Server 启动");
  }

private:
  // ── Goal 处理 ────────────────────────────────────────────
  rclcpp_action::GoalResponse
  handle_goal(const rclcpp_action::GoalUUID&,
              std::shared_ptr<const Fibonacci::Goal> goal)
  {
    RCLCPP_INFO(get_logger(), "收到 Goal: order=%d", goal->order);

    // 验证
    if (goal->order <= 0 || goal->order > 93) {
      RCLCPP_WARN(get_logger(), "无效 order: %d (1-93 有效)", goal->order);
      return rclcpp_action::GoalResponse::REJECT;
    }

    return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
  }

  // ── Cancel 处理 ──────────────────────────────────────────
  rclcpp_action::CancelResponse
  handle_cancel(std::shared_ptr<GoalHandle> goal_handle)
  {
    RCLCPP_INFO(get_logger(), "收到取消请求");
    (void)goal_handle;
    return rclcpp_action::CancelResponse::ACCEPT;
  }

  // ── Goal 接受 ────────────────────────────────────────────
  void handle_accepted(std::shared_ptr<GoalHandle> goal_handle)
  {
    // 在后台线程执行（避免阻塞 spin）
    std::thread{std::bind(&FibonacciActionServer::execute, this, _1), goal_handle}.detach();
  }

  // ── 执行循环 ─────────────────────────────────────────────
  void execute(std::shared_ptr<GoalHandle> goal_handle)
  {
    const auto goal = goal_handle->get_goal();
    int order = goal->order;

    RCLCPP_INFO(get_logger(), "开始计算 Fibonacci(%d)", order);

    // 初始化序列
    Fibonacci::Feedback feedback;
    feedback.sequence = {0, 1};

    Fibonacci::Result result;

    auto& sequence = feedback.sequence;
    for (int i = 1; i < order; ++i) {
      // ── 检查是否被取消 ────────────────────────────────
      if (goal_handle->is_canceling()) {
        goal_handle->canceled(result);
        RCLCPP_INFO(get_logger(), "Goal 被取消");
        return;
      }

      // 计算下一步
      sequence.push_back(sequence[i] + sequence[i-1]);

      // 发布反馈（客户端可订阅观察进度）
      goal_handle->publish_feedback(feedback);
      RCLCPP_INFO(get_logger(), "进度: %zu (%.2f%%)",
        sequence.size(), 100.0 * sequence.size() / order);

      // 模拟耗时（实际任务中这里做实际计算）
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    // ── 完成 ─────────────────────────────────────────────
    if (rclcpp::ok()) {
      result.sequence = sequence;
      goal_handle->succeed(result);
      RCLCPP_INFO(get_logger(), "完成! Fibonacci(%d) = %zu", order, sequence.back());
    }
  }

  rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<FibonacciActionServer>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
