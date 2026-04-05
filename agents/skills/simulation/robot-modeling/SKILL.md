---
name: robot-modeling
description: 机器人建模 — URDF/SDF/Xacro 模型、惯性参数、碰撞几何、插件配置，适用于所有 ROS2 机器人
argument-hint: URDF OR SDF OR Xacro OR robot modeling OR 机器人建模 OR 碰撞几何 OR inertial
user-invocable: true
---

# robot-modeling — 机器人建模 SKILL

## 引用技能

- `agents/skills/simulation/physics-simulation/`
- `agents/skills/ros2-debug/`

## URDF 核心元素

```xml
<link name="base_link">
  <visual>   <!-- 渲染外观 -->
    <geometry><cylinder length="0.1" radius="0.1"/></geometry>
  </visual>
  <collision>  <!-- 碰撞检测 -->
    <geometry><cylinder length="0.1" radius="0.1"/></geometry>
  </collision>
  <inertial>  <!-- 质量分布 -->
    <mass value="5.0"/>
    <inertia ixx="0.01" ixy="0" ixz="0" iyy="0.01" iyz="0" izz="0.02"/>
  </inertial>
</link>

<joint name="base_to_wheel" type="continuous">
  <parent link="base_link"/>
  <child link="wheel"/>
  <origin xyz="0 0.1 0" rpy="0 0 0"/>
  <axis xyz="0 0 1"/>  <!-- 旋转轴 -->
</joint>
```

## 惯性参数

获取方法：
1. CAD 软件导出
2. SolidWorks 插件
3. 估算（球体=0.4mr²，圆柱=0.5mr²）

## 禁止

- ❌ 惯性张量写错（机器人行为异常）
- ❌ collision 和 visual 差太多（安全测试失真）
