---
name: multi-robot-swarm
description: 多机器人 swarm 协作系统 — 分布式任务分配、蜂群编队控制、碰撞协调，适用于仓库物流/协同搜救场景
argument-hint: 多机器人 OR swarm OR multi-agent OR 蜂群 OR 编队 OR formation control OR 协同控制
user-invocable: true
---

# multi-robot-swarm — 多机器人 Swarm 协作 SKILL

## 任务描述

N 个机器人（3-10台）协同完成区域覆盖任务，包含：分布式任务分配、编队控制、机器人间碰撞协调。

## 引用技能

- `agents/skills/multi-agent-swarm/` — Swarm 协调基础
- `agents/skills/wheeled_vehicle/` — 轮式机器人控制
- `agents/skills/ros2-qos-checker/` — QoS（RELIABLE 用于协调命令）
- `agents/skills/ros2-debug/` — 调试

## 蜂群架构

```
用户任务 (Area Coverage)
       │
       ▼
┌─────────────────┐
│  Task Allocator │ ← 拍卖/竞拍分布式分配
└────────┬────────┘
         │ 广播任务
         ▼
   ┌─────────────┐
   │ Robot 1-N  │ ← 每个机器人独立运行
   │ ├─ Navigator│
   │ ├─ Formation│ ← 编队控制器
   │ └─ Collision│ ← 碰撞协调
   └─────────────┘
```

## 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 机器人数量 | 3-10 | 可配置 |
| 编队形状 | leader-follower | 直线/三角/菱形 |
| 通信半径 | 5 m | 通信距离 |
| 安全距离 | 0.5 m | 机器人间最小距离 |
| 编队间距 | 1.0 m | 机器人间距 |
| 控制频率 | 10 Hz | 编队控制频率 |

## 任务分配算法

### 拍卖算法 (Auction-Based)

```
1. 任务区域划分为 N 个子区域
2. 每个机器人对子区域投标（基于距离）
3. 拍卖人选择最低价/最优标
4. 分配结果广播给所有机器人
5. 机器人移动到分配的子区域
```

## 禁止

- ❌ 机器人间通信用 BEST_EFFORT（协调命令必须可靠）
- ❌ 安全距离 < 0.3m（碰撞风险）
- ❌ 编队间距 < 0.5m（机器人会碰撞）
- ❌ 超过 20 台机器人（通信复杂度爆炸）
