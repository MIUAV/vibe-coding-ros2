---
name: underwater-nav
description: 水下机器人导航 — DVL 多普勒计程仪 + IMU + USBL 超短基线定位，适用于 AUV 自主导航和水面母船协同
argument-hint: 水下 OR underwater OR AUV OR DVL OR USBL OR 潜航器 OR 导航 OR 定位
user-invocable: true
---

# underwater-nav — 水下机器人导航 SKILL

## 任务描述

水下机器人（AUV）实现三维空间导航，包含 DVL 速度计、IMU 惯性导航、压力传感器深度测量、USBL 水面定位修正。

## 引用技能

- `agents/skills/navigation/` — 导航基础
- `agents/skills/motion-control/underwater/` — 水下机器人控制
- `agents/skills/ros2-qos-checker/` — QoS（水声通信用 RELIABLE）
- `agents/skills/ros2-debug/` — 调试

## 水下导航架构

```
传感器层:
  DVL ──► 速度积分 ──► 位置估计 (drift累积)
  IMU  ──► 姿态估计   ──► 欧拉角
  Pressure ──► 深度估计

修正层:
  USBL ──► 绝对位置修正 (水面信标)

融合层:
  EKF ──► 融合 DVL + IMU + USBL ──► 最优位置/速度/姿态估计
```

## DVL 参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 测速范围 | ±20 m/s | 相对海底速度 |
| 频率 | 300/600 kHz | 频率越高精度越高 |
| 最大深度 | 300/600/1000 m | 取决于型号 |
| 精度 | 0.2% ± 0.002 m/s | 速度精度 |

## 水声通信约束

| 参数 | 值 |
|------|-----|
| 通信延迟 | 0.5-2.0 s（距离相关）|
| 带宽 | 几百 bps（低带宽）|
| 可靠性 | 低（水下环境）|
| USBL 刷新率 | 0.5-2 Hz |

## 禁止

- ❌ 水声通信用 BEST_EFFORT（延迟高，丢包不重传浪费带宽）
- ❌ 不做 EKF 融合直接用 DVL 积分（位置漂移会爆炸）
- ❌ DVL 丢失时不做特殊处理（DVL 高度变化大时会失效）
