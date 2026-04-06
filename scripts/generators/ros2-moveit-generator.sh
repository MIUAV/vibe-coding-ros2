#!/bin/bash
# ros2-moveit-generator.sh — MoveIt2 运动规划节点生成器
# 用法: bash ros2-moveit-generator.sh <pkg_name> [config_level]
# config_level: move_group | cartesian | pick_place | mobile_manipulator
#
# 示例: bash ros2-moveit-generator.sh my_manipulator_pkg pick_place

PKG_NAME="${1:-}"
CONFIG_LEVEL="${2:-move_group}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [配置级别]"
    echo "  move_group           — MoveGroup 节点（最简配置）"
    echo "  cartesian            —笛卡尔路径规划（linear path）"
    echo "  pick_place           — 抓取放置任务（GraspPlanner）"
    echo "  mobile_manipulator    — 移动机械臂（arm+base）"
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
  <description>MoveIt2 motion planning node</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>moveit_ros_planning_interface</depend>
  <depend>moveit_ros_manipulation</depend>
  <depend>moveit_ros_move_group</depend>
  <depend>moveit_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>shape_msgs</depend>
  <depend>std_msgs</depend>
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
find_package(moveit_ros_planning_interface REQUIRED)
find_package(moveit_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/moveit_node.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp moveit_ros_planning_interface moveit_msgs geometry_msgs
)

ament_export_dependencies(rclcpp)
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

# ── C++ MoveIt2 节点 ───────────────────────────────────────
if [[ "$CONFIG_LEVEL" == "move_group" ]]; then

cat > "$PKG_NAME/src/moveit_node.cpp" <<'CPPEOF'
// move_group — MoveIt2 MoveGroup 接口节点
// 最简 MoveGroup 配置：加载 SRDF + 发送规划请求

#include <memory>
#include <string>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <moveit/move_group_interface/move_group_interface.h>
#include <geometry_msgs/msg/pose.hpp>

class MoveGroupNode : public rclcpp::Node
{
public:
  MoveGroupNode()
  : Node("move_group_node")
  {
    this->declare_parameter("group_name", "manipulator");
    this->declare_parameter("robot_description_topic", "robot_description");
    this->declare_parameter("planning_time", 5.0);
    this->declare_parameter("max_velocity_scaling_factor", 0.1);
    this->declare_parameter("max_acceleration_scaling_factor", 0.1);

    this->get_parameter("group_name", group_name_);

    RCLCPP_INFO(this->get_logger(), "MoveGroupNode initialized for group: %s",
      group_name_.c_str());

    // 创建 MoveGroup 接口
    move_group_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), group_name_);

    // 设置规划参数
    move_group_->setPlanningTime(5.0);
    move_group_->setMaxVelocityScalingFactor(0.1);
    move_group_->setMaxAccelerationScalingFactor(0.1);

    // 规划结果发布者
    plan_result_pub_ = this->create_publisher<moveit_msgs::msg::MotionPlanResponse>(
      "/move_group/plan_result", 10);

    RCLCPP_INFO(this->get_logger(), "MoveGroup ready");
  }

  // ── 关节空间规划 ─────────────────────────────────────
  bool plan_joint_target(const std::vector<double>& joint_positions)
  {
    move_group_->setJointValueTarget(joint_positions);
    auto plan_result = move_group_->plan(moveit_msgs::msg::MotionPlanResponse());
    if (plan_result) {
      RCLCPP_INFO(this->get_logger(), "Joint plan SUCCESS");
      return true;
    }
    RCLCPP_ERROR(this->get_logger(), "Joint plan FAILED");
    return false;
  }

  // ── 笛卡尔空间规划 ───────────────────────────────────
  bool plan_pose_target(const geometry_msgs::msg::Pose& target_pose)
  {
    move_group_->setPoseTarget(target_pose);
    auto plan_result = move_group_->plan(moveit_msgs::msg::MotionPlanResponse());
    if (plan_result) {
      RCLCPP_INFO(this->get_logger(), "Pose plan SUCCESS");
      return true;
    }
    RCLCPP_ERROR(this->get_logger(), "Pose plan FAILED");
    return false;
  }

  // ── 笛卡尔线性路径（直线路径）────────────────────────
  bool plan_cartesian_path(const std::vector<geometry_msgs::msg::Pose>& waypoints)
  {
    moveit_msgs::msg::RobotTrajectory trajectory;
    double fraction = move_group_->computeCartesianPath(
      waypoints, 0.01, 0.0, trajectory);

    RCLCPP_INFO(this->get_logger(), "Cartesian path: %.2f%% achieved", fraction * 100.0);
    return fraction > 0.9;
  }

  // ── 执行规划结果 ──────────────────────────────────────
  void execute_plan()
  {
    move_group_->execute(*move_group_->getCurrentPlan());
    RCLCPP_INFO(this->get_logger(), "Plan executed");
  }

