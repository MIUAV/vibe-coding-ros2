---
name: lidar-camera-fusion
description: 激光-相机融合技能 - 深度融合、检测融合、ROS2 融合节点
argument-hint: "lidar camera fusion" / "深度融合" / "检测融合" / "multimodal"
user-invocable: true
---

# 激光-相机融合技能

> 激光雷达与相机的数据融合

---

## 何时使用

当需要以下帮助时使用此技能：
- 深度图与点云融合
- 2D-3D 目标关联
- 融合检测
- 语义地图构建
- ROS2 融合节点开发

---

## 核心实现

### ROS2 融合节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, PointCloud2, CameraInfo
from vision_msgs.msg import Detection2DArray, Detection3DArray
from cv_bridge import CvBridge
import numpy as np

class LidarCameraFusionNode(Node):
    def __init__(self):
        super().__init__('lidar_camera_fusion')
        self.bridge = CvBridge()
        
        # 订阅
        self.image_sub = self.create_subscription(
            Image, '/camera/image_raw', self.image_callback, 10)
        self.lidar_sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.lidar_callback, 10)
        self.camera_info_sub = self.create_subscription(
            CameraInfo, '/camera/camera_info', self.info_callback, 10)
        self.det_2d_sub = self.create_subscription(
            Detection2DArray, '/detections_2d', self.det2d_callback, 10)
            
        # 发布
        self.fused_pub = self.create_publisher(
            Detection3DArray, '/fused_detections_3d', 10)
            
        self.K = None
        self.image = None
        self.lidar_points = None
        self.detections_2d = []
        
    def image_callback(self, msg):
        self.image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='rgb8')
        
    def lidar_callback(self, msg):
        self.lidar_points = self.parse_pointcloud(msg)
        
    def info_callback(self, msg):
        self.K = np.array(msg.k).reshape(3, 3)
        
    def det2d_callback(self, msg):
        self.detections_2d = msg.detections
        
    def fuse(self):
        """执行融合"""
        if self.image is None or self.lidar_points is None or self.K is None:
            return
            
        for det_2d in self.detections_2d:
            # 从 2D 检测获取搜索区域
            x = int(det_2d.bbox.center.position.x)
            y = int(det_2d.bbox.center.position.y)
            w = int(det_2d.bbox.size_x)
            h = int(det_2d.bbox.size_y)
            
            # 在点云中搜索该区域
            points_in_box = self.get_points_in_box_2d(x, y, w, h)
            
            # 拟合 3D 边界框
            if len(points_in_box) > 10:
                box_3d = self.fit_3d_box(points_in_box)
                # 发布 3D 检测
                
    def get_points_in_box_2d(self, x, y, w, h):
        """获取 2D 边界框内的点云"""
        points_2d = self.project_lidar_to_image(self.lidar_points)
        
        mask = (
            (points_2d[:, 0] >= x - w/2) & 
            (points_2d[:, 0] <= x + w/2) &
            (points_2d[:, 1] >= y - h/2) & 
            (points_2d[:, 1] <= y + h/2)
        )
        
        return self.lidar_points[mask]
        
    def project_lidar_to_image(self, points):
        """投影点云到图像"""
        # 假设外参已标定
        T_lidar_cam = np.eye(4)
        
        points_hom = np.hstack([points, np.ones((len(points), 1))])
        points_cam = (T_lidar_cam @ points_hom.T).T
        
        valid = points_cam[:, 2] > 0
        points_cam = points_cam[valid]
        
        points_2d = (self.K @ points_cam[:, :3].T).T
        points_2d[:, 0] /= points_2d[:, 2]
        points_2d[:, 1] /= points_2d[:, 2]
        
        return points_2d[:, :2]
        
    def fit_3d_box(self, points):
        """拟合 3D 边界框"""
        min_pt = points.min(axis=0)
        max_pt = points.max(axis=0)
        center = (min_pt + max_pt) / 2
        size = max_pt - min_pt
        return {'center': center, 'size': size}
        
    def parse_pointcloud(self, msg):
        points = []
        for i in range(0, len(msg.data), msg.point_step):
            x = msg.data[i:i+12]
            points.append([x[0], x[1], x[2]])
        return np.array(points, dtype=np.float32)
```

### 深度融合

```python
class DepthFusion:
    def __init__(self):
        self.lidar_depth = None
        self.camera_depth = None
        
    def fill_camera_depth(self, camera_depth, lidar_points, K, T):
        """用激光雷达数据填充深度图"""
        h, w = camera_depth.shape
        filled_depth = camera_depth.copy()
        
        points_2d = self.project_lidar_to_image(lidar_points, K, T)
        
        for i, (u, v) in enumerate(points_2d):
            u, v = int(u), int(v)
            if 0 <= u < w and 0 <= v < h:
                if self.lidar_depth is not None:
                    lidar_z = self.lidar_points[i, 2]
                    if filled_depth[v, u] == 0 or lidar_z < filled_depth[v, u]:
                        filled_depth[v, u] = lidar_z
                        
        return filled_depth
        
    def project_lidar_to_image(self, points, K, T):
        """投影"""
        points_hom = np.hstack([points, np.ones((len(points), 1))])
        points_cam = (T @ points_hom.T).T
        
        valid = points_cam[:, 2] > 0
        points_cam = points_cam[valid]
        
        points_2d = (K @ points_cam[:, :3].T).T
        points_2d[:, 0] /= points_2d[:, 2]
        points_2d[:, 1] /= points_2d[:, 2]
        
        return points_2d[:, :2]
```
