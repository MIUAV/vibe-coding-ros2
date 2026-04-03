---
name: control-systems
description: MuJoCo 控制系统技能 - PD 控制器、阻抗控制、轨迹跟踪
argument-hint: MuJoCo控制 OR PD控制 OR 阻抗控制
user-invocable: true
---

# MuJoCo Control Systems Skill

> 用于 MuJoCo 控制系统

---

## 快速参考

### PD 控制器

```python
import mujoco

def pd_control(model, data, target_pos):
    kp = 100.0
    kd = 10.0
    
    error = target_pos - data.qpos
    derivative = -data.qvel
    
    control = kp * error + kd * derivative
    data.ctrl = control
```

---

## 另见

- [mjcf-models](../mjcf-models/) - MJCF 模型