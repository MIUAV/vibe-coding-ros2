# SKILL — uav_skill_planning

> 无人机任务规划技能

## Tools
- **waypoint_mission**: 航点任务（mission_executor, waypoint_marker）
- **area_coverage**: 区域覆盖算法（lawn_mower / spiral / random）
- **multi_uav_coordination**: 多机协同（swarm 协议, formation control）

## Usage
无人机任务规划，用于测绘、巡检、搜救场景：
- 地理栅格划分 + lawn_mower 覆盖路径
- MAVSDK / mavros 任务协议（DO_SET_MODE, MAV_CMD_NAV_*）
- 多机编队（leader-follower 距离保持）

## Tips
- 测绘任务：航向重叠率 80%，旁向重叠率 60%（Pix4D 标准）
- 紧急返航：低电量时自动触发 RTL（Return To Launch）
- 多机防撞：每架飞机广播 GPS + 高度，冲突检测半径 10m
