---
name: robot-sim
description: Isaac Lab 机器人仿真技能 - 机器人配置、关节控制、物理模拟
argument-hint: Isaac Lab机器人 OR 机器人仿真 OR 关节控制
user-invocable: true
---

# Isaac Lab Robot Simulation Skill

> 用于在 Isaac Lab 中配置和控制机器人

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置机器人模型
- 控制关节运动
- 应用力和扭矩
- 设置物理参数

---

## 快速参考

### 添加机器人

```python
from isaaclab.assets import RobotCfg

robot_cfg = RobotCfg(
    name="my_robot",
    usd_path="/path/to/robot.usd",
    articulation_props=ArticulationCfg(
        solver_type="Featherstone",
        activate_warmstart=True,
        stiffness={".*": 500.0},
        damping={".*": 50.0}
    )
)
```

---

## 机器人配置

### 关节配置

```python
from isaaclab.assets import RigidBodyCfg, ArticulationCfg

robot_cfg = RobotCfg(
    name="my_robot",
    usd_path="/path/to/robot.usd",
    articulation_props=ArticulationCfg(
        # 仿真参数
        solver_type="Featherstone",
        dt=0.005,
        
        # 关节刚度和阻尼
        stiffness={
            ".*": 500.0  # 所有关节
        },
        damping={
            "joint_1": 10.0,
            "joint_2": 20.0
        },
        
        # 位置/速度限制
        position_limits={
            "joint_1": (-1.5, 1.5),
            "joint_2": (-2.0, 2.0)
        },
        velocity_limits={
            ".*": 10.0  # rad/s
        },
        effort_limits={
            ".*": 100.0  # Nm
        }
    )
)
```

---

## 控制器

### 关节位置控制器

```python
from isaaclab.controllers import DifferentialIKController

controller = DifferentialIKController(
    cfg=DifferentialIKControllerCfg(
        command_type="position",
        ik_solver="dls",
        num_steps=10
    )
)

# 设置目标位置
controller.set_goal(target_position)

# 更新
joint_pos = robot.data.joint_pos
joint_pos_desired = controller.compute(
    robot.data.joint_pos,
    robot.data.joint_vel
)
```

### PD 控制器

```python
# 简单的 PD 控制器
kp = 100.0  # 比例增益
kd = 10.0  # 微分增益

def pd_control(target_pos, current_pos, current_vel):
    error = target_pos - current_pos
    torque = kp * error - kd * current_vel
    return torque
```

---

## 应用力

### 应用关节力矩

```python
# 设置关节力矩
robot.set_joint_effort(effort)

# 或者使用动作
action = torch.zeros(num_envs, num_joints)
action[:, joint_index] = 10.0  # 10 Nm
env.step(action)
```

---

## 常见问题

### 问题 1: 机器人不稳定

**解决方案**：增加阻尼，调整控制增益

---

## 另见

- [rl-training](../rl-training/) - 强化学习训练
- [sensor-sim](../sensor-sim/) - 传感器仿真