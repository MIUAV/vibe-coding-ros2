---
name: manipulator-pickplace
description: 机械臂抓取放置任务 — 视觉定位 + MoveIt! 运动规划 + 夹爪控制，适用于物流/制造业中的物品分拣
argument-hint: 机械臂 OR manipulator OR pickplace OR 抓取 OR MoveIt OR 运动规划 OR 夹爪
user-invocable: true
---

# manipulator-pickplace — 机械臂抓取放置 SKILL

## 任务描述

机械臂从货架抓取物品并放置到目标位置。包含：视觉定位、运动规划、抓取执行、放置动作。

## 引用技能

- `agents/skills/manipulation/` — 机械臂控制基础
- `agents/skills/perception/` — 视觉感知
- `agents/skills/motion-control/` — 运动规划
- `agents/skills/ros2-debug/` — 调试
- `agents/skills/navigation/nav2-config/` — Nav2 配置参考

## 任务流程

```
1. 视觉定位 → 目标物体位置 (x, y, z, roll, pitch, yaw)
2. 运动规划 → 无碰撞轨迹（MoveIt!）
3. 接近 → pre-grasp 位置（物体前方 0.1m）
4. 下降 → grasp 位置（物体上方 0.02m）
5. 夹爪闭合 → 抓取
6. 提升 → 安全高度
7. 移动 → 目标位置上方
8. 下降 → 放置位置
9. 夹爪打开 → 释放
10. 撤回 → 安全位置
```

## 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 夹爪开度 | 0.03m | 抓取物体直径范围 |
| 接近距离 | 0.1m | 接近速度 0.1 m/s |
| 抓取力 | 5N | 夹爪抓力 |
| 运动速度 | 0.2 m/s | 安全速度上限 |
| 规划超时 | 3s | MoveIt! 规划超时 |

## 抓取姿态约束

- [ ] 抓取方向：优先从上方接近（重力方向）
- [ ] 避碰：夹爪不能碰到货架
- [ ] 奇异点：避开腕部奇异配置
- [ ] 限位：每个关节在物理范围内

## 禁止

- ❌ 不做碰撞检测直接规划
- ❌ 运动速度超过 0.5 m/s
- ❌ 抓取力超过夹爪额定值（通常 10-20N）
- ❌ 在目标位置无确认的情况下夹爪闭合
