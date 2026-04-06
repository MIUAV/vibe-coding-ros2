#!/bin/bash
# ros2-behavior-tree-generator.sh — 行为树（Behavior Tree）节点生成器
# 用法: bash ros2-behavior-tree-generator.sh <pkg_name> [bt_type]
# bt_type: patrol | pick_place | exploration | navigation | custom
#
# 示例: bash ros2-behavior-tree-generator.sh bt_demo patrol

PKG_NAME="${1:-}"
BT_TYPE="${2:-navigation}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [行为树类型]"
    echo "  patrol       — 巡逻行为树（自主导航+异常处理）"
    echo "  pick_place  — 抓取放置行为树（感知→抓取→放置）"
    echo "  exploration  — 探索行为树（ frontiers 自主探索）"
    echo "  navigation  — 导航行为树（路径规划+重试+避障）"
    echo "  custom      — 空模板自定义"
    exit 1
fi

mkdir -p "$PKG_NAME/src" "$PKG_NAME/bt_xml" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Behavior Tree nodes for ROS2</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>behaviortree_cpp_v4</depend>
  <depend>nav_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>std_msgs</depend>
  <depend>action_msgs</depend>
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
find_package(behaviortree_cpp_v4 REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/bt_node.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp behavitree_cpp_v4 nav_msgs geometry_msgs
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION lib)
install(DIRECTORY bt_xml launch config DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()
ament_package()
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/CMakeLists.txt"

# ════════════════════════════════════════════════════════════
# BT XML — 巡逻行为树
# ════════════════════════════════════════════════════════════
if [[ "$BT_TYPE" == "patrol" ]]; then

cat > "$PKG_NAME/bt_xml/patrol.xml" <<'XMLEOF'
<?xml version="1.0"?>
<root main_tree_to_execute="Patrol">
  <BehaviorTree ID="Patrol">
    <PipelineSequence name="patrol_main">
      <!-- 状态机：IDLE → PATROLLING → PAUSED -->
      <ReactiveSequence name="patrol_loop">
        <!-- 检查是否有新目标 -->
        <CheckNewGoal/>
        <!-- 选择下一个航点 -->
        <SelectNextWaypoint/>
        <!-- 导航到航点 -->
        <NavigateToPose/>
        <!-- 到达后报告 -->
        <ReportArrival/>
      </ReactiveSequence>
      <!-- 异常处理：导航失败时跳过 -->
      <Fallback name="error_handling">
        <NavigateToPose/>
        <RetryUntilSuccessful name="nav_retry" num_attempts="3">
          <NavigateToPose/>
        </RetryUntilSuccessful>
        <LogMessage name="nav_failed" message="Navigation failed, skipping to next waypoint" level="WARN"/>
      </Fallback>
    </PipelineSequence>
  </BehaviorTree>
</root>
XMLEOF

cat > "$PKG_NAME/src/bt_node.cpp" <<'CPPEOF'
// patrol — 巡逻行为树节点
// BT: PipelineSequence → ReactiveSequence + Fallback error handling
// 子节点：CheckNewGoal, SelectNextWaypoint, NavigateToPose, ReportArrival

#include <memory>
#include <string>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <behaviortree_cpp_v4/behavior_tree.h>
#include <behaviortree_cpp_v4/bt_factory.h>
#include <behaviortree_cpp_v4/loggers/bt_zmq_publisher.h>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <std_msgs/msg/bool.hpp>

using namespace BT;

// ── 自定义 BT 节点 ───────────────────────────────────────

class CheckNewGoal : public SyncActionNode
{
public:
  CheckNewGoal(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config)
  {
    // 订阅目标话题
  }

  NodeStatus tick() override
  {
    // 检查是否有新巡逻目标
    RCLCPP_INFO(node_->get_logger(), "CheckNewGoal");
    return NodeStatus::SUCCESS;
  }

  rclcpp::Node::SharedPtr node_;
  PortsList providedPorts() override { return {}; }
};

class SelectNextWaypoint : public SyncActionNode
{
public:
  SelectNextWaypoint(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config)
  {
    waypoints_ = {
      geometry_msgs::msg::PoseStamped() /* ... 预设航点 ... */
    };
    wp_idx_ = 0;
  }

  NodeStatus tick() override
  {
    if (wp_idx_ >= waypoints_.size()) wp_idx_ = 0;
    RCLCPP_INFO(node_->get_logger(), "SelectNextWaypoint: %zu/%zu", wp_idx_+1, waypoints_.size());
    setOutput("waypoint", waypoints_[wp_idx_]);
    wp_idx_++;
    return NodeStatus::SUCCESS;
  }

  rclcpp::Node::SharedPtr node_;
  std::vector<geometry_msgs::msg::PoseStamped> waypoints_;
  size_t wp_idx_ = 0;

  PortsList providedPorts() override {
    return { OutputPort<geometry_msgs::msg::PoseStamped>("waypoint") };
  }
};

class NavigateToPose : public AsyncActionNode
{
public:
  NavigateToPose(const std::string& name, const NodeConfiguration& config)
    : AsyncActionNode(name, config) {}

  NodeStatus tick() override
  {
    RCLCPP_INFO(node_->get_logger(), "NavigateToPose: moving to goal...");
    // 模拟导航（实际使用 nav2）
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    RCLCPP_INFO(node_->get_logger(), "NavigateToPose: arrived");
    return NodeStatus::SUCCESS;
  }

  rclcpp::Node::SharedPtr node_;
  PortsList providedPorts() override { return {}; }
};

class ReportArrival : public SyncActionNode
{
public:
  ReportArrival(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}

  NodeStatus tick() override
  {
    RCLCPP_INFO(node_->get_logger(), "ReportArrival: waypoint reached");
    return NodeStatus::SUCCESS;
  }

  PortsList providedPorts() override { return {}; }
};

// ── 主节点 ────────────────────────────────────────────────
class PatrolNode : public rclcpp::Node
{
public:
  PatrolNode()
  : Node("patrol_bt_node")
  {
    RCLCPP_INFO(this->get_logger(), "Patrol BT node starting...");

    // ── 注册自定义节点 ────────────────────────────
    factory_.registerNodeType<CheckNewGoal>("CheckNewGoal");
    factory_.registerNodeType<SelectNextWaypoint>("SelectNextWaypoint");
    factory_.registerNodeType<NavigateToPose>("NavigateToPose");
    factory_.registerNodeType<ReportArrival>("ReportArrival");

    // 加载 BT XML
    tree_ = factory_.createTreeFromFile("bt_xml/patrol.xml");

    // BT 日志发布（可视化）
    logger_ = std::make_shared<BT::ZMQPublisher2>(tree_);

    // 定时器：执行 BT
    timer_ = create_wall_timer(
      std::chrono::milliseconds(100),
      [this]() { tree_.tickRoot(); });

    RCLCPP_INFO(this->get_logger(), "Patrol BT node running");
  }

private:
  BehaviorTreeFactory factory_;
  Tree tree_;
  std::shared_ptr<BT::ZMQPublisher2> logger_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<PatrolNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ════════════════════════════════════════════════════════════
# BT XML — 导航行为树（带重试+避障）
# ════════════════════════════════════════════════════════════
elif [[ "$BT_TYPE" == "navigation" ]]; then

cat > "$PKG_NAME/bt_xml/navigation.xml" <<'XMLEOF'
<?xml version="1.0"?>
<root main_tree_to_execute="Navigation">
  <BehaviorTree ID="Navigation">
    <RetryUntilSuccessful name="nav_with_retry" num_attempts="3">
      <Sequence name="nav_sequence">
        <ComputePathToGoal/>
        <SmoothPath/>
        <ExecutePath/>
        <GoalReached/>
      </Sequence>
    </RetryUntilSuccessful>
  </BehaviorTree>
</root>
XMLEOF

cat > "$PKG_NAME/src/bt_node.cpp" <<'CPPEOF'
// navigation — 导航行为树（带重试+路径平滑）
// RetryUntilSuccessful(3次) → Sequence(ComputePath→SmoothPath→ExecutePath→GoalReached)

#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <behaviortree_cpp_v4/behavior_tree.h>
#include <behaviortree_cpp_v4/bt_factory.h>

using namespace BT;

class ComputePathToGoal : public AsyncActionNode {
public:
  ComputePathToGoal(const std::string& name, const NodeConfiguration& config)
    : AsyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "ComputePathToGoal");
    return NodeStatus::SUCCESS;
  }
  rclcpp::Node::SharedPtr node_;
  PortsList providedPorts() override { return {}; }
};

