---
name: opencv-dnn-inference
description: OpenCV4 DNN 模块技能 - 神经网络推理、模型加载、ONNX、TFLite、Darknet 支持
user-invocable: true
argument-hint: "dnn" / "深度学习推理" / "onnx" / "tflite" / "tensorflow" / "darknet"
---

# OpenCV4 DNN Inference Skill

> OpenCV DNN 模块深度学习推理完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 使用 OpenCV DNN 模块加载神经网络
- ONNX、TensorFlow、TFLite、Darknet 模型推理
- 图像预处理和后处理
- GPU 加速推理（CUDA、OpenVINO）
- 模型部署和优化

---

## 快速参考

### 支持的模型格式

| 框架 | OpenCV 支持 | 扩展名 |
|------|-------------|--------|
| ONNX | ✓ | `.onnx` |
| TensorFlow | ✓ | `.pb`, `.tflite` |
| Caffe | ✓ | `.caffemodel`, `.prototxt` |
| Darknet | ✓ | `.weights`, `.cfg` |
| Torch | ✓ | `.t7` |
| OpenVINO | ✓ | `.xml`, `.bin` |

### Python 基础推理

```python
import cv2
import numpy as np

# 加载模型
net = cv2.dnn.readNetFromONNX('model.onnx')
# 或 TensorFlow
net = cv2.dnn.readNetFromTensorflow('model.pb')
# 或 Darknet
net = cv2.dnn.readNetFromDarknet('model.weights', 'model.cfg')

# 设置后端和目标（使用 GPU）
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)

# 图像预处理
blob = cv2.dnn.blobFromImage(img, 1/255.0, (416, 416), 
                              swapRB=True, crop=False)

# 推理
net.setInput(blob)
output = net.forward()
```

### 批量推理

```python
# 批量图像预处理
images = [cv2.imread(f) for f in image_files]
blob = cv2.dnn.blobFromImages(images, 1/255.0, (416, 416),
                               swapRB=True, crop=False)

# 批量推理
net.setInput(blob)
outputs = net.forward()

# 处理每个输出
for i, output in enumerate(outputs):
    # output shape: [batch, classes, detections, 5+classes]
    process_detection(output, images[i])
```

### 后处理（YOLO 风格）

```python
def postprocess_yolo(output, img_shape, conf_threshold=0.5, nms_threshold=0.4):
    h, w = img_shape[:2]
    boxes, confidences, class_ids = [], [], []
    
    for detection in output:
        scores = detection[5:]
        class_id = np.argmax(scores)
        confidence = scores[class_id]
        
        if confidence > conf_threshold:
            cx, cy, bw, bh = detection[:4]
            x = int((cx - bw/2) * w)
            y = int((cy - bh/2) * h)
            width = int(bw * w)
            height = int(bh * h)
            
            boxes.append([x, y, width, height])
            confidences.append(float(confidence))
            class_ids.append(class_id)
    
    # NMS
    indices = cv2.dnn.NMSBoxes(boxes, confidences, conf_threshold, nms_threshold)
    return [(boxes[i], confidences[i], class_ids[i]) for i in indices.flatten()]
```

---

## C++ 实现

```cpp
#include <opencv2/dnn.hpp>
#include <opencv2/dnn/all_layers.hpp>

using namespace cv::dnn;

// 加载模型
Net net = readNetFromONNX("model.onnx");
// Net net = readNetFromTensorflow("model.pb");
// Net net = readNetFromDarknet("model.weights", "model.cfg");

// 设置后端
net.setPreferableBackend(DNN_BACKEND_CUDA);
net.setPreferableTarget(DNN_TARGET_CUDA);

// 预处理
Mat blob = blobFromImage(img, 1/255.0, Size(416, 416),
                          Scalar(), true, false);

// 推理
net.setInput(blob);
Mat output = net.forward();

// 后处理
std::vector<int> classIds;
std::vector<float> confidences;
std::vector<Rect> boxes;
for (int i = 0; i < output.size[2]; i++) {
    float confidence = output.at<float>(0, 0, i, 2);
    if (confidence > 0.5) {
        int classId = (int)output.at<float>(0, 0, i, 1);
        int x = (int)(output.at<float>(0, 0, i, 3) * img.cols);
        int y = (int)(output.at<float>(0, 0, i, 4) * img.rows);
        int w = (int)(output.at<float>(0, 0, i, 5) * img.cols);
        int h = (int)(output.at<float>(0, 0, i, 6) * img.rows);
        boxes.emplace_back(x, y, w, h);
        confidences.push_back(confidence);
        classIds.push_back(classId);
    }
}
std::vector<int> indices;
NMSBoxes(boxes, confidences, 0.5, 0.4, indices);
```

---

## 后端和目标配置

```python
# CPU
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)

# CUDA GPU
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)

# OpenVINO
net.setPreferableBackend(cv2.dnn.DNN_BACKEND_INFERENCE_ENGINE)
net.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
```

---

## 最佳实践

1. **模型准备**：
   - 使用 ONNX 作为中间格式（跨框架兼容）
   - 模型量化：INT8 量化可加速 2-4 倍
   - 输入尺寸：固定尺寸推理更快

2. **预处理优化**：
   - 使用 `blobFromImages` 批量处理
   - `swapRB=True` 处理 RGB/BGR 转换
   - 避免不必要的数据拷贝

3. **推理优化**：
   - 首次推理 warm-up：运行一次空推理
   - 使用异步推理减少延迟
   - 批量推理提高吞吐量

4. **内存管理**：
   - 复用 `Mat` 对象避免频繁分配
   - 使用 `release()` 释放中间结果

---

## 相关技能

- [opencv-yolo-integration](./yolo-integration) - YOLO 集成
- [opencv-image-processing](./image-processing) - 图像处理
