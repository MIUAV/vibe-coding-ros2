---
name: openvino-deployment
description: OpenVINO 部署技能 - 模型优化、IR 转换、GPU/CPU/VPU 推理、ROS2 部署
argument-hint: "OpenVINO" / "IE" / "IR" / "Intel" / "openvino deployment"
user-invocable: true
---

# OpenVINO 部署技能

> Intel CPU/GPU/VPU 推理加速

---

## 何时使用

当需要以下帮助时使用此技能：
- ONNX/IR 模型部署
- CPU/GPU/VPU 加速
- 模型优化工具
- 异步推理
- ROS2 OpenVINO 节点

---

## 核心实现

### 模型转换与优化

```python
from openvino.tools import mo
from openvino.runtime import Core, Layout
import numpy as np

class OpenVINOConverter:
    def __init__(self):
        self.core = Core()
        
    def convert_model(self, model_path, input_shape, output_dir):
        """模型转换"""
        # ONNX 转 IR
        model = mo.convert_model(
            model_path,
            input_shape=input_shape,
            layout=Layout('NCHW') if 'nhwc' not in input_shape else Layout('NHWC'),
            compress_to_fp16=True
        )
        
        # 保存
        serialize(model, output_dir + '/model.xml')
        return model
        
    def compile_model(self, model_path, device='CPU'):
        """编译模型"""
        model = self.core.read_model(model_path)
        
        # 优化配置
        config = {
            'PERFORMANCE_HINT': 'LATENCY',
            'NUM_STREAMS': '1',
            'INFERENCE_PRECISION_HINT': 'f16'
        }
        
        compiled = self.core.compile_model(model, device, config)
        return compiled
        
    def optimize_model(self, model):
        """模型优化"""
        # 使用 OVC 优化
        # 量化、剪枝等
        pass
```

### ROS2 OpenVINO 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
from openvino.runtime import Core, AsyncInferQueue
import numpy as np
import cv2

class OpenVINONode(Node):
    def __init__(self):
        super().__init__('openvino_node')
        self.bridge = CvBridge()
        
        # 初始化 OpenVINO
        self.core = Core()
        self.model = self.core.read_model('/path/to/model.xml')
        self.compiled_model = self.core.compile_model(self.model, 'CPU')
        self.infer_request = self.compiled_model.create_infer_request()
        
        # 异步队列
        self.async_queue = AsyncInferQueue(self.compiled_model, 4)
        
        # 订阅
        self.image_sub = self.create_subscription(
            Image, '/image_raw', self.callback, 10)
        self.pub = self.create_publisher(Image, '/detections', 10)
        
        self.get_logger().info('OpenVINO node initialized')
        
    def callback(self, msg):
        # 图像预处理
        cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
        input_data = self.preprocess(cv_image)
        
        # 同步推理
        input_tensor = self.compiled_model.input(0)
        self.infer_request.set_input_tensor(input_tensor.data, input_data)
        self.infer_request.start_async()
        self.infer_request.wait()
        
        # 获取输出
        output = self.infer_request.get_output_tensor().data
        results = self.postprocess(output)
        
        # 可视化
        output_image = self.draw_results(cv_image, results)
        output_msg = self.bridge.cv2_to_imgmsg(output_image, 'bgr8')
        self.pub.publish(output_msg)
        
    def preprocess(self, image):
        """预处理"""
        img = cv2.resize(image, (640, 640))
        img = img.transpose(2, 0, 1)  # HWC -> CHW
        img = img.astype(np.float32) / 255.0
        return img
        
    def postprocess(self, outputs):
        """后处理"""
        return outputs
        
    def draw_results(self, image, results):
        """绘制结果"""
        for det in results:
            x1, y1, x2, y2, score, cls = det
            cv2.rectangle(image, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        return image
```

### 多设备推理

```python
class MultiDeviceInference:
    def __init__(self):
        self.core = Core()
        
    def load_multi_device(self, model_path):
        """多设备加载"""
        # GPU + CPU 异构
        device_affinity = {'image': 'GPU.0', 'detection': 'CPU'}
        
        devices = {}
        for name, device in device_affinity.items():
            model = self.core.read_model(model_path)
            devices[name] = self.core.compile_model(model, device)
            
        return devices
        
    def infer(self, devices, inputs):
        """异构推理"""
        # 异步并行
        results = {}
        for name, device in devices.items():
            request = device.create_infer_request()
            request.start_async()
            results[name] = request
            request.wait()
        return results
```
