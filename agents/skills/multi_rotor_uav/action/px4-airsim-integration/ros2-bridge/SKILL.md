---
name: px4-airsim-ros2-bridge
description: PX4 AirSim 与 ROS2 桥接技能 - SITL/HITL 集成、无人机控制、传感器数据同步、多机协同
user-invocable: true
argument-hint: PX4 AirSim桥接 OR PX4 ros2桥接 OR 无人机仿真 OR airsim多机 OR  SITL HITL
---

# PX4 AirSim ROS2 Bridge Skill

> PX4 Autopilot + AirSim 仿真器与 ROS2 之间的通讯桥接完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 PX4 SITL/HITL 与 AirSim 仿真
- 桥接无人机状态到 ROS2
- 发布 AirSim 传感器数据到 ROS2
- 订阅 ROS2 命令控制无人机
- 多无人机协同仿真
- 视觉/激光雷达仿真集成

---

## 快速参考

### 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                    PX4 Autopilot                           │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  Commander  │───▶│  Navigator   │───▶│  Actuator     │  │
│  └─────────────┘    └──────────────┘    └───────────────┘  │
└───────────┬─────────────────┬─────────────────────────────┘
            │                 │
            ▼                 ▼
    ┌───────────────┐  ┌──────────────┐
    │   AirSim API  │◄─│  uORB Topics  │
    │               │  │  (mavlink)   │
    └───────┬───────┘  └──────────────┘
            │                 │
            ▼                 ▼
┌───────────────┐      ┌──────────────┐
│  AirSim Sim   │      │   MAVLink    │
│               │      │   (ROS2)     │
└───────┬───────┘      └──────┬───────┘
        │                      │
        ▼                      ▼
┌───────────────┐      ┌──────────────┐
│   Sensors     │      │   ROS2       │
│  (Cam/Lidar)  │      │   Bridge     │
└───────────────┘      └──────────────┘
```

### PX4 AirSim 安装

```bash
# 1. 安装 AirSim
git clone https://github.com/microsoft/AirSim.git
cd AirSim
./setup.sh
./build.sh

# 2. 安装 PX4 SITL
git clone --recursive https://github.com/PX4/PX4-Autopilot.git
cd PX4-Autopilot
make px4_sitl_default

# 3. 配置 AirSim 作为 PX4 后端
export PX4_SIMULATOR=AirSim
export PX4_GAZEBO_HOSTNAME=127.0.0.1
```

---

## mavros 桥接配置

### mavros 安装

```bash
# 安装 mavros 和 mavlink
sudo apt install -y ros-humble-mavros ros-humble-mavlink
sudo apt install -y geographiclib-tools

# 初始化 mavros 地理数据库
sudo /opt/ros/humble/lib/mavros/install_geographiclib_datasets.sh

# 源码安装（最新版本）
cd ~/ws/src
git clone -b humble https://github.com/mavlink/mavros.git
git clone -b humble https://github.com/mavlink/mavlink-ros2.git
cd ~/ws && colcon build --packages-select mavros mavros_extras
```

### mavros 基础配置

```python
# px4_mavros.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # mavros 节点
        Node(
            package='mavros',
            executable='mavros_node',
            name='mavros',
            parameters=[{
                # 链接配置
                'pluginlibs': ['mavros'],
                'plugin_lock_key': '',
                
                # 系统配置
                'system_id': 1,
                'component_id': 1,
                'mavlink_system': 1,
                
                # 话题命名空间
                'fcu_url': 'udp://:14540@127.0.0.1:14557',  # PX4 SITL
                # 或串口: 'serial:///dev/ttyACM0:921600'
                
                # gz_bridge 需要这个
                'fcu_protocol': 'v2.0',
                
                # 传感器/位置源
                'sensor_bitrate': 0,
                'conn_timeout': 5.0,
                'timeout': 5.0,
                
                # 目标系统
                'target_system_id': 1,
                'target_component_id': 1,
                
                # 自动配置
                'startup_px4_usb_quirk': False,
            }],
            remappings=[
                # 无人机状态
                ('/mavros/state', '/drone0/mavros/state'),
                ('/mavros/global_position/global', '/drone0/mavros/global_position/global'),
                ('/mavros/global_position/local', '/drone0/mavros/global_position/local'),
                ('/mavros/local_position/pose', '/drone0/mavros/local_position/pose'),
                ('/mavros/local_position/odom', '/drone0/mavros/local_position/odom'),
                
                # IMU 和电池
                ('/mavros/imu/data', '/drone0/mavros/imu/data'),
                ('/mavros/imu/data_raw', '/drone0/mavros/imu/data_raw'),
                ('/mavros/battery', '/drone0/mavros/battery'),
                
                # 传感器
                ('/mavros/altitude', '/drone0/mavros/altitude'),
                ('/mavros/distance_sensor/hrlv_ez0_pub', '/drone0/distance_sensor'),
                
                # 命令
                ('/mavros/setpoint_velocity/cmd_vel_unstamped', '/drone0/cmd_vel'),
                ('/mavros/tunnel/action', '/drone0/action'),
                
                # RC
                ('/mavros/rc/in', '/drone0/rc/in'),
                
                # 状态
                ('/mavros/home_position/home', '/drone0/home_position'),
            ],
            output='screen',
            emulate_tty=True
        ),
        
        # 设置 use_sim_time
        Node(
            package='ros2_demos',
            executable='parameter_publisher',
            parameters=[{
                'use_sim_time': True
            }]
        )
    ])
