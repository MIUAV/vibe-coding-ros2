---
name: nvidia-jetpack
description: 英伟达JetPack开发 - Jetson环境配置 DeepStream TensorRT
argument-hint: JetPack OR Jetson OR DeepStream OR TensorRT
user-invocable: true
---

# NVIDIA JetPack 技能

> Jetson系列开发板SDK和工具

## 何时使用

- Jetson环境配置
- DeepStream视频分析
- TensorRT模型部署
- ROS2集成

## 支持的Jetson设备

| 设备 | AI算力 | 功耗 |
|------|--------|------|
| Jetson Orin AGX | 275 TOPS | 15-60W |
| Jetson Orin NX | 100 TOPS | 10-25W |
| Jetson Orin Nano | 40 TOPS | 7-15W |
| Jetson Xavier NX | 21 TOPS | 10-20W |

## JetPack组件

- **CUDA**: GPU计算
- **TensorRT**: 推理优化
- **DeepStream**: 视频分析
- **VPI**: 视觉处理
- **OpenCV**: 图像处理

## 版本对应

| JetPack | CUDA | TensorRT |
|---------|------|-----------|
| 6.0 | 12.2 | 8.6 |
| 5.1 | 11.8 | 8.5 |
| 4.6 | 10.2 | 8.2 |