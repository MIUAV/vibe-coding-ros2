# Navigation Task Context

## 导航范式
| 范式 | 工具 | 适用场景 |
|------|------|---------|
| 2D 导航 | Nav2 + costmap_2d | 室内轮式 |
| 3D 导航 | Nav2 + voxel_grid | 室外/无人机 |
| 视觉导航 | VSLAM (ORB-SLAM3/VINS) | 无 GPS |
| 组合导航 | GNSS + 视觉/激光融合 | 室外 |

## Nav2 核心组件
```
nav2_controller     → 轨迹跟踪（前进、恢复策略）
nav2_planner        → 全局路径规划（Dijkstra/A*/RRT*）
nav2_behavior_tree  → 决策逻辑（充电、停障、恢复）
nav2_costmap_2d     → 栅格地图（障碍物层、膨胀层）
nav2_map_server     → 地图加载（pgm/yaml）
nav2_lifecycle_mgr   → 生命周期管理
```

## 关键 Topic
| Topic | 类型 | 说明 |
|-------|------|------|
| `/nav2_runtime_stats` | `nav2_msgs/RuntimeData` | Nav2 运行时统计 |
| `/compute_path_to_pose` | `nav2_msgs/srv/ComputePathToPose` | 全局规划服务 |
| `/follow_path` | `nav2_msgs/action/FollowPath` | 轨迹跟踪动作 |

## Nav2 Lifecycle 启动顺序
```bash
# 正确顺序（按 lifecycle 依赖）
ros2 launch nav2_map_server map_server.launch.py
ros2 launch nav2_planner planner.launch.py
ros2 launch nav2_controller controller.launch.py
ros2 launch nav2_navigator navigator.launch.py
# 或用 bringup 统一启动
ros2 launch nav2_bringup bringup_launch.py
```

## 常见故障排查
| 症状 | 原因 | 解决 |
|------|------|------|
| 机器人不动，路径正常 | `/cmd_vel` 无数据 | controller 未激活，检查 `ros2 lifecycle get /controller` |
| 不绕行障碍物 | costmap update_frequency 太低 | 调高 `update_frequency: 10.0` |
| 导航崩溃 | lifecycle_manager 未激活 | 确保 lifecycle 顺序正确 |
| 地图偏移 | SLAM 漂移 | 检查 IMU 和里程计融合 |
