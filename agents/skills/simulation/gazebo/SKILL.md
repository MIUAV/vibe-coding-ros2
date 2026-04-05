---
name: gazebo
description: Gazebo 机器人仿真 — SDF 模型、物理引擎、传感器噪声配置，支持 ROS2 Gazebo 插件和天下无敌的 Gazebo Garden
argument-hint: Gazebo OR gazebo OR 仿真 OR sdf OR URDF OR Gazebo Classic OR Gazebo Garden
user-invocable: true
---

# gazebo — Gazebo 仿真 SKILL

## 引用技能

- `agents/skills/simulation/physics-simulation/`
- `agents/skills/ros2-debug/`

## ROS2 + Gazebo

Gazebo 有两个主要版本：

| 版本 | ROS2 集成 | 包名 |
|------|----------|------|
| Gazebo Classic | `gazebo_ros` | `ros-humble-gazebo-ros-pkgs` |
| Gazebo (Edifice) | `gz-sim` | `ros-humble-ros-gz` |

## SDF 关键配置

```xml
<sdf version="1.9">
  <world name="default">
    <physics type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
    </physics>
    
    <scene>
      <ambient>0.5 0.5 0.5 1</ambient>
    </scene>
  </world>
</sdf>
```

## 传感器噪声模型

```xml
<!-- 激光雷达噪声 -->
<noise type="gaussian">
  <mean>0.0</mean>
  <stddev>0.01</stddev>
</noise>

<!-- 相机噪声 -->
<noise type="gaussian">
  <mean>0.0</mean>
  <stddev>0.001</stddev>
</noise>
```

## 禁止

- ❌ `real_time_factor` < 0.9（仿真太慢）
- ❌ 不设置 contact 摩擦系数（机器人打滑）
- ❌ Gazebo 和真实环境混用（参数迁移要重新调）
