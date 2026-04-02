---
name: mujoco
description: MuJoCo 物理仿真开发技能 - 高性能物理引擎、强化学习环境、MJCF 模型、GPU 加速
argument-hint: "mujoco仿真" / "强化学习" / "MJCF模型" / "机器人控制"
user-invocable: true
---

# MuJoCo Physics Simulation Skill

> 用于 MuJoCo 物理仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 MuJoCo
- 创建 MJCF 模型
- 编写强化学习环境
- 使用 GPU 加速
- 集成 ROS

---

## 快速参考

### 安装 MuJoCo

```bash
# 安装 mujoco-py
pip install mujoco-py

# 或安装 mujoco (新版本)
pip install mujoco

# 下载 MuJoCo 引擎
# https://github.com/deepmind/mujoco/releases
# 解压到 ~/.mujoco/mujoco200
```

### 基本使用

```python
import mujoco
import mujoco.viewer as viewer

# 加载模型
model = mujoco.MjModel.from_xml_path("robot.xml")
data = model.data

# 创建查看器
v = viewer.launch_passive(model, data)

# 仿真循环
for _ in range(1000):
    mujoco.mj_step(model, data)
    v.sync()
```

---

## MJCF 模型

### 基本结构

```xml
<mujoco model="my_robot">
  <!-- 编译器设置 -->
  <compiler angle="radian" meshdir="meshes" autolimits="true"/>
  
  <!-- 选项设置 -->
  <option timestep="0.002" integrator="Euler" iterations="50" tolerance="1e-10"/>
  
  <!-- 全局设置 -->
  <global>
    <gravity gravity="0 0 -9.81"/>
    <wind wind="0 0 0"/>
    <density density="1.0"/>
    <viscosity viscosity="0.0"/>
  </global>
  
  <!-- 世界资源 -->
  <worldbody>
    <!-- 地面 -->
    <geom type="plane" size="10 10 0.1" rgba="0.5 0.5 0.5 1" friction="0.4 0.005 0.0001"/>
    
    <!-- 光照 -->
    <light pos="0 0 5" dir="0 0 -1" diffuse="0.8 0.8 0.8" specular="0.3 0.3 0.3"/>
  </worldbody>
  
  <!-- 关节驱动 -->
  <actuator>
    <motor joint="shoulder" ctrllimited="true" ctrlrange="-50 50" gear="100"/>
  </actuator>
</mujoco>
```

### 完整机器人示例 - 双足机器人

