// diff_drive_controller - 差速驱动控制器
// 功能: /cmd_vel -> 左右轮速 + 里程计 + TF
// 规范: SharedPtr, rclcpp::init+shutdown, Mutex, QoS reliable

#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/float32.hpp>
#include <tf2_ros/transform_broadcaster.h>
#include <mutex>

namespace {
  constexpr auto kNodeName   = "diff_drive_controller";
  constexpr double kWheelBase = 0.5;   // m
  constexpr double kMaxSpeed  = 1.0;   // m/s
}

struct SharedState {
  double v_l = 0.0, v_r = 0.0;
  double x = 0.0, y = 0.0, theta = 0.0;
  std::mutex mtx;
};

class DiffDriveController : public rclcpp::Node {
public:
  DiffDriveController() : Node(kNodeName) {
    double wheel_base = kWheelBase;
    this->declare_parameter("wheel_base", wheel_base);
    this->declare_parameter("max_speed",  kMaxSpeed);
    this->get_parameter("wheel_base", wheel_base);

    // QoS: reliable (控制命令不能丢)
    rclcpp::QoS qos_cmd(1);
    qos_cmd.reliable();
    cmd_sub_ = this->create_subscription<geometry_msgs::msg::Twist>(
      "/cmd_vel", qos_cmd,
      [this, wheel_base](const geometry_msgs::msg::Twist::SharedPtr msg) {
        this->cmd_callback(msg, wheel_base);
      });

    wheel_l_pub_ = this->create_publisher<geometry_msgs::msg::Float32>("/wheel_l_speed", 10);
    wheel_r_pub_ = this->create_publisher<geometry_msgs::msg::Float32>("/wheel_r_speed", 10);
    odom_pub_    = this->create_publisher<nav_msgs::msg::Odometry>("/odom", 10);
    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);
    timer_ = this->create_wall_timer(std::chrono::milliseconds(50),
      [this]() { this->publish_odom(); });

    RCLCPP_INFO(this->get_logger(), "Diff drive started (wheel_base=%.2fm)", wheel_base);
  }

private:
  void cmd_callback(const geometry_msgs::msg::Twist::SharedPtr msg, double wheel_base) {
    double v = std::max(-kMaxSpeed, std::min(kMaxSpeed, static_cast<double>(msg->linear.x)));
    double w = static_cast<double>(msg->angular.z);
    double v_l = v - w * wheel_base / 2.0;
    double v_r = v + w * wheel_base / 2.0;
    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      state_.v_l = v_l; state_.v_r = v_r;
    }
    geometry_msgs::msg::Float32 wl, wr;
    wl.data = v_l; wr.data = v_r;
    wheel_l_pub_->publish(wl);
    wheel_r_pub_->publish(wr);
  }

  void publish_odom() {
    nav_msgs::msg::Odometry odom;
    odom.header.stamp = this->get_clock()->now();
    odom.header.frame_id = "odom";
    odom.child_frame_id = "base_link";
    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      odom.pose.pose.position.x = state_.x;
      odom.pose.pose.position.y = state_.y;
      odom.pose.pose.orientation.z = std::sin(state_.theta / 2.0);
      odom.pose.pose.orientation.w = std::cos(state_.theta / 2.0);
      odom.twist.twist.linear.x = state_.v_l;
      odom.twist.twist.angular.z = state_.v_r - state_.v_l;
    }
    odom_pub_->publish(odom);

    geometry_msgs::msg::TransformStamped t;
    t.header.stamp = this->get_clock()->now();
    t.header.frame_id = "odom";
    t.child_frame_id = "base_link";
    {
      std::lock_guard<std::mutex> lock(state_.mtx);
      t.transform.translation.x = state_.x;
      t.transform.translation.y = state_.y;
      t.transform.rotation.z = std::sin(state_.theta / 2.0);
      t.transform.rotation.w = std::cos(state_.theta / 2.0);
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

int main(int argc, char * argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<DiffDriveController>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
