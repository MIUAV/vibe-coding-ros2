#!/bin/bash
# ros2-multi-agent-generator.sh — 多机器人协调控制包生成器
# 用法: bash ros2-multi-agent-generator.sh <pkg_name> [mode]
# mode: formation | task_allocation | swarming | collision_avoidance
#
# 示例: bash ros2-multi-agent-generator.sh swarm_coordination formation

PKG_NAME="${1:-}"
MODE="${2:-formation}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [协调模式]"
    echo "  formation          — 编队控制（leader-follower / virtual structure）"
    echo "  task_allocation    — 任务分配（市场机制 / 拍卖算法）"
    echo "  swarming          — 蜂群算法（BOIDs / 粒子群优化）"
    echo "  collision_avoidance — 分布式冲突避免（ORCA / MPC）"
    exit 1
fi

mkdir -p "$PKG_NAME/src" "$PKG_NAME/config" "$PKG_NAME/launch"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Multi-robot coordination package</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>nav_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>visualization_msgs</depend>
  <depend>rcl_interfaces</depend>
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
find_package(nav_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(visualization_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED
  src/multi_agent_node.cpp
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp nav_msgs geometry_msgs visualization_msgs
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

# ════════════════════════════════════════════════════════════
# 编队控制
# ════════════════════════════════════════════════════════════
if [[ "$MODE" == "formation" ]]; then

cat > "$PKG_NAME/src/multi_agent_node.cpp" <<'CPPEOF'
// formation — 多机器人编队控制节点
// 支持：Leader-Follower、Virtual Structure、Behavior-based
// 坐标系：全局地图坐标系 (map_frame)

#include <memory>
#include <vector>
#include <string>
#include <cmath>
#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <visualization_msgs/msg/marker_array.hpp>

class FormationNode : public rclcpp::Node
{
public:
  FormationNode()
  : Node("formation_node")
  {
    // ── 参数 ─────────────────────────────────────────
    this->declare_parameter("robot_name", "robot1");
    this->declare_parameter("is_leader", false);
    this->declare_parameter("formation_type", "diamond");  // diamond / line / circle / custom
    this->declare_parameter("num_robots", 5);
    this->declare_parameter("robot_spacing", 1.0);         // m
    this->declare_parameter("leader_topic", "/robot1/cmd_vel");
    this->declare_parameter("formation_topic", "/formation/targets");

    this->get_parameter("robot_name", robot_name_);
    this->get_parameter("is_leader", is_leader_);
    this->get_parameter("formation_type", formation_type_);

    // ── 话题 ────────────────────────────────────────
    if (is_leader_) {
      // Leader: 订阅用户目标，发布 leader cmd_vel
      goal_sub_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
        "/formation/goal", 10,
        std::bind(&FormationNode::on_goal, this, std::placeholders::_1));
      leader_cmd_pub_ = this->create_publisher<geometry_msgs::msg::Twist>(
        leader_topic_, 10);
      RCLCPP_INFO(this->get_logger(), "我是 Leader: %s", robot_name_.c_str());
    } else {
      // Follower: 订阅 formation_targets，计算相对位置偏差
      formation_sub_ = this->create_subscription<geometry_msgs::msg::PoseArray>(
        formation_topic_, 10,
        std::bind(&FormationNode::on_formation_targets, this, std::placeholders::_1));
      cmd_pub_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);
      RCLCPP_INFO(this->get_logger(), "我是 Follower: %s", robot_name_.c_str());
    }

    // ── 可视化 ──────────────────────────────────────
    marker_pub_ = this->create_publisher<visualization_msgs::msg::MarkerArray>(
      "/formation/markers", 10);

    // ── 定时器 ──────────────────────────────────────
    timer_ = this->create_wall_timer(
      std::chrono::milliseconds(100),
      std::bind(&FormationNode::tick, this));

    RCLCPP_INFO(this->get_logger(), "Formation node started (type=%s)", formation_type_.c_str());
  }

private:
  // ── Leader: 处理目标 ───────────────────────────
  void on_goal(const geometry_msgs::msg::PoseStamped::SharedPtr goal)
  {
    goal_pose_ = goal->pose;
    RCLCPP_DEBUG(this->get_logger(), "Leader: 收到新目标 (%.2f, %.2f)",
      goal->pose.position.x, goal->pose.position.y);

    // 简单追踪控制器
    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = 0.3;  // 固定前向速度
    cmd.angular.z = 0.2; // 固定角速度
    leader_cmd_pub_->publish(cmd);
  }

  // ── Follower: 处理编队目标 ─────────────────────
  void on_formation_targets(const geometry_msgs::msg::PoseArray::SharedPtr msg)
  {
    if (msg->poses.empty()) return;

    // 找到自己对应的编队目标
    geometry_msgs::msg::Pose target;
    bool found = false;

    for (size_t i = 0; i < msg->poses.size(); ++i) {
      std::string label = msg->header.frame_id;
      if (label == robot_name_) {
        target = msg->poses[i];
        found = true;
        break;
      }
    }

    if (!found && !msg->poses.empty()) {
      target = msg->poses[0];  // fallback
    }

    // 计算位置偏差
    double dx = target.position.x - current_pose_.position.x;
    double dy = target.position.y - current_pose_.position.y;

    // 简单的 P 控制
    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = std::clamp(dx * 1.0, -0.5, 0.5);
    cmd.angular.z = std::clamp(dy * 0.8, -1.0, 1.0);
    cmd_pub_->publish(cmd);
  }

  // ── 定时器 ───────────────────────────────────────
  void tick()
  {
    // 发布编队可视化标记
    publish_markers();
  }

  void publish_markers()
  {
    visualization_msgs::msg::MarkerArray markers;
    visualization_msgs::msg::Marker m;
    m.header.frame_id = "map";
    m.header.stamp = this->now();
    m.type = m.CUBE;
    m.scale.x = m.scale.y = 0.3;
    m.scale.z = 0.2;
    m.color.a = 0.8;

    if (is_leader_) {
      m.color.r = 1.0; m.color.g = 0.0; m.color.b = 0.0; // 红色 = Leader
    } else {
      m.color.r = 0.0; m.color.g = 0.0; m.color.b = 1.0; // 蓝色 = Follower
    }

    m.action = m.ADD;
    m.pose = current_pose_;
    markers.markers.push_back(m);
    marker_pub_->publish(markers);
  }

  // ── 编队形状计算 ────────────────────────────────
  std::vector<geometry_msgs::msg::Pose>
  compute_formation_shapes(const geometry_msgs::msg::Pose& leader_pose,
                            const std::string& type, int num)
  {
    std::vector<geometry_msgs::msg::Pose> targets;

    if (type == "diamond") {
      // 菱形编队：1 leader + 4 followers
      double d = robot_spacing_;
      targets.push_back(leader_pose); // leader 在中心
      geometry_msgs::msg::Pose p1 = leader_pose; p1.position.x += 0;  p1.position.y += d;  targets.push_back(p1);
      geometry_msgs::msg::Pose p2 = leader_pose; p2.position.x += d;  p2.position.y += 0;   targets.push_back(p2);
      geometry_msgs::msg::Pose p3 = leader_pose; p3.position.x += 0;  p3.position.y -= d;  targets.push_back(p3);
      geometry_msgs::msg::Pose p4 = leader_pose; p4.position.x -= d;  p4.position.y += 0;   targets.push_back(p4);
    } else if (type == "line") {
      for (int i = 0; i < num; ++i) {
        geometry_msgs::msg::Pose p = leader_pose;
        p.position.x -= i * robot_spacing_;
        targets.push_back(p);
      }
    } else if (type == "circle") {
      double r = robot_spacing_ * num / (2 * M_PI);
      for (int i = 0; i < num; ++i) {
        double angle = 2 * M_PI * i / num;
        geometry_msgs::msg::Pose p = leader_pose;
        p.position.x += r * std::cos(angle);
        p.position.y += r * std::sin(angle);
        targets.push_back(p);
      }
    }

    return targets;
  }

  // ── 成员变量 ───────────────────────────────────
  std::string robot_name_;
  bool is_leader_ = false;
  std::string formation_type_;
  double robot_spacing_ = 1.0;

  std::string leader_topic_ = "/robot1/cmd_vel";
  std::string formation_topic_ = "/formation/targets";

  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr goal_sub_;
  rclcpp::Subscription<geometry_msgs::msg::PoseArray>::SharedPtr formation_sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr leader_cmd_pub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
  rclcpp::Publisher<visualization_msgs::msg::MarkerArray>::SharedPtr marker_pub_;
  rclcpp::TimerBase::SharedPtr timer_;

  geometry_msgs::msg::Pose goal_pose_;
  geometry_msgs::msg::Pose current_pose_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<FormationNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

cat > "$PKG_NAME/config/formation_params.yaml" <<'YAMLEOF'
/formation_node:
  ros__parameters:
    formation_type: diamond    # diamond / line / circle
    robot_spacing: 1.0         # m
    is_leader: false
    leader_topic: /robot1/cmd_vel
    formation_topic: /formation/targets
YAMLEOF

cat > "$PKG_NAME/launch/formation.launch.py" <<'LAUNCHEOF'
"""Multi-robot formation launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        # Leader
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name='formation_robot1',
             parameters=[{
                 'robot_name': 'robot1',
                 'is_leader': True,
                 'formation_type': 'diamond',
                 'num_robots': 5,
             }],
             output='screen'),
        # Follower 1
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name='formation_robot2',
             parameters=[{
                 'robot_name': 'robot2',
                 'is_leader': False,
                 'formation_type': 'diamond',
                 'num_robots': 5,
             }],
             output='screen',
             namespace='robot2'),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/formation.launch.py"

# ════════════════════════════════════════════════════════════
# 任务分配（市场机制/拍卖）
# ════════════════════════════════════════════════════════════
elif [[ "$MODE" == "task_allocation" ]]; then

cat > "$PKG_NAME/src/multi_agent_node.cpp" <<'CPPEOF'
// task_allocation — 多机器人任务分配节点
// 算法：市场机制（Auction-based）拍卖任务
// 通信：ROS2 Service（/auction_bid, /auction_won）

#include <memory>
#include <vector>
#include <string>
#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <std_srvs/srv/trigger.hpp>

using namespace std::chrono_literals;

struct Task {
  std::string id;
  geometry_msgs::msg::PoseStamped goal;
  double cost_estimate;
  std::string winner;
};

class TaskAllocationNode : public rclcpp::Node
{
public:
  TaskAllocationNode()
  : Node("task_allocation")
  {
    this->declare_parameter("robot_id", "robot1");
    this->declare_parameter("is_auctioneer", false);
    this->get_parameter("robot_id", robot_id_);
    this->get_parameter("is_auctioneer", is_auctioneer_);

    if (is_auctioneer_) {
      // Auctioneer: 发布任务，接收投标，决定赢家
      auction_bid_sub_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
        "/auction/bid", 10,
        std::bind(&TaskAllocationNode::on_bid, this, std::placeholders::_1));
      auction_result_pub_ = this->create_publisher<std_msgs::msg::String>(
        "/auction/result", 10);
      RCLCPP_INFO(this->get_logger(), "Auctioneer started: %s", robot_id_.c_str());
    } else {
      // Bidder: 接收任务，投标，接收结果
      task_sub_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
        "/auction/task", 10,
        std::bind(&TaskAllocationNode::on_task, this, std::placeholders::_1));
      bid_pub_ = this->create_publisher<geometry_msgs::msg::PoseStamped>(
        "/auction/bid", 10);
      RCLCPP_INFO(this->get_logger(), "Bidder started: %s", robot_id_.c_str());
    }

    // 定时器：模拟投标决策
    timer_ = this->create_wall_timer(
      500ms, std::bind(&TaskAllocationNode::on_timer, this));
  }

private:
  void on_bid(const geometry_msgs::msg::PoseStamped::SharedPtr bid)
  {
    // 估算成本（简单：欧几里得距离）
    double cost = std::sqrt(
      std::pow(bid->pose.position.x - 0, 2) +
      std::pow(bid->pose.position.y - 0, 2));

    // 存储投标
    bids_[bid->header.frame_id] = cost;
    RCLCPP_DEBUG(this->get_logger(), "收到投标 from %s: cost=%.2f",
      bid->header.frame_id.c_str(), cost);
  }

  void on_task(const geometry_msgs::msg::PoseStamped::SharedPtr task)
  {
    current_task_ = task;
    // 计算我的投标（基于当前位置到任务位置的距离）
    double bid_cost = 1.5;  // 实际应计算路径规划
    geometry_msgs::msg::PoseStamped bid;
    bid.header.stamp = this->now();
    bid.header.frame_id = robot_id_;
    bid.pose.position.x = bid_cost;
    bid_pub_->publish(bid);
    RCLCPP_INFO(this->get_logger(), "投標: %.2f for task at (%.2f, %.2f)",
      bid_cost, task->pose.position.x, task->pose.position.y);
  }

  void on_timer()
  {
    if (!is_auctioneer_) return;

    // 如果有投标，决定赢家
    if (!bids_.empty()) {
      std::string winner;
      double min_cost = 1e9;
      for (const auto& [robot, cost] : bids_) {
        if (cost < min_cost) {
          min_cost = cost;
          winner = robot;
        }
      }
      RCLCPP_INFO(this->get_logger(), "任务分配给 %s (cost=%.2f)",
        winner.c_str(), min_cost);
      bids_.clear();
    }
  }

  std::string robot_id_;
  bool is_auctioneer_ = false;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr task_sub_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr auction_bid_sub_;
  rclcpp::Publisher<geometry_msgs::msg::PoseStamped>::SharedPtr bid_pub_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr auction_result_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
  std::map<std::string, double> bids_;
  geometry_msgs::msg::PoseStamped::SharedPtr current_task_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<TaskAllocationNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

cat > "$PKG_NAME/launch/task_alloc.launch.py" <<'LAUNCHEOF'
"""Task allocation launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        # Auctioneer (task publisher)
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name='auctioneer',
             parameters=[{'is_auctioneer': True, 'robot_id': 'auctioneer'}]),
        # Bidders
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name='bidder1',
             parameters=[{'is_auctioneer': False, 'robot_id': 'robot1'}]),
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name='bidder2',
             parameters=[{'is_auctioneer': False, 'robot_id': 'robot2'}]),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/task_alloc.launch.py"

