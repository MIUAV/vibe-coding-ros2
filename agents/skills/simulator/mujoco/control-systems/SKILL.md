---
name: control-systems
description: MuJoCo 控制系统仿真 — PD 控制器、阻抗控制、轨迹跟踪、QP 优化控制，适用于机器人控制算法验证
argument-hint: MuJoCo 控制 OR PD 控制器 OR 阻抗控制 OR 轨迹跟踪 OR QP 优化
user-invocable: true
---

# control-systems — MuJoCo 控制系统 SKILL

## 引用技能

- `agents/skills/simulation/mujoco/`
- `agents/skills/ros2-debug/`

## PD 控制器

```python
# MuJoCo PD 控制器
def pd_control(q_desired, q_current, qd_current, kp, kd):
    torque = kp * (q_desired - q_current) + kd * (qd_desired - qd_current)
    return torque
```

## 阻抗控制

```python
# 阻抗控制（末端力控制）
F_desired = Kp × (x_desired - x) + Kd × (xd_desired - xd)
```

## QP 优化控制

```python
# QP 求解关节力矩
H = q.T @ K @ q + R
g = -q.T @ K @ x_desired
q_solution = qp(H, g)
```

## ROS2 集成

```python
# mujoco_ros2_joint_control
from mujoco_ros2 import MujocoNode

class MujocoController(MujocoNode):
    def __init__(self):
        super().__init__('mujoco_controller')
        self.ctrl = np.zeros(njnt)
```

## 禁止

- ❌ MuJoCo 仿真参数不校准就用于真实机器人
- ❌ 控制频率不匹配（MuJoCo 1000Hz ≠ 真实 400Hz）
