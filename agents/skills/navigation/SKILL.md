---
name: navigation
description: 机器人导航基础 — SLAM 建图、AMCL 定位、Nav2 路径规划、DWB/MPPI 控制器，适用于轮式/足式/无人机
argument-hint: 导航 OR navigation OR SLAM OR amcl OR Nav2 OR 路径规划 OR 全局路径
user-invocable: true
---

# navigation — 机器人导航 SKILL

## 引用技能

- `agents/skills/navigation/nav2-config/` — Nav2 参数速查
- `agents/skills/wheeled_vehicle/` — 轮式控制
- `agents/skills/ros2-qos-checker/` — QoS（cmd_vel 必须可靠）

## 导航架构

```
传感器 → SLAM/AMCL → 全局规划 → 局部规划 → 控制器 → cmd_vel → 机器人
```

## 关键约束

| 参数 | 值 |
|------|-----|
| cmd_vel QoS | RELIABLE（控制命令）|
| 最大线速度 | 0.5 m/s（室内）|
| 局部规划距离 | 3.0 m |

## 禁止

- ❌ cmd_vel 用 BEST_EFFORT（轮式控制会抖动）
- ❌ 膨胀半径 < 0.2m（安全余量不足）
