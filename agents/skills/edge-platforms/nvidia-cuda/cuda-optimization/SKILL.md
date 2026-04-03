---
name: cuda-optimization
description: CUDA性能优化 - 内存合并 循环展开 占用率优化
argument-hint: CUDA优化 OR 内存合并 OR occupancy OR 性能调优
user-invocable: true
---

# CUDA 性能优化技能

> 优化CUDA代码性能

## 何时使用

- 提升GPU利用率
- 减少内存访问延迟
- 优化吞吐量

## 优化技术

### 1. 内存合并

```cuda
// 非合并访问
for (int i = 0; i < n; i++) {
    sum += a[i * stride];  // stride != 1
}

// 合并访问
for (int i = 0; i < n; i++) {
    sum += a[i];  // 连续访问
}
```

### 2. 共享内存

```cuda
__shared__ float shared[256];
```

### 3. 占用率优化

- 保持SM高占用
- 合理选择block大小

## 性能指标

| 指标 | 目标 |
|------|------|
| 内存带宽利用率 | >80% |
| SM占用率 | >70% |
| 指令吞吐量 | 高 |