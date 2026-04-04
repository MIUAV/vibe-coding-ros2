// diff_drive_controller.cpp
// 差速驱动轮式机器人控制器
// 订阅 geometry_msgs/Twist (cmd_vel) → 发布左右轮速度
//
// 差速驱动运动学:
//   v_l = v - ω × (W/2)
//   v_r = v + ω × (W/2)
//   v   = (v_l + v_r) / 2
//   ω   = (v_r - v_l) / W
//
// 其中: W = 轮距 (wheelbase), v = 线速度, ω = 角速度

#include <memory>
#include <string>
#include <cmath>

#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <std_msgs/msg/float64.hpp>

/**
 * DiffDriveController — 差速驱动控制器
 *
 * 订阅: /cmd_vel (geometry_msgs/Twist)
 * 发布: /left_wheel_velocity (std_msgs/Float64)
 *       /right_wheel_velocity (std_msgs/Float64)
 *
 * 参数:
 *   wheelbase (double): 轮距 (m), 默认 0.5
 *   max_linear_vel (double): 最大线速度 (m/s), 默认 1.0
 *   max_angular_vel (double): 最大角速度 (rad/s), 默认 2.0
 */
class DiffDriveController : public rclcpp::Node {
public:
  DiffDriveController()
  : Node("diff_drive_controller"),
    wheelbase_(0.5),
    max_linear_vel_(1.0),
    max_angular_vel_(2.0)
  {
    // ── 参数声明 ─────────────────────────────────
    this->declare_parameter("wheelbase", wheelbase_);
    this->declare_parameter("max_linear_vel", max_linear_vel_);
    this->declare_parameter("max_angular_vel", max_angular_vel_);
    this->declare_parameter<std::string>("cmd_vel_topic", "cmd_vel");
    this->declare_parameter<std::string>("left_wheel_topic", "left_wheel_velocity");
    this->declare_parameter<std::string>("right_wheel_topic", "right_wheel_velocity");

    // ── 读取参数 ─────────────────────────────────
    this->get_parameter("wheelbase", wheelbase_);
    this->get_parameter("max_linear_vel", max_linear_vel_);
    this->get_parameter("max_angular_vel", max_angular_vel_);

    std::string cmd_vel_topic, left_wheel_topic, right_wheel_topic;
    this->get_parameter("cmd_vel_topic", cmd_vel_topic);
    this->get_parameter("left_wheel_topic", left_wheel_topic);
    this->get_parameter("right_wheel_topic", right_wheel_topic);

    // ── 订阅者（cmd_vel 必须 RELIABLE — 控制命令不能丢）──
    cmd_vel_sub_ = this->create_subscription<geometry_msgs::msg::Twist>(
      cmd_vel_topic, QoS(10).reliable(),
      std::bind(&DiffDriveController::cmd_vel_callback, this, std::placeholders::_1));

    // ── 发布者 ───────────────────────────────────
    // QoS: RELIABLE — 控制命令不能丢包
    left_wheel_pub_ = this->create_publisher<std_msgs::msg::Float64>(
      left_wheel_topic, QoS(10).reliable());
    right_wheel_pub_ = this->create_publisher<std_msgs::msg::Float64>(
      right_wheel_topic, QoS(10).reliable());

    RCLCPP_INFO(this->get_logger(),
      "DiffDriveController started. wheelbase=%.2fm, max_v=%.2fm/s, max_ω=%.2f rad/s",
      wheelbase_, max_linear_vel_, max_angular_vel_);
    RCLCPP_INFO(this->get_logger(), "Subscribing to: %s", cmd_vel_topic.c_str());
    RCLCPP_INFO(this->get_logger(), "Publishing to: %s, %s",
                left_wheel_topic.c_str(), right_wheel_topic.c_str());
  }

private:
  /**
   * cmd_vel 回调 — 执行差速运动学转换
   */
  void cmd_vel_callback(const geometry_msgs::msg::Twist::SharedPtr cmd) {
    const double v = cmd->linear.x;   // 线速度 (m/s)
    const double w = cmd->angular.z;  // 角速度 (rad/s)

    // 限幅
    double v_clamped = std::max(-max_linear_vel_, std::min(max_linear_vel_, v));
    double w_clamped = std::max(-max_angular_vel_, std::min(max_angular_vel_, w));

    // 差速运动学
    // v_l = v - ω × (W/2)
    // v_r = v + ω × (W/2)
    const double half_wheelbase = wheelbase_ / 2.0;
    double v_left  = v_clamped - w_clamped * half_wheelbase;
    double v_right = v_clamped + w_clamped * half_wheelbase;

    // ── 发布左右轮速度 ───────────────────────────
    auto left_msg = std_msgs::msg::Float64();
    left_msg.data = v_left;
    left_wheel_pub_->publish(left_msg);

    auto right_msg = std_msgs::msg::Float64();
    right_msg.data = v_right;
    right_wheel_pub_->publish(right_msg);

    // 节流日志（每秒最多1次）
    RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 1000,
      "cmd: v=%.2f ω=%.2f → wheels: left=%.2f right=%.2f",
      v_clamped, w_clamped, v_left, v_right);
  }

  // ── 成员变量 ────────────────────────────────────────
  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_vel_sub_;
  rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr left_wheel_pub_;
  rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr right_wheel_pub_;

  double wheelbase_;       // 轮距 (m)
  double max_linear_vel_;  // 最大线速度 (m/s)
  double max_angular_vel_; // 最大角速度 (rad/s)
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);

  auto node = std::make_shared<DiffDriveController>();

  // 多线程 executor（处理 cmd_vel 回调 + 日志）
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();

  rclcpp::shutdown();
  return 0;
}
