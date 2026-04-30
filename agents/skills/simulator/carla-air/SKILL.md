---
name: carla-air
description: CARLA-Air 空地一体仿真技能 - 车辆+无人机联合仿真、ROS2 Humble 桥接
argument-hint: carla air OR 空地仿真 OR carla无人机 OR carla-air OR air-ground
user-invocable: true
---

# CARLA-Air 空地一体仿真 Skill

> 统一城市驾驶 + 多旋翼飞行，在同一个 Unreal Engine 进程中实现空地具身智能仿真
> 基于 [louiszengCN/CarlaAir](https://github.com/louiszengCN/CarlaAir)

---

## 何时使用

当需要以下场景时使用此技能：
- 城市环境车辆+无人机联合仿真
- 空地传感器融合研究（LiDAR + IMU + Camera）
- ROS2 Humble 桥接车辆/无人机传感器话题
- AirSim API 风格的无人机控制
- 无需编译的 CARLA-Air 快速部署

---

## 快速开始（4步启动）

### 前置依赖

- Ubuntu 20.04 / 22.04（推荐 22.04）
- ROS 2 Humble (`sudo apt install ros-humble-desktop`)
- conda 环境 `carlaAir`（Python 3.10）：
  ```bash
  conda create -n carlaAir python=3.10 -y
  conda activate carlaAir
  pip install carla airsim numpy opencv-python
  ```
- CARLA-Air v0.1.7 预编译包（百度盘 / Hugging Face）

### 启动步骤

```bash
# Terminal 1 — 启动 CARLA-Air
cd /path/to/CarlaAir-v0.1.7
./CarlaAir.sh

# Terminal 2 — 加载 ROS2 环境
source /opt/ros/humble/setup.bash
source examples/ros2/ros2_env.sh   # 导出 PYTHONPATH
python3 examples/ros2/air_ground_ros_demo.py

# Terminal 3 — RViz2 可视化
source /opt/ros/humble/setup.bash
rviz2 -d examples/ros2/rviz/carlaair.rviz
```

---

## 话题列表

### 车辆话题（`/carla/ego_vehicle/`）

| 话题 | 类型 |
|------|------|
| `/carla/ego_vehicle/rgb/image` | `sensor_msgs/Image` |
| `/carla/ego_vehicle/depth/image` | `sensor_msgs/Image` |
| `/carla/ego_vehicle/semantic/image` | `sensor_msgs/Image` |
| `/carla/ego_vehicle/lidar` | `sensor_msgs/PointCloud2` |
| `/carla/ego_vehicle/odom` | `nav_msgs/Odometry` |
| `/carla/ego_vehicle/rgb/camera_info` | `sensor_msgs/CameraInfo` |

### 无人机话题（`/airsim/drone_1/`）

| 话题 | 类型 |
|------|------|
| `/airsim/drone_1/fpv/image` | `sensor_msgs/Image` |
| `/airsim/drone_1/down/image` | `sensor_msgs/Image` |
| `/airsim/drone_1/imu` | `sensor_msgs/Imu` |
| `/airsim/drone_1/odom` | `nav_msgs/Odometry` |

### TF 树

```
map
├── ego_vehicle          ← CARLA 世界坐标
│   ├── ego_vehicle/rgb
│   ├── ego_vehicle/depth
│   ├── ego_vehicle/semantic
│   └── ego_vehicle/lidar
└── drone_1             ← AirSim 世界坐标（启动时与 CARLA 坐标对齐）
    ├── drone_1/fpv
    └── drone_1/down
```

---

## ROS2 桥接脚本

### `carla_vehicle_bridge.py` — 车辆传感器桥接

```bash
python3 examples/ros2/carla_vehicle_bridge.py
```

发布话题：
- `/carla/ego_vehicle/{rgb,depth,semantic}/image`
- `/carla/ego_vehicle/lidar`
- `/carla/ego_vehicle/odom`
- `/tf`, `/tf_static`

### `airsim_drone_bridge.py` — 无人机传感器桥接

```bash
python3 examples/ros2/airsim_drone_bridge.py
```

发布话题：
- `/airsim/drone_1/{fpv,down}/image`
- `/airsim/drone_1/imu`
- `/airsim/drone_1/odom`
- `/tf`, `/tf_static`

### `air_ground_ros_demo.py` — 空地联合（同时启动两者）

```bash
python3 examples/ros2/air_ground_ros_demo.py
```

---

## AirSim 风格无人机控制

### 连接无人机

```python
import airsim

# 连接到 CARLA-Air 的 AirSim API（默认端口 41451）
client = airsim.MultirotorClient()
client.confirmConnection()

# 解锁
client.enableApiControl(True)
client.armDisarm(True)

# 起飞
client.takeoffAsync().join()

# 飞行到目标位置
client.moveToPositionAsync(x=10, y=0, z=-10, velocity=5).join()
#  z 为负数表示上升（NED 坐标系）

# 悬停
client.hoverAsync().join()

# 降落
client.landAsync().join()
```

### 相机控制

```python
# 获取相机图像
responses = client.simGetImages([
    airsim.ImageRequest("fpv", airsim.ImageType.SCENE, False, True),
    airsim.ImageRequest("down", airsim.ImageType.SCENE, False, True)
], vehicle_name="drone_1")

# responses[0].image_data_uint8 即为 RGB 图像
```

### IMU 数据

```python
# 获取 IMU 状态
state = client.getImuData(vehicle_name="drone_1")
# state.angular_velocity
# state.linear_acceleration
```

---

## RViz2 可视化配置

推荐的 RViz2 配置（固定帧 = `map`）：

```
/tf                    → TF 显示
/tf_static             → TF 显示（静态）
/airsim/drone_1/odom   → Odometry 显示
/carla/ego_vehicle/odom → Odometry 显示
/carla/ego_vehicle/lidar → PointCloud2 显示
```

---

## 常见问题

### ModuleNotFoundError: carla

```bash
# 确认 conda env 在 PYTHONPATH 中
source examples/ros2/ros2_env.sh
```

### RViz 无数据显示

```bash
# 检查话题是否有数据
ros2 topic hz /carla/ego_vehicle/rgb/image

# 如果 0 Hz：CARLA-Air 未运行，或 ego_vehicle 尚未生成
# 桥接会等待最多 30 秒
```

### Fixed Frame 错误

RViz 中 Fixed Frame 必须设为 `map`。

### AirSim 无人机未找到

先启动 CARLA-Air，等待 AirSim API（端口 41451）就绪后再运行桥接脚本。

---

## 与 CARLA 原生 skill 的区别

| 特性 | carla skill | carla-air skill |
|------|------------|----------------|
| 仿真引擎 | CARLA 原生 | CARLA + AirSim 统一 |
| 无人机支持 | 有限 | AirSim API 原生 |
| 空地联合 | 需额外集成 | 原生统一坐标 |
| ROS2 桥接 | carla-ros-bridge | 轻量 Python → rclpy |
| 安装方式 | 源码/包 | 预编译可执行文件 |
| 适用场景 | 自动驾驶纯车辆 | 空地具身智能研究 |

---

## 相关资源

- [CARLA-Air GitHub](https://github.com/louiszengCN/CarlaAir)
- [Paper (arXiv:2603.28032)](https://arxiv.org/abs/2603.28032)
- [项目主页](https://carla-air.com/)
- [快速开始文档](https://github.com/louiszengCN/CarlaAir/blob/main/CarlaAir_Release/guide/Quick-Start.md)
- [ROS2 examples](https://github.com/louiszengCN/CarlaAir/blob/main/examples/ros2/README.md)
- [Hugging Face v0.1.7](https://huggingface.co/tianlezeng/CarlaAIr-v0.1.7)

---

## 另见

- [simulator](../) - 通用仿真技能
- [vehicle-dynamics](../../carla/vehicle-dynamics/) - 车辆动力学
- [sensor-config](../../carla/sensor-config/) - 传感器配置
- [multi_rotor_uav](../../../robots/multi_rotor_uav/) - 无人机控制
- [navigation](../../navigation/) - 导航集成
