---
name: localization
description: 四足机器人定位 - SLAM建图、IMU融合、EKF定位、UWB定位
argument-hint: 四足定位 OR SLAM OR IMU融合 OR 定位
user-invocable: true
---

# 四足机器人定位技能

> 用于配置和开发四足机器人的定位系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 SLAM 建图
- 实现 IMU 融合
- 设置 EKF 定位
- 室外 GPS/RTK 定位

---

## 快速参考

### SLAM 框架

| 框架 | 特点 | 适用场景 |
|------|------|----------|
| **cartographer** | 闭环检测、submap | 室内建图 |
| **gmapping** | 粒子滤波 | 小范围建图 |
| **karto** | 稀疏调整 | 中等范围 |
| **RTAB-Map** | 外观匹配 | 大范围 |
| **LIO-SAM** | 激光+IMU | 室外 |

---

## 激光雷达 SLAM

### cartographer

```bash
# 启动 cartographer
ros2 launch cartographer_ros cartographer.launch.py \
    configuration_basename:=lantern.lua \
    robot_description:=robot.urdf
```

### 配置文件

```lua
-- lantern.lua
TRAJECTORY_BUILDER_2D.scans_per_accumulation = 1
POSE_GRAPH.optimize_every_n_nodes = 90
```

### gmapping

```bash
ros2 launch slam_toolbox online_async_launch.py \
    slam_params_file:=params.yaml
```

---

## IMU 融合

### EKF 定位

```yaml
ekf_filter:
  frequency: 50
  odom0: /odom
  odom1: /imu
  imu0: /imu/data
  
  process_noise_cov: [0.05, 0, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0, 0, 0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

### robot_localization

```bash
ros2 launch robot_localization ekf.launch.py \
    odometry:=ekf_odom \
    config_file:=ekf.yaml
```

---

## 视觉定位

### RTAB-Map

```bash
ros2 launch rtabmap rtabmap.launch.py \
    rgbd_sync:=true \
    scan_cloud_topic:=/scan \
    odom_topic:=/odom
```

### VIO

```yaml
vio:
  provider: rtabmap / vins-fusion / okvis
  
  camera:
    topics: [/camera/left/image, /camera/right/image]
    baseline: 0.12
```

---

## GPS/RTK 定位

### GPS 配置

```bash
# NMEA GPS
ros2 run nmea_navsat_driver nmea_serial_node \
    port:=/dev/gps \
    baud:=115200
```

### RTK 配置

```yaml
rtk:
  type: ublox / septentrio
  
  corrections:
    type: NTRIP
    caster: rtk.example.com
    port: 2101
    mountpoint: RTS0
    username: user
    password: pass
```

---

## 多机器人定位

### 差分定位

```python
def compute_relative_pose(pose1, pose2):
    """计算两个机器人间的相对位姿"""
    delta_x = pose2.x - pose1.x
    delta_y = pose2.y - pose1.y
    delta_theta = pose2.theta - pose1.theta
    
    return (delta_x, delta_y, delta_theta)
```

---

## 常用功能包

| 包 | 功能 |
|----|------|
| `cartographer_ros` | cartographer SLAM |
| `slam_toolbox` | 同步定位建图 |
| `robot_localization` | EKF 融合 |
| `rtabmap_ros` | 视觉 SLAM |
| `nmea_navsat_driver` | GPS 驱动 |

---

## 相关文档

- [Cartographer文档](https://google-cartographer-ros.readthedocs.io/)
- [RTAB-Map](https://introlab.github.io/rtabmap/)
- [robot_localization](https://github.com/cra-ros-pkg/robot_localization)