class SmoothPath : public SyncActionNode {
public:
  SmoothPath(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "SmoothPath");
    return NodeStatus::SUCCESS;
  }
  PortsList providedPorts() override { return {}; }
};

class ExecutePath : public AsyncActionNode {
public:
  ExecutePath(const std::string& name, const NodeConfiguration& config)
    : AsyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "ExecutePath");
    return NodeStatus::RUNNING;
  }
  PortsList providedPorts() override { return {}; }
};

class GoalReached : public SyncActionNode {
public:
  GoalReached(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "GoalReached");
    return NodeStatus::SUCCESS;
  }
  PortsList providedPorts() override { return {}; }
};

class NavigationNode : public rclcpp::Node {
public:
  NavigationNode() : Node("navigation_bt_node") {
    factory_.registerNodeType<ComputePathToGoal>("ComputePathToGoal");
    factory_.registerNodeType<SmoothPath>("SmoothPath");
    factory_.registerNodeType<ExecutePath>("ExecutePath");
    factory_.registerNodeType<GoalReached>("GoalReached");
    tree_ = factory_.createTreeFromFile("bt_xml/navigation.xml");
    timer_ = create_wall_timer(std::chrono::milliseconds(100),
      [this]() { tree_.tickRoot(); });
    RCLCPP_INFO(this->get_logger(), "Navigation BT node running");
  }
private:
  BehaviorTreeFactory factory_;
  Tree tree_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<NavigationNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ════════════════════════════════════════════════════════════
# BT XML — 抓取放置
# ════════════════════════════════════════════════════════════
elif [[ "$BT_TYPE" == "pick_place" ]]; then

cat > "$PKG_NAME/bt_xml/pick_place.xml" <<'XMLEOF'
<?xml version="1.0"?>
<root main_tree_to_execute="PickPlace">
  <BehaviorTree ID="PickPlace">
    <Sequence name="pick_place_main">
      <!-- 感知：找到物体 -->
      <DetectObject name="find_target"/>
      <!-- 移动到物体 -->
      <MoveTo name="approach_object"/>
      <!-- 抓取 -->
      <GraspObject name="grasp"/>
      <!-- 举起 -->
      <LiftObject name="lift"/>
      <!-- 移动到放置区 -->
      <MoveTo name="move_to_place"/>
      <!-- 放置 -->
      <PlaceObject name="place"/>
      <!-- 返回 -->
      <MoveTo name="return_home"/>
    </Sequence>
  </BehaviorTree>
</root>
XMLEOF

cat > "$PKG_NAME/src/bt_node.cpp" <<'CPPEOF'
// pick_place — 抓取放置行为树
// Sequence: DetectObject → MoveTo → GraspObject → Lift → MoveTo → Place → ReturnHome

#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <behaviortree_cpp_v4/behavior_tree.h>
#include <behaviortree_cpp_v4/bt_factory.h>

using namespace BT;

#define DEFINE_BT_NODE(Name) \
  class Name : public SyncActionNode { \
  public: \
    Name(const std::string& name, const NodeConfiguration& config) \
      : SyncActionNode(name, config) {} \
    NodeStatus tick() override { \
      RCLCPP_INFO(node_->get_logger(), #Name); \
      return NodeStatus::SUCCESS; \
    } \
    rclcpp::Node::SharedPtr node_; \
    PortsList providedPorts() override { return {}; } \
  }

DEFINE_BT_NODE(DetectObject);
DEFINE_BT_NODE(MoveTo);
DEFINE_BT_NODE(GraspObject);
DEFINE_BT_NODE(LiftObject);
DEFINE_BT_NODE(PlaceObject);

class PickPlaceNode : public rclcpp::Node {
public:
  PickPlaceNode() : Node("pick_place_bt_node") {
    factory_.registerNodeType<DetectObject>("DetectObject");
    factory_.registerNodeType<MoveTo>("MoveTo");
    factory_.registerNodeType<GraspObject>("GraspObject");
    factory_.registerNodeType<LiftObject>("LiftObject");
    factory_.registerNodeType<PlaceObject>("PlaceObject");
    tree_ = factory_.createTreeFromFile("bt_xml/pick_place.xml");
    timer_ = create_wall_timer(std::chrono::milliseconds(100),
      [this]() { tree_.tickRoot(); });
    RCLCPP_INFO(this->get_logger(), "PickPlace BT node running");
  }
private:
  BehaviorTreeFactory factory_;
  Tree tree_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<PickPlaceNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ════════════════════════════════════════════════════════════
# BT XML — 探索行为树
# ════════════════════════════════════════════════════════════
else  # exploration 或 custom

cat > "$PKG_NAME/bt_xml/exploration.xml" <<'XMLEOF'
<?xml version="1.0"?>
<root main_tree_to_execute="Exploration">
  <BehaviorTree ID="Exploration">
    <PipelineSequence name="explore_main">
      <!-- 查找前沿点（未探索区域） -->
      <FindFrontier/>
      <!-- 导航到前沿 -->
      <NavigateToPose/>
      <!-- 更新地图 -->
      <UpdateMap/>
      <!-- 检查是否完成 -->
      <IsExplorationComplete/>
    </PipelineSequence>
  </BehaviorTree>
</root>
XMLEOF

cat > "$PKG_NAME/src/bt_node.cpp" <<'CPPEOF'
// exploration — 自主探索行为树
// PipelineSequence: FindFrontier → NavigateToPose → UpdateMap → IsExplorationComplete

#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <behaviortree_cpp_v4/behavior_tree.h>
#include <behaviortree_cpp_v4/bt_factory.h>

using namespace BT;

class FindFrontier : public SyncActionNode {
public:
  FindFrontier(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "FindFrontier: searching for unexplored area...");
    return NodeStatus::SUCCESS;
  }
  rclcpp::Node::SharedPtr node_;
  PortsList providedPorts() override { return {}; }
};

class NavigateToPose : public AsyncActionNode {
public:
  NavigateToPose(const std::string& name, const NodeConfiguration& config)
    : AsyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "NavigateToPose: exploring...");
    return NodeStatus::SUCCESS;
  }
  PortsList providedPorts() override { return {}; }
};

