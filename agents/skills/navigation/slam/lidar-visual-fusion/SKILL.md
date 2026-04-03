---
name: lidar-visual-fusion
description: 激光视觉融合 SLAM 技能 - LIO-SAM、LVI-SAM、FusionSLAM、稠密重建
argument-hint: 激光视觉融合 OR LIO-SAM OR LVI-SAM OR fusion slam
user-invocable: true
---

# 激光视觉融合 SLAM 技能

> 激光雷达与视觉融合的 SLAM

---

## 何时使用

当需要以下帮助时使用此技能：
- LIO-SAM 配置
- LVI-SAM 部署
- 激光视觉紧融合
- 稠密地图构建
- 闭环检测

---

## 核心实现

### LIO-SAM 架构

```yaml
# lio_sam.configure
lio_sam:
  # 点云配准
  pointCloudRegistration:
    scanContext:
      row: 20
      col: 60
      scanRadius: 50.0
      historySize: 10
      
  # IMU 预积分
  imuPreintegration:
    imuTopic: /imu
    deltaVDisablingThres: 0.001
    deltaQDisablingThres: 0.001
    gravity: -9.81
    
  # GPS 融合 (可选)
  gpsIntegration:
    gpsTopic: /gps/fix
    gpsAccThreshold: 2.0
```

### ROS2 LIO-SAM 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2, Imu, NavSatFix
from nav_msgs.msg import Odometry
import numpy as np

class LIO-SAMNode(Node):
    def __init__(self):
        super().__init__('lio_sam')
        
        # 订阅
        self.point_cloud_sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.cloud_callback, 10)
        self.imu_sub = self.create_subscription(
            Imu, '/imu', self.imu_callback, 10)
        self.gps_sub = self.create_subscription(
            NavSatFix, '/gps/fix', self.gps_callback, 10)
            
        # 发布
        self.odom_pub = self.create_publisher(Odometry, '/odom', 10)
        self.map_pub = self.create_publisher(PointCloud2, '/map', 10)
        
        # 初始化
        self.gps_handler = GPSHandler()
        self.imu_handler = IMUHandler()
        self.cloud_handler = CloudHandler()
        
    def cloud_callback(self, msg):
        # 点云处理
        cloud = self.cloud_handler.process(msg)
        
        # IMU 预积分
        imu_predicted = self.imu_handler.predict()
        
        # GPS 更新
        gps_correction = self.gps_handler.get_correction()
        
        # 因子图优化
        odometry = self.optimize(cloud, imu_predicted, gps_correction)
        
        # 发布
        self.publish_odom(odometry)
```

### 激光-视觉里程计融合

```python
class LidarVisualOdometry:
    def __init__(self):
        self.lidar_odom = LaserOdometry()
        self.visual_odom = VisualOdometry()
        self.fusion = KalmanFilter()
        
    def compute_fused_odom(self, lidar_cloud, image):
        """融合激光和视觉里程计"""
        # 各自计算里程计
        lidar_pose = self.lidar_odom.compute_odometry(lidar_cloud)
        visual_pose = self.visual_odom.compute_pose(image)
        
        # 互相关估计置信度
        lidar_confidence = self.lidar_odom.get_confidence()
        visual_confidence = self.visual_odom.get_confidence()
        
        # 加权融合
        total = lidar_confidence + visual_confidence
        w_lidar = lidar_confidence / total
        w_visual = visual_confidence / total
        
        fused_pose = self.weighted_fusion(
            lidar_pose, visual_pose, w_lidar, w_visual)
            
        return fused_pose
        
    def weighted_fusion(self, pose1, pose2, w1, w2):
        """位姿加权融合"""
        # 位置直接加权
        p1 = pose1[:3, 3]
        p2 = pose2[:3, 3]
        fused_p = w1 * p1 + w2 * p2
        
        # 旋转使用 SLERP
        q1 = Rotation.from_matrix(pose1[:3, :3])
        q2 = Rotation.from_matrix(pose2[:3, :3])
        q_fused = q1.slerp(q2, w2)
        
        result = np.eye(4)
        result[:3, :3] = q_fused.as_matrix()
        result[:3, 3] = fused_p
        
        return result
```