private:
  std::string group_name_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_;
  rclcpp::Publisher<moveit_msgs::msg::MotionPlanResponse>::SharedPtr plan_result_pub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<MoveGroupNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

elif [[ "$CONFIG_LEVEL" == "cartesian" ]]; then

cat > "$PKG_NAME/src/moveit_node.cpp" <<'CPPEOF'
// cartesian — MoveIt2 笛卡尔路径规划节点
// 支持 linear path（直线路径）和姿态路径规划

#include <memory>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <moveit/move_group_interface/move_group_interface.h>
#include <geometry_msgs/msg/pose.hpp>

class CartesianPlannerNode : public rclcpp::Node
{
public:
  CartesianPlannerNode()
  : Node("cartesian_planner_node")
  {
    this->declare_parameter("group_name", "manipulator");
    this->declare_parameter("eef_name", "gripper");
    this->declare_parameter("planning_time", 10.0);

    this->get_parameter("group_name", group_name_);
    this->get_parameter("eef_name", eef_name_);

    move_group_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), group_name_);

    // 笛卡尔路径服务
    cartesian_service_ = this->create_service<moveit_msgs::srv::GetCartesianPath>(
      "/compute_cartesian_path",
      [this](const std::shared_ptr<moveit_msgs::srv::GetCartesianPath::Request> req,
             std::shared_ptr<moveit_msgs::srv::GetCartesianPath::Response> res) {
        this->compute_cartesian_path(req, res);
      });

    RCLCPP_INFO(this->get_logger(), "CartesianPlanner ready (group=%s, eef=%s)",
      group_name_.c_str(), eef_name_.c_str());
  }

private:
  void compute_cartesian_path(
    const std::shared_ptr<moveit_msgs::srv::GetCartesianPath::Request> req,
    std::shared_ptr<moveit_msgs::srv::GetCartesianPath::Response> res)
  {
    geometry_msgs::msg::Pose start_pose = req->start_state.joint_state.position.empty()
      ? *move_group_->getCurrentPose().posePtr
      : req->start_state.joint_state.position[0]; // simplified

    std::vector<geometry_msgs::msg::Pose> waypoints;
    for (const auto& pose_stamped : req->waypoints) {
      waypoints.push_back(pose_stamped.pose);
    }

    moveit_msgs::msg::RobotTrajectory trajectory;
    double fraction = move_group_->computeCartesianPath(
      waypoints,
      req->max_step,
      req->jump_threshold,
      trajectory,
      req->avoid_collisions);

    res->solution.fraction = fraction;
    res->solution.trajectory = trajectory;
    res->solver_name = "MoveIt Cartesians";

    RCLCPP_INFO(this->get_logger(), "Cartesian path: %.2f%%", fraction * 100.0);
  }

  std::string group_name_;
  std::string eef_name_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_;
  rclcpp::Service<moveit_msgs::srv::GetCartesianPath>::SharedPtr cartesian_service_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<CartesianPlannerNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

elif [[ "$CONFIG_LEVEL" == "pick_place" ]]; then

cat > "$PKG_NAME/src/moveit_node.cpp" <<'CPPEOF'
// pick_place — MoveIt2 抓取放置任务节点
// 实现 PickPlan + PlacePlan，包含 grasp 生成和碰撞检测

#include <memory>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <moveit/move_group_interface/move_group_interface.h>
#include <moveit/planning_scene_interface/planning_scene_interface.h>
#include <moveit_msgs/msg/grasp.hpp>
#include <moveit_msgs/srv/pick_place.hpp>

class PickPlaceNode : public rclcpp::Node
{
public:
  PickPlaceNode()
  : Node("pick_place_node")
  {
    this->declare_parameter("arm_group", "manipulator");
    this->declare_parameter("gripper_group", "gripper");
    this->declare_parameter("world_frame", "world");
    this->declare_parameter("approach_height", 0.2);

    this->get_parameter("arm_group", arm_group_);
    this->get_parameter("gripper_group", gripper_group_);

    move_group_arm_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), arm_group_);
    move_group_gripper_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), gripper_group_);

    planning_scene_interface_ = std::make_shared<
      moveit::planning_interface::PlanningSceneInterface>();

    // Pick 服务
    pick_service_ = this->create_service<moveit_msgs::srv::PickPlace>(
      "/pick",
      [this](const auto& req, auto& res) { this->pick(req, res); });

    // Place 服务
    place_service_ = this->create_service<moveit_msgs::srv::PickPlace>(
      "/place",
      [this](const auto& req, auto& res) { this->place(req, res); });

    RCLCPP_INFO(this->get_logger(), "PickPlace node ready");
  }

