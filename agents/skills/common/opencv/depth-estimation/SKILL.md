---
name: opencv-depth-estimation
description: OpenCV4 深度估计技能 - 单目深度估计、立体深度估计、ToF、LiDAR 融合、结构光
user-invocable: true
argument-hint: "深度估计" / "深度学习" / "单目" / "立体匹配" / "ToF" / "LiDAR" / "3D点云"
---

# OpenCV4 Depth Estimation Skill

> 深度估计完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 单目深度估计（MiDaS、DPT）
- 双目深度估计（立体匹配）
- RGB-D 相机（RealSense、Kinect）
- ToF（Time of Flight）深度处理
- 深度与点云转换
- 深度补全和滤波

---

## 快速参考

### 单目深度估计（MiDaS）

```python
import cv2
import numpy as np

# 加载 MiDaS 模型
model = cv2.dnn.readNet('MiDaS/model.onnx')

# 预处理
def preprocess_midas(img):
    original = img.copy()
    input_size = (384, 384)
    img = cv2.resize(img, input_size)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB) / 255.0
    img = (img - np.array([0.485, 0.456, 0.406])) / np.array([0.229, 0.224, 0.225])
    img = img.transpose(2, 0, 1)
    return img[np.newaxis, :, :, :].astype(np.float32), original

# 推理
def estimate_depth(model, img):
    input_tensor, original = preprocess_midas(img)
    model.setInput(input_tensor)
    depth = model.forward()
    depth = cv2.resize(depth[0, 0], (original.shape[1], original.shape[0]))
    depth = (depth - depth.min()) / (depth.max() - depth.min()) * 255.0
    return depth.astype(np.uint8)

# 伪彩色显示
depth_colored = cv2.applyColorMap(cv2.convertScaleAbs(depth, alpha=0.03), cv2.COLORMAP_JET)
```

### 双目深度估计

```python
import cv2
import numpy as np

# 加载标定参数
data = np.load('stereo_calibration.npz')
mtx_l = data['mtx_l']
mtx_r = data['mtx_r']
R = data['R']
T = data['T']
dist_l = data['dist_l']
dist_r = data['dist_r']

# 立体校正
R1, R2, P1, P2, Q, _, _ = cv2.stereoRectify(
    mtx_l, dist_l, mtx_r, dist_r,
    img_size, R, T)

# 计算映射
map1_l, map2_l = cv2.initUndistortRectifyMap(mtx_l, dist_l, R1, P1, img_size, cv2.CV_32FC2)
map1_r, map2_r = cv2.initUndistortRectifyMap(mtx_r, dist_r, R2, P2, img_size, cv2.CV_32FC2)

# 校正图像
rect_l = cv2.remap(img_l, map1_l, map2_l, cv2.INTER_LINEAR)
rect_r = cv2.remap(img_r, map1_r, map2_r, cv2.INTER_LINEAR)

# SGBM 立体匹配
stereo = cv2.StereoSGBM_create(
    minDisparity=0,
    numDisparities=64,
    blockSize=9,
    uniquenessRatio=10,
    speckleWindowSize=100,
    speckleRange=32,
    disp12MaxDiff=1
)
disparity = stereo.compute(rect_l, rect_r)

# 视差转深度
focal_length = mtx_l[0, 0]
baseline = abs(T[0, 0])
depth = (focal_length * baseline) / (disparity + 1e-6)
```

### RGB-D 点云生成

```python
import cv2
import numpy as np
from open3d import *

# 从深度图和内参生成点云
def depth_to_pointcloud(depth, intrinsic):
    h, w = depth.shape
    fx, fy = intrinsic[0, 0], intrinsic[1, 1]
    cx, cy = intrinsic[0, 2], intrinsic[1, 2]
    
    points = []
    colors = []
    
    for y in range(h):
        for x in range(w):
            z = depth[y, x] / 1000.0  # mm to m
            if z <= 0:
                continue
            X = (x - cx) * z / fx
            Y = (y - cy) * z / fy
            points.append([X, y, z])
            colors.append([1, 1, 1])
    
    pcd = PointCloud()
    pcd.points = Vector3dVector(np.array(points))
    pcd.colors = Vector3dVector(np.array(colors) / 255.0)
    return pcd

# 使用 OpenCV 的 reprojectImageTo3D
points_3d = cv2.reprojectImageTo3D(disparity, Q)
mask = disparity > disparity.min()
points = points_3d[mask]
```

