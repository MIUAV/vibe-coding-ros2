---
name: ros2-communication
description: ROS2 通信机制 — Topic/Service/Action 对比、命名空间、QoS 选择、同步 vs 异步
argument-hint: ROS2 通信 OR topic OR service OR action OR namespace OR 通信模式
user-invocable: true
---

# ros2-communication — ROS2 通信 SKILL

## 通信对比

| 机制 | 模式 | 适用 |
|------|------|------|
| Topic | 发布/订阅 | 持续数据流 |
| Service | 请求/响应 | 一次性查询 |
| Action | Goal/Feedback/Result | 长时间任务 |

## QoS 选择

| 场景 | Reliability | Durability |
|------|-------------|------------|
| 控制命令 | RELIABLE | VOLATILE |
| Sensor 数据 | BEST_EFFORT | VOLATILE |
| Lifecycle 状态 | RELIABLE | TRANSIENT_LOCAL |

## 命名空间

```cpp
// 创建带命名空间的节点
rclcpp::NodeOptions opts;
opts.namespace("robot_1");
auto node = rclcpp::Node::make_shared("controller", opts);
// 话题: /robot_1/controller/cmd_vel
```

## 禁止

- ❌ Topic 用 Service 方式（阻塞）
- ❌ Service 里做长时间操作（超时）
