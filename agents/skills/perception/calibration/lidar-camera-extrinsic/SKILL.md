---
name: lidar-camera-extrinsic
description: 激光-相机外参标定技能 - 自动标定、手眼标定、标定板法、ROS2 标定
argument-hint: "外参标定" / "extrinsic" / "手眼标定" / "lidar camera calibration"
user-invocable: true
---

# 激光-相机外参标定技能

> 激光雷达与相机之间的外参标定

---

## 何时使用

当需要以下帮助时使用此技能：
- 激光-相机外参标定
- 手眼标定
- 标定板法
- 自动标定
- 标定结果验证

---

## 核心实现

### 外参标定 (标定板法)

```python
import numpy as np
import cv2
from scipy.spatial.transform import Rotation

class LidarCameraCalibrator:
    def __init__(self):
        self.T_lidar_cam = np.eye(4)  # 激光雷达到相机
        self.K = None  # 相机内参
        
    def calibrate(self, lidar_corners, camera_corners, K=None):
        """
        外参标定
        lidar_corners: 标定板角点的激光雷达坐标 (N, 3)
        camera_corners: 标定板角点的图像坐标 (N, 2)
        K: 相机内参
        """
        if K is None:
            K = self.K
            
        # 使用 PnP 求解
        # 3D-2D 对应
        success, rvec, tvec = cv2.solvePnP(
            lidar_corners, camera_corners, K, np.zeros(5),
            flags=cv2.SOLVEPNP_ITERATIVE)
            
        if success:
            # 旋转矩阵
            R, _ = cv2.Rodrigues(rvec)
            self.T_lidar_cam = np.eye(4)
            self.T_lidar_cam[:3, :3] = R
            self.T_lidar_cam[:3, 3] = tvec.flatten()
            
        return self.T_lidar_cam
        
    def project_lidar_to_camera(self, lidar_points):
        """将点云投影到图像"""
        # 变换到相机坐标系
        points_cam = (self.T_lidar_cam @ 
                     np.hstack([lidar_points, np.ones((len(lidar_points), 1))]).T).T
        
        # 过滤前景点
        valid = points_cam[:, 2] > 0
        points_cam = points_cam[valid]
        
        # 投影到像素
        points_2d = (self.K @ points_cam[:, :3].T).T
        points_2d[:, 0] /= points_2d[:, 2]
        points_2d[:, 1] /= points_2d[:, 2]
        
        return points_2d[:, :2], valid
        
    def validate(self, test_lidar, test_image):
        """验证标定精度"""
        projected, valid = self.project_lidar_to_camera(test_lidar)
        
        # 计算重投影误差
        # ...
```

### 手眼标定 (Eye-in-Hand)

```python
class EyeInHandCalibrator:
    """机械臂手眼标定"""
    
    def __init__(self):
        self.A = []  # 相机相对于物体的变换
        self.B = []  # 末端相对于基座的变换
        
    def add_observation(self, T_cam_obj, T_base_end):
        """添加观测"""
        self.A.append(T_cam_obj)  # 相机观察到标定板
        self.B.append(T_base_end)  # 机械臂末端位姿
        
    def calibrate(self):
        """
        AX = XB 求解
        X: 相机相对于末端的变换
        """
        # 使用 Tsai 方法
        # ...
        
        return X  # 相机到末端的变换
        
    @staticmethod
    def compute_relative_transform(T1, T2):
        """计算相对变换 T = T1^-1 * T2"""
        return np.linalg.inv(T1) @ T2
```

### 自动标定

```python
class AutomaticCalibrator:
    """自动化外参标定"""
    
    def __init__(self):
        self.calibrator = LidarCameraCalibrator()
        
    def run_autocalibration(self, bag_file):
        """
        自动从 bag 文件进行标定
        1. 检测标定板
        2. 匹配激光和图像数据
        3. 求解外参
        """
        import rosbag2_py
        
        reader = rosbag2_py.SequentialReader()
        reader.open(bag_file)
        
        observations = []
        
        while reader.has_next():
            topic, msg, t = reader.read_next():
                if topic == '/detections_2d':
                    # 2D 检测
                    pass
                elif topic == '/lidar_corners':
                    # 3D 角点
                    pass
                    
                # 匹配时间戳
                if self.is_matched():
                    observations.append(self.create_observation())
                    
        # 求解外参
        self.calibrator.calibrate(observations)
        
        return self.calibrator.T_lidar_cam
```
