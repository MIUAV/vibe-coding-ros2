---
name: sensor-fusion-locate
description: 多传感器融合定位 — 激光雷达+相机+IMU+GPS 融合 (EKF/UKF)，实现厘米级定位精度，适用于自动驾驶和精密机器人
argument-hint: 定位 OR localization OR EKF OR sensor fusion OR GPS OR IMU OR 激光雷达 OR 融合 OR landmark
user-invocable: true
---

# sensor-fusion-locate — 多传感器融合定位 SKILL

## 任务描述

融合激光雷达、相机、IMU、GPS（可选）实现机器人厘米级定位。

## 引用技能

- `agents/skills/navigation/` — 导航
- `agents/skills/perception/` — 感知
- `agents/skills/ros2-debug/` — 调试

## EKF 融合架构

```
传感器输入:
  Laser Scan → Scan Matching → 位姿观测
  IMU         → 线性加速度/角速度 → 预测步
  Camera      → 特征点匹配 → 视觉里程计
  GPS         → 绝对位置 (UTM) → 修正步

EKF 状态: [x, y, z, roll, pitch, yaw, vx, vy, vz]
```

## 传感器权重

| 传感器 | 权重 | 说明 |
|--------|------|------|
| 激光雷达 Scan Matching | 高 | 室内精度 < 0.05m |
| 视觉里程计 | 中 | 纹理丰富时 |
| IMU | 预测 | 频率高但漂移 |
| GPS | 低 | 仅室外开阔区域 |

## 禁止

- ❌ IMU 单独积分定位（漂移太大）
- ❌ GPS 用于室内（信号遮挡）
- ❌ 不同传感器数据时间戳不同步（必须硬件同步）
