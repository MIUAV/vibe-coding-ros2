---
name: edge-platforms
description: 边缘计算开发板平台开发知识 - RKNN CUDA JetPack 旭日平台
argument-hint: "边缘计算" / "瑞芯微" / "英伟达" / "地瓜机器人" / "旭日"
user-invocable: true
---

# 边缘计算开发板平台技能

> 用于开发不同边缘计算平台的机器人系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 在边缘设备上部署AI模型
- 优化神经网络推理性能
- 配置开发板驱动和SDK
- 集成ROS2与边缘计算框架

---

## 支持的平台

### 瑞芯微 Rockchip RKNN

- **芯片系列**: RK3588, RK3568, RK3576
- **AI加速器**: NPU (6TOPS-12TOPS)
- **适用场景**: 低成本AI推理、机器人视觉

### 英伟达 NVIDIA

- **CUDA**: GPU通用计算编程
- **JetPack**: Jetson系列SDK (Orin Nano/NX/AGX, Xavier NX)
- **适用场景**: 高性能AI推理、实时目标检测

### 地瓜机器人 DiGiWheel Sunrise

- **芯片系列**: 旭日系列 (Sunrise X3M, Sunrise X5)
- **AI加速器**: BPU (4TOPS-10TOPS)
- **适用场景**: 机器人本地AI、智能驾驶

---

## 快速参考

| 平台 | NPU性能 | 功耗 | 典型设备 |
|------|---------|------|----------|
| **RK3588** | 6TOPS | 5-15W | Orange Pi 5, Rock 5B |
| **Jetson Orin Nano** | 40TOPS | 7-15W | Orin Nano DevKit |
| **Sunrise X3M** | 10TOPS | 5-10W | 地瓜X3M开发板 |