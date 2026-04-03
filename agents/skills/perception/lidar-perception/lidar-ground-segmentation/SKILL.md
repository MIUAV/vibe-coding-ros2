---
name: lidar-ground-segmentation
description: 激光雷达地面分割技能 - 高度阈值、平面拟合、Ray casting、ROS2地面检测
argument-hint: 地面分割 OR ground segmentation OR lidar OR 地面检测
user-invocable: true
---

# 激光雷达地面分割技能

> 点云地面检测与分割算法

---

## 何时使用

当需要以下帮助时使用此技能：
- 地面点移除
- 崎岖地形检测
- 可行驶区域提取
- 地形分类
- SLAM 地面约束

---

## 核心实现

### 地面分割算法

```python
import numpy as np
from scipy.spatial import ConvexHull
from sklearn.linear_model import RANSACRegressor

class GroundSegmenter:
    def __init__(self):
        self.ground_threshold = 0.3  # 地面高度阈值
        self.angle_threshold = np.radians(15)  # 角度阈值
        
    def segment(self, points):
        """分割地面和障碍物"""
        # 方法1: 简单高度阈值
        ground_mask = points[:, 2] < self.ground_threshold
        
        return points[ground_mask], points[~ground_mask]
        
class RANSACGroundSegmenter:
    """RANSAC 平面拟合"""
    
    def __init__(self, distance_threshold=0.05):
        self.distance_threshold = distance_threshold
        
    def fit_plane(self, points):
        """拟合地面平面"""
        # RANSAC 平面拟合
        X = points[:, :2]
        y = points[:, 2]
        
        model = RANSACRegressor()
        model.fit(X, y)
        
        inliers = model.inliers_
        
        # 平面方程: z = ax + by + c
        a, b = model.coef_
        c = model.intercept_
        
        return a, b, c, inliers
        
    def segment(self, points):
        """分割"""
        a, b, c, inliers = self.fit_plane(points)
        
        ground_points = points[inliers]
        obstacle_points = points[~inliers]
        
        return ground_points, obstacle_points

class PatchBasedGroundSegmenter:
    """基于 Patch 的地面分割"""
    
    def __init__(self, patch_size=0.5, threshold=0.1):
        self.patch_size = patch_size
        self.threshold = threshold
        
    def segment(self, points):
        """划分 Patch 进行分割"""
        # 计算网格索引
        x_bins = (points[:, 0] / self.patch_size).astype(int)
        y_bins = (points[:, 1] / self.patch_size).astype(int)
        
        ground_mask = np.zeros(len(points), dtype=bool)
        
        for x in np.unique(x_bins):
            for y in np.unique(y_bins):
                mask = (x_bins == x) & (y_bins == y)
                patch_points = points[mask]
                
                if len(patch_points) < 5:
                    continue
                    
                # 最小二乘拟合
                z_mean = patch_points[:, 2].mean()
                z_std = patch_points[:, 2].std()
                
                # 判断是否为地面
                if z_std < self.threshold:
                    ground_mask[mask] = True
                    
        return points[ground_mask], points[~ground_mask]
```

### ROS2 地面分割节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2
from sensor_msgs.msg import LaserScan
from std_msgs.msg import Header

class GroundSegmentationNode(Node):
    def __init__(self):
        super().__init__('ground_segmentation')
        
        self.sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.callback, 10)
        self.ground_pub = self.create_publisher(
            PointCloud2, '/ground_points', 10)
        self.obstacle_pub = self.create_publisher(
            PointCloud2, '/obstacle_points', 10)
            
        self.segmenter = PatchBasedGroundSegmenter()
        
    def callback(self, msg):
        points = self.parse_pointcloud(msg)
        
        ground, obstacle = self.segmenter.segment(points)
        
        # 发布
        self.ground_pub.publish(self.pointcloud_to_msg(ground, msg.header))
        self.obstacle_pub.publish(self.pointcloud_to_msg(obstacle, msg.header))
        
    def parse_pointcloud(self, msg):
        points = []
        for i in range(0, len(msg.data), msg.point_step):
            x = msg.data[i:i+4]
            points.append([x[0], x[1], x[2]])
        return np.array(points, dtype=np.float32)
        
    def pointcloud_to_msg(self, points, header):
        msg = PointCloud2()
        msg.header = header
        msg.height = 1
        msg.width = len(points)
        msg.point_step = 12
        msg.row_step = 12 * len(points)
        msg.data = points.tobytes()
        return msg
```