### RealSense RGB-D 处理

```python
import pyrealsense2 as rs

# 初始化 pipeline
pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.depth, 640, 480, rs.format.z16, 30)
config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)

profile = pipeline.start(config)

# 获取内参
frames = pipeline.wait_for_frames()
depth_frame = frames.get_depth_frame()
color_frame = frames.get_color_frame()
intrinsic = depth_frame.profile.as_video_stream_profile().intrinsics

# 深度处理
depth = np.asanyarray(depth_frame.get_data())
color = np.asanyarray(color_frame.get_data())

# 深度滤波
depth_filtered = cv2.bilateralFilter(depth, 5, 30, 30)

# 深度转伪彩色
depth_colored = cv2.applyColorMap(cv2.convertScaleAbs(depth, alpha=0.03), cv2.COLORMAP_JET)
```

---

## 深度补全

```python
# 稀疏深度补全（使用 RGB 引导）
def fill_depth_holes(depth, rgb):
    # 安装 opencv-contrib
    # depth = cv2.xphoto.inpaint(depth, mask, cv2.xphoto.INPAINT_SHADOWS)
    pass

# 导向滤波深度优化
def guided_depth_filter(depth, rgb, epsilon=0.01):
    # 引导滤波
    guided_filter = cv2.ximgproc.createGuidedFilter(rgb, 9, epsilon)
    depth_filtered = guided_filter.filter(depth.astype(np.float32))
    return depth_filtered
```

---

## C++ 实现

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/ximgproc.hpp>

// MiDaS 单目深度估计
cv::Mat estimateDepthMidas(cv::dnn::Net& net, const cv::Mat& img) {
    cv::Mat input;
    cv::dnn::blobFromImage(img, input, 1/255.0, cv::Size(384, 384));
    net.setInput(input);
    cv::Mat depth = net.forward();
    
    cv::resize(depth, depth, img.size());
    cv::normalize(depth, depth, 0, 255, cv::NORM_MINMAX);
    return depth;
}

// 双目深度估计
cv::Mat computeDepthStereo(cv::Mat& rect_l, cv::Mat& rect_r, 
                           cv::Mat& mtx_l, cv::Mat& T) {
    cv::Ptr<cv::StereoSGBM> stereo = cv::StereoSGBM::create(
        0, 64, 9, 8*9*9, 32*9*9, 1, 63, 10, 100, 32);
    
    cv::Mat disparity;
    stereo->compute(rect_l, rect_r, disparity);
    
    // 视差转深度
    cv::Mat depth;
    float f = mtx_l.at<float>(0, 0);
    float b = abs(T.at<float>(0, 0));
    cv::convertScaleAbs(disparity, depth, f * b / (disparity + 1e-6));
    return depth;
}
```

---

## 最佳实践

1. **单目 vs 双目**：
   - 单目：简单、便宜，但尺度不确定
   - 双目：尺度准确，需要标定和同步

2. **立体匹配优化**：
   - 纹理丰富区域效果好
   - 光照变化大时效果差
   - 基线距离影响范围和精度

3. **深度滤波**：
   - 双边滤波：保边深度去噪
   - 时序滤波：多帧平均
   - 导向滤波：RGB 引导优化

4. **点云处理**：
   - 下采样：`VoxelGrid` 滤波
   - 去噪：`StatisticalOutlierRemoval`
   - 重投影：使用 `projectPoints`

---

## 相关技能

- [opencv-camera-calibration](./camera-calibration) - 相机标定
- [opencv-dnn-inference](./dnn-inference) - DNN 推理
