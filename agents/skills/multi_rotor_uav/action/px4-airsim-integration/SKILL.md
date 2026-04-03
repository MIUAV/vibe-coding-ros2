---
name: px4-airsim-integration
description: PX4 AirSim联合开发 - AirSim仿真器配置、SITL/HITL集成、多无人机仿真、视觉/激光雷达仿真
argument-hint: AirSim仿真 OR PX4 AirSim OR AirSim开发 OR 联合仿真
user-invocable: true
---

# PX4 AirSim 联合开发技能

> 用于配置 PX4 与 AirSim 仿真器的联合仿真开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 PX4 + AirSim 联合仿真
- AirSim 多旋翼模型配置
- 视觉/激光雷达传感器仿真
- 多无人机协同仿真
- 硬件在环 (HITL) 仿真

---

## 快速参考

### PX4 + AirSim 架构

```
AirSim <--MAVLink--> PX4 SITL/HITL <--> ROS2
                         ↓
                    QGC 地面站
```

### 快速启动命令

```bash
# 1. 启动 PX4 SITL
make px4_sitl_default

# 2. 启动 AirSim
cd AirSim && ./run.sh

# 3. 等待连接后启动 QGC
./QGroundControl.AppImage
```

---

## AirSim 安装与配置

### 安装依赖

```bash
# Ubuntu 20.04/22.04
sudo apt update
sudo apt install -y cmake git clang-10 llvm-10 libzmq3-dev

# 安装 AirSim
cd ~
git clone https://github.com/microsoft/AirSim.git
cd AirSim
./setup.sh
./build.sh
```

### AirSim 配置文件

```json
{
  "seeDocsAt": "https://microsoft.github.io/AirSim/docs/settings/",
  "SettingsVersion": 1.2,
  "LogMessagesVisible": true,
  "SimMode": "Multirotor",
  "ClockSpeed": 1,
  "Vehicles": {
    "PX4": {
      "VehicleType": "PX4Multirotor",
      "UseSerial": false,
      "LockStep": true,
      "Parameters": {
        "NAV_RCL_ACT": 0,
        "NAV_DLL_ACT": 0,
        "LND_FLIGHT_TIME": 9999999,
        "CBRK_AIRSBREW_CHECK": 0
      }
    }
  }
}
```

### settings.json 路径

```bash
# Windows: ~/Documents/AirSim/settings.json
# Linux: ~/AirSim/settings.json
```

---

## PX4 AirSim 集成

### PX4 SITL 配置

```bash
# 编译 PX4 (使用 AirSim 模块)
make px4_sitl_default

# 设置环境变量
export PX4_SIM_HOST=127.0.0.1
export PX4_SIM_PORT=14560

# 启动仿真
cd /path/to/PX4-Autopilot
make px4_sitl_default
```

### MAVLink 通信配置

```bash
# 启动 MAVLink router
mavlink-routerd -e 127.0.0.1:14550 127.0.0.1:14540

# 或使用 socat 转发
socat - UDP4:127.0.0.1:14560,reuseaddr
```

### AirSim PX4 连接

```bash
# 在 AirSim 设置中启用 MAVLink
# settings.json
{
  "PX4": {
    "ControlMode": "Mavlink",
    "LocalHostIp": "127.0.0.1",
    "UdpPort": 14560,
    "TcpPort": 14580
  }
}
```

---

## 传感器仿真

### 相机配置

```json
{
  "Cameras": {
    "front_center": {
      "CameraType": 0,
      "CaptureSettings": [
        {
          "Width": 1920,
          "Height": 1080,
          "FOV_Degrees": 90,
          "AutoExposureSpeed": 100
        }
      ],
      "X": 0.25, "Y": 0.0, "Z": 0.0,
      "Pitch": 0.0, "Roll": 0.0, "Yaw": 0.0
    }
  }
}
```

### 激光雷达配置

```json
{
  "Lidar": {
    "Lasers": {
      "max_view_angle": 360,
      "number_of_channels": 16,
      "range": 100.0,
      "points_per_second": 600000
    },
    "X": 0.0, "Y": 0.0, "Z": 0.0,
    "Roll": 0.0, "Pitch": 0.0, "Yaw": 0.0
  }
}
```

---

## 多无人机仿真

### 多机配置

```json
{
  "Vehicles": {
    "Drone1": {
      "VehicleType": "PX4Multirotor",
      "X": 0, "Y": 0, "Z": 0
    },
    "Drone2": {
      "VehicleType": "PX4Multirotor",
      "X": 5, "Y": 0, "Z": 0
    },
    "Drone3": {
      "VehicleType": "PX4Multirotor",
      "X": 10, "Y": 0, "Z": 0
    }
  }
}
```