# ════════════════════════════════════════════════════════════
# 蜂群算法（BOIDs）
# ════════════════════════════════════════════════════════════
elif [[ "$MODE" == "swarming" ]]; then

cat > "$PKG_NAME/src/multi_agent_node.cpp" <<'CPPEOF'
// swarming — BOIDs 蜂群算法实现
// 三规则：分离(Separation)、对齐(Alignment)、聚合(Cohesion)

#include <memory>
#include <vector>
#include <cmath>
#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <visualization_msgs/msg/marker.hpp>

class SwarmingNode : public rclcpp::Node
{
public:
  SwarmingNode()
  : Node("swarming_node")
  {
    this->declare_parameter("robot_id", "robot1");
    this->declare_parameter("neighbor_range", 3.0);      // m
    this->declare_parameter("separation_weight", 1.5);
    this->declare_parameter("alignment_weight", 1.0);
    this->declare_parameter("cohesion_weight", 1.0);
    this->declare_parameter("max_speed", 0.5);          // m/s
    this->declare_parameter("max_steering", 0.1);      // rad/s

    this->get_parameter("robot_id", robot_id_);

    // 位置话题（带 namespace）
    pose_sub_ = this->create_subscription<geometry_msgs::msg::PoseStamped>(
      "/poses", 10,
      std::bind(&SwarmingNode::on_pose, this, std::placeholders::_1));
    cmd_pub_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);
    marker_pub_ = this->create_publisher<visualization_msgs::msg::Marker>(
      "/swarm/markers", 10);

