---
name: simulation
description: 机器人仿真环境 — Gazebo/Mujoco/Isaac Sim 对比、仿真-真实差距、时钟同步，适用于所有仿真需求
argument-hint: 仿真 OR simulation OR Gazebo OR Mujoco OR isaac OR 仿真器 OR 环境配置
user-invocable: true
---

# simulation — 机器人仿真 SKILL

## 仿真器对比

| 仿真器 | 适用场景 | 物理 | 渲染 |
|---------|---------|------|------|
| Gazebo Classic | ROS2 集成好 | ODE/PhysX | 基础 |
| Gazebo (Garden) | 室外/光线 | PhysX | RTX |
| Mujoco | 接触密集任务 | 优化 | 无（可视化单独）|
| Isaac Sim | NVIDIA GPU | PhysX | RTX |

## 仿真-真实差距

```
物理参数: 摩擦系数/质量/惯性张量  ≠ 真实
传感器噪声: 需要精确建模
时钟同步: /clock 必须正确
```

## 禁止

- ❌ 仿真参数直接用于真实机器人
- ❌ /clock 不同步（数据错位）
