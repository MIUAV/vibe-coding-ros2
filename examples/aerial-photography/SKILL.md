---
name: aerial-photography
description: 无人机航拍任务 — 自主航线规划+相机控制+实时图传，适用于测绘、巡检、农业遥感
argument-hint: 航拍 OR aerial photography OR 测绘 OR mapping OR 巡检 OR drone survey OR 无人机航拍
user-invocable: true
---

# aerial-photography — 无人机航拍 SKILL

## 任务描述

无人机按规划航线自主飞行，拍摄目标区域照片并实时图传。用于测绘、巡检、农业遥感。

## 引用技能

- `agents/skills/navigation/` — 导航
- `agents/skills/perception/` — 相机感知
- `agents/skills/motion-control/multi_rotor_uav/` — 飞控
- `agents/skills/ros2-debug/` — 调试

## 航拍参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 航高 | 50-300 m | 测绘精度决定 |
| 重叠率 | 前向 80%/旁向 60% | 确保图像覆盖 |
| 相机焦距 | 20-35 mm（全画幅）| 根据航高选择 |
| 地面分辨率 (GSD) | 3-10 cm/pixel | 航高/焦距决定 |
| 飞行速度 | 8-15 m/s | 取决于相机曝光间隔 |

## 航线规划

```
1. 定义目标区域（多边形）
2. 计算航线条带（根据重叠率和相机参数）
3. 生成航点序列
4. 每点触发相机快门
5. 实时图传监控
```

## 禁止

- ❌ 航高低于 30m（法律限制、飞行安全）
- ❌ 重叠率低于 60%（图像拼接困难）
- ❌ 在云层下飞行（能见度要求）
