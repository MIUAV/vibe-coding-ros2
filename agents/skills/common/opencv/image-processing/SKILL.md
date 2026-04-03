---
name: opencv-image-processing
description: OpenCV4 图像处理技能 - 几何变换、滤波、形态学、阈值处理、边缘检测
user-invocable: true
argument-hint: "图像处理" / "滤波" / "形态学" / "边缘检测" / "几何变换"
---

# OpenCV4 Image Processing Skill

> 图像处理完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 图像几何变换（缩放、旋转、仿射）
- 滤波和模糊操作
- 形态学操作（开、闭、膨胀、腐蚀）
- 阈值处理和分割
- 边缘检测和轮廓提取

---

## 快速参考

### 几何变换

```python
import cv2
import numpy as np

# 缩放
resized = cv2.resize(img, (width, height))
resized = cv2.resize(img, None, fx=0.5, fy=0.5)  # 比例缩放

# 旋转
(h, w) = img.shape[:2]
center = (w // 2, h // 2)
M = cv2.getRotationMatrix2D(center, 45, 1.0)  # 旋转45度
rotated = cv2.warpAffine(img, M, (w, h))

# 仿射变换
pts1 = np.float32([[50,50], [200,50], [50,200]])
pts2 = np.float32([[10,100], [200,50], [100,250]])
M = cv2.getAffineTransform(pts1, pts2)
warped = cv2.warpAffine(img, M, (w, h))

# 透视变换
pts1 = np.float32([[0,0], [300,0], [0,300], [300,300]])
pts2 = np.float32([[0,0], [300,0], [150,300], [150,0]])
M = cv2.getPerspectiveTransform(pts1, pts2)
result = cv2.warpPerspective(img, M, (300, 300))
```

### 滤波操作

```python
# 均值滤波
blur = cv2.blur(img, (5,5))

# 高斯滤波
gaussian = cv2.GaussianBlur(img, (5,5), 0)

# 中值滤波
median = cv2.medianBlur(img, 5)

# 双边滤波（保边）
bilateral = cv2.bilateralFilter(img, 9, 75, 75)

# 卷积
kernel = np.ones((5,5), np.float32) / 25
convolved = cv2.filter2D(img, -1, kernel)
```

### 形态学操作

```python
kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (5,5))

# 腐蚀
eroded = cv2.erode(img, kernel, iterations=1)

# 膨胀
dilated = cv2.dilate(img, kernel, iterations=1)

# 开运算（先腐蚀后膨胀）
opened = cv2.morphologyEx(img, cv2.MORPH_OPEN, kernel)

# 闭运算（先膨胀后腐蚀）
closed = cv2.morphologyEx(img, cv2.MORPH_CLOSE, kernel)

# 梯度运算
gradient = cv2.morphologyEx(img, cv2.MORPH_GRADIENT, kernel)
```

### 阈值处理

```python
# 全局阈值
_, thresh = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)

# 自适应阈值
adaptive_thresh = cv2.adaptiveThreshold(gray, 255, 
    cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 11, 2)

# Otsu 自动阈值
_, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
```

### 边缘检测与轮廓

```python
# Canny 边缘检测
edges = cv2.Canny(img, 50, 150)

# Sobel 梯度
sobelx = cv2.Sobel(img, cv2.CV_64F, 1, 0, ksize=3)
sobely = cv2.Sobel(img, cv2.CV_64F, 0, 1, ksize=3)
sobel = cv2.bitwise_or(sobelx, sobely)

# Laplacian 边缘
laplacian = cv2.Laplacian(img, cv2.CV_64F)

# 轮廓提取
contours, hierarchy = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
cv2.drawContours(img, contours, -1, (0,255,0), 2)
```

---

## C++ 实现

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc.hpp>

using namespace cv;

// 几何变换
Mat rotate(const Mat& img, double angle) {
    Point2f center(img.cols/2.0, img.rows/2.0);
    Mat M = getRotationMatrix2D(center, angle, 1.0);
    Mat rotated;
    warpAffine(img, rotated, M, img.size());
    return rotated;
}

// 高斯滤波
Mat gaussianBlur(const Mat& img, int ksize, double sigma) {
    Mat blurred;
    GaussianBlur(img, blurred, Size(ksize, ksize), sigma);
    return blurred;
}

// Canny 边缘检测
Mat cannyEdge(const Mat& img, double t1, double t2) {
    Mat edges;
    Canny(img, edges, t1, t2);
    return edges;
}
```

---

## 最佳实践

1. **滤波选择**：
   - 去噪：`bilateralFilter` > `GaussianBlur` > `medianBlur`
   - 边缘保护：`bilateralFilter`
   - 实时处理：`boxFilter` with normalization

2. **形态学结构元素**：
   - `MORPH_RECT` - 矩形
   - `MORPH_ELLIPSE` - 椭圆
   - `MORPH_CROSS` - 十字

3. **边缘检测参数**：
   - 低阈值：捕获弱边缘
   - 高阈值：确定强边缘
   - 推荐比例：低:高 = 1:2 或 1:3

---

## 相关技能

- [opencv-basics](./basics) - 基础操作
- [opencv-feature-detection](./feature-detection) - 特征检测
- [opencv-camera-calibration](./camera-calibration) - 相机标定
