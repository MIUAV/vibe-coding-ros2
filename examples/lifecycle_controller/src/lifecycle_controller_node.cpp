// lifecycle_controller_node.cpp
// Lifecycle 控制器示例 — 演示 LifecycleNode + 参数 + 定时器
// 编译: colcon build --packages-select lifecycle_controller
// 运行: ros2 run lifecycle_controller lifecycle_controller_node

#include <chrono>
#include <memory>
#include <string>

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <rcl_interfaces/srv/set_parameters.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

/**
 * LifecycleController — 生命周期控制器示例
 *
 * 状态机: UNCONFIGURED → INACTIVE → ACTIVE → FINALIZED
 *
 * 这个节点演示:
 * - LifecycleNode 的标准状态转换
 * - 参数声明和读取 (on_configure 阶段)
 * - 定时器发布状态 (on_activate 后)
 * - 正确的资源清理 (on_cleanup / on_shutdown)
 */
class LifecycleController : public rclcpp_lifecycle::LifecycleNode {
public:
  LifecycleController()
  : LifecycleNode("lifecycle_controller"),
    publish_count_(0),
    cycle_duration_(1.0)  // 默认 1Hz
  {
    RCLCPP_INFO(get_logger(), "LifecycleController constructed");
  }

  // ── 状态回调 ────────────────────────────────────────

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "[%s] Configuring...", get_name());

    // 声明参数（只能在 configure 阶段声明）
    this->declare_parameter("cycle_duration", cycle_duration_);
    this->declare_parameter("node_name", std::string(get_name()));

    // 读取参数
    this->get_parameter("cycle_duration", cycle_duration_);
    if (cycle_duration_ <= 0.0) {
      RCLCPP_WARN(get_logger(), "Invalid cycle_duration %.2f, using 1.0", cycle_duration_);
      cycle_duration_ = 1.0;
    }

    // 创建 publisher（UNCONFIGURED 状态不能 publish）
    // QoS: TRANSIENT_LOCAL — 新订阅者能收到最近状态
    publisher_ = this->create_publisher<std_msgs::msg::String>(
      "controller_state", QoS(10).transient_local());

    RCLCPP_INFO(get_logger(), "[%s] Configured. cycle_duration=%.2fs",
                get_name(), cycle_duration_);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "[%s] Activating...", get_name());

    // Lifecycle publisher 需要显式 on_activate
    publisher_->on_activate();

    // 创建定时器（ACTIVATE 后才能 publish）
    timer_ = this->create_wall_timer(
      std::chrono::duration<double>(cycle_duration_),
      std::bind(&LifecycleController::timer_callback, this));

    RCLCPP_INFO(get_logger(), "[%s] Activated. Publishing at %.2f Hz",
                get_name(), 1.0 / cycle_duration_);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "[%s] Deactivating...", get_name());

    // 停止定时器（停止 publish）
    timer_.reset();
    publisher_->on_deactivate();

    RCLCPP_INFO(get_logger(), "[%s] Deactivated", get_name());
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "[%s] Cleaning up...", get_name());

    // 释放所有资源
    timer_.reset();
    publisher_.reset();

    RCLCPP_INFO(get_logger(), "[%s] Cleaned up", get_name());
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "[%s] Shutting down...", get_name());

    // 清理资源
    timer_.reset();
    publisher_.reset();

    RCLCPP_INFO(get_logger(), "[%s] Shutdown complete", get_name());
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

private:
  void timer_callback() {
    auto msg = std_msgs::msg::String();
    msg.data = "state[ACTIVE] count=" + std::to_string(publish_count_++) +
                " time=" + std::to_string(this->now().nanoseconds() / 1e9);
    RCLCPP_DEBUG(this->get_logger(), "Publishing: '%s'", msg.data.c_str());
    publisher_->publish(msg);
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  int publish_count_;
  double cycle_duration_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<LifecycleController>();

  // 手动触发 configure 和 activate（也可通过 launch 或 lifecycle manager）
  // node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_CONFIGURE);
  // node->trigger_transition(lifecycle_msgs::msg::Transition::TRANSITION_ACTIVATE);

  // 使用 executor 运行 lifecycle node
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());

  // 也可以用单线程
  // rclcpp::spin(node->get_node_base_interface());

  RCLCPP_INFO(node->get_logger(), "LifecycleController spinning...");
  executor.spin();

  rclcpp::shutdown();
  return 0;
}
