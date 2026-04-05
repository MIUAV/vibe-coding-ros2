---
name: go2-scurve
description: 四足机器人 Unitree Go2 S曲线轨迹规划 — 基于位置/速度/加速度约束的平滑轨迹生成，适用于崎岖地形避障
argument-hint: 四足 OR go2 OR 足式 OR S曲线 OR S-curve OR trajectory planning OR 轨迹规划
user-invocable: true
---

# go2-scurve — Go2 S曲线轨迹规划 SKILL

## 任务描述

为 Unitree Go2 四足机器人规划并执行 S 曲线轨迹，使机器人在二维平面内沿平滑 S 形曲线行走。

## 引用技能

- `agents/skills/motion-control/quadruped-control/` — 四足运动控制基础
- `agents/skills/ros2-debug/` — 编译/运行时调试
- `agents/skills/ros2-qos-checker/` — QoS 兼容性（关节命令必须 RELIABLE）
- `agents/skills/ros2-cmake-guard/` — CMake 依赖检查

## 任务专属规则

### S-curve 数学约束

```
S-curve = 两个相反方向的弧线连接段

参数:
  A_max  — 最大加速度 (m/s²)
  V_max  — 最大速度 (m/s)
  J_max  — 最大加加速度 (jerk, m/s³)
  
  T_acc  = V_max / A_max          # 加速时间
  T_jerk = A_max / J_max          # 加加速度时间
  L_total = 2 × S_curve_length    # 总路程
```

### Go2 物理参数

| 参数 | 值 |
|------|-----|
| 腿长 | 0.4 m |
| 单腿最大负载 | 25 kg（整机）|
| 最大行走速度 | 1.5 m/s |
| 关节数 | 12（每腿3个）|
| 控制频率 | 400 Hz |
| 通信接口 | UDP（RELIABLE）|

### 轨迹验证检查项

- [ ] 速度不超过 V_max
- [ ] 加速度不超过 A_max
- [ ] jerk 连续（无突变）
- [ ] 足端轨迹无碰撞（地隙 > 0.05m）
- [ ] 关节角度在物理限位内
- [ ] 周期 T > 0.5s（满足 400Hz 控制频率）

## 禁止

- ❌ 用直线轨迹替代 S-curve（冲击载荷大）
- ❌ 忽略 Go2 的运动学逆解（IK）直接规划笛卡尔坐标
- ❌ 控制命令用 BEST_EFFORT QoS（四足会抖动失控）
