---
name: cuda-profiling
description: CUDA性能分析工具 - Nsight Systems Nsight Compute 性能分析
argument-hint: Nsight OR CUDA性能 OR profiling OR nvprof
user-invocable: true
---

# CUDA 性能分析技能

> 使用NVIDIA工具分析CUDA性能

## 何时使用

- 性能瓶颈分析
- GPU利用率优化
- 内存访问分析

## 工具

### Nsight Systems

```bash
nsys profile -o profile ./app
# 生成 .nsys-rep 文件
```

### Nsight Compute

```bash
ncu --metrics sm__throughput.avg.pct_of_peak_sustained ./app
```

### nvprof (Legacy)

```bash
nvprof --print-gpu-trace ./app
```

## 关键指标

| 指标 | 说明 |
|------|------|
| SM Activity | SM利用率 |
| Warp Efficiency | warp效率 |
| Memory Throughput | 内存带宽 |
| L2 Cache Hit | L2命中率 |

## 分析流程

1. 收集数据
2. 分析timeline
3. 定位瓶颈
4. 优化代码