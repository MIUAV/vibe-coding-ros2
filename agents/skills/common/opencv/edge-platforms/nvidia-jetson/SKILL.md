---
name: nvidia-jetson
description: OpenCV4 NVIDIA Jetson 部署技能 - Jetson Nano/Xavier/Orin、JetPack、CUDA、TensorRT、DLA
user-invocable: true
argument-hint: jetson OR nvidia OR cuda OR tensorrt OR jetpack OR 边缘部署
---

# OpenCV4 NVIDIA Jetson Deployment Skill

> Jetson 平台 OpenCV 加速部署完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- Jetson Nano/Xavier/Orin 环境配置
- JetPack 安装和 CUDA 设置
- OpenCV CUDA 加速
- TensorRT 模型部署
- DeepStream 集成
- 功耗和性能优化

---

## 快速参考

### JetPack 版本和 CUDA 版本

| Jetson 型号 | JetPack 版本 | CUDA 版本 | GPU 架构 |
|------------|-------------|----------|---------|
| Nano | 4.6.x | 10.2 | Maxwell |
| Xavier | 5.x | 11.4 | Volta |
| Orin | 6.x | 12.x | Ampere |

### OpenCV CUDA 编译

```bash
# 安装依赖
sudo apt update
sudo apt install -y build-essential cmake git libgtk2.0-dev pkg-config \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-pip \
    libtbb2 libtbb-dev libdc1394-dev

# 克隆 OpenCV 和 opencv_contrib
git clone --branch 4.x https://github.com/opencv/opencv.git
git clone --branch 4.x https://github.com/opencv/opencv_contrib.git

# CMake 配置（启用 CUDA）
cd opencv
mkdir build && cd build
cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D WITH_CUDA=ON \
    -D CUDA_ARCH_BIN="8.7" \  # Orin: 8.7, Xavier: 8.7, Nano: 5.3
    -D WITH_TBB=ON \
    -D OPENCV_ENABLE_NONFREE=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
    ..

make -j$(nproc)
sudo make install
```

### CUDA 加速的 OpenCV 操作

```python
import cv2
import numpy as np

# 检查 CUDA 支持
print(cv2.cuda.getCudaEnabledDeviceCount())

# 创建 CUDA 内存中的图像
img = cv2.imread('image.jpg')
img_cuda = cv2.cuda.GpuMat()
img_cuda.upload(img)

# CUDA 图像处理
gray_cuda = cv2.cuda.cvtColor(img_cuda, cv2.COLOR_BGR2GRAY)
blur_cuda = cv2.cuda.GaussianBlur(img_cuda, (5, 5), 0)

# 下载回 CPU
gray = gray_cuda.download()
blur = blur_cuda.download()
```

### TensorRT 部署 YOLO

```python
import cv2
import torch
from ultralytics import YOLO

# 导出为 TensorRT
model = YOLO('yolov8n.pt')
model.export(format='engine', half=True, int8=True, device=0)

# TensorRT 推理
model = YOLO('yolov8n.engine')
results = model.predict(source='image.jpg', device=0, half=True)
```

### ROS2 Jetson 集成

```bash
# 安装 ROS2 Jetson 相关包
sudo apt install -y ros-humble-cv-bridge ros-humble-image-transport \
    ros-humble-vision-msgs ros-humble-message_filters

# 使用 image_transport 减少延迟
# Subscriber 端
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge

class JetsonCamera(Node):
    def __init__(self):
        super().__init__('jetson_camera')
        self.bridge = CvBridge()
        # 使用compressed或theora传输减少带宽
        self.sub = self.create_subscription(
            Image, '/camera/image_raw', self.callback, 10)
    
    def callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        # 处理...
```

---

## 性能优化

### 内存和带宽优化

```python
# 使用 DMA 零拷贝
# 设置环境变量
# export CUDA_BUFFER_POOL=1GB

# 使用 Pinned Memory 加速传输
import cv2
import numpy as np

# 创建 Pinned Memory 缓冲区
host_buffer = cv2.cuda.HostMem(1920, 1080, cv2.CV_8UC3)
```

### GStreamer 管道加速

```python
# 使用 GStreamer 捕获（零拷贝）
gst_str = (
    "nvarguscamerasrc ! "
    "video/x-raw(memory:NVMM), width=1280, height=720, framerate=30/1 ! "
    "nvvidconv ! "
    "video/x-raw, format=BGRx ! "
    "videoconvert ! "
    "appsink"
)
cap = cv2.VideoCapture(gst_str, cv2.CAP_GSTREAMER)
```

### 多线程推理

```python
import threading
import queue
from ultralytics import YOLO

class AsyncInference:
    def __init__(self, model_path='yolov8n.pt', num_threads=2):
        self.model = YOLO(model_path)
        self.input_queue = queue.Queue(maxsize=10)
        self.output_queue = queue.Queue()
        self.threads = []
        
        for _ in range(num_threads):
            t = threading.Thread(target=self._inference_loop)
            t.start()
            self.threads.append(t)
    
    def _inference_loop(self):
        while True:
            img = self.input_queue.get()
            if img is None:
                break
            results = self.model.predict(img, verbose=False)
            self.output_queue.put(results)
    
    def predict(self, img):
        self.input_queue.put(img)
        return self.output_queue.get()
```

---

## 最佳实践

1. **JetPack 选择**：
   - 生产环境：使用 LTS 版本
   - 开发测试：使用最新版本获取最新功能

2. **CUDA 版本匹配**：
   - OpenCV CUDA 版本需与 JetPack CUDA 版本匹配
   - TensorRT 版本需与 CUDA 版本兼容

3. **功耗管理**：
   - Nano：`sudo nvpmodel -m 1` (5W) / `-m 0` (10W)
   - Xavier/Orin：`sudo nvpmodel -m 2` (15W) / `-m 0` (MAXN)

4. **模型优化**：
   - INT8 量化可提升 2-3 倍性能
   - TensorRT优化：使用 batchdim > 1
   - 使用 DeepStream 进行复杂管线处理

---

## 相关技能

- [opencv-dnn-inference](../dnn-inference) - DNN 推理
- [opencv-edge-platforms-tensorrt](./tensorrt) - TensorRT 加速
