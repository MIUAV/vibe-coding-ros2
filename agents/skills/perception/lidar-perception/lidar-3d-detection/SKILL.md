---
name: lidar-3d-detection
description: 激光雷达 3D 检测技能 - PointPillars、PointRCNN、Clustering、NMS
argument-hint: "lidar 3D检测" / "PointPillars" / "点云检测" / "clustering"
user-invocable: true
---

# 激光雷达 3D 检测技能

> 基于激光雷达的 3D 目标检测

---

## 何时使用

当需要以下帮助时使用此技能：
- 点云目标检测
- 障碍物聚类
- 3D 边界框生成
- 多目标跟踪
- ROS2 3D 检测节点

---

## 核心实现

### 3D 聚类检测

```python
import numpy as np
import pcl
from sklearn.cluster import DBSCAN

class Lidar3DDetector:
    def __init__(self):
        self.cluster_tolerance = 0.5
        self.min_cluster_size = 10
        self.max_cluster_size = 250
        
    def detect(self, cloud):
        """检测点云中的目标"""
        # 地面移除
        ground_cloud, obstacle_cloud = self.remove_ground(cloud)
        
        # 聚类
        clusters = self.clustering(obstacle_cloud)
        
        # 生成边界框
        boxes = []
        for cluster in clusters:
            box = self.compute_bounding_box(cluster)
            boxes.append(box)
            
        return boxes, ground_cloud, obstacle_cloud
        
    def remove_ground(self, cloud):
        """移除地面点"""
        # 简单方法：高度阈值
        points = np.array(cloud)
        ground_mask = points[:, 2] < 0.3
        ground_points = points[ground_mask]
        obstacle_points = points[~ground_mask]
        
        ground_cloud = pcl.PointCloud()
        ground_cloud.from_array(ground_points.astype(np.float32))
        
        obstacle_cloud = pcl.PointCloud()
        obstacle_cloud.from_array(obstacle_points.astype(np.float32))
        
        return ground_cloud, obstacle_cloud
        
    def clustering(self, cloud):
        """欧式聚类"""
        points = np.array(cloud)
        
        # DBSCAN 聚类
        db = DBSCAN(eps=self.cluster_tolerance, min_samples=self.min_cluster_size)
        labels = db.fit_predict(points)
        
        clusters = []
        for label in set(labels):
            if label == -1:
                continue  # 噪声点
            cluster_points = points[labels == label]
            cluster_cloud = pcl.PointCloud()
            cluster_cloud.from_array(cluster_points.astype(np.float32))
            clusters.append(cluster_cloud)
            
        return clusters
        
    def compute_bounding_box(self, cluster):
        """计算边界框"""
        points = np.array(cluster)
        
        min_point = points.min(axis=0)
        max_point = points.max(axis=0)
        
        center = (min_point + max_point) / 2
        size = max_point - min_point
        
        # 计算方向角
        yaw = np.arctan2(max_point[1] - min_point[1], 
                        max_point[0] - min_point[0])
        
        return {
            'center': center,
            'size': size,
            'yaw': yaw,
            'min_point': min_point,
            'max_point': max_point
        }
```

### ROS2 3D 检测节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2
from vision_msgs.msg import Detection3DArray
from geometry_msgs.msg import Pose, Quaternion
from std_msgs.msg import Header

class Lidar3DDetectionNode(Node):
    def __init__(self):
        super().__init__('lidar_3d_detection')
        
        self.sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.callback, 10)
        self.pub = self.create_publisher(Detection3DArray, '/detections_3d', 10)
        
        self.detector = Lidar3DDetector()
        
    def callback(self, msg):
        # 解析点云
        cloud = self.parse_cloud(msg)
        
        # 检测
        boxes, _, _ = self.detector.detect(cloud)
        
        # 发布
        det_array = Detection3DArray()
        det_array.header = msg.header
        
        for box in boxes:
            det = Detection3D()
            det.bbox.center.position.x = box['center'][0]
            det.bbox.center.position.y = box['center'][1]
            det.bbox.center.position.z = box['center'][2]
            det.bbox.size.x = box['size'][0]
            det.bbox.size.y = box['size'][1]
            det.bbox.size.z = box['size'][2]
            det_array.detections.append(det)
            
        self.pub.publish(det_array)
        
    def parse_cloud(self, msg):
        points = []
        for i in range(0, len(msg.data), msg.point_step):
            x = msg.data[i:i+12]  # xyz
            points.append([struct.unpack('f', x[0:4])[0],
                          struct.unpack('f', x[4:8])[0],
                          struct.unpack('f', x[8:12])[0]])
        return np.array(points)
```
