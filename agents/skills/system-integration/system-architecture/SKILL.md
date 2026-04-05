---
name: system-architecture
description: 系统架构设计 — 模块划分、接口定义、状态机设计、故障诊断树，适用于 ROS2 机器人应用架构
argument-hint: 系统架构 OR system architecture OR 模块化 OR 接口设计 OR 故障诊断 OR fault tree
user-invocable: true
---

# system-architecture — 系统架构 SKILL

## 引用技能

- `agents/skills/motion-control/`
- `agents/skills/navigation/`
- `agents/skills/system-integration/lifecycle-management/`

## 模块划分原则

```
按职责分：感知 → 决策 → 控制
按频率分：传感器(100Hz) → 规划(10Hz) → 控制(400Hz)
```

## 接口定义

```yaml
# 模块间接口（ROS2 msg/srv/action）
interfaces:
  sensor_to_perception:
    topic: /sensor/raw
    type: sensor_msgs/PointCloud2
    qos: BEST_EFFORT

  perception_to_planning:
    topic: /obstacles
    type: geometry_msgs/PolygonArray
    qos: RELIABLE

  planning_to_control:
    action: /navigate
    type: nav2_msgs/action/NavigateToPose
```

## 禁止

- ❌ 模块间通过全局变量通信（不用 ROS2 接口）
- ❌ 接口版本不管理（不同版本兼容性问题）