private:
  // ── 生成 grasp 姿态 ──────────────────────────────────
  moveit_msgs::msg::Grasp generate_grasp(const geometry_msgs::msg::Pose& object_pose)
  {
    moveit_msgs::msg::Grasp grasp;
    grasp.grasp_pose.header.frame_id = world_frame_;
    grasp.grasp_pose.pose = object_pose;

    // pre-grasp：抬高 20cm
    grasp.pre_grasp_poses.push_back(object_pose);
    grasp.pre_grasp_poses[0].position.z += 0.2;

    // grasp：略微低于物体中心
    grasp.grasp_pose.pose.position.z -= 0.02;

    grasp.max_contact_force = 20.0;
    grasp.allowed_touch_objects.push_back("*");

    return grasp;
  }

  // ── Pick 任务 ────────────────────────────────────────
  void pick(const std::shared_ptr<moveit_msgs::srv::PickPlace::Request> req,
            const std::shared_ptr<moveit_msgs::srv::PickPlace::Response>& res)
  {
    RCLCPP_INFO(this->get_logger(), "Executing PICK task...");

    // 获取目标物体位置
    auto object_pose = req->target_name.empty()
      ? geometry_msgs::msg::pose()  // placeholder
      : req->target_name[0];         // simplified

    moveit_msgs::msg::Grasp grasp = generate_grasp(object_pose);

    // 设置支持表面（避免与桌面碰撞）
    grasp.grasp_pose.pose.position.z += 0.02;

    std::vector<moveit_msgs::msg::Grasp> grasps;
    grasps.push_back(grasp);

    move_group_arm_->setSupportSurfaceName("table_surface");

    // 执行 pick
    moveit::planning_interface::MoveGroupInterface::Plan plan;
    bool success = (move_group_arm_->plan(plan) == moveit_msgs::msg::MoveItErrorCodes::SUCCESS);

    if (success) {
      move_group_arm_->execute(plan);
      RCLCPP_INFO(this->get_logger(), "PICK SUCCESS");
      res->error_code.val = moveit_msgs::msg::MoveItErrorCodes::SUCCESS;
    } else {
      RCLCPP_ERROR(this->get_logger(), "PICK FAILED");
      res->error_code.val = moveit_msgs::msg::MoveItErrorCodes::PLANNING_FAILED;
    }
  }

  // ── Place 任务 ────────────────────────────────────────
  void place(const std::shared_ptr<moveit_msgs::srv::PickPlace::Request> req,
             const std::shared_ptr<moveit_msgs::srv::PickPlace::Response>& res)
  {
    RCLCPP_INFO(this->get_logger(), "Executing PLACE task...");

    geometry_msgs::msg::Pose place_pose;
    place_pose.position.x = 0.5;
    place_pose.position.y = 0.0;
    place_pose.position.z = 0.8;

    moveit_msgs::msg::PlaceLocation place_location;
    place_location.place_pose = place_pose;

    std::vector<moveit_msgs::msg::PlaceLocation> locations;
    locations.push_back(place_location);

    move_group_arm_->setSupportSurfaceName("table_surface");
    move_group_arm_->place("object", locations);

    res->error_code.val = moveit_msgs::msg::MoveItErrorCodes::SUCCESS;
    RCLCPP_INFO(this->get_logger(), "PLACE task completed");
  }

  std::string arm_group_;
  std::string gripper_group_;
  std::string world_frame_ = "world";
  double approach_height_;

  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_arm_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_gripper_;
  std::shared_ptr<moveit::planning_interface::PlanningSceneInterface> planning_scene_interface_;
  rclcpp::Service<moveit_msgs::srv::PickPlace>::SharedPtr pick_service_;
  rclcpp::Service<moveit_msgs::srv::PickPlace>::SharedPtr place_service_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<PickPlaceNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

else  # mobile_manipulator

cat > "$PKG_NAME/src/moveit_node.cpp" <<'CPPEOF'
// mobile_manipulator — MoveIt2 移动机械臂节点
// 同时控制 arm（机械臂）+ base（移动平台）的协调规划

#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <moveit/move_group_interface/move_group_interface.h>
#include <geometry_msgs/msg/pose.hpp>

