---
name: camera-calibration
description: OpenCV4 相机标定技能 - 单目/双目标定、畸变校正、立体匹配、深度估计、3D 重建
user-invocable: true
argument-hint: 相机标定 OR 畸变校正 OR 立体匹配 OR 深度估计 OR 3D重建 OR 内参 OR 外参
---

# OpenCV4 Camera Calibration Skill

> 相机标定与立体视觉完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 单目相机标定（内参）
- 双目相机标定（内外参）
- 畸变校正
- 立体校正（极线校正）
- 立体匹配和深度估计
- 3D 重建

---

## 快速参考

### 标定板生成

```python
import cv2
import numpy as np
import glob

# 生成棋盘格标定板
def generate_chessboard(size=(9, 6), square_size=1.0, save_path='chessboard.png'):
    objp = np.zeros((size[0]*size[1], 3), np.float32)
    objp[:, :2] = np.mgrid[0:size[0], 0:size[1]].T.reshape(-1, 2) * square_size
    
    fig, ax = plt.subplots(figsize=(8, 6))
    ax.set_xlim(0, size[0])
    ax.set_ylim(0, size[1])
    ax.set_aspect('equal')
    ax.set_facecolor('white')
    
    for i in range(size[0] + 1):
        ax.axvline(i, color='black', linewidth=1)
    for i in range(size[1] + 1):
        ax.axhline(i, color='black', linewidth=1)
    
    plt.axis('off')
    plt.savefig(save_path, dpi=150, bbox_inches='tight', 
                facecolor='white', edgecolor='none')
    plt.close()

# 或使用 OpenCV 打印标定板
# 国际象棋：9x6 角点，80mm 格子
# 圆形标定板：4x11 圆点阵列
```

### 单目相机标定

```python
import cv2
import numpy as np
import glob

# 标定板参数
objp = np.zeros((6*9, 3), np.float32)
objp[:, :2] = np.mgrid[0:9, 0:6].T.reshape(-1, 2)
objp *= 25  # 格子大小 mm

# 存储所有图像的点
objpoints = []  # 3D 点
imgpoints = []  # 2D 点

images = glob.glob('calibration/*.jpg')
img_size = None

for fname in images:
    img = cv2.imread(fname)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    img_size = gray.shape[::-1]
    
    # 查找棋盘格角点
    ret, corners = cv2.findChessboardCorners(gray, (9, 6), None)
    
    if ret:
        objpoints.append(objp)
        # 亚像素精度优化
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
        corners2 = cv2.cornerSubPix(gray, corners, (11, 11), (-1, -1), criteria)
        imgpoints.append(corners2)
        
        # 可视化
        cv2.drawChessboardCorners(img, (9, 6), corners2, ret)
        cv2.imshow('Corners', img)
        cv2.waitKey(500)

cv2.destroyAllWindows()

# 标定
ret, camera_matrix, dist_coeffs, rvecs, tvecs = cv2.calibrateCamera(
    objpoints, imgpoints, img_size, None, None)

print(f"Camera Matrix:\n{camera_matrix}")
print(f"Distortion Coefficients:\n{dist_coeffs}")

# 保存标定结果
np.savez('calibration.npz', 
         camera_matrix=camera_matrix,
         dist_coeffs=dist_coeffs,
         rvecs=rvecs,
         tvecs=tvecs)
```

### 畸变校正

```python
# 加载标定结果
data = np.load('calibration.npz')
camera_matrix = data['camera_matrix']
dist_coeffs = data['dist_coeffs']

# 读取图像
img = cv2.imread('test.jpg')
h, w = img.shape[:2]

# 方法1：矫正映射
new_camera_matrix, roi = cv2.getOptimalNewCameraMatrix(
    camera_matrix, dist_coeffs, (w, h), 1, (w, h))
mapx, mapy = cv2.initUndistortRectifyMap(
    camera_matrix, dist_coeffs, None, new_camera_matrix, (w, h), 5)
undistorted = cv2.remap(img, mapx, mapy, cv2.INTER_LINEAR)

# 方法2：一步校正
undistorted = cv2.undistort(img, camera_matrix, dist_coeffs, None, new_camera_matrix)

# 裁剪 ROI 区域
x, y, w, h = roi
undistorted = undistorted[y:y+h, x:x+w]
```

### 双目相机标定