### 多机 MAVLink 路由

```python
# 多机通信配置
import pymavlink.mavutil as mavutil

# 连接各无人机
drone1 = mavutil.mavlink_connection('udpin:127.0.0.1:14540')
drone2 = mavutil.mavlink_connection('udpin:127.0.0.1:14541')
drone3 = mavutil.mavlink_connection('udpin:127.0.0.1:14542')

# 设置系统 ID
drone1.mav.system_send(1, 1)  # sys_id=1
drone2.mav.system_send(1, 2)  # sys_id=2
drone3.mav.system_send(1, 3)  # sys_id=3
```

---

## AirSim API 开发

### Python API 控制

```python
import airsim
import msgpack
import numpy as np

# 连接 AirSim
client = airsim.MultirotorClient()
client.confirmConnection()

# 获取状态
state = client.getMultirotorState()
print(f"Position: {state.kinematics_estimated.position}")
print(f"Velocity: {state.kinematics_estimated.linear_velocity}")

# 解锁并起飞
client.enableApiControl(True)
client.armDisarm(True)
client.takeoff()

# 飞行到目标位置
client.moveToPositionAsync(10, 0, -10, 5).join()

# 获取相机图像
responses = client.simGetImages([
    airsim.ImageRequest("front_center", airsim.ImageType.Scene),
    airsim.ImageRequest("front_center", airsim.ImageType.DepthPlanner)
])
```

### ROS2 集成

```bash
# 启动 AirSim-ROS2 桥接
ros2 launch airsim_ros2 airsim_ros2_node.launch.py

# 或手动桥接
ros2 run ros2_bridge airsim_ros_node
```

```python
# AirSim ROS2 节点
import rclpy
from rclpy.node import Node
from airsim_ros2_msgs.msg import GPSYaw, ImageCapture

class AirSimBridge(Node):
    def __init__(self):
        super().__init__('airsim_bridge')
        self.gps_pub = self.create_publisher(GPSYaw, '/gps', 10)
        self.img_sub = self.create_subscription(ImageCapture, '/camera', self.img_callback)
```

---

## 视觉导航开发

### 深度感知

```python
# 获取深度图像
depth_response = client.simGetImages([
    airsim.ImageRequest("front_center", airsim.ImageType.DepthPlanner)
])
depth = np.frombuffer(depth_response[0].image_data_uint8, dtype=np.float32)
depth = depth.reshape((depth_response[0].height, depth_response[0].width))
```

### 目标检测与跟踪

```python
# YOLO 集成
from ultralytics import YOLO

model = YOLO('yolov8n.onnx')

def detect_and_track():
    # 获取图像
    img_response = client.simGetImages([
        airsim.ImageRequest("front_center", airsim.ImageType.Scene)
    ])
    img = np.frombuffer(img_response[0].image_data_uint8, dtype=np.uint8)
    img = img.reshape((img_response[0].height, img_response[0].width, 3))
    
    # 检测
    results = model(img)
    
    # 跟踪最近目标
    targets = [r for r in results if r.class_id == 0]  # person class
    if targets:
        return targets[0].center  # 返回像素坐标
```

---

## HITL 硬件在环

### HITL 配置

```bash
# 设置 HITL 模式
export PX4_SIMULATOR=AirSim
export PX4_SIM_HOST=192.168.1.100  # AirSim 主机 IP

# 启动 HITL
make px4_sitl_default px4 HITL=1
```

### 飞控连接

```
硬件连接:
[AirSim PC] <--以太网--> [飞控] <--> [QGC]
                   USB
```

---

## 常见问题排查

### AirSim 无法启动

```bash
# 检查虚幻引擎
./Engine/Binaries/Linux/UE4Editor --version

# 重新编译
cd AirSim
./build.sh -Linux

# 检查依赖
ldd ./run.sh
```

### PX4 无法连接 AirSim

```bash
# 检查 UDP 端口
sudo netstat -u -anp | grep 14560

# 确认防火墙
sudo ufw status
sudo ufw allow 14560/udp

# 测试 MAVLink
mavlink-cli -d /dev/ttyACM0 -b 921600
```

### 传感器数据异常

```bash
# 检查 AirSim 设置
cat ~/AirSim/settings.json

# 重启 AirSim
pkill -f AirSim
./run.sh
```

---

## 相关文档

- `./multi_rotor_uav/perception/px4-vision-nav/SKILL.md` - PX4 视觉导航
- `./multi_rotor_uav/localization/px4-multicopter-dev/SKILL.md` - PX4 多旋翼开发
- `./multi_rotor_uav/action/px4-dev-env/SKILL.md` - 开发环境配置
