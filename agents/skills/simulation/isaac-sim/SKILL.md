---
name: isaac-sim
description: NVIDIA Isaac Sim 仿真 — PhysX 物理引擎、RTX 渲染、传感器仿真（RGB-D/Lidar/IMU），支持 USD 资产格式
argument-hint: Isaac Sim OR isaac-sim OR NVIDIA OR PhysX OR USD OR omniverse OR 仿真
user-invocable: true
---

# isaac-sim — NVIDIA Isaac Sim SKILL

## 引用技能

- `agents/skills/simulation/physics-simulation/`
- `agents/skills/ros2-debug/`

## Isaac Sim 与 ROS2 集成

Isaac Sim 支持 ROS2 的两种方式：

| 方式 | 说明 |
|------|------|
| ROS2 + Isaac Sim bridge | ROS2 节点 ↔ Isaac Sim 传感器 |
| ROS2 Humble (Humble) | 需 Isaac Sim 2023+ |

### ROS2 传感器桥接

```
ROS2 ←→ isaac_ros2_bridge ←→ Isaac Sim
         /scan               /laser_scan
         /camera/image_raw   /rgb
```

## 关键参数

| 参数 | 值 |
|------|-----|
| Physics timestep | 1/60 s |
| Rendering | RTX ON/OFF |
| GPU | 推荐 RTX 3080+ |

## 禁止

- ❌ 在 RTX 关闭下做传感器仿真（误差大）
- ❌ 不做 IMU 标定就用于真实机器人
