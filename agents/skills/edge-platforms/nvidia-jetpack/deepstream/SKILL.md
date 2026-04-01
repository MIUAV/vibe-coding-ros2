---
name: deepstream
description: DeepStream视频分析框架 - 管道构建 插件使用 目标检测追踪
argument-hint: "DeepStream" / "视频分析" / "目标检测" / "多路视频"
user-invocable: true
---

# DeepStream 技能

> NVIDIA视频分析框架

## 何时使用

- 多路视频分析
- 目标检测追踪
- 智能监控

## 架构

```
App -> Source -> Decoder -> Streammux -> Inference -> Tracker -> Sink
```

## 示例配置

```yaml
source0: type=4
decoder: type=1
streammux:
  width: 1920
  height: 1080
  batch-size: 4
primary-detector:
  plugin: nvinfer
  config-file: config_yolo.txt
tracker:
  plugin: nvdsosd
```

## 运行

```bash
deepstream-app -c source4_1080p_dec_infer-resnet_tracker_sgie_tiled_display_int8.txt
```

## 常用插件

- **nvdsvideotemplate**: 自定义处理
- **nvmsgconv**: 消息转换
- **nvmsgbroker**: 消息发送