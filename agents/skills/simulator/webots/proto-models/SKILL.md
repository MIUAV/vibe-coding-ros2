---
name: proto-models
description: Webots PROTO 模型技能 - 创建自定义机器人模型、传感器原型
argument-hint: "Webots PROTO" / "机器人模型" / "传感器原型"
user-invocable: true
---

# Webots PROTO Models Skill

> 用于创建 Webots PROTO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建自定义 PROTO 模型
- 定义传感器原型
- 封装复用模块

---

## 快速参考

### 创建 PROTO

```protobuf
PROTO MyRobot [
  field SFVec3f    translation  0 0 0
  field SFRotation rotation     0 1 0 0
  field SFString   name          "my_robot"
]
{
  Robot {
    translation IS translation
    rotation IS rotation
    children [
      Solid { ... }
    ]
    name IS name
  }
}
```

---

## 另见

- [robot-controllers](../robot-controllers/) - 机器人控制器
- [ros2-integration](../ros2-integration/) - ROS2 集成