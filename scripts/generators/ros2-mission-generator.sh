#!/bin/bash
# ros2-mission-generator.sh — 机器人任务脚本生成器
# 用法: bash ros2-mission-generator.sh <pkg_name> [mission_type]
# mission_type: patrol | survey | inspection | delivery | exploration | custom
#
# 示例: bash ros2-mission-generator.sh robot_missions patrol

PKG_NAME="${1:-}"
MISSION_TYPE="${2:-patrol}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [任务类型]"
    echo "  patrol      — 自动巡逻任务（多航点循环）"
    echo "  survey     — 环境勘测任务（覆盖路径）"
    echo "  inspection — 定点巡检任务（设备状态检测）"
    echo "  delivery  — 物料搬运任务（起点→目标→返回）"
    echo "  exploration — 自主探索任务（ frontiers）"
    echo "  custom    — 自定义任务"
    exit 1
fi

mkdir -p "$PKG_NAME/scripts" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Robot mission scripts and state machine</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>nav_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>std_msgs</depend>
  <depend>action_msgs</depend>
  <export><build_type>ament_python</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ── setup.py ────────────────────────────────────────────────
cat > "$PKG_NAME/setup.py" <<'EOF'
from setuptools import setup
setup(
    name='PKGNAME',
    version='0.1.0',
    packages=[],
    data_files=[
        ('share/PKGNAME/scripts', ['scripts/mission_manager.py']),
        ('share/PKGNAME/config', ['config/mission_config.yaml']),
    ],
    install_requires=['setuptools'],
)
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/setup.py"

# ════════════════════════════════════════════════════════════
# Python 任务管理器
# ════════════════════════════════════════════════════════════

cat > "$PKG_NAME/scripts/mission_manager.py" <<'PYEOF'
#!/usr/bin/env python3
"""
Mission Manager — 机器人任务状态机
支持：patrol / survey / inspection / delivery / exploration
基于 Action Server 实现，支持暂停/恢复/取消
"""

import rclpy
from rclpy.node import Node
from rclpy.action import ActionServer, ActionClient
from rclpy.callback_groups import ReentrantCallbackGroup
from action_msgs.msg import GoalStatus
import threading
import time
import math


