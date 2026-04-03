---
name: physics-simulation
description: PyBullet 物理仿真技能 - 刚体动力学、碰撞检测、约束配置
argument-hint: PyBullet物理 OR 碰撞检测 OR 约束配置
user-invocable: true
---

# PyBullet Physics Simulation Skill

> 用于 PyBullet 物理仿真配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置物理参数
- 设置碰撞检测
- 使用约束

---

## 快速参考

### 连接

```python
import pybullet as p
import pybullet_data

client = p.connect(p.GUI)  # GUI 模式
# client = p.connect(p.DIRECT)  # 无头模式

p.setAdditionalSearchPath(pybullet_data.getDataPath())
```

---

## 物理配置

### 重力和时间步

```python
p.setGravity(0, 0, -9.81)
p.setTimeStep(1/240)  # 默认 240Hz
```

---

## 约束

### 关节约束

```python
# 创建点对点约束
constraint = p.createConstraint(
    parentBodyUniqueId,
    parentLinkIndex,
    childBodyUniqueId,
    childLinkIndex,
    p.JOINT_POINT2POINT,
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0]
)
```

---

## 另见

- [rl-environments](../rl-environments/) - RL 环境
- [robot-control](../robot-control/) - 机器人控制