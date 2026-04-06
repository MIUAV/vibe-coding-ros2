#!/bin/bash
# ros2-control-node-generator.sh — ros2_control 硬件接口节点生成器
# 用法: bash ros2-control-node-generator.sh <pkg_name> [node_type]
# node_type: hardware_interface | joint_trajectory_controller | diff_drive
#
# 示例: bash ros2-control-node-generator.sh my_robot_control diff_drive

PKG_NAME="${1:-}"
NODE_TYPE="${2:-diff_drive}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [节点类型]"
    echo "  hardware_interface          — 通用硬件接口基类"
    echo "  diff_drive                  — 差速驱动控制器（JointTrajectoryController）"
    echo "  joint_trajectory_controller — 关节轨迹控制器"
    exit 1
fi

mkdir -p "$PKG_NAME/src" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>ros2_control hardware interface node</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>hardware_interface</depend>
  <depend>controller_interface</depend>
  <depend>ros2_controllers</depend>
  <depend>geometry_msgs</depend>
  <depend>nav2_msgs</depend>
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ── CMakeLists.txt ────────────────────────────────────────
cat > "$PKG_NAME/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(PKGNAME)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(hardware_interface REQUIRED)
find_package(controller_interface REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/diff_drive.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp rclcpp_lifecycle hardware_interface controller_interface geometry_msgs
)

ament_export_dependencies(rclcpp hardware_interface controller_interface)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION lib)
install(DIRECTORY launch config DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()
ament_package()
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/CMakeLists.txt"

# ── Diff Drive 控制器（完整实现）────────────────────────
if [[ "$NODE_TYPE" == "diff_drive" ]]; then

cat > "$PKG_NAME/src/diff_drive.cpp" <<'CPPEOF'
// DiffDrive — ros2_control 差速驱动控制器
// JointTrajectoryController 实现，支持自定义轨迹接口
// 符合 ros2_controllers/diff_drive_controller 规范

#include <vector>
#include <cmath>
#include <memory>
#include <string>

#include "hardware_interface/hardware_info.hpp"
#include "hardware_interface/system_interface.hpp"
#include "rclcpp/rclcpp.hpp"
#include "rclcpp_lifecycle/rclcpp_lifecycle.hpp"
#include "geometry_msgs/msg/twist.hpp"
#include "nav_msgs/msg/odometry.hpp"

using CallbackReturn = rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn;

class DiffDriveHardware : public hardware_interface::SystemInterface
{
public:
  // ── hardware_interface::SystemInterface 接口 ───────────

  CallbackReturn on_init(const hardware_interface::HardwareInfo& info) override
  {
    RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "Initializing DiffDrive hardware interface...");

    if (info.hardware_parameters["device"].empty()) {
      RCLCPP_ERROR(rclcpp::get_logger("DiffDrive"), "Device parameter not set");
      return CallbackReturn::ERROR;
    }

    device_ = info.hardware_parameters["device"];
    hardware_timeout_ms_ = std::stoi(info.hardware_parameters["timeout_ms"]);

    // 获取关节配置
    for (const auto& joint : info.joints) {
      if (joint.name == "left_wheel_joint") {
        RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "Found left wheel joint: %s",
          joint.name.c_str());
      } else if (joint.name == "right_wheel_joint") {
        RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "Found right wheel joint: %s",
          joint.name.c_str());
      }
    }

    // 初始化状态反馈
    hw_positions_.resize(info.joints.size(), 0.0);
    hw_velocities_.resize(info.joints.size(), 0.0);
    hw_commands_.resize(info.joints.size(), 0.0);

    RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "DiffDrive initialized for device: %s",
      device_.c_str());
    return CallbackReturn::SUCCESS;
  }

  std::vector<hardware_interface::StateInterface> export_state_interfaces() override
  {
    std::vector<hardware_interface::StateInterface> state_interfaces;
    for (size_t i = 0; i < info_.joints.size(); ++i) {
      state_interfaces.emplace_back(info_.joints[i].name, hardware_interface::HW_IF_POSITION,
        &hw_positions_[i]);
      state_interfaces.emplace_back(info_.joints[i].name, hardware_interface::HW_IF_VELOCITY,
        &hw_velocities_[i]);
    }
    return state_interfaces;
  }

  std::vector<hardware_interface::CommandInterface> export_command_interfaces() override
  {
    std::vector<hardware_interface::CommandInterface> command_interfaces;
    for (size_t i = 0; i < info_.joints.size(); ++i) {
      command_interfaces.emplace_back(info_.joints[i].name, hardware_interface::HW_IF_VELOCITY,
        &hw_commands_[i]);
    }
    return command_interfaces;
  }

  CallbackReturn on_activate(const rclcpp::Time&) override
  {
    RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "Activating DiffDrive hardware...");
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_deactivate(const rclcpp::Time&) override
  {
    RCLCPP_INFO(rclcpp::get_logger("DiffDrive"), "Deactivating DiffDrive hardware...");
    return CallbackReturn::SUCCESS;
  }

  hardware_interface::return_type read(const rclcpp::Time&, const rclcpp::Duration&) override
  {
    // TODO: 从实际硬件读取电机编码器数据
    // 示例：从 UART/CAN 总线读取左右轮速度
    // struct MotorFeedback { double left_pos, right_pos; };
    // auto feedback = read_motor_feedback(device_);
    // hw_positions_[0] = feedback.left_pos;
    // hw_positions_[1] = feedback.right_pos;
    return hardware_interface::return_type::OK;
  }

  hardware_interface::return_type write(const rclcpp::Time&, const rclcpp::Duration&) override
  {
    // TODO: 向实际硬件发送电机速度指令
    // 示例：发送 CAN 帧到左右轮电机驱动器
    // struct MotorCommand { double left_vel, right_vel; };
    // MotorCommand cmd = { hw_commands_[0], hw_commands_[1] };
    // send_motor_command(device_, cmd);
    return hardware_interface::return_type::OK;
  }

