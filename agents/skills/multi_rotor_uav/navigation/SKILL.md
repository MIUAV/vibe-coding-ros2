# SKILL — uav_navigation

> 无人机导航技能

## Tools
- **nav2_core**: Nav2 核心（planner + controller + behavior_tree）
- **path_planning**: A*/RRT* 全局路径规划（swarm_nav / smac_planner）
- **ekf_nav**: 无人机 EKF 位姿估计（robot_localization）

## Usage
无人机自主导航，室外 GPS + 室内 VIO 混合：
- Nav2 + MoveBase 替代品（behavior_tree_navigation）
- 全局规划：smac_planner_ros（支持 A*, Dijkstra, Hybrid-A*）
- 局部规划：DWB Controller（差速驱动 / 全向轮）

## Tips
- 无人机航迹跟踪：APF（人工势场）或 Pure Pursuit + PID 高度
- GPS 失效区：提前切换 VIO，使用 ` bonded` 标记触发切换
- 障碍物感知：使用 voxel_grid 过滤地面障碍，检测低空障碍物
- 多层规划：全局路径（1Hz）+ 局部避障（10Hz）分离