```python
import cv2
import numpy as np
import glob

# 左右相机标定板点
objp = np.zeros((6*9, 3), np.float32)
objp[:, :2] = np.mgrid[0:9, 0:6].T.reshape(-1, 2) * 25

objpoints_l, imgpoints_l = [], []
objpoints_r, imgpoints_r = [], []

# 读取左右图像
images_l = sorted(glob.glob('stereo/left/*.jpg'))
images_r = sorted(glob.glob('stereo/right/*.jpg'))

for fname_l, fname_r in zip(images_l, images_r):
    img_l = cv2.imread(fname_l)
    img_r = cv2.imread(fname_r)
    gray_l = cv2.cvtColor(img_l, cv2.COLOR_BGR2GRAY)
    gray_r = cv2.cvtColor(img_r, cv2.COLOR_BGR2GRAY)
    
    ret_l, corners_l = cv2.findChessboardCorners(gray_l, (9, 6), None)
    ret_r, corners_r = cv2.findChessboardCorners(gray_r, (9, 6), None)
    
    if ret_l and ret_r:
        objpoints_l.append(objp)
        objpoints_r.append(objp)
        # 亚像素优化
        corners_l = cv2.cornerSubPix(gray_l, corners_l, (11,11), (-1,-1),
                                       (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
        corners_r = cv2.cornerSubPix(gray_r, corners_r, (11,11), (-1,-1),
                                       (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
        imgpoints_l.append(corners_l)
        imgpoints_r.append(corners_r)

# 分别标定左右相机
ret_l, mtx_l, dist_l, _, _ = cv2.calibrateCamera(objpoints_l, imgpoints_l, gray_l.shape[::-1], None, None)
ret_r, mtx_r, dist_r, _, _ = cv2.calibrateCamera(objpoints_r, imgpoints_r, gray_r.shape[::-1], None, None)

# 双目标定
ret, mtx_l, dist_l, mtx_r, dist_r, R, T, E, F = cv2.stereoCalibrate(
    objpoints_l, imgpoints_l, imgpoints_r,
    mtx_l, dist_l, mtx_r, dist_r,
    gray_l.shape[::-1],
    flags=cv2.CALIB_FIX_INTRINSIC)

print(f"Rotation R:\n{R}")
print(f"Translation T:\n{T}")
```

### 立体校正和匹配

```python
# 立体校正
R1, R2, P1, P2, Q, _, _ = cv2.stereoRectify(
    mtx_l, dist_l, mtx_r, dist_r,
    gray_l.shape[::-1], R, T)

# 计算映射表
map1_l, map2_l = cv2.initUndistortRectifyMap(mtx_l, dist_l, R1, P1, gray_l.shape[::-1], cv2.CV_32FC2)
map1_r, map2_r = cv2.initUndistortRectifyMap(mtx_r, dist_r, R2, P2, gray_r.shape[::-1], cv2.CV_32FC2)

# 校正图像
rect_l = cv2.remap(img_l, map1_l, map2_l, cv2.INTER_LINEAR)
rect_r = cv2.remap(img_r, map1_r, map2_r, cv2.INTER_LINEAR)

# SGBM 立体匹配
stereo = cv2.StereoSGBM_create(minDisparity=0, numDisparities=64, blockSize=9)
disparity = stereo.compute(rect_l, rect_r)

# 转换为深度图
depth = (mtx_l[0,0] * T[0,0]) / disparity
```

---

## ROS2 集成

```python
# ROS2 相机标定
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2
import numpy as np

class CameraCalibrator(Node):
    def __init__(self):
        super().__init__('camera_calibrator')
        self.bridge = CvBridge()
        self.objpoints = []
        self.imgpoints = []
        self.objp = np.zeros((6*9, 3), np.float32)
        self.objp[:, :2] = np.mgrid[0:9, 0:6].T.reshape(-1, 2)
        
        self.subscription = self.create_subscription(
            Image, '/camera/image_raw', self.calibration_callback, 10)
    
    def calibration_callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        ret, corners = cv2.findChessboardCorners(gray, (9, 6), None)
        
        if ret:
            corners2 = cv2.cornerSubPix(gray, corners, (11,11), (-1,-1),
                                         (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001))
            self.objpoints.append(self.objp)
            self.imgpoints.append(corners2)
            cv2.drawChessboardCorners(img, (9, 6), corners2, ret)
        
        cv2.imshow('Calibration', img)
        cv2.waitKey(1)
    
    def calibrate(self, img_size):
        ret, mtx, dist, _, _ = cv2.calibrateCamera(
            self.objpoints, self.imgpoints, img_size, None, None)
        return mtx, dist
```

---

## 最佳实践

1. **标定板准备**：
   - 打印在高精度纸上，或使用显示器显示
   - 确保标定板平整无褶皱
   - 格子尺寸精确（常用 25mm 或 30mm）

2. **标定图像采集**：
   - 至少 15-20 张图像
   - 覆盖整个视野（中心和边缘）
   - 不同角度和距离（俯仰、偏航、滚动）
   - 光照均匀，避免反光

3. **标定质量评估**：
   - 重投影误差 < 0.5 像素
   - 检查各图像的角点检测精度
   - 剔除误差大的图像重新标定

4. **双目标定**：
   - 确保左右相机同步采集
   - 两相机在同一平面上（简化标定）
   - 基线距离影响深度精度

---

## 相关技能

- [opencv-image-processing](./image-processing) - 图像处理基础
- [opencv-depth-estimation](./depth-estimation) - 深度估计
