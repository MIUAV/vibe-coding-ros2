---
name: vehicle-dynamics
description: CARLA 车辆动力学仿真 — 轮胎模型、动力传动、车辆物理参数配置，支持 CARLA-ROS2 桥接
argument-hint: CARLA 车辆 OR vehicle dynamics OR 车辆动力学 OR 轮胎模型 OR carla
user-invocable: true
---

# vehicle-dynamics — CARLA 车辆动力学 SKILL

## 引用技能

- `agents/skills/simulation/gazebo/`
- `agents/skills/ros2-debug/`

## CARLA 车辆配置

```python
# 设置车辆物理参数
vehicle_physics = carla.VehiclePhysicsControl(
    torque_curve=[(0, 500), (3000, 800)],
    max_rpm=6000,
    drag_coefficient=0.3,
    center_of_mass=carla.Vector3D(0, 0, -0.5),
)
```

## 轮胎模型

```python
# Pacejka 轮胎模型参数
wheel_friction=0.8,
roll_friction=0.1,
```

## ROS2 桥接

```python
# CARLA → ROS2
carla_ros_bridge  # 自动桥接
/carla/vehicle/odometry → /odom
/carla/vehicle/cmd_vel → /cmd_vel
```

## 禁止

- ❌ 不做车辆参数标定就用（与真实车行为差异大）