private:
  std::string device_;
  int hardware_timeout_ms_ = 100;
  std::vector<double> hw_positions_;
  std::vector<double> hw_velocities_;
  std::vector<double> hw_commands_;
};

// ── 控制器节点（Twist → Joint Commands）──────────────────
class DiffDriveControllerNode : public rclcpp_lifecycle::LifecycleNode
{
public:
  DiffDriveControllerNode()
  : LifecycleNode("diff_drive_controller")
  {
    this->declare_parameter("wheel_radius", 0.165);        // m
    this->declare_parameter("wheel_separation", 0.6);       // m
    this->declare_parameter("max_linear_vel", 1.0);         // m/s
    this->declare_parameter("max_angular_vel", 2.0);        // rad/s
  }

  CallbackReturn on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[DiffDrive] Configuring...");

    std::string left_joint, right_joint;
    this->get_parameter("left_wheel_joint", left_joint);
    this->get_parameter("right_wheel_joint", right_joint);

    // /cmd_vel 订阅
    cmd_vel_sub_ = this->create_subscription<geometry_msgs::msg::Twist>(
      "/cmd_vel", 10,
      std::bind(&DiffDriveControllerNode::cmd_vel_callback, this, std::placeholders::_1));

    // 关节命令发布（通过 joint_trajectory_controller 接口）
    left_cmd_pub_ = this->create_publisher<std_msgs::msg::Float64>(
      "/diff_drive_controller/commands/left_wheel", 10);
    right_cmd_pub_ = this->create_publisher<std_msgs::msg::Float64>(
      "/diff_drive_controller/commands/right_wheel", 10);

    RCLCPP_INFO(get_logger(), "[DiffDrive] Configured");
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[DiffDrive] Activating...");
    return CallbackReturn::SUCCESS;
  }

  CallbackReturn on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[DiffDrive] Deactivating...");
    return CallbackReturn::SUCCESS;
  }

