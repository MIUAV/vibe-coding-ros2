---
name: dataset-playback
description: ManiSkill3 数据回放技能 - 演示数据加载、重放、轨迹分析
argument-hint: "ManiSkill3数据" / "演示回放" / "轨迹分析"
user-invocable: true
---

# ManiSkill3 Dataset Playback Skill

> 用于 ManiSkill3 中的演示数据回放

---

## 何时使用

当需要以下帮助时使用此技能：
- 加载演示数据集
- 回放机器人轨迹
- 分析演示数据
- 预处理数据

---

## 快速参考

### 加载数据

```python
from mani_skill3 import trajectory

# 加载轨迹
traj = trajectory.load("demo.h5")

# 获取数据
states = traj["states"]
actions = traj["actions"]
```

---

## 数据格式

### 轨迹结构

```python
trajectory = {
    "observations": [
        {
            "robot_state": {...},
            "image": {...},
            "depth": {...}
        }
    ],
    "actions": [...],
    "rewards": [...],
    "dones": [...]
}
```

---

## 回放

```python
# 回放演示
env.reset()
for i in range(len(trajectory)):
    obs, reward, done, info = env.step(trajectory["actions"][i])
    env.render()
```

---

## 常见问题

### 问题 1: 数据格式不匹配

**解决方案**：检查数据版本兼容性

---

## 另见

- [manipulation-tasks](../manipulation-tasks/) - 操作任务
- [environment-setup](../environment-setup/) - 环境配置