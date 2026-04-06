#!/bin/bash
# ros2-tf2-broadcaster.sh — TF2 广播节点生成器
# 用法: bash ros2-tf2-broadcaster.sh <pkg_name> <parent_frame> <child_frame>
# 示例: bash ros2-tf2-broadcaster.sh my_robot base_link laser_frame

PKG_NAME="${1:-}"
PARENT="${2:-base_link}"
CHILD="${3:-laser_frame}"
RATE="${4:-10.0}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <pkg名> <父坐标系> <子坐标系> [发布频率Hz]"
    echo "  例: $0 my_robot base_link laser_link 10"
    exit 1
fi

mkdir -p "$PKG_NAME/src"

cat > "$PKG_NAME/src/tf2_broadcaster_node.cpp" <<CPPEOF
// tf2_broadcaster — 广播静态/动态 TF 变换
// 用法:
//   ros2 run $PKG_NAME tf2_broadcaster
// 测试:
//   ros2 run tf2_bridge tf2_echo $PARENT $CHILD

#include <rclcpp/rclcpp.hpp>
#include <tf2_ros/transform_broadcaster.h>
#include <geometry_msgs/msg/transform_stamped.hpp>
#include <std_msgs/msg/string.hpp>
#include <tf2/LinearMath/Quaternion.h>
#include <tf2/LinearMath/Matrix3x3.h>

class TF2BroadcasterNode : public rclcpp::Node
{
public:
  TF2BroadcasterNode()
  : Node("tf2_broadcaster")
  {
    // ── TF2 广播器 ──────────────────────────────
    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    // ── 参数声明 ────────────────────────────────
    this->declare_parameter("parent_frame", "$PARENT");
    this->declare_parameter("child_frame", "$CHILD");
    this->declare_parameter("rate_hz", $RATE);

    // ── 从参数读取 ────────────────────────────
    this->get_parameter("parent_frame", parent_frame_);
    this->get_parameter("child_frame", child_frame_);

    double rate_hz;
    this->get_parameter("rate_hz", rate_hz);
    auto period = std::chrono::duration<double>(1.0 / rate_hz);

    // ── 发布者（可选，用于调试）────────────────
    debug_pub_ = this->create_publisher<std_msgs::msg::String>(
      "/tf2_debug", rclcpp::QoS(10).best_effort());

    // ── 定时器 ─────────────────────────────────
    timer_ = this->create_wall_timer(
      std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::duration<double>(period)),
      std::bind(&TF2BroadcasterNode::broadcast_callback, this));

    RCLCPP_INFO(this->get_logger(),
      "TF2 Broadcaster started: %s → %s @ %.1f Hz",
      parent_frame_.c_str(), child_frame_.c_str(), rate_hz);
  }

private:
  void broadcast_callback()
  {
    geometry_msgs::msg::TransformStamped t;

    // ── 标准头 ──────────────────────────────────
    t.header.stamp = this->now();
    t.header.frame_id = parent_frame_;
    t.child_frame_id = child_frame_;

    // ── 设置平移 ────────────────────────────────
    // TODO: 替换为实际传感器位姿（从 topic 订阅或参数读取）
    t.transform.translation.x = 0.0;
    t.transform.translation.y = 0.0;
    t.transform.translation.z = 0.0;

    // ── 设置旋转（四元数）───────────────────────
    // TODO: 替换为实际朝向
    // 示例: 绕 Z 轴旋转 45度
    tf2::Quaternion q;
    q.setRPY(0, 0, 0.785);  // roll, pitch, yaw (rad)
    t.transform.rotation.x = q.x();
    t.transform.rotation.y = q.y();
    t.transform.rotation.z = q.z();
    t.transform.rotation.w = q.w();

    // ── 发布 TF ────────────────────────────────
    tf_broadcaster_->sendTransform(t);

    // ── 发布调试信息 ───────────────────────────
    std_msgs::msg::String dbg;
    dbg.data = parent_frame_ + " → " + child_frame_ +
               " t=" + std::to_string(t.transform.translation.x) + "," +
               std::to_string(t.transform.translation.y) + "," +
               std::to_string(t.transform.translation.z);
    debug_pub_->publish(dbg);
  }

  std::unique_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster_;
  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr debug_pub_;
  std::string parent_frame_;
  std::string child_frame_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TF2BroadcasterNode>());
  rclcpp::shutdown();
  return 0;
}
CPPEOF

cat > "$PKG_NAME/package.xml" <<PKGEOF
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>$PKG_NAME</name>
  <version>0.1.0</version>
  <description>TF2 broadcaster: $PARENT → $CHILD</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>std_msgs</depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
PKGEOF

cat > "$PKG_NAME/CMakeLists.txt" <<CMAKEEOF
cmake_minimum_required(VERSION 3.16)
project($PKG_NAME)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

add_library(tf2_broadcaster SHARED
  src/tf2_broadcaster_node.cpp
)

ament_target_dependencies(tf2_broadcaster
  rclcpp tf2_ros tf2_msgs geometry_msgs std_msgs
)

ament_export_dependencies(rclcpp tf2_ros)
ament_export_include_directories(include)
ament_export_libraries(\${PROJECT_NAME})

install(TARGETS tf2_broadcaster
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib)

ament_package()
CMAKEEOF

echo "Generated: $PKG_NAME/src/tf2_broadcaster_node.cpp"
echo ""
echo "使用:"
echo "  colcon build --packages-select $PKG_NAME"
echo "  ros2 run $PKG_NAME tf2_broadcaster"
echo ""
echo "调试:"
echo "  ros2 run tf2_ros tf2_echo $PARENT $CHILD"
echo "  ros2 topic echo /tf2_debug"
echo ""
echo "参数:"
echo "  ros2 param list /tf2_broadcaster"
