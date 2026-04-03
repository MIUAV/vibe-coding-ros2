---
name: rknn-model-conversion
description: 瑞芯微RKNN模型转换 - ONNX PyTorch TensorFlow转RKNN
argument-hint: "模型转换" / "RKNN转换" / "量化"
user-invocable: true
---

# Rockchip RKNN 模型转换技能

> 将PyTorch/TensorFlow/ONNX模型转换为RKNN格式

## 何时使用

- 将训练好的模型部署到RK3588/RK3568
- 模型量化 (INT8/FP16)
- 混合精度优化

## 支持的模型格式

| 格式 | 支持程度 | 说明 |
|------|---------|------|
| ONNX | 完整支持 | 推荐格式 |
| PyTorch | 完整支持 | .pt/.pth |
| TensorFlow | 部分支持 | .pb |
| TFLite | 部分支持 | .tflite |

## 转换示例

```python
from rknn.api import RKNN

rknn = RKNN()
# 配置输入预处理
rknn.config(
    mean_values=[123.675, 116.28, 103.53],
    std_values=[58.82, 57.12, 57.12],
    inputs_format=['RGB']
)
# 加载模型
rknn.load_onnx(model='resnet50.onnx', input_size_list=[[1, 3, 224, 224]])
# 构建
rknn.build(do_quantization=True, quantize_dtype='int8')
# 保存
rknn.save_rknn('./resnet50.rknn')
```

## 常见问题

- 算子不支持: 使用ONNX算子替代
- 量化精度损失: 调整量化算法或使用FP16