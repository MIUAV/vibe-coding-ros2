---
name: rknn-deployment
description: RKNN 部署技能 - RKNN-Toolkit2、RK3588 NPU、模型转换、ROS2 部署
argument-hint: RKNN OR RK3588 OR 瑞芯微 OR NPU OR rknn deployment
user-invocable: true
---

# RKNN 部署技能

> 瑞芯微 RK3588/RK3399Pro NPU 加速部署

---

## 何时使用

当需要以下帮助时使用此技能：
- ONNX/TFLite 转 RKNN
- RK3588 NPU 部署
- RKNN-Toolkit2 使用
- 性能优化
- ROS2 RKNN 节点

---

## 核心实现

### RKNN 模型转换

```python
from rknn.api import RKNN

class RKNNConverter:
    def __init__(self):
        self.rknn = RKNN(verbose=True)
        
    def convert_onnx(self, onnx_path, rknn_path, 
                     inputs=['images'], input_shapes=[[1, 3, 640, 640]],
                     layout='NCHW'):
        """ONNX 转 RKNN"""
        # 加载 ONNX
        self.rknn.config(
            mean_values=[[123.675, 116.28, 103.53]],
            std_values=[[58.395, 57.12, 57.375]],
            target_platform='rk3588'
        )
        
        self.rknn.load_onnx(onnx_path, inputs=inputs, input_shapes=input_shapes)
        
        # 构建
        self.rknn.build(do_quantization=True, dataset='./dataset.txt')
        
        # 导出
        self.rknn.export_rknn(rknn_path)
        
    def convert_tflite(self, tflite_path, rknn_path):
        """TFLite 转 RKNN"""
        self.rknn.config(target_platform='rk3588')
        self.rknn.load_tflite(tflite_path)
        self.rknn.build(do_quantization=True)
        self.rknn.export_rknn(rknn_path)
```

### ROS2 RKNN 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
from rknn.api import RKNN
import numpy as np
import cv2

class RKNNNode(Node):
    def __init__(self):
        super().__init__('rknn_node')
        self.bridge = CvBridge()
        
        # 初始化 RKNN
        self.rknn = RKNN()
        self.rknn.load_rknn('/path/to/model.rknn')
        self.rknn.init_runtime()
        
        # 订阅
        self.image_sub = self.create_subscription(
            Image, '/image_raw', self.callback, 10)
        self.pub = self.create_publisher(Image, '/detections', 10)
        
    def callback(self, msg):
        # 图像预处理
        cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
        input_data = self.preprocess(cv_image)
        
        # 推理
        outputs = self.rknn.inference([input_data])
        
        # 后处理
        results = self.postprocess(outputs[0])
        
        # 可视化
        output_image = self.draw_results(cv_image, results)
        
        # 发布
        output_msg = self.bridge.cv2_to_imgmsg(output_image, 'bgr8')
        self.pub.publish(output_msg)
        
    def preprocess(self, image):
        """预处理"""
        img = cv2.resize(image, (640, 640))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = img.astype(np.float32)
        img = (img - [123.675, 116.28, 103.53]) / [58.395, 57.12, 57.375]
        img = img.transpose(2, 0, 1)  # HWC -> CHW
        img = img.reshape(1, 3, 640, 640)
        return img
        
    def postprocess(self, outputs):
        """后处理"""
        # 解析输出
        return outputs
        
    def draw_results(self, image, results):
        """绘制结果"""
        for det in results:
            x1, y1, x2, y2, score, cls = det
            cv2.rectangle(image, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        return image
```

### RK3588 性能优化

```python
class RKNNOptimizer:
    def __init__(self, rknn_model):
        self.rknn = rknn_model
        
    def optimize(self):
        """性能优化"""
        # 1. 设置核心亲和性
        self.rknn.config(core_mask='BIG')
        
        # 2. 内存优化
        self.rknn.config(mem_alloc_type='dma')
        
        # 3. 批量推理
        self.rknn.config(batch_size=4)
        
    def benchmark(self, input_data, num_iterations=100):
        """性能测试"""
        import time
        
        times = []
        for _ in range(num_iterations):
            start = time.time()
            self.rknn.inference([input_data])
            times.append(time.time() - start)
            
        print(f"Average inference time: {np.mean(times)*1000:.2f} ms")
        print(f"FPS: {1/np.mean(times):.2f}")
```
