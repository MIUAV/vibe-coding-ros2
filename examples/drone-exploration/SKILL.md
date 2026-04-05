---
name: drone-exploration
description: 无人机自主探索任务 — 基于 Octomap 的未知环境快速建图，RRT* 路径规划，适用于搜救/巡检场景
argument-hint: 无人机 OR drone OR UAV OR exploration OR 探索 OR 自主导航 OR octomap OR RRT
user-invocable: true
---

# drone-exploration — 无人机自主探索 SKILL

## 任务描述

无人机在未知环境中自主探索，快速构建 3D 地图（Octomap），同时规划无碰撞飞行路径。

## 引用技能

- `agents/skills/navigation/` — 导航基础
- `agents/skills/perception/` — 感知（SLAM/Occupancy Grid）
- `agents/skills/motion-control/multi_rotor_uav/` — 飞控
- `agents/skills/ros2-debug/` — 调试
- `agents/skills/ros2-qos-checker/` — QoS（传感器数据用 BEST_EFFORT）

## 探索策略

### Next-Best-View (NBV)

```
1. 从 Octomap 计算前沿（frontier）— 已探索与未探索区域的边界
2. 对每个 frontier 计算信息增益（information gain）
3. 选择信息增益最大的 frontier 作为目标
4. RRT* 路径规划（无碰撞）
5. 执行飞行
```

### Octomap 参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 分辨率 | 0.1 m | 体素大小 |
| 最大范围 | 50 m | 传感器最大距离 |
| 占用阈值 | 0.5 | 体素占用概率 |
| 更新频率 | ≥ 10 Hz | 点云处理频率 |

### 无人机约束

| 参数 | 值 |
|------|-----|
| 最大速度 | 2 m/s |
| 最大加速度 | 1 m/s² |
| 飞行高度 | 2-30 m |
| 控制频率 | 50 Hz |
| 电池续航 | ~25 min |

## 禁止

- ❌ 探索速度超过 1 m/s（环境未知，安全优先）
- ❌ 在未完成局部规划时全速飞行
- ❌ 飞行高度低于 1.5m（地面效应）
- ❌ 传感器点云用 RELIABLE QoS（高频率，丢帧可接受）