class MissionState:
    IDLE = "idle"
    RUNNING = "running"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class MissionManager(Node):
    def __init__(self):
        super().__init__('mission_manager')
        self.declare_parameter('mission_type', 'patrol')
        self.declare_parameter('mission_config', 'config/mission_config.yaml')

        mission_type = self.get_parameter('mission_type').value
        self.get_logger().info(f'MissionManager starting: {mission_type}')

        self.state_ = MissionState.IDLE
        self.current_waypoint_ = 0
        self.total_waypoints_ = 0
        self.mission_pause_flag_ = False

        # Action server for mission control
        self.action_server_ = ActionServer(
            self,
            'mission_msgs/action/Mission',
            '/mission/execute',
            execute_callback=self.execute_callback,
            callback_group=ReentrantCallbackGroup())

        # Action client for navigation
        self.nav_client_ = ActionClient(
            self, 'nav2_msgs/action/NavigateToPose', '/navigate_to_pose')

        # Publisher for mission status
        self.status_pub_ = self.create_publisher(
            'mission_msgs/msg/MissionStatus', '/mission/status', 10)

        self.timer_ = self.create_timer(1.0, self.publish_status)

        self.get_logger().info('MissionManager ready')

    async def execute_callback(self, goal_handle):
        self.get_logger().info(f'Received mission goal: {goal_handle.goal_id}')
        self.state_ = MissionState.RUNNING

        result = MissionResult()
        waypoints = self.load_waypoints(goal_handle.goal.mission_config)

        for i, wp in enumerate(waypoints):
            if goal_handle.is_cancel_requested:
                self.state_ = MissionState.CANCELLED
                goal_handle.canceled()
                result.success = False
                result.message = "Mission cancelled"
                return result

            while self.mission_pause_flag_:
                self.get_logger().info('Mission PAUSED')
                await self.sleep(1.0)

            self.current_waypoint_ = i
            self.get_logger().info(f'Going to waypoint {i+1}/{len(waypoints)}: {wp}')

            success = await self.navigate_to(wp)
            if not success:
                self.state_ = MissionState.FAILED
                goal_handle.abort()
                result.success = False
                result.message = f"Failed at waypoint {i+1}"
                return result

            await self.perform_action(wp)

        self.state_ = MissionState.COMPLETED
        goal_handle.succeed()
        result.success = True
        result.message = "Mission completed"
        return result

    async def navigate_to(self, waypoint):
        """导航到目标点"""
        if self.nav_client_ is None:
            self.get_logger().warn('Nav client not available — simulating')
            await self.sleep(2.0)
            return True

        goal = NavigateToPose.Goal()
        goal.pose.header.stamp = self.get_clock().now().to_msg()
        goal.pose.header.frame_id = 'map'
        goal.pose.pose.position.x = waypoint['x']
        goal.pose.pose.position.y = waypoint['y']
        goal.pose.pose.position.z = 0.0
        goal.pose.pose.orientation.w = 1.0

        self.get_logger().info(f'Navigating to ({waypoint["x"]}, {waypoint["y"]})')
        nav_future = await self.nav_client_.send_goal_async(goal)
        if not nav_future.accepted:
            return False

        result = await nav_future.get_result_async()
        return result.result.accepted

    async def perform_action(self, waypoint):
        """在航点执行动作（拍照/检测/放下等）"""
        action_type = waypoint.get('action', 'none')
        self.get_logger().info(f'Performing action: {action_type}')

        if action_type == 'photo':
            await self.take_photo(waypoint)
        elif action_type == 'scan':
            await self.scan_area(waypoint)
        elif action_type == 'pick':
            await self.pick_object(waypoint)
        elif action_type == 'place':
            await self.place_object(waypoint)
        else:
            await self.sleep(1.0)

    async def take_photo(self, waypoint):
        self.get_logger().info('Taking photo...')
        await self.sleep(1.0)
        self.get_logger().info('Photo captured')

    async def scan_area(self, waypoint):
        self.get_logger().info('Scanning area...')
        await self.sleep(2.0)
        self.get_logger().info('Scan complete')

    async def pick_object(self, waypoint):
        self.get_logger().info('Picking object...')
        await self.sleep(1.5)
        self.get_logger().info('Object picked')

    async def place_object(self, waypoint):
        self.get_logger().info('Placing object...')
        await self.sleep(1.5)
        self.get_logger().info('Object placed')

    async def sleep(self, seconds):
        """非阻塞等待"""
        start = time.time()
        while (time.time() - start) < seconds and rclpy.ok():
            await rclpy.task.loop_in_node(self, seconds=0.1)

    def load_waypoints(self, config):
        """加载航点配置"""
        # 实际应从 YAML 文件加载
        return [
            {'x': 0.0, 'y': 0.0, 'action': 'none'},
            {'x': 5.0, 'y': 0.0, 'action': 'photo'},
            {'x': 5.0, 'y': 5.0, 'action': 'scan'},
            {'x': 0.0, 'y': 5.0, 'action': 'none'},
        ]

    def publish_status(self):
        msg = MissionStatus()
        msg.state = self.state_
        msg.current_waypoint = self.current_waypoint_
        msg.total_waypoints = self.total_waypoints_
        self.status_pub_.publish(msg)

    # ── 任务控制接口 ─────────────────────────────────
    def pause_mission(self):
        """暂停任务"""
        self.mission_pause_flag_ = True
        self.state_ = MissionState.PAUSED
        self.get_logger().info('Mission paused')

    def resume_mission(self):
        """恢复任务"""
        self.mission_pause_flag_ = False
        self.state_ = MissionState.RUNNING
        self.get_logger().info('Mission resumed')

    def cancel_mission(self):
        """取消任务"""
        # 通过 action client 取消
        self.get_logger().info('Mission cancelled by user')


