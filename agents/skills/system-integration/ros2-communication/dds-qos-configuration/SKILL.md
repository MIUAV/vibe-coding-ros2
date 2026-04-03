---
name: dds-qos-configuration
description: DDS QoS 配置技能 - QoS 策略、可靠性、持久性、 Deadline、Lifespan
argument-hint: QoS OR DDS OR reliability OR durability OR deadline
user-invocable: true
---

# DDS QoS 配置技能

> ROS2 DDS QoS 策略配置

---

## 何时使用

当需要以下帮助时使用此技能：
- QoS 策略选择
- 可靠性配置
- 持久性配置
- Deadline 和 Liveliness
- 话题兼容性

---

## 核心 QoS 配置

### QoS 策略表

| 策略 | 描述 | 典型用途 |
|------|------|---------|
| Reliability | 可靠 vs 最大努力 | 可靠: 控制命令; 最大努力: 传感器数据 |
| Durability | 持久性 | 服务端: Volatile; 订阅者需要历史: TransientLocal |
| Deadline | 周期期望 | 传感器: 10ms; 控制: 20ms |
| Liveliness | 节点存活性 | 确保通信伙伴存活 |
| History | 历史深度 | KeepLast(n), KeepAll |

### ROS2 QoS 配置

```python
import rclpy
from rclpy.node import Node
from rclpy.qos import (
    QoSProfile, ReliabilityPolicy, DurabilityPolicy,
    HistoryPolicy, DeadlinePolicy
)

class QoSExample(Node):
    def __init__(self):
        super().__init__('qos_example')
        
        # 传感器数据 - 快速但不要求完全可靠
        sensor_qos = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=5,
            deadline=DeadlinePolicy(duration=0.1)
        )
        
        self.lidar_sub = self.create_subscription(
            LaserScan, '/lidar/scan', self.lidar_callback,
            qos_profile=sensor_qos)
            
        # 控制命令 - 必须可靠
        control_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=1,
            deadline=DeadlinePolicy(duration=0.02)
        )
        
        self.cmd_pub = self.create_publisher(
            Twist, '/cmd_vel', qos_profile=control_qos)
            
        # 地图数据 - 需要持久性
        map_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.TRANSIENT_LOCAL,
            history=HistoryPolicy.KEEP_ALL
        )
        
        self.map_pub = self.create_publisher(
            OccupancyGrid, '/map', qos_profile=map_qos)
```

### DDS XML 配置

```xml
<!-- dds_qos.xml -->
<dds>
  <profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPSProfiles">
    
    <!-- 可靠发布者 -->
    <publisher profile_name="reliable_publisher">
      <qos>
        <reliability>
          <kind>RELIABLE</kind>
        </reliability>
        <durability>
          <kind>VOLATILE_DURABILITY_QOS</kind>
        </durability>
        <deadline>
          <period>20000000</period>  <!-- 20ms -->
        </deadline>
      </qos>
    </publisher>
    
    <!-- 持久订阅者 -->
    <subscriber profile_name="durable_subscriber">
      <qos>
        <reliability>
          <kind>RELIABLE</kind>
        </reliability>
        <durability>
          <kind>TRANSIENT_LOCAL_DURABILITY_QOS</kind>
        </durability>
      </qos>
    </subscriber>
    
  </profiles>
</dds>
```

### QoS 兼容性检查

```python
class QoSCompatibility:
    @staticmethod
    def are_compatible(pub_qos, sub_qos):
        """检查发布者和订阅者 QoS 是否兼容"""
        
        # 可靠性兼容性
        if pub_qos.reliability == ReliabilityPolicy.RELIABLE:
            # 可靠发布者可以和任何订阅者通信
            pass
        else:
            # 最大努力发布者只能和最大努力订阅者通信
            if sub_qos.reliability != ReliabilityPolicy.BEST_EFFORT:
                return False
                
        # 持久性兼容性
        if sub_qos.durability == DurabilityPolicy.TRANSIENT_LOCAL:
            # 订阅者要求持久性，发布者必须是 TRANSIENT_LOCAL
            if pub_qos.durability != DurabilityPolicy.TRANSIENT_LOCAL:
                return False
                
        return True
```
