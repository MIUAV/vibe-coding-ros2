---
name: nav2-integration
description: 导航2 (Nav2) 集成技能 - Nav2 配置、行为树、路径规划、避障、定位适配
argument-hint: Nav2配置 OR 导航集成 OR 行为树导航 OR Nav2避障
user-invocable: true
---

# Navigation2 (Nav2) 集成技能

> 用于将 Navigation2 导航堆栈集成到 ROS2 机器人项目中，涵盖配置、调参和定制开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 将 Nav2 集成到机器人项目
- 配置行为树（Behavior Tree）
- 调优路径规划和避障参数
- 多机器人导航
- Nav2 与定位系统（SLAM）集成

---

## 快速参考

### Nav2 架构

```
Nav2 堆栈
├── planner_server      # 全局路径规划 (NavFn, Smac, Theta*)
├── controller_server   # 局部路径跟踪 (DWB, TEB, RPP)
├── smoother_server     # 路径平滑
├── behaviors_server    # 行为树 (备份、等待、旋回)
├── bt_navigator        # 行为树导航器
├── navigatorLifecycle  # 生命周期管理
└── recovery_server     # 恢复行为
```

### 核心话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/navigate_to_pose` | action | 导航到目标点 |
| `/compute_path_to_pose` | action | 计算路径 |
| `/goal_pose` | geometry_msgs/PoseStamped | 2D 导航目标 |
| `/local_costmap/costs` | nav_msgs/OccupancyGrid | 本地代价地图 |

---

## ROS2 launch 集成

### 最小启动配置

```python
# launch/nav2_bringup.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from nav2_common.launch import RewrittenYaml
import os

def generate_launch_description():
    # 导航参数文件
    nav2_params = os.path.join(
        get_package_share_directory('nav2_bringup'),
        'params/nav2_params.yaml'
    )

    # 替换参数
    configured_params = RewrittenYaml(
        source_file=nav2_params,
        root_key='',
        param_rewrites={
            'robot_base_frame': 'base_link',
            'use_sim_time': 'false',
        }
    )

    return LaunchDescription([
        # Nav2 生命周期节点
        Node(
            package='nav2_controller',
            executable='controller_server',
            name='controller_server',
            parameters=[configured_params],
            remappings=[
                ('/cmd_vel', '/diff_driver_base_controller/cmd_vel_unstamped'),
            ],
        ),
        Node(
            package='nav2_planner',
            executable='planner_server',
            name='planner_server',
            parameters=[configured_params],
        ),
        Node(
            package='nav2_behaviors',
            executable='behavior_server',
            name='behavior_server',
            parameters=[configured_params],
        ),
        Node(
            package='nav2_bt_navigator',
            executable='bt_navigator',
            name='bt_navigator',
            parameters=[configured_params],
        ),
        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager',
            parameters=[{'autostart': True}],
        ),
    ])
```

### 订阅 SLAM 定位

```yaml
# nav2_params.yaml
amcl:
  ros__parameters:
    use_sim_time: false
    alpha1: 0.2
    alpha2: 0.2
    alpha3: 0.2
    alpha4: 0.2
    alpha5: 0.2
    base_frame: base_link
    global_frame: map
    robot_frame: base_link

bt_navigator:
  ros__parameters:
    default_nav_to_pose_bt_xml: $(find-pkg-share nav2_bt_navigator)/behavior_trees/navigate_to_pose_w_replanning_and_ifcovery_bt.xml
    plugin_lib_names:
      - nav2_compute_path_to_pose_action_bt_node
      - nav2_follow_path_action_bt_node
      - nav2_back_up_action_bt_node
      - nav2_spin_action_bt_node
      - nav2_wait_action_bt_node
      - nav2_clear_costmap_service_bt_node
```

---

## 行为树 (Behavior Tree)

### 自定义行为树 XML

```xml
<?xml version="1.0"?>
<root BTCPP_format="4">
  <BehaviorTree ID="main_bt">
    <PipelineSequence name="navigate_recovering">
      <!-- 主导航 -->
      <RecoveryNode name="navigate_and_recover">
        <Sequence name="nav_w_replanning">
          <RateController hz="1.0">
            <ComputePathToPose goal="{goal}" path="{path}" error_code_id="{error_code}"/>
          </RateController>
          <FollowPath path="{path}" controller_id="FollowPath" error_code_id="{follow_error}"/>
        </Sequence>
        <!-- 恢复策略 -->
        <Sequence name="recovery">
          <ClearEntireCostmapService name="clear_costmap" service="/global_costmap/clear_entirely_costmap"/>
          <WaitTrigger name="wait" duration="3"/>
        </Sequence>
      </RecoveryNode>
    </PipelineSequence>
  </BehaviorTree>
</root>
```

### Python 自定义行为节点

```python
# my_bt_nodes.py
from nav2_behaviors.plugins.backup import BackUp

class CustomBackUp(BackUp):
    def onConfigure(self) -> bool:
        self->state->setInput("speed", 0.1)  # 自定义速度
        self->state->setInput("time_allowed", 10.0)
        return True
```

