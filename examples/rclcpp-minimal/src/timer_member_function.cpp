// timer_member_function.cpp
// 定时器节点 - 演示 rclcpp 定时器用法（非阻塞定时）

#include <chrono>
#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

/**
 * TimerNode - 演示 wall_timer 非阻塞定时
 *
 * 禁止在回调中使用 time.sleep()！
 * 必须用 create_wall_timer，否则会阻塞事件循环。
 */
class TimerNode : public rclcpp::Node
{
public:
  TimerNode()
    : Node("timer_node"), iteration_(0)
  {
    timer_ = this->create_wall_timer(
      1s, [this]() { this->timer_callback(); });

    RCLCPP_INFO(this->get_logger(), "TimerNode 已启动，每秒触发一次");
  }

private:
  void timer_callback()
  {
    iteration_++;
    RCLCPP_INFO(this->get_logger(), "Timer 触发 #%zu", iteration_);

    // 错误示例（禁止这样做！）：
    // std::this_thread::sleep_for(500ms);  // ← 阻塞事件循环！

    // 正确做法：用 wall_timer 或 rclcpp::Rate
  }

  rclcpp::TimerBase::SharedPtr timer_;
  size_t iteration_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TimerNode>());
  rclcpp::shutdown();
  return 0;
}
