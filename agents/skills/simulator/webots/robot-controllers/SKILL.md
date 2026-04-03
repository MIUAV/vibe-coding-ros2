---
name: robot-controllers
description: Webots 机器人控制器技能 - Python/C++ 控制器、电机控制、传感器读取
argument-hint: Webots控制器 OR 电机控制 OR 传感器读取
user-invocable: true
---

# Webots Robot Controllers Skill

> 用于开发 Webots 机器人控制器

---

## 何时使用

当需要以下帮助时使用此技能：
- 编写机器人控制器
- 控制电机运动
- 读取传感器数据

---

## 快速参考

### Python 控制器

```python
from controller import Robot, Motor, Lidar

robot = Robot()
timestep = int(robot.getBasicTimeStep())

# 获取设备
motor = robot.getMotor('left wheel')
lidar = robot.getLidar('lidar')

# 主循环
while robot.step(timestep) != -1:
    motor.setVelocity(1.0)
```

---

## 控制器类型

### 差速驱动

```python
class DiffDriveController:
    def __init__(self, robot):
        self.left_motor = robot.getMotor('left wheel')
        self.right_motor = robot.getMotor('right wheel')
        
    def move(self, linear, angular):
        v_left = linear - angular * self.wheel_separation / 2
        v_right = linear + angular * self.wheel_separation / 2
        self.left_motor.setVelocity(v_left)
        self.right_motor.setVelocity(v_right)
```

---

## 另见

- [proto-models](../proto-models/) - PROTO 模型
- [ros2-integration](../ros2-integration/) - ROS2 集成