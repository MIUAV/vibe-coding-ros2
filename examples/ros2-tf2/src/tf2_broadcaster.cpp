// tf2_broadcaster.cpp
// TF2 坐标变换广播器 — 发布静态和动态坐标系变换
//
// TF2 树:
//   world → base_link → laser_frame
//                  ↘ camera_link
//
// 使用:
//   ros2 run ros2_tf2 tf2_broadcaster
//   ros2 run tf2_ros view_frames        # 可视化 TF 树
//   ros2 topic echo /tf_static          # 查看静态变换

#include <memory>
#include <string>
#include <chrono>
#include <cmath>

#include <rclcpp/rclcpp.hpp>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Vector3.h>
#include <tf2_ros/transform_broadcaster.h>
#include <tf2_ros/static_transform_broadcaster.h>
#include <geometry_msgs/msg/transform_stamped.hpp>

using namespace std::chrono_literals;

class TF2Broadcaster : public rclcpp::Node {
public:
  TF2Broadcaster()
  : Node("tf2_broadcaster"), yaw_angle_(0.0)
  {
    // ── 动态 Transform Broadcaster（随时间变化的坐标系）──────────
    dynamic_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    // ── 静态 Transform Broadcaster（固定的坐标系关系）────────────
    static_broadcaster_ = std::make_unique<tf2_ros::StaticTransformBroadcaster>(*this);

    // ── 发布静态变换（只发布一次）──────────────────────────────
    publish_static_transforms();

    // ── 定时器：发布动态变换（base_link 相对于 world）────────
    timer_ = this->create_wall_timer(
      50ms, std::bind(&TF2Broadcaster::timer_callback, this));

    RCLCPP_INFO(this->get_logger(), "TF2 Broadcaster started");
  }

private:
  /**
   * 发布静态变换（只调用一次）
   */
  void publish_static_transforms()
  {
    geometry_msgs::msg::TransformStamped t;

    // ── laser_frame → base_link ─────────────────────────────
    // 激光雷达通常在机器人顶部前方
    t = geometry_msgs::msg::TransformStamped();
    t.header.stamp = this->get_clock()->now();
    t.header.frame_id = "base_link";
    t.child_frame_id = "laser_frame";
    t.transform.translation.x = 0.0;   // 位于 base_link 前方 0.1m
    t.transform.translation.y = 0.0;
    t.transform.translation.z = 0.2;   // 位于 base_link 上方 0.2m
    t.transform.rotation = quaternion_from_rpy(0, 0, 0);  // 无旋转

    // ── camera_link → base_link ───────────────────────────
    geometry_msgs::msg::TransformStamped t2 = t;
    t2.child_frame_id = "camera_link";
    t2.transform.translation.x = 0.1;
    t2.transform.translation.y = -0.15;  // 左侧
    t2.transform.translation.z = 0.1;
    t2.transform.rotation = quaternion_from_rpy(0, 0, 0);

    // 一次性发布静态变换
    std::vector<geometry_msgs::msg::TransformStamped> static_transforms = {t, t2};
    static_broadcaster_->sendTransform(static_transforms);

    RCLCPP_INFO(this->get_logger(), "Published static transforms: base_link→laser_frame, base_link→camera_link");
  }

  /**
   * 定时发布动态变换（base_link 在 world 中移动）
   */
  void timer_callback()
  {
    // 模拟机器人绕圈运动
    const double dt = 0.05;  // 50ms
    yaw_angle_ += dt * 0.5;  // 角速度 0.5 rad/s

    const double radius = 1.0;  // 圆圈半径 1m
    const double x = radius * std::cos(yaw_angle_);
    const double y = radius * std::sin(yaw_angle_);
    const double z = 0.0;
    const double yaw = yaw_angle_;

    geometry_msgs::msg::TransformStamped t;
    t.header.stamp = this->get_clock()->now();
    t.header.frame_id = "world";       // 父坐标系
    t.child_frame_id = "base_link";  // 子坐标系
    t.transform.translation.x = x;
    t.transform.translation.y = y;
    t.transform.translation.z = z;
    t.transform.rotation = quaternion_from_rpy(0, 0, yaw);

    // 发布动态变换
    dynamic_broadcaster_->sendTransform(t);
  }

  /**
   * 从 RPY (Roll, Pitch, Yaw) 创建四元数
   */
  geometry_msgs::msg::Quaternion quaternion_from_rpy(double roll, double pitch, double yaw)
  {
    tf2::Quaternion q;
    q.setRPY(roll, pitch, yaw);
    geometry_msgs::msg::Quaternion q_msg;
    q_msg.x = q.x();
    q_msg.y = q.y();
    q_msg.z = q.z();
    q_msg.w = q.w();
    return q_msg;
  }

  std::unique_ptr<tf2_ros::TransformBroadcaster> dynamic_broadcaster_;
  std::unique_ptr<tf2_ros::StaticTransformBroadcaster> static_broadcaster_;
  rclcpp::TimerBase::SharedPtr timer_;
  double yaw_angle_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TF2Broadcaster>());
  rclcpp::shutdown();
  return 0;
}