```xml
<mujoco model="biped_robot">
  <compiler angle="radian" meshdir="meshes" autolimits="true"/>
  <option timestep="0.002" iterations="100" solver="Newton" gravity="0 0 -9.81"/>
  
  <worldbody>
    <!-- 躯干 -->
    <body name="torso" pos="0 0 1.0">
      <freejoint/>
      <inertial pos="0 0 0" mass="8" diaginertia="0.1 0.08 0.08"/>
      
      <geom type="capsule" size="0.07 0.2" rgba="0.4 0.4 0.4 1" friction="0.5"/>
      
      <!-- 头部 -->
      <body name="head" pos="0 0 0.25">
        <inertial pos="0 0 0" mass="1.5" diaginertia="0.01 0.01 0.01"/>
        <geom type="sphere" size="0.1" rgba="0.6 0.6 0.6 1"/>
        
        <!-- 眼睛传感器 -->
        <camera name="eye" pos="0.05 0 0.05" fovy="90"/>
      </body>
      
      <!-- 左腿 -->
      <body name="left_hip" pos="0 0.1 -0.2">
        <joint name="hip_flexion" type="hinge" axis="1 0 0" range="-90 90" damping="0.1"/>
        <inertial pos="0 0 -0.1" mass="2" diaginertia="0.02 0.01 0.02"/>
        
        <geom type="capsule" size="0.04 0.2" rgba="0.3 0.3 0.3 1"/>
        
        <body name="left_knee" pos="0 0 -0.2">
          <joint name="knee" type="hinge" axis="1 0 0" range="-150 0" damping="0.1"/>
          <inertial pos="0 0 -0.1" mass="1.5" diaginertia="0.015 0.01 0.015"/>
          
          <geom type="capsule" size="0.035 0.2" rgba="0.35 0.35 0.35 1"/>
          
          <body name="left_foot" pos="0 0 -0.2">
            <joint name="ankle" type="hinge" axis="1 0 0" range="-45 45" damping="0.05"/>
            <inertial pos="0 0 -0.05" mass="0.5" diaginertia="0.005 0.003 0.005"/>
            
            <geom type="box" size="0.06 0.04 0.02" rgba="0.2 0.2 0.2 1" friction="1.0 0.005 0.0001"/>
          </body>
        </body>
      </body>
      
      <!-- 右腿 (镜像) -->
      <body name="right_hip" pos="0 -0.1 -0.2">
        <joint name="hip_flexion" type="hinge" axis="1 0 0" range="-90 90" damping="0.1"/>
        <inertial pos="0 0 -0.1" mass="2" diaginertia="0.02 0.01 0.02"/>
        
        <geom type="capsule" size="0.04 0.2" rgba="0.3 0.3 0.3 1"/>
        
        <body name="right_knee" pos="0 0 -0.2">
          <joint name="knee" type="hinge" axis="1 0 0" range="-150 0" damping="0.1"/>
          <inertial pos="0 0 -0.1" mass="1.5" diaginertia="0.015 0.01 0.015"/>
          
          <geom type="capsule" size="0.035 0.2" rgba="0.35 0.35 0.35 1"/>
          
          <body name="right_foot" pos="0 0 -0.2">
            <joint name="ankle" type="hinge" axis="1 0 0" range="-45 45" damping="0.05"/>
            <inertial pos="0 0 -0.05" mass="0.5" diaginertia="0.005 0.003 0.005"/>
            
            <geom type="box" size="0.06 0.04 0.02" rgba="0.2 0.2 0.2 1" friction="1.0 0.005 0.0001"/>
          </body>
        </body>
      </body>
      
      <!-- 左臂 -->
      <body name="left_shoulder" pos="0.15 0 0.15">
        <joint name="shoulder_flexion" type="hinge" axis="0 0 1" range="-180 180" damping="0.05"/>
        <inertial pos="0 0 0" mass="0.8" diaginertia="0.005 0.005 0.002"/>
        
        <geom type="capsule" size="0.025 0.15" rgba="0.4 0.4 0.4 1"/>
        
        <body name="left_elbow" pos="0 0 -0.15">
          <joint name="elbow" type="hinge" axis="0 0 1" range="-150 0" damping="0.05"/>
          <inertial pos="0 0 0" mass="0.5" diaginertia="0.003 0.003 0.001"/>
          
          <geom type="capsule" size="0.02 0.12" rgba="0.45 0.45 0.45 1"/>
        </body>
      </body>
      
      <!-- 右臂 -->
      <body name="right_shoulder" pos="0.15 0 0.15">
        <joint name="shoulder_flexion" type="hinge" axis="0 0 1" range="-180 180" damping="0.05"/>
        <inertial pos="0 0 0" mass="0.8" diaginertia="0.005 0.005 0.002"/>
        
        <geom type="capsule" size="0.025 0.15" rgba="0.4 0.4 0.4 1"/>
        
        <body name="right_elbow" pos="0 0 -0.15">
          <joint name="elbow" type="hinge" axis="0 0 1" range="-150 0" damping="0.05"/>
          <inertial pos="0 0 0" mass="0.5" diaginertia="0.003 0.003 0.001"/>
          
          <geom type="capsule" size="0.02 0.12" rgba="0.45 0.45 0.45 1"/>
        </body>
      </body>
    </body>
  </worldbody>
  
  <!-- 驱动器 -->
  <actuator>
    <motor joint="hip_flexion" ctrllimited="true" ctrlrange="-50 50" gear="50"/>
    <motor joint="knee" ctrllimited="true" ctrlrange="-30 30" gear="30"/>
    <motor joint="ankle" ctrllimited="true" ctrlrange="-20 20" gear="20"/>
    <motor joint="shoulder_flexion" ctrllimited="true" ctrlrange="-20 20" gear="20"/>
    <motor joint="elbow" ctrllimited="true" ctrlrange="-15 15" gear="15"/>
  </actuator>
  
  <!-- 传感器 -->
  <sensor>
    <!-- 触地传感器 -->
    <framepos objtype="body" objname="left_foot"/>
    <framepos objtype="body" objname="right_foot"/>
    
    <!-- 关节角度 -->
    <jointpos joint="hip_flexion"/>
    <jointpos joint="knee"/>
    <jointpos joint="ankle"/>
    
    <!-- IMU -->
    <gyro site="torso"/>
    <accelerometer site="torso"/>
  </sensor>
</mujoco>
```

---

## 强化学习环境

### 使用 Gymnasium

```python
import gymnasium as gym
from gym import spaces
import numpy as np

class MuJoCoEnv(gym.Env):
    def __init__(self, model_path="robot.xml"):
        super().__init__()
        
        # 加载模型
        self.model = mujoco.MjModel.from_xml_path(model_path)
        self.data = self.model.data
        
        # 定义空间
        self.action_space = spaces.Box(
            low=-1, high=1,
            shape=(self.model.nu,),
            dtype=np.float32
        )
        
        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf,
            shape=(self.model.nq + self.model.nv + self.model.nu,),
            dtype=np.float32
        )
        
    def reset(self, seed=None, options=None):
        # 重置状态
        mujoco.mj_resetData(self.model, self.data)
        
        # 获取观察
        obs = self._get_obs()
        
        return obs, {}
    
    def step(self, action):
        # 应用控制
        self.data.ctrl[:] = action
        
        # 仿真一步
        mujoco.mj_step(self.model, self.data)
        
        # 获取结果
        obs = self._get_obs()
        reward = self._compute_reward()
        done = self._is_done()
        
        return obs, reward, done, False, {}
    
    def _get_obs(self):
        # 状态 = 关节位置 + 关节速度 + 控制
        return np.concatenate([
            self.data.qpos,  # 关节位置
            self.data.qvel,  # 关节速度
            self.data.ctrl  # 控制输入
        ])
    
    def _compute_reward(self):
        # 奖励函数
        return 0
    
    def _is_done(self):
        # 检查是否终止
        return False
    
    def render(self):
        # 渲染
        pass
```

