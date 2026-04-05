---
name: sensor-fusion
description: 多传感器融合 — EKF/UKF/PF 状态估计，激光雷达+相机+IMU+GPS融合，实现厘米级定位
argument-hint: 传感器融合 OR sensor fusion OR EKF OR UKF OR 状态估计 OR 定位 OR localization
user-invocable: true
---

# sensor-fusion — 多传感器融合 SKILL

## 引用技能

- `agents/skills/navigation/`
- `agents/skills/ros2-debug/`

## EKF 状态估计

```
预测: x̄ = F × x + B × u
更新: x = x̄ + K × (z - H × x̄)
```

状态向量: `[x, y, z, roll, pitch, yaw, vx, vy, vz]`

## 传感器权重

| 传感器 | 权重 | 说明 |
|--------|------|------|
| 激光雷达 Scan Matching | 高 | 室内精度 < 0.05m |
| IMU | 预测 | 频率高但漂移 |
| GPS | 低 | 仅室外开阔区域 |

## 禁止

- ❌ IMU 单独积分定位（漂移爆炸）
- ❌ GPS 用于室内（信号遮挡）