```

---

## AirSim 传感器桥接

### AirSim 图像发布

```python
# airsim_camera_bridge.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # 前视相机
        Node(
            package='airsim_ros_pkgs',
            executable='img_pub_node',
            name='front_camera',
            parameters=[{
                'camera_name': 'front_center',
                'publish_rate': 30,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'front_camera/image_raw'
            }]
        ),
        
        # 深度相机
        Node(
            package='airsim_ros_pkgs',
            executable='img_pub_node',
            name='depth_camera',
            parameters=[{
                'camera_name': 'depth_center',
                'publish_rate': 15,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'depth_camera/image_raw'
            }]
        ),
        
        # 红外相机
        Node(
            package='airsim_ros_pkgs',
            executable='img_pub_node',
            name='seg_camera',
            parameters=[{
                'camera_name': 'seg_center',
                'publish_rate': 15,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'seg_camera/image_raw'
            }]
        ),
    ])
```

### AirSim 激光雷达桥接

```python
# airsim_lidar_bridge.launch.py
def generate_launch_description():
    return LaunchDescription([
        Node(
            package='airsim_ros_pkgs',
            executable='lidar_pub_node',
            name='lidar',
            parameters=[{
                'lidar_name': 'Lidar1',
                'publish_rate': 10,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'lidar/scan',
                'frame_id': 'lidar_link',
                
                # 激光雷达参数
                'points_per_second': 100000,
                'angle_min': -3.14159,
                'angle_max': 3.14159,
                'range_min': 0.5,
                'range_max': 100.0,
            }]
        )
    ])
```

### AirSim GPS/IMU 桥接

```python
# airsim_gps_imu_bridge.launch.py
def generate_launch_description():
    return LaunchDescription([
        # GPS
        Node(
            package='airsim_ros_pkgs',
            executable='gps_pub_node',
            name='gps',
            parameters=[{
                'gps_name': 'Gps1',
                'publish_rate': 10,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'gps/fix'
            }]
        ),
        
        # IMU
        Node(
            package='airsim_ros_pkgs',
            executable='imu_pub_node',
            name='imu',
            parameters=[{
                'imu_name': 'Imu1',
                'publish_rate': 100,
                'publish_via_ros2': True,
                'ros2_namespace': '/drone0',
                'topic_id': 'imu/data'
            }]
        ),
    ])
```

---

## 无人机控制桥接

### 起飞/降落服务

```python
# drone_control.launch.py
def generate_launch_description():
    return LaunchDescription([
        # 起飞服务
        Node(
            package='mavros',
            executable='mavros_node',
            name='mavros_takeoff',
            parameters=[{
                'fcu_url': 'udp://:14540@127.0.0.1:14557',
            }],
            remappings=[
                ('/mavros/cmd/arming', '/drone0/mavros/cmd/arming'),
                ('/mavros/cmd/takeoff', '/drone0/mavros/cmd/takeoff'),
                ('/mavros/cmd/land', '/drone0/mavros/cmd/land'),
            ]
        ),
    ])
```

### Python 控制脚本

```python
# drone_control.py
import rclpy
from rclpy.node import Node
from mavros_msgs.srv import CommandBool, CommandTOL, SetMode
from mavros_msgs.msg import State, GlobalPosition, LocalPosition
from geometry_msgs.msg import PoseStamped, Twist
from geographic_msgs.msg import GeoPoseStamped

