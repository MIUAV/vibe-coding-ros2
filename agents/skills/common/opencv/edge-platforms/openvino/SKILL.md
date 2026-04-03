---
name: openvino
description: OpenCV4 OpenVINO 部署技能 - Intel CPU/GPU/VPU、OpenVINO Toolkit、IR 模型、ROS2 部署
user-invocable: true
argument-hint: openvino OR intel OR movidius OR vpu OR ncs2 OR 边缘部署
---

# OpenCV4 OpenVINO Deployment Skill

> OpenVINO 加速 OpenCV 推理完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- OpenVINO Toolkit 安装和配置
- 模型优化器转换（PyTorch/ONNX → IR）
- OpenCV DNN OpenVINO 后端
- Intel GPU/VPU 加速
- ROS2 Intel 相机集成
- 性能优化

---

## 快速参考

### OpenVINO 安装

```bash
# 下载安装
wget https://registrationcenter-download.intel.com/akdlm/irc_nas/vision/l_openvino_toolkit_p_2024.2.0.tgz
tar -xf l_openvino_toolkit_p_2024.2.0.tgz
cd l_openvino_toolkit_p_2024.2.0
sudo ./install.sh

# 激活环境
source /opt/intel/openvino/setupvars.sh

# 安装 Python 工具
pip install openvino openvino-dev[onnx,pytorch,tensorflow]
```

### 模型转换

```bash
# ONNX 转 IR
ovc model.onnx --output_model model_ir

# PyTorch 转 OpenVINO
python -m openvino.convert --input_model model.pt \
    --input_shape [1,3,640,640]

# TensorFlow 保存为 Frozen Graph 再转换
python -m openvino.convert --input_model frozen_graph.pb \
    --input_shape [1,640,640,3]
```

### OpenCV DNN OpenVINO 后端

```python
import cv2
import numpy as np

# 加载 IR 模型
net = cv2.dnn.readNetFromModelOptimizer('model.xml', 'model.bin')

# 设置后端
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_INFERENCE_ENGINE)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
# 或使用 GPU
# net.setPreferableTarget(cv2.dnn.DNN_TARGET_OPENCL_FP16)

# 推理
blob = cv2.dnn.blobFromImage(img, 1/255.0, (640, 640), swapRB=True)
net.setInput(blob)
output = net.forward()
```

### Intel 显卡加速

```python
# GPU 推断
net.setPreferableTarget(cv2.dnn.DNN_TARGET_OPENCL)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_OPENCL_FP16)

# VPU (Neural Compute Stick 2)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_MYRIAD)
```

### ROS2 OpenVINO 部署

```bash
# 安装 ROS2 OpenVINO 相关包
sudo apt install -y ros-humble-openvino-* ros-humble-vitis-ai \
    ros-humble-realsense2-*

# 使用 Intel 相机
# realsense-ros 已经支持 OpenVINO 加速
```

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2

class OpenVINONode(Node):
    def __init__(self):
        super().__init__('openvino_inference')
        self.bridge = CvBridge()
        
        # 加载 OpenVINO 模型
        self.net = cv2.dnn.readNetFromModelOptimizer('model.xml', 'model.bin')
        self.net.setPreferableBackend(cv2.dnn.DNN_BACKEND_INFERENCE_ENGINE)
        self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
        
        self.sub = self.create_subscription(Image, '/image_raw', self.callback, 10)
        self.pub = self.create_publisher(Image, '/detections', 10)
    
    def callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        blob = cv2.dnn.blobFromImage(img, 1/255.0, (640, 640), swapRB=True)
        self.net.setInput(blob)
        output = self.net.forward()
```

---

## 性能优化

### 异步推理

```python
# 异步推理减少延迟
net = cv2.dnn.readNetFromModelOptimizer('model.xml', 'model.bin')
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_INFERENCE_ENGINE)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

# 多次推理 warm-up
for _ in range(10):
    net.forward()

# 异步执行
net.setInput(blob1, 'input1')
net.setInput(blob2, 'input2')
async_infer1 = net.startWarmupAsync(0, 'output1')
async_infer2 = net.startWarmupAsync(1, 'output2')
# 处理其他事情
result1 = net.endPoll(0)
result2 = net.endPoll(1)
```

### 批处理优化

```python
# 批量推理提高吞吐
batch_size = 4
blobs = []
for i in range(batch_size):
    blob = cv2.dnn.blobFromImage(images[i], 1/255.0, (640, 640), swapRB=True)
    blobs.append(blob)

batch_blob = cv2.dnn blobFromImages(images, 1/255.0, (640, 640), swapRB=True)
net.setInput(batch_blob)
outputs = net.forward()
```

---

## 支持的 Intel 硬件

| 硬件 | 算力 | 适用场景 |
|------|------|---------|
| CPU (AVX2/AVX512) | 1-2 TOPS | 通用推理 |
| Integrated GPU | 1-4 TOPS | 图像处理 |
| Movidius VPU | 1 TOPS | 低功耗 |
| Neural Compute Stick 2 | 1 TOPS | USB 加速 |
| Intel DGPU | 4-16 TOPS | 高性能 |

---

## 最佳实践

1. **模型转换**：
   - 优先使用 ONNX 作为中间格式
   - 使用 `mo --compress_to_fp16` 压缩到 FP16
   - 确保输入形状固定或指定动态维度

2. **后端选择**：
   - CPU：延迟敏感场景
   - GPU：吞吐优先，INT8 量化
   - VPU：低功耗部署

3. **OpenVINO 2024**：
   - 使用 `openvino.runtime.Core` API
   - 新的 hetero 和自动设备分配

---

## 相关技能

- [opencv-dnn-inference](../dnn-inference) - DNN 推理基础
