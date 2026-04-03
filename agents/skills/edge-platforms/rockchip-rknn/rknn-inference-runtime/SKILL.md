---
name: rknn-inference-runtime
description: 瑞芯微RKNN推理运行时 - 模型加载 推理执行 结果获取
argument-hint: "RKNN推理" / "NPU运行" / "模型部署"
user-invocable: true
---

# RKNN 推理运行时技能

> 在瑞芯微NPU上运行RKNN模型推理

## 何时使用

- 部署转换好的RKNN模型
- 多模型管理
- 实时推理优化

## 基础用法

```python
from rknn.runtime importRKNN

rknn = RKNN()
rknn.load_rknn('./model.rknn')
rknn.init_runtime()

# 推理
outputs = rknn.inference(inputs=[input_data])
```

## 性能优化

- 使用零拷贝DMA buffer
- 批量推理
- 模型预热