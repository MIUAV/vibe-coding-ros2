---
name: nvidia-cuda
description: 英伟达CUDA开发 - GPU编程 性能优化 CUDA库
argument-hint: CUDA OR GPU编程 OR NVIDIA OR 并行计算
user-invocable: true
---

# NVIDIA CUDA 技能

> 用于在NVIDIA GPU上进行通用计算开发

## 何时使用

- GPU加速计算
- CUDA编程
- 性能优化

## 支持的GPU架构

| 架构 | GPU型号 | 算力 |
|------|---------|------|
| Ampere | RTX 30xx, A100 | 19.5 TFLOPS |
| Ada | RTX 40xx, L40 | 24.9 TFLOPS |
| Orin | Jetson Orin | 275 TOPS |

## 快速参考

```cuda
__global__ void kernel(float *data) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    data[idx] *= 2.0f;
}
```