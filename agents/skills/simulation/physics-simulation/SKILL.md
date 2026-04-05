---
name: physics-simulation
description: 物理仿真基础 — 刚体动力学、接触力、摩擦模型、关节约束，适用于 Gazebo/Mujoco/Isaac Sim
argument-hint: 物理仿真 OR physics simulation OR 刚体 OR dynamics OR 接触力 OR friction OR 关节约束
user-invocable: true
---

# physics-simulation — 物理仿真基础 SKILL

## 引用技能

- `agents/skills/simulation/gazebo/`
- `agents/skills/simulation/mujoco/`
- `agents/skills/ros2-debug/`

## 刚体动力学

```
M × ä + C × á + g = F_external + F_contact
```

| 参数 | 说明 |
|------|------|
| M | 质量矩阵 |
| C | 科里奥利矩阵 |
| g | 重力向量 |
| F_contact | 接触力 |

## 接触力模型

```
F_normal = k × penetration^e
F_friction = μ × F_normal × tangent_velocity
```

## 禁止

- ❌ 摩擦系数设错（机器人打滑或卡死）
- ❌ 质量/惯性张量错误（行为异常）
