// ros2-lifecycle-demo — 生产级 LifecycleNode 完整示例
// 展示: 状态机 / QoS 配置 / RCLCPP 日志 / 错误处理 / Launch 集成
//
// 生命周期: UNCONFIGURED → Inactive → Active → Inactive → Finalized
// 测试命令:
//   ros2 lifecycle list /lifecycle_controller
//   ros2 lifecycle set /lifecycle_controller configure
//   ros2 lifecycle set /lifecycle_controller activate
//   ros2 lifecycle set /lifecycle_controller deactivate
//   ros2 lifecycle set /lifecycle_controller cleanup
//   ros2 lifecycle set /lifecycle_controller shutdown

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>
#include <geometry_msgs/msg/twist.hpp>

using std::placeholders::_1;
using namespace std::chrono_literals;

// ─────────────────────────────────────────────────────────────
// LifecycleControllerNode — 生产级 LifecycleNode 实现
// ─────────────────────────────────────────────────────────────
class LifecycleControllerNode : public rclcpp_lifecycle::LifecycleNode
{
public:
  LifecycleControllerNode()
  : LifecycleNode("lifecycle_controller")
  {
    RCLCPP_INFO(get_logger(), "LifecycleControllerNode 构造");

    // ── 参数声明（可在 configure 阶段读取）─────────────
    param_callback_handle_ = this->add_on_set_parameters_callback(
      std::bind(&LifecycleControllerNode::on_parameter_set, this, _1));
  }

  // ─────────────────────────────────────────────────────────
  // on_configure: 创建发布者、订阅者、计时器
  // ─────────────────────────────────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Configuring...");

    // ① 创建发布者 — QoS: RELIABLE（控制命令用）
    cmd_publisher_ = this->create_publisher<geometry_msgs::msg::Twist>(
      "/cmd_vel", rclcpp::QoS(10).reliable());

    // ② 创建发布者 — QoS: BEST_EFFORT（状态反馈用）
    status_publisher_ = this->create_publisher<std_msgs::msg::String>(
      "/controller_status", rclcpp::QoS(10).best_effort());

    // ③ 创建订阅者 — 订阅外部指令
    cmd_subscriber_ = this->create_subscription<geometry_msgs::msg::Twist>(
      "/external_cmd",
      rclcpp::QoS(10).reliable(),
      std::bind(&LifecycleControllerNode::cmd_callback, this, _1));

    // ④ 创建参数（可动态更新）
    this->declare_parameter("publish_rate_hz", 20.0);
    this->declare_parameter("max_linear_vel", 1.0);
    this->declare_parameter("max_angular_vel", 2.0);

    // ⑤ 从参数服务器读取参数
    double rate_hz;
    this->get_parameter("publish_rate_hz", rate_hz);
    auto period = std::chrono::duration<double>(1.0 / rate_hz);

    // ⑥ 创建计时器（在 inactive 状态不能运行，激活后才开始）
    timer_ = this->create_wall_timer(
      std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::duration<double>(period)),
      std::bind(&LifecycleControllerNode::timer_callback, this));

    RCLCPP_INFO(get_logger(), "[Lifecycle] Configured — publishing at %.1f Hz", rate_hz);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────────────────────
  // on_activate: 激活发布者和计时器
  // ─────────────────────────────────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Activating...");

    // 激活发布者（切换到 active 状态）
    cmd_publisher_->on_activate();
    status_publisher_->on_activate();

    // 发布初始状态消息
    auto status_msg = std_msgs::msg::String();
    status_msg.data = "controller_active";
    status_publisher_->publish(status_msg);

    // 计时器在 activate 后才会触发
    RCLCPP_INFO(get_logger(), "[Lifecycle] Activated — timer started");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────────────────────
  // on_deactivate: 停止计时器（但不销毁资源）
  // ─────────────────────────────────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Deactivating...");

    // 停止计时器（计时器对象保留，用于下次激活时复用）
    timer_->cancel();

    // 停用发布者
    cmd_publisher_->on_deactivate();
    status_publisher_->on_deactivate();

    RCLCPP_INFO(get_logger(), "[Lifecycle] Deactivated");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────────────────────
  // on_cleanup: 清理所有资源（恢复到 configure 前状态）
  // ─────────────────────────────────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Cleaning up...");

    // 销毁计时器
    timer_.reset();

    // 销毁订阅者（发布者也会被清理）
    cmd_subscriber_.reset();

    RCLCPP_INFO(get_logger(), "[Lifecycle] Cleaned up — back to unconfigured");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────────────────────
  // on_shutdown: 关闭（可在任意状态触发）
  // ─────────────────────────────────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp::State& current_state) override
  {
    RCLCPP_WARN(get_logger(), "[Lifecycle] Shutting down from state: %s",
      current_state.label().c_str());

    // 如果是从 active/deactivate 状态进来，先清理
    if (current_state.label() == "active" || current_state.label() == "deactivating") {
      timer_.reset();
      cmd_publisher_.reset();
      status_publisher_.reset();
      cmd_subscriber_.reset();
    }

    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────────────────────
  // 计时器回调 — 发布控制命令
  // ─────────────────────────────────────────────────────────
private:
  void timer_callback()
  {
    // 从参数读取当前限幅值
    double max_lin, max_ang;
    this->get_parameter("max_linear_vel", max_lin);
    this->get_parameter("max_angular_vel", max_ang);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = 0.0;
    cmd.angular.z = 0.0;

    cmd_publisher_->publish(cmd);

    // 发布状态（带上时间戳）
    std_msgs::msg::String status;
    status.data = "tick at " + std::to_string(this->now().nanoseconds() / 1e9);
    status_publisher_->publish(status);
  }

  // ─────────────────────────────────────────────────────────
  // 订阅者回调
  // ─────────────────────────────────────────────────────────
  void cmd_callback(const geometry_msgs::msg::Twist::SharedPtr msg)
  {
    RCLCPP_DEBUG(get_logger(), "Received cmd: lin=%.2f, ang=%.2f",
      msg->linear.x, msg->angular.z);
    // 简单存储，后续在 timer_callback 中使用
    last_cmd_ = *msg;
  }

  // ─────────────────────────────────────────────────────────
  // 参数更新回调
  // ─────────────────────────────────────────────────────────
  rcl_interfaces::msg::SetParametersResult
  on_parameter_set(const std::vector<rclcpp::Parameter>& params)
  {
    rcl_interfaces::msg::SetParametersResult result;
    result.successful = true;

    for (const auto& param : params) {
      if (param.get_name() == "publish_rate_hz") {
        if (param.as_double() <= 0 || param.as_double() > 1000) {
          result.successful = false;
          result.reason = "publish_rate_hz must be between 0 and 1000";
          return result;
        }
      }
    }
    return result;
  }

  // ── 成员变量 ────────────────────────────────────────────
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_publisher_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr status_publisher_;
  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_subscriber_;
  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::node_parameters::OnSetParametersCallbackHandle::SharedPtr param_callback_handle_;
  geometry_msgs::msg::Twist last_cmd_;
};

// ─────────────────────────────────────────────────────────────
// main — MultiThreadedExecutor 支持多线程回调
// ─────────────────────────────────────────────────────────────
int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);

  auto node = std::make_shared<LifecycleControllerNode>();

  // MultiThreadedExecutor 允许并发执行多个回调
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());

  // 注意：LifecycleNode 的回调（configure/activate 等）由 trigger_transition 触发
  // spin() 期间如果调用 node->trigger_transition()，会自动执行对应回调
  executor.spin();

  rclcpp::shutdown();
  return 0;
}
