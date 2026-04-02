---
name: mjcf-models
description: MuJoCo MJCF 模型技能 - 创建机器人模型、关节、接触配置
argument-hint: "MuJoCo MJCF" / "模型创建" / "关节配置"
user-invocable: true
---

# MuJoCo MJCF Models Skill

> 用于创建 MuJoCo MJCF 模型

---

## 快速参考

### 基本模型

```xml
<mujoco model="robot">
  <compiler angle="radian" meshdir="meshes"/>
  <option timestep="0.002"/>
  
  <worldbody>
    <light diffuse=".5 .5 .5" pos="0 0 3" dir="0 0 -1"/>
    <geom type="plane" size="1 1 0.1" rgba=".9 .9 .9 1"/>
  </worldbody>
  
  <actuator>
    <motor joint="joint1" ctrllim="100" gear="100"/>
  </actuator>
</mujoco>
```

---

## 另见

- [control-systems](../control-systems/) - 控制系统