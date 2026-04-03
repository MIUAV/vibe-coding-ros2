---
name: sunrise-perception
description: 旭日视觉感知 - 目标检测 语义分割 实例分割
argument-hint: "视觉感知" / "目标检测" / "语义分割" / "旭日AI"
user-invocable: true
---

# Sunrise 视觉感知技能

> 旭日BPU视觉感知应用

## 何时使用

- 目标检测部署
- 语义分割应用
- 实例分割实现

## 模型

### 目标检测

- YOLOv5s/v8s
- NanoDet
- SSD-MobileNet

### 分割

- DeepLabV3
- UNet
- PSPNet

## 部署

```python
import horizon_nn

model = horizon_nn.load('model.onnx')
outputs = model.forward(image)
```

## 性能

- 1080P: 30+ FPS
- 720P: 50+ FPS
- INT8量化精度损失<1%