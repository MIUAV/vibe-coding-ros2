---
name: rknn-camera-driver
description: 瑞芯微MIPI CSI相机驱动 - 相机配置 ISP调优 视频流获取
argument-hint: MIPI相机 OR CSI驱动 OR ISP OR Rockchip相机
user-invocable: true
---

# RKNN 相机驱动技能

> 配置瑞芯微MIPI CSI相机和ISP

## 何时使用

- 配置MIPI CSI相机
- ISP参数调优
- 获取视频流数据

## 支持的相机

| 型号 | 分辨率 | 接口 | 特点 |
|------|--------|------|------|
| IMX415 | 4K | MIPI CSI-2 | 星光级 |
| IMX327 | 1080P | MIPI CSI-2 | 低光夜视 |
| GC4663 | 4K | MIPI CSI-2 | 高性价比 |
| OV13850 | 1300W | MIPI CSI-2 | 宽动态 |

## 配置步骤

```bash
# 检查相机设备
ls /dev/video*

# 配置Media topology
media-ctl -d /dev/media0 -p
```

## ISP调优

- 曝光控制
- 白平衡
- 降噪参数