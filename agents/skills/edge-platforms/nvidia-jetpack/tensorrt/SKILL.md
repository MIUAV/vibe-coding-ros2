---
name: tensorrt
description: TensorRT推理优化 - 模型转换 引擎构建 INT8量化
argument-hint: TensorRT OR 模型优化 OR INT8量化 OR 引擎生成
user-invocable: true
---

# TensorRT 技能

> NVIDIA推理优化引擎

## 何时使用

- 模型推理优化
- INT8量化加速
- 实时推理部署

## 工作流程

```
ONNX/PyTorch -> TensorRT -> Engine -> Inference
```

## Python示例

```python
import tensorrt as trt

logger = trt.Logger(trt.Logger.WARNING)
builder = trt.Builder(logger)
network = builder.create_network(1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH))
config = builder.create_builder_config()
parser = trt.OnnxParser(network, logger)

# 解析ONNX
with open('model.onnx', 'rb') as f:
    parser.parse(f.read())

# 构建引擎
engine = builder.build_serialized_network(network, config)

# 推理
runtime = trv.Runtime(logger)
engine = runtime.deserialize_cuda_engine(engine)
context = engine.create_execution_context()
context.execute_v2(bindings)
```

## 优化技术

- **FP16**: 半精度加速
- **INT8**: 量化加速
- **动态形状**: 灵活推理
- **插件**: 自定义算子