class DroneController(Node):
    def __init__(self, drone_name='drone0'):
        super().__init__(f'{drone_name}_controller')
        self.drone_name = drone_name
        
        # 服务客户端
        self.arming_client = self.create_client(CommandBool, f'/{drone_name}/mavros/cmd/arming')
        self.takeoff_client = self.create_client(CommandTOL, f'/{drone_name}/mavros/cmd/takeoff')
        self.land_client = self.create_client(CommandTOL, f'/{drone_name}/mavros/cmd/land')
        self.set_mode_client = self.create_client(SetMode, f'/{drone_name}/mavros/set_mode')
        
        # 订阅状态
        self.state_sub = self.create_subscription(
            State, f'/{drone_name}/mavros/state', self.state_callback, 10)
        self.local_pos_sub = self.create_subscription(
            PoseStamped, f'/{drone_name}/mavros/local_position/pose', self.pos_callback, 10)
        
        # 发布命令
        self.cmd_vel_pub = self.create_publisher(
            Twist, f'/{drone_name}/mavros/setpoint_velocity/cmd_vel_unstamped', 10)
        self.local_pos_pub = self.create_publisher(
            PoseStamped, f'/{drone_name}/mavros/setpoint_position/local', 10)
        
        self.current_state = None
        self.current_pos = None
    
    def state_callback(self, msg):
        self.current_state = msg
    
    def pos_callback(self, msg):
        self.current_pos = msg
    
    def wait_for_service(self, client):
        while not client.wait_for_service(timeout_sec=1.0):
            self.get_logger().info(f'Waiting for {client.srv_name}...')
    
    def arm(self):
        self.wait_for_service(self.arming_client)
        req = CommandBool.Request()
        req.value = True
        future = self.arming_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result().success
    
    def takeoff(self, altitude=10.0):
        self.wait_for_service(self.takeoff_client)
        req = CommandTOL.Request()
        req.altitude = altitude
        req.latitude = 0  # 使用当前 GPS
        req.longitude = 0
        req.min_pitch = 0
        req.yaw = 0
        future = self.takeoff_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result().success
    
    def land(self):
        self.wait_for_service(self.land_client)
        req = CommandTOL.Request()
        future = self.land_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result().success
    
    def set_mode(self, mode):
        self.wait_for_service(self.set_mode_client)
        req = SetMode.Request()
        req.custom_mode = mode
        future = self.set_mode_client.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result().mode_sent
    
    def publish_cmd_vel(self, linear=(0,0,0), angular=(0,0,0)):
        cmd = Twist()
        cmd.linear.x = linear[0]
        cmd.linear.y = linear[1]
        cmd.linear.z = linear[2]
        cmd.angular.x = angular[0]
        cmd.angular.y = angular[1]
        cmd.angular.z = angular[2]
        self.cmd_vel_pub.publish(cmd)
    
    def publish_local_pos(self, x, y, z):
        pos = PoseStamped()
        pos.header.stamp = self.get_clock().now().to_msg()
        pos.header.frame_id = 'map'
        pos.pose.position.x = x
        pos.pose.position.y = y
        pos.pose.position.z = z
        self.local_pos_pub.publish(pos)


def main():
    rclpy.init()
    controller = DroneController('drone0')
    
    # 起飞
    controller.get_logger().info('Arming...')
    if controller.arm():
        controller.get_logger().info('Armed!')
    else:
        controller.get_logger().error('Arming failed!')
        return
    
    controller.get_logger().info('Taking off...')
    if controller.takeoff(altitude=10.0):
        controller.get_logger().info('Takeoff initiated!')
    else:
        controller.get_logger().error('Takeoff failed!')
        return
    
    # 保持悬停
    rate = controller.create_rate(10)
    for _ in range(50):
        controller.publish_cmd_vel(linear=(0, 0, 0), angular=(0, 0, 0))
        rclpy.spin_once(controller)
        rate.sleep()
    
    # 降落
    controller.get_logger().info('Landing...')
    controller.land()
    
    rclpy.shutdown()
```

---

## 多无人机配置

### AirSim 多无人机设置

```bash
# settings.json 配置
{
    "SeeDocsAt": "https://github.com/Microsoft/AirSim/blob/main/docs/settings.md",
    "SettingsVersion": 1.2,
    
    "SimMode": "Multirotor",
    
    "Vehicles": {
        "Drone0": {
            "VehicleType": "SimpleFlight",
            "X": 0, "Y": 0, "Z": 0,
            "Yaw": 0,
            "Cameras": {
                "front_center": {
                    "CaptureSettings": [
                        {
                            "ImageType": 0,
                            "Width": 640,
                            "Height": 480
                        }
                    ]
                }
            }
        },
        "Drone1": {
            "VehicleType": "SimpleFlight",
            "X": 10, "Y": 0, "Z": 0,
            "Yaw": 0,
            "Cameras": {...}
        }
    }
}
```

### ROS2 多无人机桥接

```python
# multi_drone_bridge.launch.py
def generate_launch_description():
    nodes = []
    
    # 为每架无人机启动 mavros
    for i, port in enumerate([14540, 14541, 14542]):
        drone_ns = f'drone{i}'
        nodes.append(
            Node(
                package='mavros',
                executable='mavros_node',
                name='mavros',
                namespace=drone_ns,
                parameters=[{
                    'system_id': i + 1,
                    'component_id': 1,
                    'fcu_url': f'udp://:14540@{127.0.0.1}:{14557 + i}',
                    'target_system_id': i + 1,
                }],
                remappings=[
                    ('/mavros/state', f'/{drone_ns}/mavros/state'),
                    ('/mavros/local_position/pose', f'/{drone_ns}/mavros/local_position/pose'),
                    ('/mavros/setpoint_velocity/cmd_vel_unstamped', f'/{drone_ns}/cmd_vel'),
                ]
            )
        )
    
    return LaunchDescription(nodes)