注册到插件库：
```xml
<library path="my_bt_nodes">
  <node library="my_bt_nodes" name="CustomBackUp" action="nav2_behaviors/plugins/actions"/>
</library>
```

---

## 局部路径跟踪

### DWB Controller 配置

```yaml
dwb_controller:
  ros__parameters:
    min_vel_x: 0.0
    min_vel_theta: -1.5
    max_vel_x: 0.5
    max_vel_y: 0.5
    max_vel_theta: 1.5
    min_speed_xy: 0.0
    max_speed_xy: 0.5
    acc_lim_x: 2.5
    acc_lim_y: 2.5
    acc_lim_theta: 3.2

    # TEB 配置（备选）
teb_local_planner:
  ros__parameters:
    max_vel_x: 0.5
    max_vel_theta: 1.5
    max_accel: 2.5
    wheelbase: 0.5
    cmd_angle_instead_rotvel: true
```

### 跟踪前沿（FollowWaypoints）

```python
from nav2_msgs.action import FollowWaypoints
from rclpy.action import ActionClient

class WaypointFollower:
    def __init__(self):
        self._action_client = ActionClient(
            self, FollowWaypoints, '/follow_waypoints'
        )

    def follow_waypoints(self, poses: list):
        goal = FollowWaypoints.Goal()
        goal.poses = poses
        self._action_client.wait_for_server()
        self._action_client.send_goal_async(goal)
```

---

## 代价地图配置

### 全局代价地图

```yaml
global_costmap:
  global_costmap:
    ros__parameters:
      footprint_padding: 0.05
      plugin_lib_names:
        - nav2_layered_plugins.CostmapPlugin
      update_frequency: 1.0
      publish_frequency: 1.0
      global_frame: map
      robot_base_frame: base_link
      resolution: 0.05
      track_unknown_space: true
      plugins:
        - plugin: nav2_costmap_2d_plugins.StaticLayer
        - plugin: nav2_costmap_2d_plugins.ObstacleLayer
          observation_sources: scan
          scan:
            topic: /scan
            max_obstacle_height: 2.0
            clearing: true
        - plugin: nav2_costmap_2d_plugins.VoxelLayer
          enabled: true
```

### 本地代价地图

```yaml
local_costmap:
  local_costmap:
    ros__parameters:
      update_frequency: 5.0
      publish_frequency: 2.0
      global_frame: odom
      robot_base_frame: base_link
      resolution: 0.05
      rolling_window: true
      width: 3
      height: 3
      plugins:
        - plugin: nav2_costmap_2d_plugins.ObstacleLayer
```

---

## 多机器人导航

### 命名空间隔离

```python
# launch/multi_robot.launch.py
def generate_multi_robot_launch(robot_names: list):
    nodes = []
    for name in robot_names:
        # 每个机器人有独立的节点组
        ns = f'/{name}'
        nodes.extend([
            Node(
                package='nav2_bringup',
                executable='navigation_launch',
                name='nav2_bringup',
                namespace=ns,
                parameters=[f'{name}_nav2_params.yaml'],
                remappings=[
                    ('/cmd_vel', f'{ns}/cmd_vel'),
                    ('/scan', f'{ns}/scan'),
                ],
            ),
        ])
    return LaunchDescription(nodes)
```

### 坐标系管理

```yaml
# 每个机器人使用独立的 map frame
amcl:
  ros__parameters:
    global_frame: $(var robot_name)/map
    robot_base_frame: $(var robot_name)/base_link
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 机器人不动 | 局部路径跟踪失败 | 检查 `/cmd_vel` 是否到达电机驱动 |
| 代价地图全红 | 传感器数据异常 | 检查 scan 话题是否有数据 |
| 路径绕远 | 全局规划器问题 | 切换 planner_plugin 或调参 |
| BT 超时 | 计算太慢 | 减小地图分辨率，简化行为树 |
| 恢复行为不停 | 环境确实不可通行 | 添加障碍物清理或手动干预 |

### 调试命令

```bash
# 查看 Nav2 状态
ros2 action list -t

# 查看代价地图
ros2 topic echo /local_costmap/costmap

# 发送导航目标
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose "{pose: {header: {frame_id: map}, pose: {position: {x: 2.0, y: 1.0}}}}"

# 运行时修改参数
ros2 param set /bt_navigator plugin_lib_names "['nav2_compute_path_to_pose_action_bt_node', 'nav2_follow_path_action_bt_node']"

# 查看行为树状态
ros2 topic echo /bt_navigator/transition_log
```

---

## 相关技能

- `navigation/slam` — SLAM 定位系统
- `navigation/obstacle-avoidance` — 动态避障
- `navigation/path-planning` — 路径规划算法
- `wheeled_vehicle/navigation` — 轮式车辆导航
- `quadruped/navigation` — 四足机器人导航
- `humanoid/navigation` — 人形机器人导航
