#!/bin/bash
# ros2-nav2-node-generator.sh — Nav2 compatible 节点生成器
# 用法: bash ros2-nav2-node-generator.sh <pkg_name> [node_type]
# node_type: nav2_thin | nav2_full | controller | planner
#
# 示例: bash ros2-nav2-node-generator.sh my_nav2_pkg controller

PKG_NAME="${1:-}"
NODE_TYPE="${2:-nav2_thin}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [节点类型]"
    echo "  nav2_thin  — 最简 Nav2 兼容节点（订阅 map → 发布 costmap）"
    echo "  nav2_full   — 完整 Nav2 节点（含 lifecycle + param）"
    echo "  controller — 进度控制器（FollowPath action）"
    echo "  planner    — 全局路径规划器"
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
  <description>Nav2 compatible node</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>nav2_util</depend>
  <depend>nav2_costmap_2d</depend>
  <depend>nav2_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>
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
find_package(nav2_util REQUIRED)
find_package(nav2_costmap_2d REQUIRED)
find_package(nav2_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/nav2_node.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp rclcpp_lifecycle nav2_util nav2_costmap_2d nav2_msgs geometry_msgs tf2_ros
)

ament_export_dependencies(rclcpp nav2_util)
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

# ── C++ 节点代码 ──────────────────────────────────────────
if [[ "$NODE_TYPE" == "nav2_thin" ]]; then

cat > "$PKG_NAME/src/nav2_node.cpp" <<'CPPEOF'
// nav2_thin — 最简 Nav2 兼容节点
// 符合 Nav2 lifecycle 规范，可被 nav2_lifecycle_manager 管理

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <nav2_util/lifecycle_node_interface.hpp>
#include <nav2_costmap_2d/costmap_2d.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <tf2_ros/transform_listener.hpp>

using std::placeholders::_1;
using LifecycleNode = rclcpp_lifecycle::LifecycleNode;

class Nav2ThinNode : public LifecycleNode
{
public:
  Nav2ThinNode()
  : LifecycleNode("nav2_node")
  {
    // ── 声明 Nav2 标准参数 ─────────────────────────────
    this->declare_parameter("robot_base_frame", std::string("base_link"));
    this->declare_parameter("costmap_subscribe_topic", std::string("global_costmap/costmap"));
    this->declare_parameter("costmap_publish_topic", std::string("costmap"));

    RCLCPP_INFO(get_logger(), "Nav2ThinNode constructed");
  }

  // ── on_configure: 订阅 costmap，发布处理结果 ───────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2] Configuring...");

    std::string costmap_sub_topic, costmap_pub_topic;
    this->get_parameter("costmap_subscribe_topic", costmap_sub_topic);
    this->get_parameter("costmap_publish_topic", costmap_pub_topic);

    // QoS: transient_local 确保新订阅者收到最近数据
    costmap_sub_ = this->create_subscription<nav2_costmap_2d::msg::Costmap>(
      costmap_sub_topic,
      rclcpp::QoS(1).transient_local().reliable(),
      std::bind(&Nav2ThinNode::costmap_callback, this, _1));

    costmap_pub_ = this->create_publisher<nav2_costmap_2d::msg::Costmap>(
      costmap_pub_topic, 10);

    RCLCPP_INFO(get_logger(), "[Nav2] Configured — sub=%s pub=%s",
      costmap_sub_topic.c_str(), costmap_pub_topic.c_str());
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2] Activating...");
    costmap_pub_->on_activate();
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2] Deactivating...");
    costmap_pub_->on_deactivate();
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2] Cleaning up...");
    costmap_sub_.reset();
    costmap_pub_.reset();
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2] Shutting down...");
    return CallbackReturn::SUCCESS;
  }

private:
  void costmap_callback(nav2_costmap_2d::msg::Costmap::SharedPtr msg)
  {
    // TODO: 在这里处理 costmap 数据
    // 例如：障碍物检测、路径安全检查等
    RCLCPP_DEBUG(get_logger(), "Received costmap: %ux%u",
      msg->metadata.size_x, msg->metadata.size_y);
  }

  rclcpp::Subscription<nav2_costmap_2d::msg::Costmap>::SharedPtr costmap_sub_;
  rclcpp::Publisher<nav2_costmap_2d::msg::Costmap>::SharedPtr costmap_pub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Nav2ThinNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

elif [[ "$NODE_TYPE" == "controller" ]]; then

cat > "$PKG_NAME/src/nav2_node.cpp" <<'CPPEOF'
// controller — Nav2 进度控制器（FollowPath action）
// 实现 nav2_core::ControllerInterface，可被 nav2_controller_manager 加载

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <nav2_core/controller.hpp>
#include <nav2_msgs/action/follow_path.hpp>
#include <geometry_msgs/msg/twist.hpp>

using FollowPath = nav2_msgs::action::FollowPath;
using GoalHandle = rclcpp_action::ServerGoalHandle<FollowPath>;

