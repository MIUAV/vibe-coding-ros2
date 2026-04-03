---
name: basics
description: OpenCV4 基础技能 - 图像读取、显示、保存、绘制、色彩空间转换
user-invocable: true
argument-hint: opencv基础 OR 图像读取 OR imread OR imshow OR 色彩空间
---

# OpenCV4 Basics Skill

> OpenCV 基础操作完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 读取、显示、保存图像
- 在图像上绘制形状和文字
- 色彩空间转换（BGR、RGB、HSV、Gray）
- 图像属性获取
- 像素操作

---

## 快速参考

### 基础架构

```
Image (Mat) → Processing → Display/Save
     │
     ├── imread()      # 读取图像
     ├── imshow()      # 显示图像
     ├── imwrite()     # 保存图像
     ├── cvtColor()    # 色彩空间转换
     └── line()/rectangle()/circle()/putText()  # 绘制
```

### Python 基础操作

```python
import cv2
import numpy as np

# 读取图像
img = cv2.imread('image.jpg')
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# 显示图像
cv2.imshow('Image', img)
cv2.waitKey(0)
cv2.destroyAllWindows()

# 保存图像
cv2.imwrite('output.jpg', img)

# 绘制
cv2.line(img, (0,0), (100,100), (0,255,0), 2)
cv2.rectangle(img, (50,50), (150,150), (255,0,0), 2)
cv2.circle(img, (100,100), 30, (0,0,255), -1)
cv2.putText(img, 'Hello', (10,30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255,255,255), 2)
```

### C++ 基础操作

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>

using namespace cv;

int main() {
    Mat img = imread("image.jpg");
    Mat gray;
    cvtColor(img, gray, COLOR_BGR2GRAY);
    
    imshow("Image", img);
    waitKey(0);
    imwrite("output.jpg", img);
    
    line(img, Point(0,0), Point(100,100), Scalar(0,255,0), 2);
    rectangle(img, Point(50,50), Point(150,150), Scalar(255,0,0), 2);
    circle(img, Point(100,100), 30, Scalar(0,0,255), -1);
    putText(img, "Hello", Point(10,30), FONT_HERSHEY_SIMPLEX, 1, Scalar(255,255,255), 2);
    
    return 0;
}
```

### 色彩空间转换

| 转换 | OpenCV 常量 |
|------|------------|
| BGR → Gray | `COLOR_BGR2GRAY` |
| BGR → HSV | `COLOR_BGR2HSV` |
| BGR → RGB | `COLOR_BGR2RGB` |
| Gray → BGR | `COLOR_GRAY2BGR` |
| HSV → BGR | `COLOR_HSV2BGR` |

---

## 最佳实践

1. **图像加载后检查**：确保图像不为空
   ```python
   if img is None:
       raise ValueError("Failed to load image")
   ```

2. **NumPy 与 OpenCV 转换**：
   - OpenCV BGR → NumPy RGB： `img[:,:,::-1]`
   - NumPy → OpenCV：直接使用

3. **数据类型**：
   - 默认 `uint8` (0-255)
   - 运算时注意防止溢出，使用 `np.clip()`

4. **ROS2 集成**：
   ```python
   # ROS2 Image 消息转 OpenCV
   def image_callback(msg: Image):
       img = bridge.imgmsg_to_cv2(msg, "bgr8")
       # 处理...
       # OpenCV 转 ROS2 Image
       out_msg = bridge.cv2_to_imgmsg(processed_img, "bgr8")
   ```

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 图像显示中文乱码 | 使用 PIL 渲染中文文字 |
| `waitKey()` 无响应 | 确保 `cv2.imshow()` 在 `waitKey()` 之前 |
| 内存泄漏 | 及时 `release()` 视频捕获对象 |

---

## 相关技能

- [opencv-image-processing](./image-processing) - 图像处理进阶
- [opencv-feature-detection](./feature-detection) - 特征检测
- [opencv-yolo-integration](./yolo-integration) - YOLO 集成
