---
name: edge-inference
description: 边缘推理 — TensorRT/ONNX 加速、ROS2 节点集成、GPU 内存管理，适用于机器人实时感知
argument-hint: 边缘推理 OR edge inference OR TensorRT OR ONNX OR GPU 加速 OR yolo OR 目标检测
user-invocable: true
---

# edge-inference — 边缘推理 SKILL

## 引用技能

- `agents/skills/perception/camera-perception/`
- `agents/skills/ros2-debug/`

## TensorRT 加速

```cpp
// ONNX → TensorRT
trt_builder->setDLACore(0);  // GPU
trt_builder->setFP16Enabled(true);  // 半精度加速
```

## ROS2 集成

```cpp
auto model = std::make_shared<TrtYolo>();
model->load("/path/to/model.trt");

// 推理（< 10ms 每帧）
auto output = model->infer(input_tensor);
```

## 关键参数

| 参数 | 值 |
|------|-----|
| 批量大小 | 1（实时要求）|
| 精度 | FP16（速度/精度权衡）|
| GPU 内存 | < 2GB |

## 禁止

- ❌ Batch > 1 用于实时感知（延迟超标）
- ❌ 不做后处理优化（NMS 等在 CPU 上）
