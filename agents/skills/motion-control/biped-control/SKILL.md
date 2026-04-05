---
name: biped-control
description: 双足机器人步行控制 — ZMP 零力矩点规划、SSP/DSP 双支撑相、关节力矩限位，适用于人形机器人步态规划和平衡控制
argument-hint: 双足 OR biped OR 人形 OR 步行 OR ZMP OR 步态 OR balance control OR 平衡
user-invocable: true
---

# biped-control — 双足机器人步行控制 SKILL

## 引用技能

- `agents/skills/motion-control/balance-control/` — 平衡控制基础
- `agents/skills/ros2-debug/` — 调试

## 步行周期

```
SSP (Single Support Phase) — 单脚支撑
  摆动腿向前迈步，支撑脚绕跟旋转

DSP (Double Support Phase) — 双脚支撑
  脚跟着地 → 脚掌全接地 → 换脚

周期 = SSP + DSP
占空比 = 60% SSP / 40% DSP
```

## ZMP 约束

```
ZMP 必须在支撑多边形内
稳定条件: ZMP 到支撑边界 > 0.02m
```

## 关键参数

| 参数 | 值 |
|------|-----|
| 步长 | 0.15-0.25 m |
| 步高 | 0.05-0.10 m |
| 步行速度 | 0.3-0.6 m/s |
| 步频 | 0.8-1.5 Hz |
| ZMP 安全余量 | > 0.02m |

## 禁止

- ❌ ZMP 在支撑多边形外（摔倒）
- ❌ 步行速度 > 1.0 m/s（无辅助无法稳定）
- ❌ 关节力矩超限
