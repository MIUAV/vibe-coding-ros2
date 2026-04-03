---
name: yolo-integration
description: OpenCV4 YOLO 集成技能 - Ultralytics YOLOv5/v8/v11、目标检测、分割、分类、姿态估计
user-invocable: true
argument-hint: yolo OR ultralytics OR 目标检测 OR 实例分割 OR 姿态估计 OR 目标追踪
---

# OpenCV4 YOLO Integration Skill

> Ultralytics YOLO 集成完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- YOLOv5/v8/v10/v11 目标检测
- 实例分割（Segmentation）
- 姿态估计（Pose）
- 分类模型（Classification）
- 目标追踪（Tracking）
- ROS2 集成部署

---

## 快速参考

### Ultralytics 安装

```bash
pip install ultralytics
```

### Python YOLO 推理

```python
from ultralytics import YOLO

# 加载模型
model = YOLO('yolov8n.pt')  # nano 版本
# model = YOLO('yolov8s.pt')  # small 版本
# model = YOLO('yolov8m.pt')  # medium 版本
# model = YOLO('yolov8l.pt')  # large 版本
# model = YOLO('yolov8x.pt')  # extra-large 版本

# 推理
results = model.predict(source='image.jpg', conf=0.5, iou=0.4)

# 绘制结果
annotated = results[0].plot()

# 获取检测结果
for result in results:
    boxes = result.boxes  # 边界框
    masks = result.masks   # 分割掩码
    keypoints = result.keypoints  # 关键点
    probs = result.probs    # 分类概率
```

### YOLO 目标检测

```python
# 图片推理
results = model.predict(source='bus.jpg', conf=0.5, show=True)

# 视频推理
results = model.predict(source='video.mp4', conf=0.5, save=True)

# 摄像头推理
results = model.predict(source=0, conf=0.5, show=True)

# 批量处理
results = model.predict(source='images/*.jpg', conf=0.5)

# 获取结构化结果
for r in results:
    print(r.boxes.xyxy)      # xyxy 格式边界框
    print(r.boxes.xywh)      # xywh 格式边界框
    print(r.boxes.xyxyn)     # 归一化 xyxy
    print(r.boxes.conf)      # 置信度
    print(r.boxes.cls)       # 类别 ID
```

### YOLO 分割（Segmentation）

```python
# 加载分割模型
model = YOLO('yolov8n-seg.pt')

# 分割推理
results = model.predict(source='image.jpg', conf=0.5)

for r in results:
    masks = r.masks  # 分割掩码
    if masks is not None:
        for mask in masks:
            # 获取掩码数据
            mask_data = mask.data.cpu().numpy()
            # 或归一化掩码
            mask_norm = mask.data.cpu().numpy()
```

### YOLO 姿态估计（Pose）

```python
# 加载姿态模型
model = YOLO('yolov8n-pose.pt')

# 姿态推理
results = model.predict(source='person.jpg', conf=0.5)

for r in results:
    kpts = r.keypoints  # 关键点
    if kpts is not None:
        # 获取所有关键点坐标
        all_kpts = kpts.data.cpu().numpy()
        # 获取可见关键点
        visible = kpts.conf
```

### YOLO 分类（Classification）

```python
# 加载分类模型
model = YOLO('yolov8n-cls.pt')

# 分类推理
results = model.predict(source='cat.jpg')

for r in results:
    top5_probs, top5_idxs = torch.topk(torch.tensor(r.probs.data), 5)
    print(f"Top 5: {top5_idxs.numpy()}, {top5_probs.numpy()}")
```

### 目标追踪（Tracking）

```python
from ultralytics import YOLO
from ultralytics.utils.trackers import ByteTrack

# 加载模型并启用追踪
model = YOLO('yolov8n.pt')
model.predict(source='video.mp4', conf=0.5, persist=True)

# 或使用 tracker 参数
results = model.predict(source='video.mp4', tracker='bytetrack.yaml')

# 获取追踪 ID
for r in results:
    if r.boxes.id is not None:
        track_ids = r.boxes.id.cpu().numpy()
        boxes = r.boxes.xyxy.cpu().numpy()
        classes = r.boxes.cls.cpu().numpy()
```

---

## OpenCV DNN 部署 YOLO

### ONNX 导出与加载

```python
# Ultralytics 导出 ONNX
model = YOLO('yolov8n.pt')
model.export(format='onnx', dynamic=True, opset=12)

# OpenCV DNN 加载
import cv2
import numpy as np

net = cv2.dnn.readNetFromONNX('yolov8n.onnx')

# 预处理
img = cv2.imread('image.jpg')
blob = cv2.dnn.blobFromImage(img, 1/255.0, (640, 640), 
                              swapRB=True, crop=False)

# 推理
net.setInput(blob)
output = net.forward()

# 后处理
def postprocess_yolov8(output, img_shape, conf_thresh=0.5, iou_thresh=0.4):
    # output shape: [1, 84, 8400] (80 classes + 4 coords)
    predictions = output[0].T  # [8400, 84]
    
    boxes = []
    for pred in predictions:
        cx, cy, w, h = pred[:4]
        class_scores = pred[4:]
        class_id = np.argmax(class_scores)
        confidence = class_scores[class_id]
        
        if confidence > conf_thresh:
            x = int((cx - w/2) * img_shape[1])
            y = int((cy - h/2) * img_shape[0])
            w = int(w * img_shape[1])
            h = int(h * img_shape[0])
            boxes.append([x, y, w, h, confidence, class_id])
    
    return boxes
```

---

## ROS2 集成

```python
import cv2
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image
from cv_bridge import CvBridge
from ultralytics import YOLO

class YOLONode(Node):
    def __init__(self):
        super().__init__('yolo_node')
        self.bridge = CvBridge()
        self.model = YOLO('yolov8n.pt')
        
        self.subscription = self.create_subscription(
            Image, '/camera/image_raw', self.image_callback, 10)
        self.publisher = self.create_publisher(Image, '/yolo/detections', 10)
    
    def image_callback(self, msg):
        img = self.bridge.imgmsg_to_cv2(msg, 'bgr8')
        results = self.model.predict(img, conf=0.5, verbose=False)
        annotated = results[0].plot()
        out_msg = self.bridge.cv2_to_imgmsg(annotated, 'bgr8')
        self.publisher.publish(out_msg)

def main(args=None):
    rclpy.init(args=args)
    node = YOLONode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

---

## 最佳实践

1. **模型选择**：
   - 实时应用：`YOLOv8n` 或 `YOLOv11n`
   - 精度优先：`YOLOv8x` 或 `YOLOv11x`
   - 分割任务：`YOLOv8n-seg` / `YOLOv11n-seg`

2. **推理优化**：
   - 使用 TensorRT 加速（需导出）
   - 半精度（FP16）加速
   - 批量推理提高吞吐

3. **参数调优**：
   - `conf`：降低可提高召回率
   - `iou`：降低可减少重叠检测
   - `max_det`：限制最大检测数

4. **ROS2 部署**：
   - 使用 `image_transport` 减少传输开销
   - 考虑使用组件（Component）方式部署
   - 预处理在 GPU 做

---

## 相关技能

- [opencv-dnn-inference](./dnn-inference) - DNN 推理
- [ros2-topic-communication](../ros2-topic-communication) - ROS2 通讯
