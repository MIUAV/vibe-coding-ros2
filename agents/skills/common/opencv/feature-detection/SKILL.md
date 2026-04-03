---
name: feature-detection
description: OpenCV4 特征检测技能 - SIFT、SURF、ORB、AKAZE、FAST、BRISK 特征提取与匹配
user-invocable: true
argument-hint: 特征检测 OR SIFT OR ORB OR 特征匹配 OR 图像拼接
---

# OpenCV4 Feature Detection Skill

> 特征检测与匹配完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 图像特征提取（SIFT、ORB、AKAZE 等）
- 特征描述符匹配
- 图像拼接和全景图生成
- 物体识别和定位
- 几何校正

---

## 快速参考

### 特征检测器对比

| 算法 | 旋转不变 | 尺度不变 | 速度 | 专利 |
|------|----------|----------|------|------|
| SIFT | ✓ | ✓ | 慢 | 是 |
| SURF | ✓ | ✓ | 中 | 是 |
| ORB | ✓ | ✗ | 快 | 否 |
| AKAZE | ✓ | ✓ | 中 | 否 |
| FAST | ✗ | ✗ | 很快 | 否 |
| BRISK | ✓ | ✓ | 快 | 否 |

### SIFT 特征检测

```python
import cv2

# 创建 SIFT 检测器
sift = cv2.SIFT_create()

# 检测特征点和描述符
keypoints, descriptors = sift.detectAndCompute(gray, None)

# 绘制特征点
img_with_kp = cv2.drawKeypoints(img, keypoints, None, 
                                 flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)

# BFMatcher 匹配
bf = cv2.BFMatcher(cv2.NORM_L2, crossCheck=True)
matches = bf.match(descriptors1, descriptors2)

# 绘制匹配结果
result = cv2.drawMatches(img1, kp1, img2, kp2, matches, None)
```

### ORB 特征检测（实时推荐）

```python
# 创建 ORB 检测器
orb = cv2.ORB_create(nfeatures=500)

# 检测
keypoints, descriptors = orb.detectAndCompute(gray, None)

# 绘制
img_with_kp = cv2.drawKeypoints(img, keypoints, None, (0, 255, 0))

# 使用 Hamming 距离匹配（ORB 专用）
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
matches = bf.match(des1, des2)

# KNN 匹配
matches = bf.knnMatch(des1, des2, k=2)
good_matches = [m for m, n in matches if m.distance < 0.75 * n.distance]
```

### AKAZE 特征检测

```python
# 创建 AKAZE 检测器
akaze = cv2.AKAZE_create()

# 检测
keypoints, descriptors = akaze.detectAndCompute(gray, None)

# DMatcher（支持 AKAZE）
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
```

### 图像拼接

```python
def stitch_images(images):
    stitcher = cv2.Stitcher_create(cv2.STITCHER_PANORAMA)
    status, panorama = stitcher.stitch(images)
    if status == 0:
        return panorama
    else:
        raise ValueError(f"Stitching failed with status {status}")
```

---

## C++ 实现

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/xfeatures2d.hpp>
#include <opencv2/features2d.hpp>

using namespace cv;

// SIFT 特征检测
Ptr<SIFT> sift = SIFT_create();
vector<KeyPoint> keypoints;
Mat descriptors;
sift->detectAndCompute(gray, noArray(), keypoints, descriptors);

// ORB 特征检测
Ptr<ORB> orb = ORB_create();
orb->detectAndCompute(gray, noArray(), keypoints, descriptors);

// BFMatcher
BFMatcher matcher(NORM_HAMMING, true);
vector<DMatch> matches;
matcher.match(descriptors1, descriptors2, matches);

// 绘制匹配
Mat result;
drawMatches(img1, kp1, img2, kp2, matches, result);
```

---

## 特征匹配流程

```
图像1 → 特征检测 → 描述符提取
                           ↓
图像2 → 特征检测 → 描述符提取
                           ↓
                    特征匹配 (BF/FLANN)
                           ↓
                      匹配结果
                           ↓
                    去噪过滤 (Lowe's ratio)
                           ↓
                    单应性矩阵估计 (RANSAC)
                           ↓
                    透视变换/融合
```

### RANSAC 去噪

```python
# 获取匹配点坐标
src_pts = np.float32([kp1[m.queryIdx].pt for m in good_matches])
dst_pts = np.float32([kp2[m.trainIdx].pt for m in good_matches])

# 计算单应性矩阵
H, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)

# 过滤内点
inliers = [matches[i] for i in range(len(matches)) if mask[i]]
```

---

## 最佳实践

1. **算法选择**：
   - 实时应用：`ORB` > `FAST` > `BRISK`
   - 高精度需求：`SIFT` > `SURF` > `AKAZE`
   - 无专利要求：`AKAZE` > `ORB`

2. **匹配优化**：
   - 使用 Lowe's ratio test (0.75-0.8)
   - KNN 匹配比 BF 更稳定
   - 先过滤再匹配

3. **特征点数量**：
   - 纹理丰富区域：500-1000
   - 纹理稀疏区域：2000-5000

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 匹配点太少 | 降低匹配阈值或使用多尺度检测 |
| 匹配噪声多 | 提高 Lowe's ratio 阈值到 0.7 |
| 实时性差 | 使用 ORB/FAST，限制特征点数量 |

---

## 相关技能

- [opencv-image-processing](./image-processing) - 图像处理基础
- [opencv-camera-calibration](./camera-calibration) - 相机标定
- [opencv-yolo-integration](./yolo-integration) - YOLO 集成
