---
name: force-control
description: 力控制 — 力矩控制、力位混合控制、阻抗控制，适用于装配、磨抛、医疗机器人
argument-hint: 力控制 OR force control OR 力矩 OR impedance control OR 阻抗控制 OR hybrid force-position
user-invocable: true
---

# force-control — 力控制 SKILL

## 引用技能

- `agents/skills/motion-control/balance-control/`
- `agents/skills/ros2-debug/`

## 力位混合控制

```
F_total = Kp × (F_desired - F_measured) + ∫Ki × (F_desired - F_measured) × dt
```

## 阻抗控制

```
F = M × (ẍd - ẍ) + B × (ẋd - ẋ) + K × (xd - x)
```

| 参数 | 值 |
|------|-----|
| 刚度 K | 可调 (0-1000 N/m) |
| 阻尼 B | 可调 |
| 质量 M | 可调 |

## 禁止

- ❌ 不做力传感器标定就用（力控精度差）
- ❌ 力指令超电机额定力矩（损坏）
