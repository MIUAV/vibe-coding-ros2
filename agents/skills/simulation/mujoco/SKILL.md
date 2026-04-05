---
name: mujoco
description: Mujoco 物理仿真环境 — 接触动力学、肌肉驱动、物理约束配置，支持人形/机械臂/四足等刚体仿真
argument-hint: Mujoco OR mujoco OR 物理仿真 OR physics simulation OR 接触力 OR 肌肉驱动
user-invocable: true
---

# mujoco — Mujoco 物理仿真 SKILL

## 引用技能

- `agents/skills/simulation/physics-simulation/` — 物理仿真基础
- `agents/skills/ros2-debug/` — 调试

##Mujoco 与 ROS2 集成

Mujoco 通常不直接通过 ROS2 接口使用，而是作为独立仿真器，通过两种方式集成：

```python
# 方式1: mujoco_、同步 pyMJ cf. 方式2: 调用 mujoco 仿真器（不依赖 ROS）
import mujoco
```

### ROS2 + Mujoco 桥接

```
ROS2 节点 ←→ mujoco_ros2_plugin ←→ Mujoco 物理引擎
```

## 关键配置

### MJCF 模型文件

```xml
<mujoco model="robot">
  <compiler angle="degree" meshdir="meshes/"/>
  <option timestep="0.002" iterations="50" solver="Newton"/>
  
  <worldbody>
    <light diffuse=".5 .5 .5" pos="0 0 3" dir="0 0 -1"/>
    <geom type="plane" size="10 10 0.1" rgba=".9 .9 .9 1"/>
  </worldbody>
</mujoco>
```

## 禁止

- ❌ timestep > 0.005（数值不稳定）
- ❌ 不设置 contact 参数（穿透问题）
- ❌ Mujoco用作实时控制（仿真≠真实）
