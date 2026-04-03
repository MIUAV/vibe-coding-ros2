/**
 * diff_drive_controller — 差速驱动轮式机器人控制器
 *
 * 功能: 接收 geometry_msgs/Twist (cmd_vel) → 发布左右轮速
 *
 * 对应规范 (ANTI_PATTERNS.md):
 *   ✅ SharedPtr（禁止裸指针）
 *   ✅ rclcpp::init() / rclcpp::shutdown()
 *   ✅ RCLCPP_INFO（不用 printf）
 *   ✅ QoS: cmd_vel 用 reliable
 *   ✅ MultiThreadedExecutor 时 Mutex 保护共享数据
 *
 * 差速驱动数学:
 *   v_l = (2*v - ω*W) / 2     (左轮速)
 *   v_r = (2*v + ω*W) / 2     (右轮速)
 *   其中 v=线速度, ω=角速度, W=轮距
 */

#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <tf2_ros/transform_broadcaster.h>
#include <mutex>

namespace
{
  constexpr auto kNodeName   = "diff_drive_controller";
  constexpr auto kWheelBase  = 0.5;   // 轮距 (m)
  constexpr auto kMaxSpeed  = 1.0;    // 最大线速度 (m/s)
}

// 线程安全的共享数据
struct SharedState {
  double v_l = 0.0, v_r = 0.0;
  double x = 0.0, y = 0.0, theta = 0.0;
  std::mutex mtx;
};

class DiffDriveController : public rclcpp::Node
{
public:
  DiffDriveController()
  : Node(kNodeName)
  {
    // ── 参数声明 ──────────────────────────────
    this->declare_parameter("wheel_base", kWheelBase);
    this->declare_parameter("max_speed", kMaxSpeed);

    double wheel_base = kWheelBase;
    this->get_parameter("wheel_base", wheel_base);

    // ── cmd_vel 订阅 ─────────────────────────
    // QoS: reliable（控制命令必须到达）
    rclcpp::QoS qos_cmd(1);
    qos_cmd.reliable();

    cmd_sub_ = this->create_subscription<geometry_msgs::msg::Twist>(
      "/cmd_vel", qos_cmd,
      [this, wheel_base](const geometry_msgs::msg::Twist::SharedPtr msg) {
        this->cmd_callback(msg, wheel_base);
      }
    );

    // ── 左右轮速发布 ──────────────────────────
    // 这里模拟发布（实际机器人会通过 CAN 总线发到电机驱动器）
    wheel_l_pub_ = this->create_publisher<geometry_msgs::msg::Float32>("/wheel_l_speed", 10);
    wheel_r_pub_ = this->create_publisher<geometry_msgs::msg::Float32>("/wheel_r_speed", 10);

    // ── 里程计发布 ──────────────────────────
    odom_pub_ = this->create_publisher<nav_msgs::msg::Odometry>("/odom", 10);

    // ── TF 广播 ──────────────────────────────
    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    // ── 里程计定时器 ──────────────────────────
    timer_ = this->create_wall_timer(
      std::chrono::milliseconds(50),  // 20Hz
      [this]() { this->publish_odom(); }
    );

    RCLCPP_INFO(this->get_logger(), "Diff drive controller started (wheel_base=%.2fm)", wheel_base);
  }

private:
  void cmd_callback(const geometry_msgs::msg::Twist::SharedPtr msg, double wheel_base)
  {
    // 差速驱动逆运动学
    // v_l = v - ω * W/2
    // v_r = v + ω * W/2
    double v = std::max(-kMaxSpeed, std::min(kMaxSpeed, static_cast<double>(msg->linear.x)));
    double w = static_cast<double>(msg->angular.z);

    double v_l = v - w * wheel_base / 2.0;
    double v_r = v + w * wheel_base / 2.0;

    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      state_.v_l = v_l;
      state_.v_r = v_r;
    }

    // 发布轮速
    geometry_msgs::msg::Float32 wl_msg, wr_msg;
    wl_msg.data = v_l;
    wr_msg.data = v_r;
    wheel_l_pub_->publish(wl_msg);
    wheel_r_pub_->publish(wr_msg);

    RCLCPP_INFO_ONCE(this->get_logger(), "cmd: v=%.2f, ω=%.2f → wl=%.2f, wr=%.2f",
                     v, w, v_l, v_r);
  }

  void publish_odom()
  {
    nav_msgs::msg::Odometry odom;
    odom.header.stamp = this->get_clock()->now();
    odom.header.frame_id = "odom";
    odom.child_frame_id = "base_link";

    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      odom.pose.pose.position.x = state_.x;
      odom.pose.pose.position.y = state_.y;
      // 偏航角转四元数（简化版）
      odom.pose.pose.orientation.z = std::sin(state_.theta / 2);
      odom.pose.pose.orientation.w = std::cos(state_.theta / 2);
      odom.twist.twist.linear.x = state_.v_l;   // 简化：用左轮速当线速度
      odom.twist.twist.angular.z = state_.v_r - state_.v_l;  // 简化的角速度
    }

    odom_pub_->publish(odom);

    // TF: odom → base_link
    geometry_msgs::msg::TransformStamped t;
    t.header.stamp = this->get_clock()->now();
    t.header.frame_id = "odom";
    t.child_frame_id = "base_link";
    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      t.transform.translation.x = state_.x;
      t.transform.translation.y = state_.y;
      t.transform.rotation.z = std::sin(state_.theta / 2);
      t.transform.rotation.w = std::cos(state_.theta / 2);
    }
    tf_broadcaster_->sendTransform(t);
  }

  SharedState state_;

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_sub_;
  rclcpp::Publisher<geometry_msgs::msg::Float32>::SharedPtr wheel_l_pub_;
  rclcpp::Publisher<geometry_msgs::msg::Float32>::SharedPtr wheel_r_pub_;
  rclcpp::Publisher<nav_msgs::msg::Odometry>::SharedPtr odom_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
  std::unique_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);

  // 多线程：cmd_callback 和 publish_odom 可能并发执行
  auto node = std::make_shared<DiffDriveController>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();

  rclcpp::shutdown();
  return 0;
}