class UpdateMap : public SyncActionNode {
public:
  UpdateMap(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "UpdateMap: integrating scan data...");
    return NodeStatus::SUCCESS;
  }
  PortsList providedPorts() override { return {}; }
};

class IsExplorationComplete : public SyncActionNode {
public:
  IsExplorationComplete(const std::string& name, const NodeConfiguration& config)
    : SyncActionNode(name, config) {}
  NodeStatus tick() override {
    RCLCPP_INFO(node_->get_logger(), "IsExplorationComplete: checking...");
    return NodeStatus::FAILURE;  // 永远不完成，持续探索
  }
  PortsList providedPorts() override { return {}; }
};

class ExplorationNode : public rclcpp::Node {
public:
  ExplorationNode() : Node("exploration_bt_node") {
    factory_.registerNodeType<FindFrontier>("FindFrontier");
    factory_.registerNodeType<NavigateToPose>("NavigateToPose");
    factory_.registerNodeType<UpdateMap>("UpdateMap");
    factory_.registerNodeType<IsExplorationComplete>("IsExplorationComplete");
    tree_ = factory_.createTreeFromFile("bt_xml/exploration.xml");
    timer_ = create_wall_timer(std::chrono::milliseconds(100),
      [this]() { tree_.tickRoot(); });
    RCLCPP_INFO(this->get_logger(), "Exploration BT node running");
  }
private:
  BehaviorTreeFactory factory_;
  Tree tree_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<ExplorationNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF
fi

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/bt.launch.py" <<'LAUNCHEOF'
"""Behavior Tree launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='PKGNAME',
            executable='bt_node',
            name='bt_node',
            output='screen',
            parameters=[{'bt_xml_file': 'bt_xml/BTTYPE.xml'}],
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g; s/BTTYPE/$BT_TYPE/g" "$PKG_NAME/launch/bt.launch.py"

# ── config ────────────────────────────────────────────────
cat > "$PKG_NAME/config/bt_params.yaml" <<'YAMLEOF'
/bt_node:
  ros__parameters:
    bt_xml_file: "bt_xml/BTTYPE.xml"
    plugin_namespaces: [""]
YAMLEOF
sed -i "s/BTTYPE/$BT_TYPE/g" "$PKG_NAME/config/bt_params.yaml"

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/bt_node.cpp"
echo "  bt_xml/BTTYPE.xml"
echo "  launch/bt.launch.py"
echo "  config/bt_params.yaml"
echo ""
echo "Behavior Tree type: $BT_TYPE"
echo ""
echo "Dependencies to install:"
echo "  sudo apt install ros-\${ROS_DISTRO}-behaviortree-cpp-v4"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME"
echo "  2. rosdep install --from-paths . --ignore-src -r -y"
echo "  3. colcon build --packages-select $PKG_NAME"
echo "  4. ros2 launch $PKG_NAME bt.launch.py"
echo ""
echo "Visualize BT:"
echo "  ros2 run bt_rviz_gui bt_rviz_gui"
echo "  bt_gui: 加载 bt_xml/BTTYPE.xml"
