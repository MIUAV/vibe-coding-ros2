---
name: px4-ros2
description: PX4 ROS2 集成与控制 - MAVROS/mavros2 配置、Offboard 控制、话题订阅发布
argument-hint: "PX4 ROS2" / "MAVROS" / "Offboard控制" / "无人机ROS"
user-invocable: true
---

# PX4 ROS2 集成技能

> 用于将 PX4 与 ROS2 系统集成实现自主控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 MAVROS/mavros2
- 通过 ROS2 控制无人机
- 订阅 PX4 话题
- 实现 Offboard 模式控制

---

## 快速参考

### 安装 MAVROS

```bash
# ROS2 安装
sudo apt install ros-${ROS_DISTRO}-mavros ros-${ROS_DISTRO}-mavros-extras

# 安装 mavros 工具
sudo apt install mavros-utils
```

### 启动 MAVROS

```bash
# 通过 UDP 连接 SITL
ros2 launch mavros px4.launch fcu_url:="udp://:14540@"

# 通过 UDP 连接真实飞控
ros2 launch mavros px4.launch fcu_url:="udp://192.168.1.1:14550@"

# 通过串口连接
ros2 launch mavros px4.launch fcu_url:="/dev/ttyUSB0:921600"
```

---

## MAVROS 节点

### 话题订阅

| 话题 | 类型 | 说明 |
|------|------|------|
| `/mavros/state` | `mavros_msgs/State` | 连接状态 |
| `/mavros/local_position/pose` | `geometry_msgs/PoseStamped` | 局部位置 |
| `/mavros/global_position/global` | `sensor_msgs/NavSatFix` | GPS 位置 |
| `/mavros/imu/data` | `sensor_msgs/Imu` | IMU 数据 |
| `/mavros/battery` | `sensor_msgs/BatteryState` | 电池状态 |
| `/mavros/rc/in` | `mavros_msgs/RCIn` | 遥控输入 |

### 话题发布

| 话题 | 类型 | 说明 |
|------|------|------|
| `/mavros/setpoint_position/local` | `geometry_msgs/PoseStamped` | 位置目标 |
| `/mavros/setpoint_velocity/cmd_vel` | `geometry_msgs/Twist` | 速度目标 |
| `/mavros/setpoint_raw/attitude` | `mavros_msgs/AttitudeTarget` | 姿态目标 |
| `/mavros/cmd/arming` | `mavros_msgs/CommandBool` | 解锁/锁定 |
| `/mavros/cmd/land` | `mavros_msgs/CommandVtolTransition` | 降落 |
| `/mavros/cmd/takeoff` | `mavros_msgs/CommandTOL` | 起飞 |

---

## Offboard 控制示例

### 节点模板 (Python)

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import PoseStamped
from mavros_msgs.srv import CommandBool, SetMode
from mavros_msgs.msg import State

class OffboardNode(Node):
    def __init__(self):
        super().__init__('offboard_node')
        
        # 状态订阅
        self.state_sub = self.create_subscription(
            State,
            '/mavros/state',
            self.state_callback)
        
        # 位置发布
        self.pos_pub = self.create_publisher(
            PoseStamped,
            '/mavros/setpoint_position/local',
            10)
        
        # 服务客户端
        self.arm_client = self.create_client(CommandBool, '/mavros/cmd/arming')
        self.mode_client = self.create_client(SetMode, '/mavros/set_mode')
        
        self.connected = False
        self.armed = False
        
    def state_callback(self, msg):
        self.connected = msg.connected
        self.armed = msg.armed
        
    def send_position(self, x, y, z):
        pose = PoseStamped()
        pose.header.stamp = self.get_clock().now().to_msg()
        pose.pose.position.x = x
        pose.pose.position.y = y
        pose.pose.position.z = z
        self.pos_pub.publish(pose)
```

---

## 起飞降落

### 起飞命令

```bash
# 通过 service
ros2 service call /mavros/cmd/takeoff mavros_msgs/srv/CommandTOL \
  "{min_pitch: 0.0, yaw: 0.0, latitude: 0.0, longitude: 0.0, altitude: 2.0}"
```

### 降落命令

```bash
ros2 service call /mavros/cmd/land mavros_msgs/srv/CommandTOL \
  "{min_pitch: 0.0, yaw: 0.0, latitude: 0.0, longitude: 0.0, altitude: 0.0}"
```

### 解锁/锁定

```bash
# 解锁
ros2 service call /mavros/cmd/arming mavros_msgs/srv/CommandBool \
  "{value: true}"

# 锁定
ros2 service call /mavros/cmd/arming mavros_msgs/srv/CommandBool \
  "{value: false}"
```

---

## 切换飞行模式

```bash
# Offboard 模式
ros2 service call /mavros/set_mode mavros_msgs/srv/SetMode \
  "{custom_mode: 'OFFBOARD'}"

# Position 模式
ros2 service call /mavros/set_mode mavros_msgs/srv/SetMode \
  "{custom_mode: 'POSCTL'}"

# Stabilized 模式
ros2 service call /mavros/set_mode mavros_msgs/srv/SetMode \
  "{custom_mode: 'STABILIZED'}"
```

---

## 速度控制

### 速度消息

```bash
ros2 topic pub /mavros/setpoint_velocity/cmd_vel geometry_msgs/Twist \
  "{linear: {x: 1.0, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}"
```

---

## 参数配置

### mavros 参数文件

```yaml
mavros:
  fcu_url: "udp://:14540@"
  fcu_protocol: "v2.0"
  protocol_version: "2.0"
  
  pub_global_position: {frame_id: "map", rate: 100.0}
  pub_local_position: {frame_id: "base_link", rate: 50.0}
  pub_imu: {frame_id: "base_link", rate: 100.0}
  
  subscribe_attitude: true
  subscribe_rc: true
```

---

## 使用 XRCE-DDS

### PX4 端配置

```bash
# 启用 uXRCE-DDS
UXRCE_DDS_CFG = 1  # 启用
UXRCE_DDS_PRT      # 端口
```

### ROS 2 端

```bash
# 安装 micro_ros_agent
sudo apt install ros-humble-micro-ros-agent

# 启动 agent
micro_ros_agent udp 8888
```

---

## 常见问题

### 无法连接

1. **检查飞控模式**
   ```
   # 需要先切换到 Offboard 模式
   ```
   
2. **检查防火墙**
   ```bash
   sudo ufw allow 14540/udp
   ```

3. **检查话题映射**

### 控制无效

```bash
# 确认 Offboard 模式已激活
# 确认已解锁
# 检查 MAVLink 状态
```

---

## 相关文档

- [MAVROS 文档](https://github.com/mavlink/mavros)
- [PX4 ROS2](https://docs.px4.io/main/en/ros2/)
- [Offboard 模式](https://docs.px4.io/main/en/flight_modes/offboard.html)