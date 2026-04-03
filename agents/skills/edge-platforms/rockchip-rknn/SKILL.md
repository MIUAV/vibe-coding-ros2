---
name: rockchip-rknn
description: 瑞芯微RKNN开发 - 模型转换 NPU推理 相机驱动
argument-hint: 瑞芯微 OR RKNN OR RK3588 OR NPU
user-invocable: true
---

# 瑞芯微 Rockchip RKNN 技能

> 用于在瑞芯微芯片平台上进行AI模型开发和部署

---

## 何时使用

当需要以下帮助时使用此技能：
- 将PyTorch/TensorFlow模型转换为RKNN格式
- 使用RKNPU运行模型推理
- 配置MIPI CSI相机驱动
- 优化NPU推理性能

---

## 快速参考

### 支持的芯片

| 芯片 | NPU | 算力 | 内存 |
|------|-----|------|------|
| **RK3588** | 6TOPS | 8K/4K@30fps | 8GB |
| **RK3568** | 1TOPS | 4K@30fps | 8GB |
| **RK3576** | 6TOPS | 8K/4K@30fps | 6GB |

### 工具链

- **模型转换**: rknn-toolkit2
- **推理运行时**: rknn-runtime
- **量化**: INT8/FP16 支持

---

## 模型转换流程

### 1. 安装工具

```bash
pip install rknn-toolkit2==2.0.0
```

### 2. 转换模型

```python
from rknn.api import RKNN

rknn = RKNN()
rknn.config(mean_values=[123.675, 116.28, 103.53],
            std_values=[58.82, 57.12, 57.12])
rknn.load_pytorch(model='model.onnx', input_size_list=[[1, 3, 224, 224]])
rknn.build(do_quantization=True)
rknn.save_rknn('./model.rknn')
```

---

## 性能优化

- 使用DMA buffer减少内存拷贝
- 启用多线程推理
- 批量推理提高吞吐量