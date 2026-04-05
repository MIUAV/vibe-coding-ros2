---
name: biped-walk
description: 双足机器人行走控制 — ZMP 零力矩点规划 + 步行周期生成，适用于人形机器人步态规划和平衡控制
argument-hint: 双足 OR biped OR 人形 OR walking OR 步态 OR ZMP OR 步行 OR 平衡控制
user-invocable: true
---

# biped-walk — 双足机器人步行控制 SKILL

## 任务描述

双足人形机器人实现稳定的周期性步行，包含 ZMP 零力矩点规划、步行周期生成、实时平衡控制。

## 引用技能

- `agents/skills/motion-control/humanoid/` — 人形机器人控制
- `agents/skills/ros2-debug/` — 调试
- `agents/skills/ros2-qos-checker/` — QoS

## 步行周期

```
SINGLE SUPPORT PHASE (SSP) — 单脚支撑
  └─ 支撑脚绕跟旋转，摆动腿向前迈步

DOUBLE SUPPORT PHASE (DSP) — 双脚支撑
  └─ 脚跟着地 → 脚掌着地 → 换脚

步行周期 = SSP + DSP
典型占空比 = 60% SSP / 40% DSP
```

## ZMP 约束

```
ZMP (Zero Moment Point) — 零力矩点

稳定条件: ZMP 必须在支撑多边形内
  └─ 单脚支撑: ZMP 在该脚支撑面内
  └─ 双脚支撑: ZMP 在两脚支撑多边形内

安全余量: ZMP 到支撑边界 > 0.02m
```

## 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 步长 | 0.15-0.25 m | 一步的长度 |
| 步高 | 0.05-0.10 m | 抬脚高度 |
| 步行速度 | 0.3-0.6 m/s | 安全速度 |
| 步频 | 0.8-1.5 Hz | 步行频率 |
| ZMP 安全余量 | > 0.02 m | 到支撑边界 |
| 脚底尺寸 | 0.12 × 0.24 m | 标准人形脚 |

## 禁止

- ❌ ZMP 在支撑多边形外（会摔倒）
- ❌ 步行速度 > 1.0 m/s（无辅助无法稳定）
- ❌ 关节力矩超限（会损坏电机）
- ❌ 在不平地面使用固定步长参数
