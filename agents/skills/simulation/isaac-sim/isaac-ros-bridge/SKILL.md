---
name: isaac-ros-bridge
description: Isaac ROS 桥接技能 - ROS2-Gazebo 桥接、Omnigraph、Graph 脚本
argument-hint: Isaac ROS OR ros2_bridge OR omni.graph OR bridge
user-invocable: true
---

# Isaac ROS 桥接技能

> Isaac Sim ROS2 桥接配置

---

## 何时使用

当需要以下帮助时使用此技能：
- ROS2 Isaac 桥接
- Omnigraph 配置
- Graph 脚本
- 传感器数据桥接
- 关节命令桥接

---

## 核心实现

### ROS2 桥接配置

```python
# isaac_ros_bridge.py
import rospy
from sensor_msgs.msg import Image, Imu, LaserScan
from geometry_msgs.msg import Twist

class IsaacROS_Bridge:
    def __init__(self):
        # 图像订阅/发布
        self.image_sub = rospy.Subscriber('/rgb_camera', Image, self.image_callback)
        self.image_pub = rospy.Publisher('/isaac/image', Image)
        
        # IMU
        self.imu_sub = rospy.Subscriber('/imu', Imu, self.imu_callback)
        
        # 激光雷达
        self.scan_pub = rospy.Publisher('/scan', LaserScan)
        
    def image_callback(self, msg):
        # 处理图像
        self.image_pub.publish(msg)
```

### Omnigraph 节点

```python
# Omnigraph Python API
import omni.graph.core as og

# 创建 Action graph
(ros_clock, _, _, _) = og.Controller.edit(
    "/World/ROS2Clock",
    {
        og.Controller.Keys.CREATE_NODES: [
            ("OnPlaybackTick", "omni.graph.action.OnPlaybackTick"),
            ("ReadSimTime", "omni.isaac.core_nodes.IsaacReadSimulationTime"),
            ("ROS2Context", "omni.isaac.ros2_bridge.ROS2Context"),
            ("ClockPublisher", "omni.isaac.ros2_bridge.ROS2PublishClock"),
        ],
        og.Controller.Keys.CONNECT: [
            ("OnPlaybackTick.outputs:tick", "ReadSimTime.inputs:execIn"),
            ("ReadSimTime.outputs:simulationTime", "ClockPublisher.inputs:time"),
            ("ROS2Context.outputs:context", "ClockPublisher.inputs:context"),
        ],
    },
)
```
