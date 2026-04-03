---
name: stereo-depth-estimation
description: 立体匹配与深度估计技能 - 双目校正、立体匹配、SGM、深度融合
argument-hint: 立体匹配 OR 深度估计 OR stereo OR SGM OR disparity
user-invocable: true
---

# 立体匹配与深度估计技能

> 双目视觉深度估计的完整实现

---

## 何时使用

当需要以下帮助时使用此技能：
- 双目相机标定
- 立体匹配算法
- 深度图生成
- 3D 重建
- 视觉测距

---

## 核心实现

### ROS2 双目深度节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from cv_bridge import CvBridge
import cv2
import numpy as np

class StereoDepthNode(Node):
    def __init__(self):
        super().__init__('stereo_depth_node')
        self.bridge = CvBridge()
        
        # 立体校正
        self.left_sub = self.create_subscription(
            Image, '/stereo/left/image_raw', self.left_callback, 10)
        self.right_sub = self.create_subscription(
            Image, '/stereo/right/image_raw', self.right_callback, 10)
        self.info_sub = self.create_subscription(
            CameraInfo, '/stereo/left/camera_info', self.info_callback, 10)
            
        self.depth_pub = self.create_publisher(Image, '/stereo/depth', 10)
        
        self.Q = None  # 重投影矩阵
        self.left_img = None
        self.right_img = None
        
        # SGM 参数
        self.stereo = cv2.StereoSGBM_create(
            minDisparity=0,
            numDisparities=128,
            blockSize=5,
            P1=8*3*5**2,
            P2=32*3*5**2,
            disp12MaxDiff=1,
            uniquenessRatio=10,
            speckleWindowSize=100,
            speckleRange=32
        )
        
    def info_callback(self, msg):
        if self.Q is None:
            # 从相机内参构建 Q 矩阵
            fx = msg.k[0]
            cx = msg.k[2]
            cy = msg.k[5]
            baseline = 0.12  # 双目基线
            self.Q = np.array([[1, 0, 0, -cx],
                               [0, 1, 0, -cy],
                               [0, 0, 0, fx],
                               [0, 0, -1/baseline, 0]])
                               
    def left_callback(self, msg):
        self.left_img = self.bridge.imgmsg_to_cv2(msg, desired_encoding='mono8')
        self.compute_depth()
        
    def right_callback(self, msg):
        self.right_img = self.bridge.imgmsg_to_cv2(msg, desired_encoding='mono8')
        self.compute_depth()
        
    def compute_depth(self):
        if self.left_img is None or self.right_img is None or self.Q is None:
            return
            
        # 立体匹配
        disparity = self.stereo.compute(self.left_img, self.right_img)
        
        # 计算深度
        depth = cv2.reprojectImageTo3D(disparity, self.Q)[:, :, 2]
        
        # 发布
        depth_msg = self.bridge.cv2_to_imgmsg(depth.astype(np.float32), encoding='32FC1')
        self.depth_pub.publish(depth_msg)
        
        self.left_img = None
        self.right_img = None
```

### 深度融合

```python
class DepthFusion:
    def __init__(self):
        self.depth_images = []
        self.camera_poses = []
        
    def add_depth(self, depth, pose):
        self.depth_images.append(depth)
        self.camera_poses.append(pose)
        
    def fuse(self, method='tsdf'):
        """TSDF 融合"""
        if method == 'tsdf':
            return self.tsdf_fusion()
        elif method == 'median':
            return self.median_fusion()
            
    def tsdf_fusion(self):
        """TSDF 体积融合"""
        volume = np.zeros((100, 100, 100), dtype=np.float32)
        voxel_size = 0.01
        
        for depth, pose in zip(self.depth_images, self.camera_poses):
            # 投影深度到体积
            points = self.depth_to_pointcloud(depth, pose)
            
            for point in points:
                voxel_idx = (point / voxel_size).astype(int)
                if 0 <= voxel_idx[0] < volume.shape[0]:
                    volume[tuple(voxel_idx)] += 1
                    
        return volume
        
    def depth_to_pointcloud(self, depth, pose):
        """深度图转点云"""
        h, w = depth.shape
        points = []
        for v in range(h):
            for u in range(w):
                z = depth[v, u]
                if z > 0:
                    x = (u - w/2) * z / 500
                    y = (v - h/2) * z / 500
                    points.append([x, y, z])
        return np.array(points)
        
    def median_fusion(self):
        """中值融合"""
        stacked = np.stack(self.depth_images, axis=0)
        return np.median(stacked, axis=0)
```
