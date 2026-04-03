---
name: perception
description: 四足机器人感知系统 - 视觉识别、深度相机、激光雷达、触觉传感器配置
argument-hint: 四足感知 OR 机器人视觉 OR 深度相机 OR 激光雷达
user-invocable: true
---

# 四足机器人感知技能

> 用于配置和开发四足机器人的感知系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置视觉传感器
- 设置激光雷达
- 实现目标识别
- 环境感知融合

---

## 快速参考

### 传感器配置

```yaml
quadruped_perception:
  # 深度相机
  camera:
    type: realsense / astra / orbbec
    topics: [/camera/color/image, /camera/depth/image]
    
  # 激光雷达
  lidar:
    type: rplidar / livox / garfield
    topics: [/scan, /point_cloud]
    
  # IMU
  imu:
    type: BMI088 / CH110
    topics: [/imu/data]
```

---

## 视觉感知

### 深度相机配置

```bash
# Intel RealSense
ros2 launch realsense2_camera rs_launch.py

# Astra
ros2 launch astra_camera astra_launch.py

# ORBBEC
ros2 launch orbbec_camera orbbec_launch.py
```

### 目标检测

```python
# YOLO 目标检测
class QuadrupedVision:
    def __init__(self):
        self.yolo = YOLOWrapper("yolov8n.onnx")
        
    def detect_objects(self, image):
        results = self.yolo.predict(image)
        return self.filter_quadruped_relevant(results)
```

---

## 激光雷达感知

### 雷达配置

```bash
# RPLIDAR
ros2 launch sllidar_ros2 sllidar_a1_launch.py

# Livox
ros2 launch livox_ros_driver livox_lidar_launch.py

# 思岚
ros2 launch rplidar_ros2 rplidar_a3_launch.py
```

### 点云处理

```python
# 点云滤波
def filter_point_cloud(point_cloud):
    # 地面移除
    ground_filter = PointCloudFilter()
    ground_filter.set_optimized_coefficients([0, 0, 1, 0])
    
    filtered = ground_filter.apply(point_cloud)
    return filtered
```

---

## 传感器融合

### 多传感器融合

```python
class PerceptionFusion:
    def __init__(self):
        self.camera_sub = ...
        self.lidar_sub = ...
        self.imu_sub = ...
        
    def fuse(self):
        # 相机目标检测
        objects = self.detect_objects()
        
        # 激光雷达距离
        distances = self.get_lidar_distances()
        
        # IMU 姿态
        orientation = self.get_orientation()
        
        # 融合结果
        return self.merge_sensory_data(objects, distances, orientation)
```

---

## 地形感知

### 足端感知

```yaml
foot_sensors:
  - type: proximity    # 接近传感器
  - type: force       # 力传感器
  - type: contact     # 触地检测
```

### 地形分类

```python
class TerrainClassifier:
    def classify(self, sensor_data):
        features = extract_features(sensor_data)
        
        terrain_types = {
            'flat': 0.9,
            'rough': 0.05,
            'stairs': 0.03,
            'slope': 0.02
        }
        
        return terrain_types
```

---

## 常用功能包

| 包 | 功能 |
|----|------|
| `vision_msgs` | 视觉消息类型 |
| `darknet_ros` | YOLO 目标检测 |
| `lidar_localization` | 激光雷达定位 |

---

## 相关文档

- [Realsense ROS2](https://github.com/IntelRealSense/realsense-ros)
- [Livox SDK](https://github.com/Livox-SDK)