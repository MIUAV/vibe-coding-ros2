---
name: cuda-programming
description: CUDA编程基础 - 线程模型 内存管理 kernel编写
argument-hint: CUDA编程 OR thread OR memory OR kernel
user-invocable: true
---

# CUDA 编程技能

> NVIDIA CUDA基础编程

## 何时使用

- 编写CUDA kernel
- 内存管理
- 线程同步

## 线程模型

- **Grid**: 多个Block组成
- **Block**: 多个Thread组成 (max 1024)
- **Warp**: 32个Thread一组

## 内存类型

| 类型 | 访问速度 | 作用域 |
|------|---------|--------|
| 寄存器 | 最快 | thread |
| 共享内存 | 快 | block |
| 全局内存 | 慢 | 全局 |
| 常量内存 | 快 | 全局 |

## 示例

```cuda
__global__ void add(float *a, float *b, float *c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) c[i] = a[i] + b[i];
}

// 调用
add<<<(n+255)/256, 256>>>(a, b, c, n);
```