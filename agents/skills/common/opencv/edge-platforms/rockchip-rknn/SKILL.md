---
name: opencv-rockchip-rknn
description: OpenCV4 Rockchip RKNN 部署技能 - RK3588/RK3399Pro、RKNN-Toolkit2、NPU 加速
user-invocable: true
argument-hint: "rockchip" / "rknn" / "rk3588" / "rk3399" / "npu" / "边缘部署"
---

# OpenCV4 Rockchip RKNN Deployment Skill

> Rockchip 平台 RKNN 加速部署完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- RK3588/RK3399Pro 开发环境配置
- RKNN-Toolkit2 模型转换
- RKNN SDK OpenCV 集成
- NPU 加速推理
- ROS2 Rockchip 部署
- 性能调优

---

## 快速参考

### Rockchip 芯片对比

| 芯片 | NPU 算力 | CPU | 适用场景 |
|------|---------|-----|---------|
| RK3588 | 6TOPS | 4xA76 + 4xA55 | 高性能边缘 |
| RK3399Pro | 3TOPS | 2xA72 + 4xA53 | 中等性能 |
| RV1126 | 1TOPS | 4xA7 | 低功耗 |

### RKNN-Toolkit2 安装

```bash
# 创建 conda 环境
conda create -n rknn python=3.8
conda activate rknn

# 安装依赖
pip install torch torchvision
pip install rknn-toolkit2==1.5.0

# 或使用 Docker
docker pull rockchip/rknn-toolkit2:1.5.0
docker run -it --network host \
    -v $(pwd):/workspace \
    rockchip/rknn-toolkit2:1.5.0 /bin/bash
```

### YOLO 转 RKNN 模型

```python
from rknnocket2 import RKNN
from ultralytics import YOLO

# 加载 PyTorch 模型
model = YOLO('yolov8n.pt')
model.export(format='onnx', simplify=True)

# 转换为 RKNN
rknn = RKNN(verbose=True)
rknn.config(mean_values=[0, 0, 0], std_values=[255, 255, 255],
            target_platform='rk3588')
rknn.load_onnx('yolov8n.onnx')

# 构建模型
rknn.build(do_quantization=True, dataset='dataset.txt')

# 导出
rknn.save('yolov8n.rknn')
```

### RKNN OpenCV DNN 推理

```python
import cv2
import numpy as np
from rknn.toolkit.decrypt import decrypt_model

# 加载 RKNN 模型
rknn = cv2.dnn.readRKNN('yolov8n.rknn')

# 读取图片
img = cv2.imread('image.jpg')
 resized = cv2.resize(img, (640, 640))
input = np.expand_dims(resized, axis=0)

# 推理
outputs = rknn.inference(inputs=[input])

# 后处理
def postprocess(outputs, img_shape, conf_thresh=0.5, iou_thresh=0.4):
    # 解析 YOLO 输出
    ...
    return boxes
```

### ROS2 Rockchip 部署

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
import cv2

class RockchipNode(Node):
    def __init__(self):
        super().__init__('rockchip_inference')
        self.bridge = CvBridge()
        
        # 加载 RKNN 模型
        self.rknn = cv2.dnn.readRKNN('/models/yolov8n.rknn')
        
        self.sub = self.create_subscription(
            Image, '/image_raw', self.callback, 10)
        self.pub = self.create_publisher(Image, '/detections', 10)
    
    def callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        resized = cv2.resize(img, (640, 640))
        input_data = np.expand_dims(resized, axis=0)
        
        outputs = self.rknn.inference(inputs=[input_data])
        # 后处理和发布
```

---

## 最佳实践

1. **模型转换**：
   - 使用 RKNN-Toolkit2 的 `do_quantization=True` 启用量化
   - 提供代表性的 `dataset.txt` 提高量化精度
   - 输入尺寸需与训练时一致

2. **NPU 利用率**：
   - RK3588 NPU 算力 6TOPS，需合理分配模型
   - 使用 `rknn-toolkit-benchmark` 测试性能

3. **内存管理**：
   - RK3399Pro/3588 支持 DMA 共享内存
   - 多模型时注意释放 RKNN 上下文

4. **调试工具**：
   - `rknn_monitor` 查看 NPU 状态
   - `adb shell cat /sys/class/npu/npu/利用率`

---

## 相关技能

- [opencv-dnn-inference](../dnn-inference) - DNN 推理
- [edge-platforms-rockchip-rknn](../../edge-platforms/rockchip-rknn) - RKNN 通用
