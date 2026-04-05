# Case: action-fibonacci-demo

> 用工具链生成 ROS2 Action Server 的完整流程。Fibonacci Action 是 ROS2 官方示例 Actions 的标准入门案例。

## 目标

生成一个 ROS2 Action Server：
- 使用 `example_interfaces` 提供的 Fibonacci Action
- 实现 `handle_goal` / `handle_cancel` / `handle_accepted`
- 后台线程执行计算
- 实时发布 Feedback

## 工具链使用步骤

### Step 1: 生成包骨架

```bash
bash scripts/generators/ros2-package-generator.sh fibonacci_action cpp rclcpp,rclcpp_action,rclcpp_components,example_interfaces --verify
```

### Step 2: 生成 Action Server 代码

替换 `src/fibonacci_action_node.cpp`：

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

using Fibonacci = example_interfaces::action::Fibonacci;
using GoalHandle = rclcpp_action::ServerGoalHandle<Fibonacci>;

class FibonacciServer : public rclcpp::Node {
public:
  FibonacciServer() : Node("fibonacci_server") {
    action_server_ = rclcpp_action::create_server<Fibonacci>(
      this, "fibonacci",
      std::bind(&FibonacciServer::handle_goal, this, _1, _2),
      std::bind(&FibonacciServer::handle_cancel, this, _1),
      std::bind(&FibonacciServer::handle_accepted, this, _1));
    RCLCPP_INFO(get_logger(), "Fibonacci Action Server 启动");
  }

private:
  // ── 验证 Goal ────────────────────────────────────────
  rclcpp_action::GoalResponse
  handle_goal(const rclcpp_action::GoalUUID&, std::shared_ptr<const Fibonacci::Goal> goal) {
    if (goal->order <= 0 || goal->order > 93) {
      RCLCPP_WARN(get_logger(), "拒绝无效 order: %d", goal->order);
      return rclcpp_action::GoalResponse::REJECT;
    }
    return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
  }

  // ── 接受 Cancel ─────────────────────────────────────
  rclcpp_action::CancelResponse handle_cancel(std::shared_ptr<GoalHandle>) {
    return rclcpp_action::CancelResponse::ACCEPT;
  }

  // ── 启动后台执行 ─────────────────────────────────────
  void handle_accepted(std::shared_ptr<GoalHandle> goal_handle) {
    std::thread{std::bind(&FibonacciServer::execute, this, _1), goal_handle}.detach();
  }

  // ── 执行循环（后台线程）──────────────────────────────
  void execute(std::shared_ptr<GoalHandle> goal_handle) {
    const auto goal = goal_handle->get_goal();
    Fibonacci::Feedback fb;
    fb.sequence = {0, 1};

    for (int i = 1; i < goal->order; ++i) {
      if (goal_handle->is_canceling()) {
        goal_handle->canceled(fb);
        RCLCPP_INFO(get_logger(), "Goal 被取消");
        return;
      }
      fb.sequence.push_back(fb.sequence[i] + fb.sequence[i-1]);
      goal_handle->publish_feedback(fb);  // 实时反馈进度
      std::this_thread::sleep_for(100ms);
    }

    Fibonacci::Result result;
    result.sequence = fb.sequence;
    goal_handle->succeed(result);
    RCLCPP_INFO(get_logger(), "完成! Fibonacci(%d) = %zu", goal->order, result.sequence.back());
  }

  rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<FibonacciServer>());
  rclcpp::shutdown();
  return 0;
}
```

### Step 3: 编译并测试

```bash
colcon build --packages-select fibonacci_action
source install/setup.bash

# Terminal 1: 启动 Server
ros2 run fibonacci_action fibonacci_action_server

# Terminal 2: 发送 Goal（观察反馈）
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}" --feedback

# Terminal 3: 取消 Goal
ros2 action cancel /fibonacci
```

## 关键模式

```
Client                    Server
  │─────── Goal ─────────→│  handle_goal() → ACCEPT
  │←───── Feedback ───────│  publish_feedback() (循环)
  │←───── Result ─────────│  succeed(result)
  │      or Cancel ───────│  is_canceling() → canceled()
```