class ProgressController : public rclcpp_lifecycle::LifecycleNode,
                          public nav2_core::Controller
{
public:
  ProgressController()
  : LifecycleNode("progress_controller")
  {
    // Nav2 控制器标准参数
    this->declare_parameter("max_speed", 0.5);
    this->declare_parameter("max_accel", 1.0);

    RCLCPP_INFO(get_logger(), "ProgressController constructed");
  }

  // ── nav2_core::Controller 接口 ──────────────────────────
  void configure(const rclcpp::SharedPtr<rclcpp::Node>& node,
                 const std::string& name,
                 const std::shared_ptr<tf2_ros::Buffer>&) override
  {
    node_ = node;
    name_ = name;
    RCLCPP_INFO(node_->get_logger(), "[Controller] Configuring: %s", name_.c_str());
  }

  void activate() override
  {
    RCLCPP_INFO(node_->get_logger(), "[Controller] Activating");
    cmd_pub_->on_activate();
  }

  void deactivate() override
  {
    RCLCPP_INFO(node_->get_logger(), "[Controller] Deactivating");
    cmd_pub_->on_deactivate();
  }

  void cleanup() override
  {
    RCLCPP_INFO(node_->get_logger(), "[Controller] Cleaning up");
    cmd_pub_.reset();
  }

  void shutdown() override
  {
    RCLCPP_INFO(node_->get_logger(), "[Controller] Shutdown");
  }

  geometry_msgs::msg::TwistStamped computeVelocityCommands(
    const geometry_msgs::msg::PoseStamped& pose,
    const geometry_msgs::msg::Twist& velocity)
  {
    // 最简进度控制器：输出最大速度
    double max_speed;
    node_->get_parameter("max_speed", max_speed);

    geometry_msgs::msg::TwistStamped cmd;
    cmd.header.stamp = node_->now();
    cmd.header.frame_id = "base_link";
    cmd.twist.linear.x = max_speed;
    cmd.twist.angular.z = 0.0;
    return cmd;
  }

private:
  rclcpp::Node::SharedPtr node_;
  std::string name_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<ProgressController>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

else  # nav2_full 或其他

cat > "$PKG_NAME/src/nav2_node.cpp" <<'CPPEOF'
// nav2_full — 完整 Nav2 节点（lifecycle + param + tf2）
// 包含完整的 Nav2 生命周期管理和参数更新

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <nav2_util/node_parameters.hpp>
#include <tf2_ros/transform_listener.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>

using LifecycleNode = rclcpp_lifecycle::LifecycleNode;

class Nav2FullNode : public LifecycleNode
{
public:
  Nav2FullNode()
  : LifecycleNode("nav2_full_node")
  {
    // Nav2 标准参数
    this->declare_parameter("enabled", true);
    this->declare_parameter("update_frequency", 10.0);
    this->declare_parameter("robot_base_frame", std::string("base_link"));
    this->declare_parameter("map_frame", std::string("map"));

    // 参数变更回调
    param_callback_ = this->add_on_set_parameters_callback(
      std::bind(&Nav2FullNode::on_param_change, this, std::placeholders::_1));

    RCLCPP_INFO(get_logger(), "Nav2FullNode constructed");
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2Full] Configuring...");

    // TF2 缓冲区和监听器
    tf_buffer_ = std::make_shared<tf2_ros::Buffer>(get_clock());
    tf_listener_ = std::make_shared<tf2_ros::TransformListener>(*tf_buffer_);

    // 代价地图订阅
    costmap_sub_ = this->create_subscription<nav2_costmap_2d::msg::Costmap>(
      "/costmap", rclcpp::QoS(1).transient_local().reliable(),
      [this](nav2_costmap_2d::msg::Costmap::SharedPtr msg) {
        RCLCPP_DEBUG(get_logger(), "Costmap received: %ux%u",
          msg->metadata.size_x, msg->metadata.size_y);
      });

    RCLCPP_INFO(get_logger(), "[Nav2Full] Configured");
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2Full] Activating...");
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2Full] Deactivating...");
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2Full] Cleaning up...");
    tf_listener_.reset();
    tf_buffer_.reset();
    costmap_sub_.reset();
    return CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "[Nav2Full] Shutting down...");
    return CallbackReturn::SUCCESS;
  }

private:
  rcl_interfaces::msg::SetParametersResult
  on_param_change(const std::vector<rclcpp::Parameter>& params)
  {
    rcl_interfaces::msg::SetParametersResult result;
    result.successful = true;
    for (const auto& param : params) {
      RCLCPP_INFO(get_logger(), "Param changed: %s", param.get_name().c_str());
    }
    return result;
  }

  rclcpp::node_parameters::OnSetParametersCallbackHandle::SharedPtr param_callback_;
  std::shared_ptr<tf2_ros::Buffer> tf_buffer_;
  std::shared_ptr<tf2_ros::TransformListener> tf_listener_;
  rclcpp::Subscription<nav2_costmap_2d::msg::Costmap>::SharedPtr costmap_sub_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<Nav2FullNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF
fi

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/nav2.launch.py" <<'LAUNCHEOF'
"""Nav2 node launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='PKGNAME',
            executable='nav2_node',
            name='nav2_node',
            output='screen',
            parameters=[{'use_sim_time': False}],
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/nav2.launch.py"

# ── config ────────────────────────────────────────────────
cat > "$PKG_NAME/config/nav2.yaml" <<'YAMLEOF'
/nav2_node:
  ros__parameters:
    enabled: true
    update_frequency: 10.0
    robot_base_frame: base_link
    map_frame: map
    costmap_subscribe_topic: /costmap
    costmap_publish_topic: /processed_costmap
YAMLEOF
sed -i "s|/nav2_node|/$PKG_NAME|g" "$PKG_NAME/config/nav2.yaml"

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/nav2_node.cpp"
echo "  launch/nav2.launch.py"
echo "  config/nav2.yaml"
echo ""
echo "Node type: $NODE_TYPE"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME"
echo "  2. rosdep install --from-paths . --ignore-src -r -y"
echo "  3. colcon build --packages-select $PKG_NAME"
echo "  4. ros2 launch $PKG_NAME nav2.launch.py"
