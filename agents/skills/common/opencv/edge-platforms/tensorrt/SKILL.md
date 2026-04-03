---
name: tensorrt
description: OpenCV4 TensorRT 加速技能 - GPU 加速推理、INT8 量化、Engine 优化、YOLO 部署
user-invocable: true
argument-hint: tensorrt OR trt OR int8 OR fp16 OR gpu加速 OR cuda
---

# OpenCV4 TensorRT Acceleration Skill

> TensorRT 加速 OpenCV 推理完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- TensorRT 安装和配置
- ONNX 模型转 TensorRT Engine
- INT8/FP16 量化优化
- OpenCV DNN TensorRT 后端
- YOLO TensorRT 部署
- 性能调优和基准测试

---

## 快速参考

### TensorRT 安装

```bash
# 下载 TensorRT tar 包（需登录 NVIDIA）
wget https://developer.nvidia.com/tensorrt/download

# 或使用 pip
pip install tensorrt

# 安装 CUDA 依赖
sudo apt install cuda-12-2  # 根据 CUDA 版本

# 验证安装
python -c "import tensorrt; print(tensorrt.__version__)"
```

### ONNX 转 TensorRT Engine

```python
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit

# 创建 builder
logger = trt.Logger(trt.Logger.WARNING)
builder = trt.Builder(logger)
network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
config = builder.create_builder_config()

# 设置 FP16/INT8
config.set_flag(trt.BuilderFlag.FP16)
config.set_flag(trt.BuilderFlag.INT8)
config.int8_calibrator = calibrator  # INT8 需要校准器

# 解析 ONNX
parser = trt.OnnxParser(network, logger)
with open('model.onnx', 'rb') as f:
    parser.parse(f.read())

# 构建 engine
engine = builder.build_serialized_network(network, config)

# 保存
with open('model.engine', 'wb') as f:
    f.write(engine)

# 加载 engine
runtime = trt.Runtime(logger)
engine = runtime.deserialize_cuda_engine(engine)
```

### OpenCV DNN TensorRT 后端

```python
import cv2
import numpy as np

# 加载 TensorRT Engine
net = cv2.dnn.readNet('model.engine')

# 设置后端和目标
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)

# 推理
blob = cv2.dnn.blobFromImage(img, 1/255.0, (640, 640), swapRB=True)
net.setInput(blob)
output = net.forward()
```

### INT8 校准

```python
class INT8Calibrator(trt.IInt8Calibrator):
    def __init__(self, data_loader, cache_file='calibration.cache'):
        self.data_loader = data_loader
        self.cache_file = cache_file
        self.batch_size = 8
        
    def get_batch(self, names):
        data = next(self.data_loader)
        return [data]
    
    def get_batch_size(self):
        return self.batch_size
    
    def read_calibration_cache(self):
        if os.path.exists(self.cache_file):
            with open(self.cache_file, 'rb') as f:
                return f.read()
    
    def write_calibration_cache(self, cache):
        with open(self.cache_file, 'wb') as f:
            f.write(cache)
```

### Ultralytics TensorRT 导出

```python
from ultralytics import YOLO

# 导出为 TensorRT
model = YOLO('yolov8n.pt')
model.export(format='engine', half=True, int8=True, device=0)

# 加载和推理
model = YOLO('yolov8n.engine')
results = model.predict(source='image.jpg', device=0, half=True)
```

---

## ROS2 TensorRT 部署

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2
import numpy as np

class TensorRTNode(Node):
    def __init__(self):
        super().__init__('tensorrt_inference')
        self.bridge = CvBridge()
        
        # 加载 TensorRT Engine
        self.net = cv2.dnn.readNet('yolov8n.engine')
        self.net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
        self.net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)
        
        self.sub = self.create_subscription(Image, '/image_raw', self.callback, 10)
        self.pub = self.create_publisher(Image, '/detections', 10)
    
    def callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        blob = cv2.dnn.blobFromImage(img, 1/255.0, (640, 640), swapRB=True)
        self.net.setInput(blob)
        output = self.net.forward()
        # 后处理...
```

---

## 性能对比

| 精度 | 相对 FP32 速度 | 精度损失 |
|------|---------------|---------|
| FP32 | 1x | 无 |
| FP16 | 2-3x | 极小 |
| INT8 | 3-4x | < 1% mAP |

### 优化参数

```python
config.set_memory_pool_limit(trt.MemoryPoolType.WORKSPACE, 1 << 30)  # 1GB
config.set_preview_feature(trt.PreviewFeature.FASTER_DYNAMIC_SHAPES_0806, 1)
config.set_flag(trt.BuilderFlag.DIRECT_IO)  # 减少拷贝
```

---

## 最佳实践

1. **Engine 构建**：
   - 使用实际部署硬件构建 Engine
   - 固定 batch size 通常更快
   - 设置合理的 workspace 大小

2. **INT8 量化**：
   - 需要代表性数据集（100-500 张图）
   - 避免极端值和异常样本
   - 量化后验证精度

3. **内存管理**：
   - CUDA 流并行处理
   - 使用 Pinned Memory 加速传输
   - 批处理提高 GPU 利用率

4. **调试**：
   - 使用 `trtexec --verbose` 测试
   - `nvidia-smi dmon` 监控 GPU
   - TensorRT profiler 分析瓶颈

---

## 相关技能

- [opencv-nvidia-jetson](./nvidia-jetson) - Jetson 部署
- [opencv-dnn-inference](../dnn-inference) - DNN 推理基础