```

---

## 视觉/激光雷达仿真

### 深度感知示例

```python
# depth_perception.py
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from geometry_msgs.msg import TransformStamped
from cv_bridge import CvBridge
import cv2
import numpy as np

class DepthPerception(Node):
    def __init__(self):
        super().__init__('depth_perception')
        self.bridge = CvBridge()
        
        # 订阅深度图像
        self.depth_sub = self.create_subscription(
            Image, '/drone0/depth_camera/image_raw', self.depth_callback, 10)
        
        # 订阅 RGB 图像
        self.rgb_sub = self.create_subscription(
            Image, '/drone0/front_camera/image_raw', self.rgb_callback, 10)
        
        # 发布检测结果
        self.detection_pub = self.create_publisher(
            Image, '/drone0/detections', 10)
        
        self.latest_depth = None
        self.latest_rgb = None
    
    def depth_callback(self, msg):
        self.latest_depth = self.bridge.imgmsg_to_cv2(msg)
    
    def rgb_callback(self, msg):
        self.latest_rgb = self.bridge.imgmsg_to_cv2(msg)
        
        if self.latest_depth is not None:
            # 处理深度数据
            depth_m = np.array(self.latest_depth, dtype=np.float32)
            
            # 计算距离统计
            valid_depth = depth_m[depth_m > 0]
            if len(valid_depth) > 0:
                min_dist = valid_depth.min()
                max_dist = valid_depth.max()
                avg_dist = valid_depth.mean()
                
                self.get_logger().info(
                    f'Depth: min={min_dist:.2f}m, max={max_dist:.2f}m, avg={avg_dist:.2f}m')
            
            # 发布处理后的深度图像
            depth_colored = cv2.applyColorMap(
                cv2.convertScaleAbs(depth_m, alpha=0.05), cv2.COLORMAP_JET)
            out_msg = self.bridge.cv2_to_imgmsg(depth_colored, 'bgr8')
            self.detection_pub.publish(out_msg)
```

---

## 调试和诊断

### 检查连接

```bash
# 检查 mavros 连接状态
ros2 service call /drone0/mavros/get_log_info mavros_msgs/srv/FileClose

# 查看 PX4 状态
ros2 topic echo /drone0/mavros/state

# 检查飞行模式
ros2 topic echo /drone0/mavros/extended_state
```

### AirSim API 测试

```python
# airsim_api_test.py
import airsim

# 连接
client = airsim.MultirotorClient()
client.confirmConnection()

# 获取状态
state = client.getMultirotorState()
print(f"State: {state}")

# 解锁
client.armDisarm(True)

# 起飞
client.takeoff()

# 飞到目标位置
client.moveToPositionAsync(0, 0, -10, 5).join()

# 降落
client.land()
```

---

## 最佳实践

1. **端口配置**：确保 PX4 SITL 和 mavros 使用正确的 UDP 端口

2. **时钟同步**：PX4 使用仿真时钟，确保 `use_sim_time:=true`

3. **多机ID**：每架无人机使用不同的 `system_id`

4. **安全检查**：飞行前确认无人机状态

5. **GPS原点**：AirSim 中设置与 ROS2 地图一致的 GPS 原点

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| mavros 连接失败 | 端口被占用 | 检查 PX4 是否启动 |
| 无人机不响应 | 未解锁 | 调用 arming 服务 |
| 位置漂移 | GPS 未同步 | 设置一致的 GPS 原点 |
| 相机无数据 | AirSim 插件未加载 | 检查 settings.json |

---

## 相关技能

- [px4-airsim-integration](../px4-airsim-integration) - PX4 AirSim 基础
- [ros2-topic-communication](../ros2-topic-communication) - ROS2 通讯
