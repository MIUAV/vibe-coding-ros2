---
name: ros2-qos-checker
description: ROS2 QoS 兼容性检测 — Reliability/Durability/Deadline/Lifespan 四个维度的兼容性判断，控制命令/sensor数据/lifecycle节点的 QoS 配置规则
argument-hint: QoS不兼容 OR ros2 topic info OR BEST_EFFORT OR RELIABLE OR TRANSIENT_LOCAL OR 话题收不到数据
user-invocable: true
---

# ros2-qos-checker — QoS 兼容性检测

## 目的

ROS2 的 QoS (Quality of Service) 策略不匹配是静默故障：发布和订阅都成功，但数据永远不过去。本技能用于：
1. 列出话题的 QoS 配置
2. 检测发布/订阅两端的 QoS 兼容性
3. 给出修复建议

## 强制规则

### 🔴 发布者与订阅者 QoS 必须兼容

ROS2 QoS 有 4 个关键维度：

| 维度 | 选项 | 影响 |
|------|------|------|
| Reliability | RELIABLE / BEST_EFFORT | BEST_EFFORT 可能丢包，RELIABLE 保证交付 |
| Durability | TRANSIENT_LOCAL / VOLATILE | TRANSIENT_LOCAL 保留旧数据给晚加入的订阅者 |
| Deadline | Duration (默认 infinite) | 超过则报错 |
| Lifespan | Duration (默认 infinite) | 超过则丢弃 |

### 兼容性矩阵

```
Publisher \ Subscriber | RELIABLE | BEST_EFFORT |
-----------------------|----------|-------------|
RELIABLE               | ✅ 兼容  | ⚠️ 只发一次  |
BEST_EFFORT            | ⚠️ 不推荐 | ✅ 兼容     |

Durability: TRANSIENT_LOCAL 订阅者 只能接收 TRANSIENT_LOCAL 发布者的数据
```

## 使用方法

### 1. 列出话题 QoS

```bash
ros2 topic info /scan --verbose
```

输出示例：
```
Type: sensor_msgs/msg/LaserScan
Publisher count: 1
Reliability: BEST_EFFORT
Durability: VOLATILE
Depth: 5
```

### 2. 运行时检测（rqt）

```bash
ros2 run rqt_qos_collector rqt_qos_collector
# 或
ros2 run rqt_publisher rqt_publisher
```

### 3. 编程检测

```python
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, DurabilityPolicy

class QoSChecker(Node):
    def __init__(self):
        super().__init__('qos_checker')
        # sensor 数据用 BEST_EFFORT
        sensor_qos = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE,
            depth=10
        )
        self.create_subscription(
            LaserScan, '/scan', self.cb, sensor_qos)
    
    def cb(self, msg):
        pass  # 收到数据说明 QoS 兼容
```

## QoS 选择指南

### 控制命令（position/velocity/torque）
```cpp
QoS qos(10);
qos.reliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);      // 必须可靠，不能丢命令
qos.durability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
```
❌ 禁止用 BEST_EFFORT — 丢命令会导致机器人失控。

### Sensor 数据（laser scan / camera / IMU）
```cpp
QoS qos(10);
qos.reliability(RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT); // 允许丢帧，保证实时性
qos.durability(RMW_QOS_POLICY_DURABILITY_VOLATILE);
```
✅ BEST_EFFORT 适合传感器 — 丢了下一帧就来了。

### Lifecycle 节点状态
```cpp
QoS qos(10);
qos.reliability(RMW_QOS_POLICY_RELIABILITY_RELIABLE);
qos.durability(RMW_QOS_POLICY_DURABILITY_TRANSIENT_LOCAL); // 新订阅者能收到最近状态
```
TRANSIENT_LOCAL 让晚加入的订阅者收到最近一次数据（如当前机器人位置）。

## 常见错误

### ❌ LaserScan 收不到数据

原因：sensor_msgs 默认用 RELIABLE，但 `rplidar` 驱动用 BEST_EFFORT 发布。

解决：订阅端强制改 QoS：
```python
sub_qos = QoSProfile(reliability=ReliabilityPolicy.BEST_EFFORT, depth=10)
self.create_subscription(LaserScan, '/scan', self.cb, sub_qos)
```

### ❌ Lifecycle 节点状态不更新

原因：新订阅者用 VOLATILE，无法接收已发布的状态。

解决：订阅端用 TRANSIENT_LOCAL：
```python
qos.durability(DurabilityPolicy.TRANSIENT_LOCAL)
```

## AI 生成代码时的强制检查

生成 ROS2 发布/订阅代码时，必须在注释中写明 QoS 选择理由：

```cpp
// QoS: RELIABLE + VOLATILE — 控制命令，不能丢包
auto pub = this->create_publisher<JointCommand>("/arm/command", 
    QoS(10).reliable());
```

没有 QoS 注释的代码，AI 必须默认用 RELIABLE（ROS2 默认值）。