# ── 简化消息类型（实际项目应 import 真实消息）────────────
class MissionGoal: pass
class MissionResult: pass
class MissionStatus: pass
class NavigateToPose: pass


def main(args=None):
    rclpy.init(args=args)
    node = MissionManager()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

# ════════════════════════════════════════════════════════════
# 巡逻任务脚本
# ════════════════════════════════════════════════════════════
if [[ "$MISSION_TYPE" == "patrol" ]]; then

cat > "$PKG_NAME/config/mission_config.yaml" <<'YAMLEOF'
mission:
  type: patrol
  name: "Auto Patrol Route"

waypoints:
  - name: "Point A"
    x: 0.0
    y: 0.0
    z: 0.0
    action: "none"
    dwell_time: 5.0

  - name: "Point B"
    x: 5.0
    y: 0.0
    z: 0.0
    action: "photo"
    dwell_time: 3.0

  - name: "Point C"
    x: 5.0
    y: 5.0
    z: 0.0
    action: "scan"
    dwell_time: 10.0

  - name: "Point D"
    x: 0.0
    y: 5.0
    z: 0.0
    action: "none"
    dwell_time: 2.0

loop: true
max_velocity: 0.5
YAMLEOF

# ════════════════════════════════════════════════════════════
# 环境勘测任务
# ════════════════════════════════════════════════════════════
elif [[ "$MISSION_TYPE" == "survey" ]]; then

cat > "$PKG_NAME/config/mission_config.yaml" <<'YAMLEOF'
mission:
  type: survey
  name: "Area Survey"

# 覆盖路径生成参数
coverage:
  area_width: 20.0      # m
  area_height: 20.0     # m
  track_spacing: 2.0     # m (行间距)
  overlap: 0.2           # 20% 重叠率

waypoints:
  # 自动生成（lawn mower pattern）
  # 手动覆盖路径
  - {x: 0, y: 0, action: none}
  - {x: 5, y: 0, action: photo}
  - {x: 5, y: 2, action: none}
  - {x: 0, y: 2, action: photo}
  - {x: 0, y: 4, action: none}
  - {x: 5, y: 4, action: photo}
  - {x: 5, y: 6, action: none}
  - {x: 0, y: 6, action: photo}

altitude: 3.0           # m
camera_angle: 90        # degrees (俯视)
overlap_required: true
YAMLEOF

# ════════════════════════════════════════════════════════════
# 定点巡检任务
# ════════════════════════════════════════════════════════════
elif [[ "$MISSION_TYPE" == "inspection" ]]; then

cat > "$PKG_NAME/config/mission_config.yaml" <<'YAMLEOF'
mission:
  type: inspection
  name: "Equipment Inspection"

inspection_points:
  - name: "Motor A1"
    location: {x: 2.0, y: 1.0, z: 1.5}
    sensors: [thermal, visual]
    dwell_time: 10.0
    critical: true

  - name: "Motor A2"
    location: {x: 2.0, y: 3.0, z: 1.5}
    sensors: [thermal, visual]
    dwell_time: 10.0
    critical: true

  - name: "Panel B1"
    location: {x: 4.0, y: 1.0, z: 1.2}
    sensors: [thermal]
    dwell_time: 8.0
    critical: false

  - name: "Panel B2"
    location: {x: 4.0, y: 3.0, z: 1.2}
    sensors: [thermal]
    dwell_time: 8.0
    critical: false

  - name: "Valve Station"
    location: {x: 6.0, y: 2.0, z: 0.0}
    sensors: [thermal, visual, gas]
    dwell_time: 15.0
    critical: true

report_format: json
alarm_on_anomaly: true
YAMLEOF