### 使用 DM Control

```python
from dm_control import suite
import numpy as np

# 加载环境
env = suite.load(domain_name="walker", task_name="run")

# 获取观察和动作规格
action_spec = env.action_spec()
observation_spec = env.observation_spec()

# 运行 episodes
time_step = env.reset()
while not time_step.last():
    action = np.random.uniform(action_spec.minimum, action_spec.maximum)
    time_step = env.step(action)
    
    print(f"Reward: {time_step.reward}")
```

---

## 控制器

### PD 控制器

```python
def pd_control(model, data, kp=1.0, kd=0.5):
    """PD 控制器"""
    # 目标位置 (可以从外部输入)
    q_des = np.zeros(model.nq)
    qdot_des = np.zeros(model.nv)
    
    # PD 控制
    q_error = q_des - data.qpos
    qdot_error = qdot_des - data.qvel
    
    # 计算控制力
    ctrl = kp * q_error + kd * qdot_error
    
    return ctrl
```

### 阻抗控制

```python
def impedance_control(model, data, target_pos, k_p=100, k_d=10):
    """阻抗控制器"""
    # 当前末端位置 (假设为最后一个 body)
    current_pos = data.body_xpos[-1]
    
    # 位置误差
    error = target_pos - current_pos
    
    # 阻抗控制力
    f = k_p * error - k_d * data.cvel
    
    # 转换为关节力 (简化版)
    ctrl = np.zeros(model.nu)
    # 实际需要使用 Jacobian
    
    return ctrl
```

---

## GPU 加速

### GPU 仿真

```python
# 检查 GPU 可用性
print(mujoco.get_platform())

# 启用 GPU
model = mujoco.MjModel.from_xml_path("robot.xml", 
                                       nthread=4,
                                       nsubsteps=2)
```

### 并行环境

```python
# 使用 dm_control 并行环境
from dm_control import composer
from dm_control import suite

# 创建并行环境
env = suite.load(domain_name="cartpole", 
                 task_name="balance",
                 visualize_reward=False)

# 并行步骤
for _ in range(1000):
    action = env.action_spec().sample()
    time_step = env.step(action)
```

---

## 传感器

### 读取传感器数据

```python
# 关节位置
qpos = data.qpos

# 关节速度
qvel = data.qvel

# 力
qfrc = data.qfrc

# 末端位置
end_effector_pos = data.body_xpos[-1]

# 接触力
contact_force = data.eforce

# 触地检测
for i in range(model.ncon):
    contact = data.contact[i]
    # contact 包含接触信息
```

---

## ROS 集成

### ROS2 控制器

```python
import rclpy
from rclpy.node import Node
import mujoco

class MuJoCoROS2(Node):
    def __init__(self):
        super().__init__('mujoco_ros2')
        
        # 加载模型
        self.model = mujoco.MjModel.from_xml_path('/path/to/robot.xml')
        self.data = self.model.data
        
        # 订阅
        self.create_subscription(
            Float64MultiArray,
            '/joint_commands',
            self.cmd_callback,
            10)
        
        # 定时器
        self.timer = self.create_timer(0.002, self.step_callback)
        
    def cmd_callback(self, msg):
        self.data.ctrl[:] = msg.data
        
    def step_callback(self):
        mujoco.mj_step(self.model, self.data)
        
        # 发布状态
        # ...
```

---

## 常见问题

### 问题 1: 模型不稳定

**解决方案**：
- 增加 solver iterations
- 调整 timestep
- 检查质量分布

### 问题 2: 仿真速度慢

**解决方案**：
- 使用 GPU
- 减少约束求解迭代
- 启用快速积分器

### 问题 3: 碰撞检测失败

**解决方案**：
- 检查 geom 类型
- 调整碰撞容差
- 使用正确的摩擦系数

---

## 相关资源

- [MuJoCo 文档](https://mujoco.readthedocs.io/)
- [DM Control](https://github.com/deepmind/dm_control)
- [MuJoCo Python](https://github.com/openai/mujoco-py)

---

## 另见

- [pybullet](../pybullet/) - PyBullet 仿真
- [isaaclab](../isaaclab/) - Isaac Lab