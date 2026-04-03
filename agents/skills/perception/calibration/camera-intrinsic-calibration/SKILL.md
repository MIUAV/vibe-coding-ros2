---
name: camera-intrinsic-calibration
description: 相机内参标定技能 - Kalibr、ROS2 标定工具、单目/双目标定
argument-hint: 相机标定 OR intrinsic OR Kalibr OR 单目标定 OR 双目标定
user-invocable: true
---

# 相机内参标定技能

> 相机内参标定理论与 ROS2 实现

---

## 何时使用

当需要以下帮助时使用此技能：
- 单目相机标定
- 双目相机标定
- 畸变校正
- Kalibr 工具使用
- ROS2 标定

---

## 核心实现

### ROS2 相机标定

```bash
# 安装标定工具
sudo apt install ros-humble-camera-calibration

# 标定单目相机
ros2 run camera_calibration cameracalibrator --size 9x6 --square 0.025 \
    --ros-args -p image:=/camera/image_raw \
                -p camera:=/camera

# 标定双目相机
ros2 run camera_calibration stereocalibrator --size 9x6 --square 0.025 \
    --ros-args -p left:=/stereo/left/image_raw \
                -p right:=/stereo/right/image_raw
```

### Kalibr 标定

```bash
# 创建标定板配置
cat > target.yaml << EOF
target_type: 'checkerboard'
targetCols: 6
targetRows: 4
targetSpacing: 0.03
EOF

# 录制数据
ros2 bag record /camera/image_raw /camera/camera_info -o calibration.bag

# 运行 Kalibr
kalibr_calibrate_cameras --target target.yaml \
    --bag calibration.bag \
    --topic /camera/image_raw \
    --output-path kalibr_results/
```

### Python 标定实现

```python
import numpy as np
import cv2
import glob

class CameraCalibrator:
    def __init__(self, board_size=(9, 6), square_size=0.025):
        self.board_size = board_size
        self.square_size = square_size
        self.objp = self.create_object_points()
        
    def create_object_points(self):
        """创建标定板三维坐标点"""
        objp = np.zeros((self.board_size[0] * self.board_size[1], 3), np.float32)
        objp[:, :2] = np.mgrid[0:self.board_size[0], 0:self.board_size[1]].T.reshape(-1, 2)
        objp *= self.square_size
        return objp
        
    def calibrate(self, image_paths):
        """标定相机"""
        objpoints = []  # 3D points
        imgpoints = []  # 2D points
        
        for fname in image_paths:
            img = cv2.imread(fname)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # 找角点
            ret, corners = cv2.findChessboardCorners(gray, self.board_size, None)
            
            if ret:
                objpoints.append(self.objp)
                corners2 = cv2.cornerSubPix(gray, corners, (11, 11), (-1, -1),
                    criteria=(cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
                imgpoints.append(corners2)
                
        # 标定
        ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(
            objpoints, imgpoints, gray.shape[::-1], None, None)
            
        return {
            'K': mtx,  # 内参矩阵
            'dist': dist,  # 畸变系数
            'rvecs': rvecs,
            'tvecs': tvecs,
            'ret': ret
        }
        
    def undistort(self, image, K, dist):
        """校正畸变"""
        h, w = image.shape[:2]
        newK, roi = cv2.getOptimalNewCameraMatrix(K, dist, (w, h), 1, (w, h))
        
        dst = cv2.undistort(image, K, dist, None, newK)
        
        # 裁剪
        x, y, w, h = roi
        dst = dst[y:y+h, x:x+w]
        
        return dst
```

### 双目标定

```python
class StereoCalibrator:
    def __init__(self, board_size=(9, 6), square_size=0.025):
        self.board_size = board_size
        self.square_size = square_size
        self.objp = self.create_object_points()
        
    def calibrate_stereo(self, left_images, right_images):
        """双目标定"""
        # 分别标定两个相机
        retL, mtxL, distL, _, _ = self.calibrate_single(left_images)
        retR, mtxR, distR, _, _ = self.calibrate_single(right_images)
        
        # 双目标定
        objpoints = []
        imgpointsL = []
        imgpointsR = []
        
        for lImg, rImg in zip(left_images, right_images):
            grayL = cv2.cvtColor(lImg, cv2.COLOR_BGR2GRAY)
            grayR = cv2.cvtColor(rImg, cv2.COLOR_BGR2GRAY)
            
            retL, cornersL = cv2.findChessboardCorners(grayL, self.board_size, None)
            retR, cornersR = cv2.findChessboardCorners(grayR, self.board_size, None)
            
            if retL and retR:
                objpoints.append(self.objp)
                cornersL2 = cv2.cornerSubPix(grayL, cornersL, (11, 11), (-1, -1),
                    criteria=(cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
                cornersR2 = cv2.cornerSubPix(grayR, cornersR, (11, 11), (-1, -1),
                    criteria=(cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
                imgpointsL.append(cornersL2)
                imgpointsR.append(cornersR2)
                
        # 双目标定
        ret, mtxL, distL, mtxR, distR, R, T, E, F = cv2.stereoCalibrate(
            objpoints, imgpointsL, imgpointsR,
            mtxL, distL, mtxR, distR, grayL.shape[::-1])
            
        # 计算基线和焦距
        baseline = np.linalg.norm(T)
        fx = mtxL[0, 0]
        
        return {
            'K_left': mtxL, 'K_right': mtxR,
            'dist_left': distL, 'dist_right': distR,
            'R': R, 'T': T,  # 右相机相对于左相机的旋转和平移
            'E': E, 'F': F,  # 本质矩阵和基础矩阵
            'baseline': baseline,
            'rms': ret
        }
```