class MobileManipulatorNode : public rclcpp::Node
{
public:
  MobileManipulatorNode()
  : Node("mobile_manipulator_node")
  {
    this->declare_parameter("arm_group", "manipulator");
    this->declare_parameter("base_group", "mobile_base");
    this->declare_parameter("eef_name", "gripper");

    this->get_parameter("arm_group", arm_group_);
    this->get_parameter("base_group", base_group_);

    move_group_arm_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), arm_group_);
    move_group_base_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), base_group_);

    // 同时规划（arm + base）
    arm_base_group_ = std::make_shared<moveit::planning_interface::MoveGroupInterface>(
      shared_from_this(), "arm_with_base");

    RCLCPP_INFO(this->get_logger(), "MobileManipulator ready");
  }

  // ── 协调规划：基座移动到位置 + 臂架到达目标姿态 ──────
  bool plan_arm_and_base(const geometry_msgs::msg::Pose& arm_target,
                         const geometry_msgs::msg::Pose& base_target)
  {
    arm_base_group_->setPoseTarget(arm_target);

    // 设置基座目标位置（简化版：只控制 x,y,yaw）
    std::vector<double> base_joints(3, 0.0);
    base_joints[0] = base_target.position.x;
    base_joints[1] = base_target.position.y;
    base_joints[2] = base_target.position.z;  // yaw

    move_group_base_->setJointValueTarget(base_joints);

    auto plan_result = arm_base_group_->plan(moveit_msgs::msg::MotionPlanResponse());
    RCLCPP_INFO(this->get_logger(), "Arm+Base plan: %s",
      plan_result ? "SUCCESS" : "FAILED");
    return plan_result;
  }

  // ── 基座导航到位置（move_base 风格）──────────────────
  void move_base_to(const geometry_msgs::msg::Pose& goal_pose)
  {
    move_group_base_->setPoseTarget(goal_pose);
    move_group_base_->setMaxVelocityScalingFactor(0.3);  // 安全限速

    auto plan = move_group_base_->plan();
    if (plan) {
      move_group_base_->execute(plan);
      RCLCPP_INFO(this->get_logger(), "Base moved to (%.2f, %.2f)",
        goal_pose.position.x, goal_pose.position.y);
    }
  }

  std::string arm_group_;
  std::string base_group_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_arm_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> move_group_base_;
  std::shared_ptr<moveit::planning_interface::MoveGroupInterface> arm_base_group_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<MobileManipulatorNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF
fi

# ── MoveIt config (SRDF 模板) ──────────────────────────────
cat > "$PKG_NAME/config/robot.srdf" <<'SRDFEOF'
<?xml version="1.0"?>
<robot name="PKGNAME">
  <handles_ready>true</handles_ready>
  <group name="manipulator">
    <chain base_link="base_link" tip_link="tool0"/>
  </group>
  <group name="gripper">
    <joint name="gripper_joint"/>
  </group>
  <group_state name="home" group="manipulator">
    <joint name="joint1" value="0"/>
    <joint name="joint2" value="0"/>
    <joint name="joint3" value="0"/>
    <joint name="joint4" value="0"/>
    <joint name="joint5" value="0"/>
    <joint name="joint6" value="0"/>
  </group_state>
  <end_effector name="gripper" parent_group="gripper" parent_link="tool0"/>
</robot>
SRDFEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/config/robot.srdf"

# ── ros2_controllers yaml (MoveIt2 with ros2_controllers) ──
cat > "$PKG_NAME/config/moveit_controllers.yaml" <<'YAMLEOF'
moveit_controller_manager:
  moveit_simple_controller_manager:
    joint_trajectory_controllers:
      - name: arm_trajectory_controller
        type: JointTrajectoryController
        joints:
          - joint1
          - joint2
          - joint3
          - joint4
          - joint5
          - joint6
    default: arm_trajectory_controller
YAMLEOF

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/moveit.launch.py" <<'LAUNCHEOF'
"""MoveIt2 launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='moveit_ros_move_group',
            executable='move_group',
            name='move_group',
            output='screen',
            parameters=['src/PKGNAME/config/robot.srdf'],
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/moveit.launch.py"

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/moveit_node.cpp"
echo "  config/robot.srdf"
echo "  config/moveit_controllers.yaml"
echo "  launch/moveit.launch.py"
echo ""
echo "Config level: $CONFIG_LEVEL"
echo ""
echo "Next steps:"
echo "  1. ros2 run moveit setup_assistant (generate SRDF)"
echo "  2. colcon build --packages-select $PKG_NAME"
echo "  3. ros2 launch $PKG_NAME moveit.launch.py"
