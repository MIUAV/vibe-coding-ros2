---
name: vision-perception
description: 视觉感知技能集合 — 目标检测、语义分割、立体匹配、3D检测、边缘部署，适用于机器人环境感知
argument-hint: 视觉感知 OR 目标检测 OR 语义分割 OR vision perception OR yolo OR 图像分割
user-invocable: true
---

# vision-perception — 视觉感知 SKILL

## 引用技能

- `agents/skills/perception/edge-inference/` — 边缘推理加速
- `agents/skills/ros2-debug/` — 调试

## 视觉感知流程

```
相机图像 → 预处理 → 推理 → 后处理 → 输出
```

## YOLO 部署

```cpp
// ROS2 + YOLO
auto detector = std::make_shared<YoloDetector>("/model.onnx");
auto sub = this->create_subscription<Image>(
  "/camera/image_raw", QoS(10).best_effort(),
  [&](Image::SharedPtr msg) {
    auto results = detector->infer(msg);
    publish_detections(results);
  });
```

## ROS2 图像处理

```cpp
#include <cv_bridge/cv_bridge.h>
#include <image_transport/image_transport.hpp>

// ROS2 Image → OpenCV
auto cv_img = cv_bridge::toCvShare(msg, "bgr8");
```

## 3D 检测

```cpp
// 深度图像 → 点云 → 3D BBox
auto pc = depth_to_pointcloud(depth_img, camera_intrinsics);
auto bboxes = detect_3d(pc);  // 输出 [x,y,z,w,h,d,yaw]
```

## QoS 规则

相机图像用 **BEST_EFFORT**（高频率，丢帧可接受）。

## 禁止

- ❌ 图像推理用 RELIABLE（延迟累积，实时性差）
- ❌ 不做 NMS 后处理（重复检测）
- ❌ Batch > 1 用于实时（延迟超标）