private:
  void cmd_vel_callback(const geometry_msgs::msg::Twist::SharedPtr msg)
  {
    double wheel_radius, wheel_separation, max_lin, max_ang;
    this->get_parameter("wheel_radius", wheel_radius);
    this->get_parameter("wheel_separation", wheel_separation);
    this->get_parameter("max_linear_vel", max_lin);
    this->get_parameter("max_angular_vel", max_ang);

    // Twist → 差速轮速度转换
    double v = std::clamp(msg->linear.x, -max_lin, max_lin);
    double w = std::clamp(msg->angular.z, -max_ang, max_ang);

    double left_vel  = (2.0 * v - w * wheel_separation) / (2.0 * wheel_radius);
    double right_vel = (2.0 * v + w * wheel_separation) / (2.0 * wheel_radius);

    // 发布到 joint_trajectory_controller
    std_msgs::msg::Float64 left_cmd, right_cmd;
    left_cmd.data = left_vel;
    right_cmd.data = right_vel;
    left_cmd_pub_->publish(left_cmd);
    right_cmd_pub_->publish(right_cmd);

    RCLCPP_DEBUG(get_logger(), "cmd_vel: v=%.3f w=%.3f → left=%.3f right=%.3f",
      v, w, left_vel, right_vel);
  }

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_vel_sub_;
  rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr left_cmd_pub_;
  rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr right_cmd_pub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);

  // 方式1：使用 ros2_control 控制器管理器（真实机器人）
  // auto controller_node = std::make_shared<DiffDriveControllerNode>();

  // 方式2：独立测试用模拟节点（无 ros2_control_manager）
  auto sim_node = std::make_shared<DiffDriveControllerNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(sim_node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ── ros2_controllers yaml ──────────────────────────────────
cat > "$PKG_NAME/config/diff_drive_controllers.yaml" <<'YAMLEOF'
controller_manager:
  ros__parameters:
    update_rate: 50  # Hz

    diff_drive_controller:
      type: diff_drive_controller/DiffDriveController

    joint_state_broadcaster:
      type: joint_state_broadcaster/JointStateBroadcaster

diff_drive_controller:
  ros__parameters:
    left_wheel_joint: left_wheel_joint
    right_wheel_joint: right_wheel_joint
    wheel_radius: 0.165          # m
    wheel_separation: 0.6        # m (track width)
    wheel_radius_multiplier: 1.0
    cmd_vel_timeout: 0.5
    base_frame_id: base_link
    odom_frame_id: odom
    publish_rate: 50.0
    linear.x.max_velocity: 1.0   # m/s
    angular.z.max_velocity: 2.0  # rad/s
YAMLEOF

# ── ros2_control xacro ──────────────────────────────────────
cat > "$PKG_NAME/config/diff_drive.urdf.xacro" <<'XACROEOF'
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro">
  <!-- ros2_control 差速驱动小车硬件接口 -->
  <xacro:macro name="diff_drive_system" params="name">
    <ros2_control name="${name}" type="system">
      <hardware>
        <plugin>diff_drive_controllers/DiffDriveHardware</plugin>
        <param name="device">/dev/ttyUSB0</param>
        <param name="timeout_ms">100</param>
      </hardware>
      <joint name="left_wheel_joint">
        <command_interface namespace="velocity"/>
        <state_interface namespace="position"/>
        <state_interface namespace="velocity"/>
      </joint>
      <joint name="right_wheel_joint">
        <command_interface namespace="velocity"/>
        <state_interface namespace="position"/>
        <state_interface namespace="velocity"/>
      </joint>
    </ros2_control>
  </xacro:macro>
</robot>
XACROEOF

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/diff_drive.launch.py" <<'LAUNCHEOF'
"""ros2_control diff_drive launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='controller_manager',
            executable='ros2_control_node',
            parameters=[{'robot_description': ''}],
            output='screen',
        ),
        Node(
            package='diff_drive_controller',
            executable='diff_drive_controller',
            name='diff_drive_controller',
            output='screen',
        ),
    ])
LAUNCHEOF
sed -i "s/diff_drive_controller/${PKG_NAME}/g" "$PKG_NAME/launch/diff_drive.launch.py"

fi

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/diff_drive.cpp"
echo "  config/diff_drive_controllers.yaml"
echo "  config/diff_drive.urdf.xacro"
echo "  launch/diff_drive.launch.py"
echo ""
echo "Node type: $NODE_TYPE"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME"
echo "  2. rosdep install --from-paths . --ignore-src -r -y"
echo "  3. colcon build --packages-select $PKG_NAME"
echo "  4. ros2 control load_controller -s set diff_drive_controller"
