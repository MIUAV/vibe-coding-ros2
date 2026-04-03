---
name: sunrise-sdk
description: 旭日SDK开发 - BPU SDK环境 工具链安装 模型部署
argument-hint: 旭日SDK OR BPU开发 OR 工具链 OR DDK
user-invocable: true
---

# Sunrise SDK 技能

> 地瓜机器人旭日系列SDK

## 何时使用

- SDK环境配置
- BPU工具链安装
- 模型编译部署

## 安装

```bash
# 下载SDK
tar -xzvf sunrise_x3m_ddk_v2.6.0.tar.gz

# 安装依赖
cd ddk
./install.sh

# 配置环境
source setup_env.sh
```

## 工具

- **bpu_model_tool**: 模型转换
- **bpu_runtime**: 推理运行时
- **bpu_profiler**: 性能分析

## 模型部署

1. 模型转换 (ONNX -> BPU)
2. 编译模型
3. 加载推理