---
name: visual-slam
description: 视觉 SLAM 技能 - ORB-SLAM3、VINS-Fusion、RTAB-Map、ROS2 视觉里程计
argument-hint: "视觉SLAM" / "ORB-SLAM3" / "VINS" / "visual slam"
user-invocable: true
---

# 视觉 SLAM 技能

> 视觉同步定位与地图构建

---

## 何时使用

当需要以下帮助时使用此技能：
- ORB-SLAM3 部署
- VINS-Fusion 配置
- 单目/双目/深度 SLAM
- 视觉里程计
- 地图复用

---

## 核心实现

### ORB-SLAM3 ROS2 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from nav_msgs.msg import Odometry
import numpy as np

class ORBSLAM3Node(Node):
    def __init__(self):
        super().__init__('orb_slam3')
        
        # 初始化 ORB-SLAM3
        # self.slam = ORBSLAM3()
        
        # 订阅图像
        self.image_sub = self.create_subscription(
            Image, '/camera/image_raw', self.image_callback, 10)
        self.info_sub = self.create_subscription(
            CameraInfo, '/camera/camera_info', self.info_callback, 10)
            
        # 发布
        self.odom_pub = self.create_publisher(Odometry, '/visual_odom', 10)
        self.map_pub = self.create_publisher(PointCloud2, '/map_points', 10)
        
        self.K = None
        self.Tcw = None
        
    def image_callback(self, msg):
        # 转换图像
        cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='mono8')
        
        # 跟踪
        self.Tcw = self.slam.track_monocular(cv_image, msg.header.stamp.sec)
        
        # 发布
        if self.Tcw is not None:
            self.publish_odom()
            
    def info_callback(self, msg):
        self.K = np.array(msg.k).reshape(3, 3)
        self.slam.set_camera_params(self.K)
```

### VINS-Fusion 配置

```yaml
# config/camera-imu.yaml
header:
  seq: 0
  stamp: 0
  frame_id: world

model_configuration:
  fx: 500.0
  fy: 500.0
  cx: 320.0
  cy: 240.0
  k1: 0.0
  p1: 0.0
  p2: 0.0
  k2: 0.0

extrinsicRotation: [1, 0, 0, 0, 1, 0, 0, 0, 1]
extrinsicTranslation: [0, 0, 0]

# VINS 节点配置
 vins_config:
   max_solver_time: 0.04
   max_num_iterations: 10
   keyframe_parallax: 10.0
   acceleration_noise: 0.001
   gyroscope_noise: 0.001
   accelerometer_bias: 0.0001
```

### 视觉里程计

```python
class VisualOdometry:
    def __init__(self, K):
        self.K = K
        self.prev_features = None
        self.prev_pose = np.eye(4)
        
    def compute_pose(self, image):
        """计算相机位姿"""
        # 1. 特征检测
        features = self.detect_features(image)
        
        if self.prev_features is None:
            self.prev_features = features
            return np.eye(4)
            
        # 2. 特征匹配
        matches = self.match_features(self.prev_features, features)
        
        # 3. 计算本质矩阵
        E, mask = self.compute_essential_matrix(
            self.prev_features, features, matches)
            
        # 4. 恢复位姿
        R, t, mask = self.recover_pose(E, self.prev_features, features, self.K)
        
        # 5. 更新
        pose = np.eye(4)
        pose[:3, :3] = R
        pose[:3, 3] = t
        
        self.prev_features = features
        self.prev_pose = pose
        
        return pose
        
    def detect_features(self, image):
        """检测特征点"""
        # ORB 特征
        orb = cv2.ORB_create()
        kp, des = orb.detectAndCompute(image, None)
        return {'keypoints': kp, 'descriptors': des}
        
    def match_features(self, prev, curr):
        """特征匹配"""
        bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
        matches = bf.match(prev['descriptors'], curr['descriptors'])
        return matches
        
    def compute_essential_matrix(self, prev, curr, matches):
        """计算本质矩阵"""
        # 选取匹配点
        pts1 = np.float32([prev['keypoints'][m.queryIdx].pt for m in matches])
        pts2 = np.float32([curr['keypoints'][m.trainIdx].pt for m in matches])
        
        E, mask = cv2.findEssentialMat(pts1, pts2, self.K)
        return E, mask
        
    def recover_pose(self, E, pts1, pts2, K):
        """从本质矩阵恢复位姿"""
        _, R, t, mask = cv2.recoverPose(E, pts1, pts2, K)
        return R, t, mask
```
