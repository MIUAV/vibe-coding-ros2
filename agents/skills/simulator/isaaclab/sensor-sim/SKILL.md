---
name: sensor-sim
description: Isaac Lab 传感器仿真技能 - 相机、深度传感器、IMU、激光雷达配置
argument-hint: Isaac Lab传感器 OR 相机仿真 OR 深度传感器
user-invocable: true
---

# Isaac Lab Sensor Simulation Skill

> 用于在 Isaac Lab 中配置传感器

---

## 何时使用

当需要以下帮助时使用此技能：
- 添加相机传感器
- 配置深度传感器
- 设置 IMU 和 GPS
- 生成点云数据

---

## 快速参考

### 配置相机

```python
from isaaclab.sensors import CameraCfg

camera_cfg = CameraCfg(
    name="front_camera",
    sensor_type="rgb",
    resolution=(640, 480),
    frame_rate=30.0,
    prim_path="/World/my_robot/camera"
)
```

---

## 传感器类型

### RGB 相机

```python
camera_cfg = CameraCfg(
    name="rgb_camera",
    sensor_type="rgb",
    resolution=(1920, 1080),
    frame_rate=30.0,
    data_type="rgb",
    prim_path="/World/robot/camera"
)
```

### 深度相机

```python
depth_camera_cfg = CameraCfg(
    name="depth_camera",
    sensor_type="depth",
    resolution=(640, 480),
    frame_rate=30.0,
    data_type="depth",
    depth_scale=1000.0,  # 毫米
    prim_path="/World/robot/depth_camera"
)
```

### RGBD 相机

```python
rgbd_camera_cfg = CameraCfg(
    name="rgbd_camera",
    sensor_type="rgbd",
    resolution=(640, 480),
    frame_rate=30.0,
    data_type="rgbd",
    prim_path="/World/robot/rgbd_camera"
)
```

---

## IMU 传感器

```python
from isaaclab.sensors import IMUSensorCfg

imu_cfg = IMUSensorCfg(
    name="imu",
    sensor_type="imu",
    prim_path="/World/robot/imu",
    update_rate=100.0,
    accel_bias=(0.0, 0.0, 0.0),
    gyro_bias=(0.0, 0.0, 0.0),
    accel_noise_std=0.01,
    gyro_noise_std=0.002
)
```

---

## 激光雷达

```python
lidar_cfg = LidarSensorCfg(
    name="lidar",
    sensor_type="ray_cast_lidar",
    prim_path="/World/robot/lidar",
    update_rate=10.0,
    horizontal_fov=360.0,
    num_rows=32,
    num_cols=360,
    min_range=0.1,
    max_range=100.0
)
```

---

## 常见问题

### 问题 1: 传感器数据为空

**解决方案**：检查传感器路径是否正确

---

## 另见

- [robot-sim](../robot-sim/) - 机器人仿真
- [rl-training](../rl-training/) - 强化学习训练