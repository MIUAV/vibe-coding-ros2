---
name: cuda-libraries
description: CUDA常用库 - cuBLAS cuDNN cuFFT NPP性能加速库
argument-hint: "cuBLAS" / "cuDNN" / "cuFFT" / "NPP" / "CUDA库"
user-invocable: true
---

# CUDA 库技能

> NVIDIA CUDA常用加速库

## 何时使用

- 深度学习框架
- 信号处理
- 线性代数计算

## 常用库

### cuBLAS

矩阵运算库

```cpp
cublasHandle_t handle;
cublasCreate(&handle);
cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, 
            m, n, k, &alpha, A, lda, B, ldb, &beta, C, ldc);
```

### cuDNN

深度神经网络库

```c
cudnnHandle_t handle;
cudnnCreate(&handle);
cudnnConvolutionForward(handle, &alpha, inputDesc, input,
                         filterDesc, filter, convDesc, &beta, outputDesc, output);
```

### cuFFT

傅里叶变换

```c
cufftPlan1d(&plan, N, CUFFT_C2C, 1);
cufftExecC2C(plan, (cufftComplex *)in, (cufftComplex *)out, CUFFT_FORWARD);
```

### NPP

图像处理

```cpp
nppiResize_8u_C1R(src, srcStep, srcRoi, dst, dstStep, dstRoi, interp);
```