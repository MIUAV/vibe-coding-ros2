---
name: opencv-video-analysis
description: OpenCV4 视频分析技能 - 视频读取/保存、光流、背景分离、帧差分、运动检测
user-invocable: true
argument-hint: "视频分析" / "光流" / "背景分离" / "运动检测" / "视频处理"
---

# OpenCV4 Video Analysis Skill

> 视频分析完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 视频读取和保存
- 光流估计（稀疏/稠密）
- 背景分离和前景检测
- 帧差分和运动检测
- 物体追踪
- 视频稳定化

---

## 快速参考

### 视频读取和保存

```python
import cv2

# 读取视频
cap = cv2.VideoCapture('video.mp4')
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    # 处理帧
    cv2.imshow('Frame', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
cap.release()
cv2.destroyAllWindows()

# 保存视频
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter('output.mp4', fourcc, 30.0, (w, h))
out.write(frame)
out.release()

# 获取视频信息
fps = cap.get(cv2.CAP_PROP_FPS)
width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
```

### 光流（稠密）

```python
import cv2
import numpy as np

cap = cv2.VideoCapture('video.mp4')

# 读取第一帧
ret, old_frame = cap.read()
old_gray = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)

# Shi-Tomasi 角点检测
corners = cv2.goodFeaturesToTrack(old_gray, maxCorners=100, 
                                   qualityLevel=0.3, minDistance=7)
corners = np.int0(corners)

# 光流参数
lk_params = dict(winSize=(21, 21), maxLevel=3,
                  criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 30, 0.01))

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # 计算光流
    new_corners, status, _ = cv2.calcOpticalFlowPyrLK(
        old_gray, frame_gray, corners, None, **lk_params)
    
    # 选择有效点
    good_old = corners[status.flatten() == 1]
    good_new = new_corners[status.flatten() == 1]
    
    # 绘制轨迹
    for new, old in zip(good_new, good_old):
        a, b = new.ravel()
        c, d = old.ravel()
        cv2.line(frame, (a, b), (c, d), (0, 255, 0), 2)
        cv2.circle(frame, (a, b), 5, (0, 0, 255), -1)
    
    cv2.imshow('Optical Flow', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    
    old_gray = frame_gray.copy()
    corners = good_new.reshape(-1, 1, 2)

cap.release()
cv2.destroyAllWindows()
```

### 稠密光流（Farneback）

```python
# 稠密光流
prev = cv2.cvtColor(old_frame, cv2.COLOR_BGR2GRAY)
next = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

flow = cv2.calcOpticalFlowFarneback(prev, next, None, 
                                      0.5, 3, 15, 3, 5, 1.2, 0)

# 绘制光流
h, w = frame.shape[:2]
hsv = cv2.createTrackbar('Hue', 'flow', 0, 179, lambda x: None)
flow_hsv = np.zeros_like(frame)
flow_hsv[..., 1] = 255

mag, ang = cv2.cartToPolar(flow[..., 0], flow[..., 1])
flow_hsv[..., 0] = ang * 180 / np.pi / 2
flow_hsv[..., 2] = cv2.normalize(mag, None, 0, 255, cv2.NORM_MINMAX)
flow_bgr = cv2.cvtColor(flow_hsv, cv2.COLOR_HSV2BGR)
```

### 背景分离

```python
# 创建背景分离器
fgbg = cv2.createBackgroundSubtractorMOG2(history=500, varThreshold=16, detectShadows=True)
# 或 KNN
# fgbg = cv2.createBackgroundSubtractorKNN(history=500, dist2Threshold=400)

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    # 获取前景掩码
    fgmask = fgbg.apply(frame)
    
    # 形态学处理
    fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_OPEN, kernel)
    fgmask = cv2.morphologyEx(fgmask, cv2.MORPH_CLOSE, kernel)
    
    cv2.imshow('Foreground', fgmask)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
```

### 帧差分

```python
ret, frame1 = cap.read()
ret, frame2 = cap.read()

while cap.isOpened():
    ret, frame3 = cap.read()
    if not ret:
        break
    
    # 差分
    diff1 = cv2.absdiff(frame2, frame1)
    diff2 = cv2.absdiff(frame3, frame2)
    
    # 合并
    diff = cv2.bitwise_and(diff1, diff2)
    
    # 灰度化和阈值处理
    gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 25, 255, cv2.THRESH_BINARY)
    
    # 轮廓检测
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for contour in contours:
        if cv2.contourArea(contour) > 500:
            x, y, w, h = cv2.boundingRect(contour)
            cv2.rectangle(frame3, (x, y), (x+w, y+h), (0, 255, 0), 2)
    
    frame1 = frame2
    frame2 = frame3

cap.release()
```

---

## C++ 实现

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/video.hpp>
#include <opencv2/videoio.hpp>

using namespace cv;

// 背景分离
Ptr<BackgroundSubtractor> pBackSub = createBackgroundSubtractorMOG2(500, 16, true);
Mat fgMask, frame;
while (capture.read(frame)) {
    pBackSub->apply(frame, fgMask);
    imshow("Foreground", fgMask);
    if (waitKey(30) == 'q') break;
}

// 光流
vector<Point2f> corners, newCorners;
goodFeaturesToTrack(prevGray, corners, 100, 0.3, 7);
calcOpticalFlowPyrLK(prevGray, currGray, corners, newCorners, status, err, Size(21,21), 3);
```

---

## 最佳实践

1. **光流选择**：
   - 稀疏光流：实时性要求高、只需要关键点
   - 稠密光流：需要完整运动信息

2. **背景分离器选择**：
   - MOG2：复杂场景、需检测阴影
   - KNN：简单场景、更快
   - GMG：动态背景变化

3. **运动检测**：
   - 三帧差分比两帧差分更稳定
   - 结合形态学操作消除噪声
   - 最小轮廓面积过滤

4. **视频稳定化**：
   - 使用 `vstab` 模块
   - 两步：轨迹估计 + 平滑

---

## 相关技能

- [opencv-image-processing](./image-processing) - 图像处理
- [opencv-feature-detection](./feature-detection) - 特征检测