# ════════════════════════════════════════════════════════════
# 物料搬运任务
# ════════════════════════════════════════════════════════════
elif [[ "$MISSION_TYPE" == "delivery" ]]; then

cat > "$PKG_NAME/config/mission_config.yaml" <<'YAMLEOF'
mission:
  type: delivery
  name: "Material Delivery"

# 任务队列
tasks:
  - id: 1
    pickup: {x: 0.0, y: 0.0, z: 0.0, station: "Station A"}
    dropoff: {x: 5.0, y: 3.0, z: 0.0, station: "Station B"}
    priority: 1
    cargo_type: "package"

  - id: 2
    pickup: {x: 3.0, y: 8.0, z: 0.0, station: "Station C"}
    dropoff: {x: 0.0, y: 0.0, z: 0.0, station: "Station A"}
    priority: 2
    cargo_type: "tray"

  - id: 3
    pickup: {x: 8.0, y: 5.0, z: 0.0, station: "Station D"}
    dropoff: {x: 5.0, y: 3.0, z: 0.0, station: "Station B"}
    priority: 1
    cargo_type: "package"

retry_on_failure: 3
return_to_home_after_each: false
collision_avoidance: true
YAMLEOF

# ════════════════════════════════════════════════════════════
# 自主探索任务
# ════════════════════════════════════════════════════════════
else  # exploration 或 custom

cat > "$PKG_NAME/config/mission_config.yaml" <<'YAMLEOF'
mission:
  type: exploration
  name: "Autonomous Exploration"

exploration:
  # frontiers 探索参数
  min_frontier_size: 1.0       # m²
  exploration_interval: 2.0   # s
  robot_radius: 0.3           # m
  safety_margin: 0.5          # m

  # 地图边界
  bounds:
    min_x: -20.0
    max_x: 20.0
    min_y: -20.0
    max_y: 20.0

  # 探索优先级
  frontier_selection: "nearest"  # nearest / largest / information_gain

  # 停止条件
  stop_conditions:
    - type: time
      value: 600      # 10 分钟后停止

    - type: coverage
      value: 0.95   # 95% 覆盖率

    - type: no_frontiers
      enabled: true

  # 保存地图
  save_map: true
  map_filename: "exploration_map.bag"
YAMLEOF

fi

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/mission.launch.py" <<'LAUNCHEOF'
"""Mission manager launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='PKGNAME',
            executable='scripts/mission_manager.py',
            name='mission_manager',
            output='screen',
            parameters=['config/mission_config.yaml'],
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/mission.launch.py"

# ── CLI 工具 ────────────────────────────────────────────────
cat > "$PKG_NAME/scripts/mission_cli.py" <<'PYEOF'
#!/usr/bin/env python3
"""Mission CLI — 命令行任务控制工具"""
import sys
import rclpy
from rclpy.node import Node
from mission_msgs.action import Mission


class MissionCLI(Node):
    def __init__(self):
        super().__init__('mission_cli')
        self.client = self.create_action_client(Mission, '/mission/execute')

    def send_mission(self, mission_config):
        goal = Mission.Goal()
        goal.mission_config = mission_config
        self.get_logger().info('Sending mission...')
        self.client.send_goal_async(goal)


if __name__ == '__main__':
    rclpy.init()
    node = MissionCLI()
    rclpy.spin(node)
PYEOF

echo ""
echo "Generated: $PKG_NAME/"
echo "  scripts/mission_manager.py"
echo "  scripts/mission_cli.py"
echo "  config/mission_config.yaml"
echo "  launch/mission.launch.py"
echo ""
echo "Mission type: $MISSION_TYPE"
echo ""
echo "Usage:"
echo "  ros2 launch $PKG_NAME mission.launch.py"
echo ""
echo "CLI controls:"
echo "  ros2 action send_goal /mission/execute mission_msgs/action/Mission \"{mission: {}}\""
