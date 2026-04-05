// imu_sensor_node.cpp
// IMU 传感器节点 — 模拟/发布 sensor_msgs/Imu 数据
//
// QoS: BEST_EFFORT — IMU 是高频 sensor 数据，允许丢帧
// Topic: /imu/data (sensor_msgs/Imu)
// Frame: imu_link
//
// 真实 IMU 使用:
//   - Bosch BMI085/BMI270
//   - STMicroelectronics LSM6DSR
//   - xsens mtii

#include <memory>
#include <chrono>
#include <random>
#include <cmath>

#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/imu.hpp>
#include <geometry_msgs/msg/quaternion.hpp>
#include <tf2_ros/transform_broadcaster.h>
#include <geometry_msgs/msg/transform_stamped.hpp>

using namespace std::chrono_literals;

class IMUSensorNode : public rclcpp::Node {
public:
  IMUSensorNode()
  : Node("imu_sensor_node"),
    yaw_(0.0), pitch_(0.0), roll_(0.0),
    yaw_velocity_(0.0), pitch_velocity_(0.0), roll_velocity_(0.0),
    rng_(std::random_device{}()),
    noise_(0.0, 0.001)  // 高斯噪声: mean=0, std=0.001 rad
  {
    // ── QoS: BEST_EFFORT for IMU data ──────────────────────
    // IMU 数据 100-1000Hz，丢一帧没关系
    rclcpp::QoS imu_qos(100);
    imu_qos.best_effort()
         .durability_volatile();

    // ── 发布者 ───────────────────────────────────────────
    imu_pub_ = this->create_publisher<sensor_msgs::msg::Imu>("imu/data", imu_qos);

    // ── TF 广播器 ───────────────────────────────────────
    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    // ── 定时器: 200Hz ─────────────────────────────────────
    timer_ = this->create_wall_timer(5ms, std::bind(&IMUSensorNode::timer_callback, this));

    this->declare_parameter("frame_id", "imu_link");
    this->declare_parameter("imu_rate", 200.0);  // Hz
    this->declare_parameter("angular_velocity_noise", 0.001);
    this->declare_parameter("linear_acceleration_noise", 0.01);

    this->get_parameter("frame_id", frame_id_);

    RCLCPP_INFO(this->get_logger(), "IMU Sensor started. Publishing to: /imu/data (QoS: BEST_EFFORT)");
  }

private:
  void timer_callback()
  {
    const double dt = 0.005;  // 5ms = 200Hz
    auto now = this->get_clock()->now();

    // ── 更新角度（模拟小幅运动）─────────────────────────
    yaw_velocity_ = 0.1 + noise_(rng_) * 10;      // 0.1 rad/s ± 噪声
    pitch_velocity_ = 0.05 + noise_(rng_) * 5;
    roll_velocity_ = 0.02 + noise_(rng_) * 2;

    yaw_ += yaw_velocity_ * dt;
    pitch_ += pitch_velocity_ * dt;
    roll_ += roll_velocity_ * dt;

    // ── 构建 IMU 消息 ────────────────────────────────────
    sensor_msgs::msg::Imu imu_msg;
    imu_msg.header.stamp = now;
    imu_msg.header.frame_id = frame_id_;

    // 四元数（从 RPY）
    imu_msg.orientation = rpy_to_quaternion(roll_, pitch_, yaw_);

    // 角速度（IMU 陀螺仪）
    imu_msg.angular_velocity.x = roll_velocity_ + noise_(rng_) * 50;
    imu_msg.angular_velocity.y = pitch_velocity_ + noise_(rng_) * 50;
    imu_msg.angular_velocity.z = yaw_velocity_ + noise_(rng_) * 50;

    // 线加速度（IMU 加速度计，减去重力）
    imu_msg.linear_acceleration.x = noise_(rng_) * 10;
    imu_msg.linear_acceleration.y = noise_(rng_) * 10;
    imu_msg.linear_acceleration.z = -9.81 + noise_(rng_) * 5;  // 重力在 Z 轴

    // 协方差（简化）
    imu_msg.orientation_covariance[0] = -1;  // 方向不使用
    for (int i = 0; i < 9; i++) {
      if (i != 0) imu_msg.angular_velocity_covariance[i] = 0.0;
      imu_msg.linear_acceleration_covariance[i] = 0.0;
    }

    imu_pub_->publish(imu_msg);

    // ── 发布 TF ─────────────────────────────────────────
    geometry_msgs::msg::TransformStamped t;
    t.header.stamp = now;
    t.header.frame_id = "imu_base";  // 父 frame
    t.child_frame_id = frame_id_;
    t.transform.translation.x = 0;
    t.transform.translation.y = 0;
    t.transform.translation.z = 0;
    t.transform.rotation = imu_msg.orientation;
    tf_broadcaster_->sendTransform(t);
  }

  geometry_msgs::msg::Quaternion rpy_to_quaternion(double roll, double pitch, double yaw)
  {
    double cy = std::cos(yaw * 0.5);
    double sy = std::sin(yaw * 0.5);
    double cp = std::cos(pitch * 0.5);
    double sp = std::sin(pitch * 0.5);
    double cr = std::cos(roll * 0.5);
    double sr = std::sin(roll * 0.5);

    geometry_msgs::msg::Quaternion q;
    q.w = cr * cp * cy + sr * sp * sy;
    q.x = sr * cp * cy - cr * sp * sy;
    q.y = cr * sp * cy + sr * cp * sy;
    q.z = cr * cp * sy - sr * sp * cy;
    return q;
  }

  rclcpp::Publisher<sensor_msgs::msg::Imu>::SharedPtr imu_pub_;
  std::unique_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster_;
  rclcpp::TimerBase::SharedPtr timer_;

  double yaw_, pitch_, roll_;
  double yaw_velocity_, pitch_velocity_, roll_velocity_;
  std::mt19937 rng_;
  std::normal_distribution<double> noise_;
  std::string frame_id_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<IMUSensorNode>());
  rclcpp::shutdown();
  return 0;
}
