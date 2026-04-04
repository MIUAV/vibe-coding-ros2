---
name: ros2-qos-checker
description: ROS2 QoS兼容性检测技能 - 诊断发布/订阅QoS不匹配、sensor_dataQoS/reliable配置、话题带宽分析
argument-hint: QoS OR sensor_dataQoS OR reliable OR BestEffort OR TransientLocal OR QoS不兼容 OR 话题带宽
user-invocable: true
---

# ROS2 QoS 检查技能

> 用于检测和修复 ROS2 发布/订阅之间的 QoS 不兼容问题

---

## 一、QoS 兼容性矩阵

### History

| 设置 | 效果 |
|------|------|
| Keep last N (depth) | 缓存 N 条消息给迟到的订阅者 |
| Keep all | 保留所有历史（内存开销大） |

### Reliability

| 发布者 | 订阅者 | 结果 |
|--------|--------|------|
| Reliable | Reliable | ✅ 兼容 |
| Reliable | BestEffort | ✅ 兼容（订阅者更宽松） |
| BestEffort | Reliable | ❌ **不兼容** — 发布者允许丢，订阅者要求不丢，静默丢数据 |
| BestEffort | BestEffort | ✅ 兼容 |

### Durability

| 发布者 | 订阅者 | 结果 |
|--------|--------|------|
| Volatile | Volatile | ✅ 兼容（不保留历史） |
| Volatile | TransientLocal | ❌ **不兼容** — 订阅者要历史，但发布者不保留 |
| TransientLocal | TransientLocal | ✅ 兼容 |
| TransientLocal | Volatile | ✅ 兼容（订阅者更宽松） |

---

## 二、ROS2 内置 QoS 配置文件

| 配置 | Reliability | Durability | Depth | 适用场景 |
|------|-------------|------------|-------|----------|
| `sensor_dataQoS()` | BestEffort | Volatile | 5 | **激光、相机、IMU** |
| `parametersQoS()` | Reliable | Volatile | 1000 | 参数服务 |
| `Services default` | Reliable | Volatile | 10 | Service 调用 |
| `Default` | Reliable | Volatile | 10 | 一般用途 |

---

## 三、诊断命令

### 3.1 查看话题 QoS

```bash
ros2 topic info /scan --verbose

# 输出示例：
# Type: sensor_msgs/msg/LaserScan
# Publisher count: 1
#     QoS:
#       Reliability: BEST_EFFORT        ← 传感器用 BestEffort
#       Durability: VOLATILE
#       History: KEEP_LAST
#       Depth: 5
# Subscription count: 1
#     QoS:
#       Reliability: RELIABLE          ← 错误！应该也是 BestEffort
#       Durability: VOLATILE
#       History: KEEP_LAST
#       Depth: 5
```

### 3.2 常见不兼容场景

**场景 1：相机发布者用默认 Reliable，rviz2 订阅用 Transient Local**

```
发布者: Reliable + Volatile
订阅者: Reliable + TransientLocal
结果: ❌ 订阅者永远收不到历史数据（因为发布者 Volatile 不保留）
```

**场景 2：激光发布者用 BestEffort，调试工具用 Reliable**

```
发布者: BestEffort + Volatile    ← 正确（高频传感器）
订阅者: Reliable + Volatile
结果: ✅ 兼容（订阅者更宽松）
```

---

## 四、修复方法

### 4.1 传感器数据（激光、相机、IMU）

```cpp
// 发布端必须用 sensor_dataQoS()
rclcpp::QoS qos_sensor = rclcpp::SensorDataQoS();
qos_sensor.best_effort();      // 显式设置
qos_sensor.durability_volatile();

publisher_ = this->create_publisher<sensor_msgs::msg::LaserScan>("/scan", qos_sensor);
```

### 4.2 控制命令（速度、位置）

```cpp
// 控制命令必须可靠
rclcpp::QoS qos_cmd(10);
qos_cmd.reliable();             // 不能丢命令
qos_cmd.durability_volatile();

publisher_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", qos_cmd);
```

### 4.3 地图数据（需要迟到订阅者也收到）

```cpp
// 地图服务用 transient_local
rclcpp::QoS qos_map(1);
qos_map.reliable();
qos_map.transient_local();      // 新订阅者也收到最后一条

publisher_ = this->create_publisher<nav_msgs::msg::OccupancyGrid>("/map", qos_map);
```

---

## 五、Python QoS 设置

```python
from rclpy.qos import QoSProfile, QoSReliabilityPolicy, QoSDurabilityPolicy

# 传感器数据
qos_sensor = QoSProfile(
    reliability=QoSReliabilityPolicy.BEST_EFFORT,
    durability=QoSDurabilityPolicy.VOLATILE,
    depth=5
)

# 控制命令
qos_cmd = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.VOLATILE,
    depth=10
)

# 地图
qos_map = QoSProfile(
    reliability=QoSReliabilityPolicy.RELIABLE,
    durability=QoSDurabilityPolicy.TRANSIENT_LOCAL,
    depth=1
)

self.publisher_ = self.create_publisher(Msg, '/topic', qos_sensor)
```

---

## 六、ros2 topic pub 设置 QoS

```bash
# 测试 BestEffort 发布
ros2 topic pub /scan sensor_msgs/msg/LaserScan '{}' \
  --once -r 10 \
  --qos-reliability best_effort

# 测试 Reliable 发布
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist '{}' \
  --once \
  --qos-reliability reliable

# 设置 TransientLocal
ros2 topic pub /map nav_msgs/msg/OccupancyGrid '{}' \
  --once \
  --qos-durability transient_local
```

---

## 七、AI 生成代码时的 QoS 检查

AI 生成 ROS2 节点时，必须对以下话题检查 QoS：

| 话题类型 | 必须用 QoS |
|----------|------------|
| `/scan` | `sensor_dataQoS()` |
| `/image_raw` | `sensor_dataQoS()` |
| `/depth/image_raw` | `sensor_dataQoS()` |
| `/imu/data` | `sensor_dataQoS()` |
| `/cmd_vel` | Reliable |
| `/plan` | Reliable |
| `/map` | `transient_local()` |
| `/parameter_events` | `parametersQoS()` |

### 检查清单

- [ ] 传感器话题（scan/image/imu）使用 `sensor_dataQoS()`
- [ ] 控制话题（cmd_vel）使用 `reliable()`
- [ ] 地图话题使用 `transient_local()`
- [ ] 发布端和订阅端 QoS 兼容
