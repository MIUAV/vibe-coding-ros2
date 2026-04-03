---
name: opencv
description: OpenCV4 技能库 - 图像处理、特征检测、深度学习推理、YOLO、边缘部署等完整技能集合
user-invocable: true
argument-hint: "opencv" / "视觉" / "图像处理" / "目标检测" / "深度学习" / "边缘部署"
---

# OpenCV4 Skills Library

> OpenCV4 + Ultralytics 完整技能集合

---

## 技能概览

### 基础技能

| 技能 | 描述 |
|------|------|
| [basics](./basics) | OpenCV 基础 - 图像读写、显示、绘制、色彩空间 |
| [image-processing](./image-processing) | 图像处理 - 几何变换、滤波、形态学、边缘检测 |
| [feature-detection](./feature-detection) | 特征检测 - SIFT、ORB、AKAZE、特征匹配、图像拼接 |

### 深度学习与 AI

| 技能 | 描述 |
|------|------|
| [dnn-inference](./dnn-inference) | DNN 模块 - ONNX/TFLite/Darknet 模型推理 |
| [yolo-integration](./yolo-integration) | YOLO 集成 - Ultralytics YOLOv5/v8/v11 目标检测/分割/姿态 |
| [video-analysis](./video-analysis) | 视频分析 - 光流、背景分离、运动检测 |
| [depth-estimation](./depth-estimation) | 深度估计 - 单目/双目深度、RGB-D、点云 |

### 相机与标定

| 技能 | 描述 |
|------|------|
| [camera-calibration](./camera-calibration) | 相机标定 - 单目/双目标定、畸变校正、立体匹配 |

### 边缘部署

| 技能 | 描述 |
|------|------|
| [edge-platforms/nvidia-jetson](./edge-platforms/nvidia-jetson) | NVIDIA Jetson - JetPack、CUDA、TensorRT 部署 |
| [edge-platforms/rockchip-rknn](./edge-platforms/rockchip-rknn) | Rockchip RKNN - RK3588/RK3399Pro NPU 加速 |
| [edge-platforms/openvino](./edge-platforms/openvino) | Intel OpenVINO - CPU/GPU/VPU 加速 |
| [edge-platforms/tensorrt](./edge-platforms/tensorrt) | TensorRT 加速 - INT8/FP16 量化、Engine 优化 |

---

## 快速导航

### 新手入门
1. 先学习 [basics](./basics) 掌握基础操作
2. 学习 [image-processing](./image-processing) 了解图像处理
3. 学习 [dnn-inference](./dnn-inference) 掌握深度学习推理

### 目标检测
1. 学习 [yolo-integration](./yolo-integration) 掌握 YOLO 使用
2. 学习 [edge-platforms](./edge-platforms) 选择部署平台

### 边缘部署
- Jetson: [nvidia-jetson](./edge-platforms/nvidia-jetson) + [tensorrt](./edge-platforms/tensorrt)
- RK3588: [rockchip-rknn](./edge-platforms/rockchip-rknn)
- Intel: [openvino](./edge-platforms/openvino)

---

## 技术栈

- **OpenCV**: 4.x 系列
- **Python**: 3.8+
- **深度学习框架**: PyTorch, TensorFlow
- **模型格式**: ONNX (推荐), TFLite, Darknet, Caffe
- **YOLO**: Ultralytics YOLOv5/v8/v11
- **边缘硬件**: NVIDIA Jetson, Rockchip RK3588, Intel CPU/GPU/VPU

---

## 相关文档

- [OpenCV 官方文档](https://docs.opencv.org/4.x/)
- [Ultralytics 文档](https://docs.ultralytics.com/)
- [TensorRT 文档](https://docs.nvidia.com/deeplearning/tensorrt/)
- [OpenVINO 文档](https://docs.openvino.ai/)
