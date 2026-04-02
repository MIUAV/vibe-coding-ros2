---
name: ros2-integration
description: Webots ROS2 集成技能 - webots_ros2 包、话题订阅、服务调用
argument-hint: "Webots ROS2" / "ROS2集成" / "话题通信"
user-invocable: true
---

# Webots ROS2 Integration Skill

> 用于 Webots 与 ROS2 的集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装 webots_ros2
- 配置话题桥接
- 使用服务接口

---

## 快速参考

### 安装

```bash
# 安装
sudo apt install ros-humble-webots-ros2

# 或从源码
git clone https://github.com/cyberbotics/webots_ros2.git
cd webots_ros2
colcon build
```

---

## 话题通信

### 激光扫描

```python
from sensor_msgs.msg import LaserScan

def scan_callback(msg):
    print(f"Distance: {msg.ranges[0]}")
```

---

## 另见

- [proto-models](../proto-models/) - PROTO 模型
- [robot-controllers](../robot-controllers/) - 机器人控制器