    timer_ = this->create_wall_timer(
      100ms, std::bind(&SwarmingNode::tick, this));

    RCLCPP_INFO(this->get_logger(), "Swarming node %s started", robot_id_.c_str());
  }

private:
  struct Agent { double x, y, vx, vy; };

  void on_pose(const geometry_msgs::msg::PoseStamped::SharedPtr msg)
  {
    Agent a;
    a.x = msg->pose.position.x;
    a.y = msg->pose.position.y;
    a.vx = 0; a.vy = 0;
    neighbors_[msg->header.frame_id] = a;
  }

  void tick()
  {
    Agent self = get_self_pose();

    // BOIDs 三规则
    auto sep = compute_separation(self);
    auto ali = compute_alignment(self);
    auto coh = compute_cohesion(self);

    double steer_x = sep.x * 1.5 + ali.x * 1.0 + coh.x * 1.0;
    double steer_y = sep.y * 1.5 + ali.y * 1.0 + coh.y * 1.0;

    // 限幅
    double mag = std::sqrt(steer_x*steer_x + steer_y*steer_y);
    if (mag > max_steering_) {
      steer_x = steer_x / mag * max_steering_;
      steer_y = steer_y / mag * max_steering_;
    }

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = std::clamp(steer_x, -max_speed_, max_speed_);
    cmd.angular.z = std::clamp(steer_y, -max_steering_, max_steering_);
    cmd_pub_->publish(cmd);
  }

  Agent get_self_pose()
  {
    Agent a{0, 0, 0, 0};
    // 实际应订阅自身里程计
    return a;
  }

  Agent compute_separation(const Agent& self)
  {
    Agent steer{0, 0, 0, 0};
    int count = 0;
    double range = neighbor_range_;

    for (const auto& [id, other] : neighbors_) {
      double dx = self.x - other.x;
      double dy = self.y - other.y;
      double dist = std::sqrt(dx*dx + dy*dy);
      if (dist > 0 && dist < range) {
        steer.x += dx / (dist * dist);  // 越近推力越大
        steer.y += dy / (dist * dist);
        count++;
      }
    }
    if (count > 0) { steer.x /= count; steer.y /= count; }
    return steer;
  }

  Agent compute_alignment(const Agent& self)
  {
    Agent avg_vel{0, 0, 0, 0};
    int count = 0;
    for (const auto& [id, other] : neighbors_) {
      avg_vel.vx += other.vx;
      avg_vel.vy += other.vy;
      count++;
    }
    if (count > 0) {
      avg_vel.vx /= count; avg_vel.vy /= count;
    }
    return avg_vel;
  }

  Agent compute_cohesion(const Agent& self)
  {
    Agent centroid{0, 0, 0, 0};
    int count = 0;
    for (const auto& [id, other] : neighbors_) {
      centroid.x += other.x;
      centroid.y += other.y;
      count++;
    }
    if (count > 0) {
      centroid.x /= count; centroid.y /= count;
      centroid.x -= self.x; centroid.y -= self.y; // 到质心的向量
    }
    return centroid;
  }

  std::string robot_id_;
  double neighbor_range_ = 3.0;
  double max_speed_ = 0.5, max_steering_ = 0.1;
  std::map<std::string, Agent> neighbors_;
  rclcpp::Subscription<geometry_msgs::msg::PoseStamped>::SharedPtr pose_sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
  rclcpp::Publisher<visualization_msgs::msg::Marker>::SharedPtr marker_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<SwarmingNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

