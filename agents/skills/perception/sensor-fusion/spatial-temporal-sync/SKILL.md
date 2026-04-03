---
name: spatial-temporal-sync
description: 时空同步技能 - 硬件同步、软件同步、时间戳对齐、外参标定
argument-hint: "时间同步" / "hardware sync" / "temporal sync" / "spatial sync"
user-invocable: true
---

# 时空同步技能

> 多传感器时间同步与空间对齐

---

## 何时使用

当需要以下帮助时使用此技能：
- 多传感器时间同步
- 硬件/软件同步配置
- 空间外参标定
- 数据插值对齐
- ROS2 同步机制

---

## 核心实现

### 硬件同步

```yaml
# 硬件同步配置示例
hardware_sync:
  # GPS + IMU 同步
  gps_imu_sync:
    trigger_mode: external_interrupt
    frequency: 100  # Hz
    offset_ns: 0
    
  # 激光雷达 + 相机同步  
  lidar_camera_sync:
    trigger_mode: time_based
    phase_offset: 0.05  # 50ms 相位偏移
```

### 软件同步 (ROS2 ApproximateTimeSynchronizer)

```python
import rclpy
from rclpy.node import Node
from message_filters import Subscriber, ApproximateTimeSynchronizer
from sensor_msgs.msg import Image, PointCloud2, Imu
from cv_bridge import CvBridge

class SensorSyncNode(Node):
    def __init__(self):
        super().__init__('sensor_sync_node')
        self.bridge = CvBridge()
        
        # 创建订阅者
        self.image_sub = Subscriber(self, Image, '/camera/image_raw')
        self.lidar_sub = Subscriber(self, PointCloud2, '/lidar_points')
        self.imu_sub = Subscriber(self, Imu, '/imu/data')
        
        # 近似时间同步器
        self.sync = ApproximateTimeSynchronizer(
            [self.image_sub, self.lidar_sub, self.imu_sub],
            queue_size=10,
            slop=0.1  # 100ms 容差
        )
        self.sync.registerCallback(self.sync_callback)
        
        # 发布同步后的话题
        self.synced_pub = self.create_publisher(PointCloud2, '/synced/lidar', 10)
        
    def sync_callback(self, image_msg, lidar_msg, imu_msg):
        # 所有数据时间戳已对齐
        stamp = image_msg.header.stamp
        
        # 使用同步后的数据
        self.get_logger().info(f'Synced data at {stamp.sec}.{stamp.nanosec}')
        
        # 投影点云到图像
        projected = self.project_lidar_to_image(lidar_msg, image_msg)
        
        self.synced_pub.publish(projected)
        
    def project_lidar_to_image(self, lidar_msg, image_msg):
        """将点云投影到图像平面"""
        # 相机内参
        K = np.array([500, 0, 320, 0, 500, 240, 0, 0, 1]).reshape(3, 3)
        
        # 外参 (激光雷达到相机)
        T_lidar_cam = np.eye(4)
        
        # 解析点云
        points = self.parse_pointcloud(lidar_msg)
        
        # 投影
        points_hom = np.hstack([points, np.ones((len(points), 1))])
        points_cam = (T_lidar_cam @ points_hom.T).T
        
        # 过滤前景点
        valid = points_cam[:, 2] > 0
        points_cam = points_cam[valid]
        
        # 投影到像素
        points_2d = (K @ points_cam[:, :3].T).T
        points_2d[:, 0] /= points_2d[:, 2]
        points_2d[:, 1] /= points_2d[:, 2]
        
        return points_2d[:, :2]
```

### 空间同步 - 外参标定

```python
import numpy as np

class ExtrinsicCalibrator:
    def __init__(self):
        self.T_lidar_cam = np.eye(4)  # 激光雷达到相机的变换
        
    def calibrate(self, lidar_corners, camera_corners):
        """
        基于标定板的 extrinsic calibration
        lidar_corners: 激光雷达检测到的角点 (N, 3)
        camera_corners: 图像中检测到的角点 (N, 2)
        K: 相机内参矩阵
        """
        # 使用 PnP 求解
        # 3D-2D 对应关系
        pass
        
    def refine_calibration(self, observations):
        """非线性优化 refinement"""
        # Ceres solver 或 g2o 优化
        pass
        
    def validate_calibration(self, test_lidar, test_image):
        """验证标定精度"""
        # 投影测试点
        projected = self.project_lidar_to_camera(test_lidar)
        
        # 计算重投影误差
        error = np.linalg.norm(projected - test_image, axis=1)
        return error.mean(), error.std()
```
