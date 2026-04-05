---
name: wheeled-nav2
description: 轮式机器人 Nav2 自主导航 — 从 SLAM 建图到目标点导航，包含路径规划、动态避障、行为树状态机
argument-hint: 轮式 OR wheeled OR 导航 OR Nav2 OR navigation OR SLAM OR amcl OR 路径规划 OR 动态避障
user-invocable: true
---

# wheeled-nav2 — 轮式机器人 Nav2 自主导航 SKILL

## 任务描述

轮式机器人在已知/未知环境中实现从 A 点到 B 点的自主导航，包含 SLAM 建图（可选）、定位、路径规划、动态避障。

## 引用技能

- `agents/skills/navigation/nav2-config/` — Nav2 参数速查
- `agents/skills/wheeled_vehicle/` — 轮式机器人控制
- `agents/skills/ros2-qos-checker/` — QoS（cmd_vel 必须 RELIABLE）
- `agents/skills/ros2-debug/` — 调试
- `agents/skills/ros2-cmake-guard/` — CMake

## 导航架构

```
目标点
  │
  ▼
Behavior Tree (bt_navigator)
  ├── ComputePathToPose ──► Planner (NavFn / Smac)
  ├── FollowPath ─────────► Controller (DWB / MPPI)
  ├── Spin ───────────────► 原地旋转
  ├── DriveOnHeading ────► 直线行进
  └── Wait ──────────────► 等待
          │
          ▼
   Controller (DWB)
          │
          ▼
    cmd_vel ──► diff_drive_controller ──► 轮子
```

## 核心参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 最大线速度 | 0.5 m/s | 安全速度 |
| 最大角速度 | 1.0 rad/s | |
| 规划超时 | 3.0 s | 全局路径规划超时 |
| 控制周期 | 10 Hz | 控制器输出频率 |
| 代价地图膨胀半径 | 0.3 m | 障碍物安全距离 |
| 局部规划距离 | 3.0 m | 前视距离 |

## 行为树节点

| 节点 | 作用 |
|------|------|
| `ComputePathToPose` | 全局路径规划 |
| `FollowPath` | 局部路径跟踪 |
| `Spin` | 原地旋转（目标方向校正）|
| `DriveOnHeading` | 直线前进 |
| `Wait` | 等待指定时间 |
| `IsPathValid` | 路径有效性检查 |

## 禁止

- ❌ cmd_vel 用 BEST_EFFORT（轮式控制命令必须可靠）
- ❌ 局部代价地图膨胀半径 < 0.2m（安全余量不足）
- ❌ 机器人速度 > 1.0 m/s（室内安全速度）
