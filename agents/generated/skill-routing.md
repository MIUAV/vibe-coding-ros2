# Skill Routing — 技能路由表

> 由 init-agent.sh 自动生成。同名 skill 按完整路径优先级路由。

## 路由规则

```
用户请求 → 机器人类型 → 功能域 → 具体 skill
         → humanoid/manipulator/... → motion-control/perception/...
```

## 机器人类型路由

| 类型 | 场景 |
|------|------|
| humanoid | 双足步态、人形操作、平衡控制 |
| quadruped | 四足行走、复杂地形 |
| manipulator | 机械臂抓取、运动规划 |
| wheeled_vehicle | 轮式导航、差速驱动 |
| multi_rotor_uav | 无人机飞行、悬停 |
| underwater | AUV/ROV、水下导航 |
| common | 所有类型通用（cmake、colcon 等） |
