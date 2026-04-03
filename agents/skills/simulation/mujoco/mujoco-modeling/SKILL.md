---
name: mujoco-modeling
description: Mujoco 建模技能 - MJCF 模型、关节驱动、接触参数、ROS2 Mujoco 桥接
argument-hint: "Mujoco" / "MJCF" / "建模" / "mujoco_model"
user-invocable: true
---

# Mujoco 建模技能

> Mujoco 物理仿真建模

---

## 何时使用

当需要以下帮助时使用此技能：
- MJCF 模型
- 关节和驱动
- 接触参数
- 力学验证
- ROS2 Mujoco 桥接

---

## 核心实现

### MJCF 模型

```xml
<!-- robot.xml -->
<mujoco model="robot">
  <compiler angle="radian" meshdir="meshes" autolimits="true"/>
  
  <!-- 默认参数 -->
  <option timestep="0.001" iterations="50" jacobian="dense" solver="Newton"/>
  
  <!-- 视觉化 -->
  <visual>
    <map znear="0.02" zfar="50"/>
    <quality shadow="true"/>
  </visual>
  
  <!-- 物理参数 -->
  <flag contact="true" energy="true"/>
  
  <!-- 世界 -->
  <worldbody>
    <!-- 地面 -->
    <geom type="plane" size="10 10 0.1" rgba="0.8 0.8 0.8 1" friction="1 0.005 0.0001"/>
    
    <!-- 机器人 -->
    <body name="torso" pos="0 0 0.5">
      <freejoint/>
      <inertial pos="0 0 0" mass="10" diaginertia="0.1 0.1 0.1"/>
      
      <geom type="box" size="0.2 0.2 0.3" rgba="1 0.5 0 1" mass="10"/>
      
      <!-- 腿 -->
      <body name="front_left_leg" pos="0.15 0.15 0">
        <joint name="hip_x" type="hinge" axis="1 0 0" range="-1 1"/>
        <inertial pos="0 0 -0.2" mass="1" diaginertia="0.01 0.01 0.01"/>
        
        <geom type="capsule" fromto="0 0 0 0 0 -0.4" rgba="0.8 0.2 0.2 1" 
              friction="1" density="500"/>
        
        <body name="front_left_foot" pos="0 0 -0.4">
          <joint name="ankle_x" type="hinge" axis="1 0 0" range="-0.5 0.5"/>
          <geom type="sphere" size="0.05" rgba="0.2 0.2 0.8 1" friction="1"/>
        </body>
      </body>
    </body>
  </worldbody>
  
  <!-- 驱动器 -->
  <actuator>
    <motor joint="hip_x" gear="100" ctrllimited="true" ctrlrange="-10 10"/>
    <motor joint="ankle_x" gear="50" ctrllimited="true" ctrlrange="-5 5"/>
  </actuator>
</mujoco>
```

### ROS2 Mujoco 桥接

```python
# mujoco_ros_bridge.py
import mujoco
import numpy as np

class MujocoROS_Bridge:
    def __init__(self, model_path):
        self.model = mujoco.MjModel.from_xml_path(model_path)
        self.data = mujoco.MjData(self.model)
        
        # ROS2 接口
        # 订阅关节命令
        # 发布关节状态
        
    def step(self, ctrl):
        """执行一步仿真"""
        self.data.ctrl = ctrl
        mujoco.mj_step(self.model, self.data)
        
        return {
            'qpos': self.data.qpos.copy(),
            'qvel': self.data.qvel.copy(),
            'qacc': self.data.qacc.copy()
        }
```