cat > "$PKG_NAME/launch/swarm.launch.py" <<'LAUNCHEOF'
"""BOIDs swarm launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    nodes = []
    for i in range(1, 6):
        nodes.append(Node(
            package='PKGNAME',
            executable='multi_agent_node',
            name=f'swarm_robot{i}',
            parameters=[{
                'robot_id': f'robot{i}',
                'neighbor_range': 3.0,
                'max_speed': 0.5,
            }],
            namespace=f'robot{i}'))
    return LaunchDescription(nodes)
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/swarm.launch.py"

# ════════════════════════════════════════════════════════════
# 分布式冲突避免（ORCA）
# ════════════════════════════════════════════════════════════
else  # collision_avoidance

cat > "$PKG_NAME/src/multi_agent_node.cpp" <<'CPPEOF'
// collision_avoidance — ORCA 最优互惠冲突避免
// 每台机器人计算其他机器人的速度障碍锥，选择安全速度

#include <memory>
#include <vector>
#include <cmath>
#include <rclcpp/rclcpp.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <geometry_msgs/msg/twist.hpp>

class ORCANode : public rclcpp::Node
{
public:
  ORCANode()
  : Node("orca_node")
  {
    this->declare_parameter("robot_radius", 0.3);       // m
    this->declare_parameter("time_horizon", 5.0);      // s
    this->declare_parameter("max_speed", 1.0);         // m/s
    this->declare_parameter("preferred_speed", 0.5);   // m/s

    this->get_parameter("robot_radius", robot_radius_);
    this->get_parameter("time_horizon", time_horizon_);
    this->get_parameter("max_speed", max_speed_);
    this->get_parameter("preferred_speed", preferred_speed_);

    // 订阅其他机器人位置
    others_sub_ = this->create_subscription<geometry_msgs::msg::PoseArray>(
      "/orca/others", 10,
      std::bind(&ORCANode::on_others, this, std::placeholders::_1));

    // 发布自己的速度
    cmd_pub_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);

    timer_ = this->create_wall_timer(
      100ms, std::bind(&ORCANode::tick, this));

    RCLCPP_INFO(this->get_logger(), "ORCA node started");
  }

private:
  struct Vec2 { double x, y; };
  struct Robot { Vec2 pos, vel; };

  Vec2 operator-(const Vec2& a, const Vec2& b) { return {a.x-b.x, a.y-b.y}; }
  Vec2 operator+(const Vec2& a, const Vec2& b) { return {a.x+b.x, a.y+b.y}; }
  Vec2 operator*(const Vec2& a, double s) { return {a.x*s, a.y*s}; }
  double dot(const Vec2& a, const Vec2& b) { return a.x*b.x + a.y*b.y; }
  double len(const Vec2& a) { return std::sqrt(a.x*a.x + a.y*a.y); }
  Vec2 norm(const Vec2& a) { double l = len(a); return l > 0 ? Vec2{a.x/l, a.y/l} : Vec2{0,0}; }

  void on_others(const geometry_msgs::msg::PoseArray::SharedPtr msg)
  {
    others_.clear();
    for (const auto& pose : msg->poses) {
      Robot r;
      r.pos = {pose.position.x, pose.position.y};
      r.vel = {0, 0}; // 实际应从 odometry 获取
      others_.push_back(r);
    }
  }

  Vec2 compute_orca_velocity(const Vec2& my_pos, const Vec2& my_vel,
                             const std::vector<Robot>& others)
  {
    Vec2 preferred_vel = {preferred_speed_, 0};  // 默认向 x 正方向
    Vec2 new_vel = preferred_vel;

    double r = robot_radius_ * 2;  // 两人安全距离

    for (const auto& other : others) {
      Vec2 rel_pos = my_pos - other.pos;
      Vec2 rel_vel = my_vel - other.vel;

      double dist = len(rel_pos);
      if (dist > time_horizon_ * max_speed_ + r) continue; // 太远，跳过

      // ORCA 半平面计算（简化版）
      // 速度障碍锥的切线方向
      double toc = dist * dist / (2.0 * dist);  // time of closest approach (简化)
      Vec2 w = rel_pos + rel_vel * toc;  // 相对速度在最近点的位置

      if (len(w) >= r) {
        // 安全：不需要调整
        continue;
      }

      // 碰撞：计算避免碰撞所需的最小速度调整
      Vec2 u = w * (-1.0) * (r / len(w) - 1.0);  // 调整向量
      Vec2orca = u * 0.5;  // 取一半调整量

      new_vel.x +=orca.x * 0.5;
      new_vel.y +=orca.y * 0.5;
    }

    // 限速
    if (len(new_vel) > max_speed_) {
      Vec2 n = norm(new_vel);
      new_vel = n * max_speed_;
    }

    return new_vel;
  }

  void tick()
  {
    Vec2 my_pos{0, 0};  // 实际应从里程计读取
    Vec2 my_vel{preferred_speed_, 0};

    Vec2 safe_vel = compute_orca_velocity(my_pos, my_vel, others_);

    geometry_msgs::msg::Twist cmd;
    cmd.linear.x = safe_vel.x;
    cmd.angular.z = safe_vel.y;
    cmd_pub_->publish(cmd);
  }

  double robot_radius_ = 0.3;
  double time_horizon_ = 5.0;
  double max_speed_ = 1.0;
  double preferred_speed_ = 0.5;
  std::vector<Robot> others_;

  rclcpp::Subscription<geometry_msgs::msg::PoseArray>::SharedPtr others_sub_;
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<ORCANode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

cat > "$PKG_NAME/launch/orca.launch.py" <<'LAUNCHEOF'
"""ORCA collision avoidance launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    nodes = [
        Node(package='PKGNAME',
             executable='multi_agent_node',
             name=f'orca_robot{i}',
             parameters=[{
                 'robot_radius': 0.3,
                 'time_horizon': 5.0,
                 'preferred_speed': 0.5,
             }],
             namespace=f'robot{i}')
        for i in range(1, 6)
    ]
    return LaunchDescription(nodes)
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/orca.launch.py"

fi

echo ""
echo "Generated: $PKG_NAME/"
echo "  src/multi_agent_node.cpp"
echo "  config/"
echo "  launch/*.launch.py"
echo ""
echo "Mode: $MODE"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME"
echo "  2. rosdep install --from-paths . --ignore-src -r -y"
echo "  3. colcon build --packages-select $PKG_NAME"
echo "  4. ros2 launch $PKG_NAME *.launch.py"
