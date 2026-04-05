---
name: collaborative-control
description: 多机器人协同控制 — 编队保持、任务分配、冲突协调、leader-follower，适用于多移动机器人协同作业
argument-hint: 协同控制 OR collaborative OR 多机编队 OR formation control OR leader-follower OR 任务分配
user-invocable: true
---

# collaborative-control — 多机器人协同控制 SKILL

## 引用技能

- `agents/skills/wheeled_vehicle/`
- `agents/skills/ros2-qos-checker/`

## 编队控制

### Leader-Follower

```
u_follower = Kp × (p_formation - p_current) + Kd × (v_target - v_current)
```

| 参数 | 值 |
|------|-----|
| 编队间距 | 1.0 m |
| 安全距离 | 0.5 m |
| 控制频率 | 10 Hz |

## 禁止

- ❌ 安全距离 < 0.3m（碰撞风险）
- ❌ 通信用 BEST_EFFORT（协调命令必须可靠）
