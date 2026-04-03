---
name: ros2-integration
description: Unreal Engine ROS2 集成技能 - ROS2 桥接、话题通信、动作接口
argument-hint: Unreal ROS2 OR ROS2桥接 OR 话题通信
user-invocable: true
---

# Unreal Engine ROS2 Integration Skill

> 用于 Unreal Engine 与 ROS2 的集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装 ROS2 桥接
- 配置话题通信
- 设置动作服务器
- 数据同步

---

## 快速参考

### 安装

```bash
# 安装 ROS2 Unreal Bridge
cd ~/ros2_ws/src
git clone https://github.com/ros2-unreal/ros2-unreal.git
colcon build
```

---

## 话题桥接

### 配置

```cpp
// 创建 ROS2 节点
URos2Node* node = NewObject<URos2Node>();
node->Init();

node->CreatePublisher("scan", "sensor_msgs/LaserScan");
node->CreateSubscriber("cmd_vel", "geometry_msgs/Twist");
```

---

## 常见问题

### 问题 1: 通信延迟

**解决方案**：减少消息频率，优化数据序列化

---

## 另见

- [project-setup](../project-setup/) - 项目设置
- [robot-integration](../robot-integration/) - 机器人集成