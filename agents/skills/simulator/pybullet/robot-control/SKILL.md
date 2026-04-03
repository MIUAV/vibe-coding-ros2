---
name: robot-control
description: PyBullet 机器人控制技能 - 关节控制、力控制、运动学
argument-hint: "PyBullet控制" / "关节控制" / "力控制"
user-invocable: true
---

# PyBullet Robot Control Skill

> 用于 PyBullet 中的机器人控制

---

## 何时使用

当需要以下帮助时使用此技能：
- 控制关节位置
- 应用力和扭矩
- 运动学计算

---

## 快速参考

### 加载机器人

```python
robot_id = p.loadURDF("franka_panda/panda.urdf")
```

---

## 控制模式

### 位置控制

```python
p.setJointMotorControl2(
    robot_id,
    joint_index,
    p.POSITION_CONTROL,
    targetPosition=1.0,
    force=100
)
```

### 速度控制

```python
p.setJointMotorControl2(
    robot_id,
    joint_index,
    p.VELOCITY_CONTROL,
    targetVelocity=0.5,
    force=50
)
```

### 力控制

```python
p.setJointMotorControl2(
    robot_id,
    joint_index,
    p.TORQUE_CONTROL,
    force=10.0
)
```

---

## 另见

- [rl-environments](../rl-environments/) - RL 环境
- [physics-simulation](../physics-simulation/) - 物理仿真