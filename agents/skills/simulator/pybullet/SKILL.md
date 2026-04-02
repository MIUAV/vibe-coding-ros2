---
name: pybullet
description: PyBullet 物理仿真开发技能 - Python 机器人仿真、强化学习环境、GPU 加速、URDF 导入
argument-hint: "pybullet仿真" / "强化学习环境" / "机器人仿真" / "GPU加速"
user-invocable: true
---

# PyBullet Physics Simulation Skill

> 用于 PyBullet 物理仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 PyBullet
- 创建机器人仿真环境
- 编写强化学习训练环境
- 导入 URDF/SDF 模型
- 使用 GPU 加速仿真

---

## 快速参考

### 安装 PyBullet

```bash
pip install pybullet
pip install pybullet-gym  # 预定义环境

# GPU 版本 (需要 CUDA)
pip install pybullet-gpu
```

---

## 基本使用

### 连接模式

```python
import pybullet as p
import pybullet_data

# GUI 模式 - 可视化
client_id = p.connect(p.GUI)
# 或
client_id = p.connect(p.GUI, options="--width=1920 --height=1080")

# DIRECT 模式 - 无窗口，快速仿真
client_id = p.connect(p.DIRECT)

# SHARED_MEMORY - 多进程共享
client_id = p.connect(p.SHARED_MEMORY)

# 加载数据路径
p.setAdditionalSearchPath(pybullet_data.getDataPath())
```

### 基本仿真循环

```python
import pybullet as p
import time

# 连接
p.connect(p.GUI)

# 设置重力
p.setGravity(0, 0, -9.81)

# 设置时间步
p.setTimeStep(1/240)

# 加载地面
plane_id = p.loadURDF("plane.urdf")

# 加载机器人
robot_id = p.loadURDF("franka_panda/panda.urdf", [0, 0, 0])

# 仿真循环
for _ in range(1000):
    p.stepSimulation()
    time.sleep(1/240)

# 断开连接
p.disconnect()
```

---

## 机器人模型

### 加载 URDF

```python
# 基本加载
robot_id = p.loadURDF(
    "robot.urdf",
    basePosition=[0, 0, 0.5],
    baseOrientation=[0, 0, 0, 1],
    useFixedBase=True
)

# 获取关节信息
num_joints = p.getNumJoints(robot_id)
for i in range(num_joints):
    info = p.getJointInfo(robot_id, i)
    print(f"Joint {i}: {info[1].decode()}")

# 读取状态
joint_states = p.getJointStates(robot_id, [0, 1, 2])
positions = [state[0] for state in joint_states]
velocities = [state[1] for state in joint_states]
```

### 创建简单机器人

```python
# 创建四轮车
def create_mobile_robot():
    # 车身
    body_id = p.createMultiBody(
        baseMass=1.0,
        baseCollisionShape=p.createCollisionShape(p.GEOM_BOX, halfExtents=[0.2, 0.1, 0.05]),
        baseVisualShape=p.createVisualShape(p.GEOM_BOX, halfExtents=[0.2, 0.1, 0.05], rgbaColor=[0.3, 0.3, 0.8, 1]),
        basePosition=[0, 0, 0.1]
    )
    
    # 轮子
    wheel_radius = 0.05
    wheel_positions = [
        [0.15, 0.12, 0.05],
        [0.15, -0.12, 0.05],
        [-0.15, 0.12, 0.05],
        [-0.15, -0.12, 0.05]
    ]
    
    wheel_ids = []
    for pos in wheel_positions:
        wheel_id = p.createMultiBody(
            baseMass=0.1,
            baseCollisionShape=p.createCollisionShape(p.GEOM_CYLINDER, radius=wheel_radius, height=0.02),
            baseVisualShape=p.createVisualShape(p.GEOM_CYLINDER, radius=wheel_radius, length=0.02, rgbaColor=[0.1, 0.1, 0.1, 1]),
            basePosition=pos,
            baseOrientation=[0, 0, 0, 1]
        )
        wheel_ids.append(wheel_id)
    
    return body_id, wheel_ids

# 创建机械臂
def create_robot_arm():
    links = []
    parent = -1
    
    # 基座
    base_id = p.createMultiBody(
        baseMass=0,
        baseCollisionShape=p.createCollisionShape(p.GEOM_BOX, halfExtents=[0.05, 0.05, 0.02]),
        basePosition=[0, 0, 0.02]
    )
    links.append(base_id)
    parent = base_id
    
    # 链接1-3
    link_params = [
        (0.15, 0.03, [0, 0, 0.1]),
        (0.12, 0.025, [0, 0, 0.15]),
        (0.1, 0.02, [0, 0, 0.12])
    ]
    
    for mass, radius, pos in link_params:
        link_id = p.createMultiBody(
            baseMass=mass,
            baseCollisionShape=p.createCollisionShape(p.GEOM_CYLINDER, radius=radius, height=0.1),
            baseVisualShape=p.createVisualShape(p.GEOM_CYLINDER, radius=radius, length=0.1, rgbaColor=[0.4, 0.4, 0.4, 1]),
            basePosition=pos,
            baseInertialFramePosition=[0, 0, 0],
            baseInertialFrameOrientation=[0, 0, 0, 1]
        )
        
        # 创建关节
        p.createConstraint(
            parent, -1, link_id, -1,
            jointType=p.JOINT_REVOLUTE,
            jointAxis=[0, 1, 0],
            parentFramePosition=[0, 0, 0.05],
            childFramePosition=[0, 0, -0.05]
        )
        
        links.append(link_id)
        parent = link_id
    
    return links
```

---

## 控制器

### 位置控制

```python
# 位置控制
def position_control(robot_id, joint_indices, target_positions):
    for i, target in zip(joint_indices, target_positions):
        p.setJointMotorControl2(
            bodyUniqueId=robot_id,
            jointIndex=i,
            controlMode=p.POSITION_CONTROL,
            targetPosition=target,
            force=100
        )

# 使用
position_control(robot_id, [1, 2, 3], [0.5, -0.3, 0.8])
```

### 速度控制

```python
# 速度控制
def velocity_control(robot_id, joint_indices, velocities):
    for i, vel in zip(joint_indices, velocities):
        p.setJointMotorControl2(
            bodyUniqueId=robot_id,
            jointIndex=i,
            controlMode=p.VELOCITY_CONTROL,
            targetVelocity=vel,
            force=50
        )
```

### 力控制

```python
# 力控制
def torque_control(robot_id, joint_indices, torques):
    for i, torque in zip(joint_indices, torques):
        p.setJointMotorControl2(
            bodyUniqueId=robot_id,
            jointIndex=i,
            controlMode=p.TORQUE_CONTROL,
            force=torque
        )

# 启用零重力模式 (用于位置控制)
p.setJointMotorControl2(
    bodyUniqueId=robot_id,
    jointIndex=1,
    controlMode=p.POSITION_CONTROL,
    targetPosition=0,
    force=0,
    positionGain=0,
    velocityGain=0,
    maxVelocity=10
)
```

### PID 控制

```python
class PIDController:
    def __init__(self, kp=1.0, ki=0.1, kd=0.5):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.integral = 0
        self.prev_error = 0
        
    def compute(self, target, current, dt):
        error = target - current
        self.integral += error * dt
        derivative = (error - self.prev_error) / dt
        
        output = self.kp * error + self.ki * self.integral + self.kd * derivative
        self.prev_error = error
        
        return output
```

---

## 传感器

### 获取传感器数据

```python
# 关节状态
states = p.getJointStates(robot_id, range(num_joints))
positions = [s[0] for s in states]
velocities = [s[1] for s in states]

# 基础状态
base_pos, base_orn = p.getBasePositionAndOrientation(robot_id)
base_vel, base_ang = p.getBaseVelocity(robot_id)

# 相机图像
import cv2
import numpy as np

# 渲染图像
width = 640
height = 480
img = p.getCameraImage(width, height, renderer=p.ER_BULLET_HARDWARE_OPENGL)
rgb_image = np.array(img[2], dtype=np.uint8).reshape(height, width, 4)
rgb_image = rgb_image[:, :, :3]
rgb_image = cv2.cvtColor(rgb_image, cv2.COLOR_RGB2BGR)
```

### 深度传感器

```python
# 深度图像
img = p.getCameraImage(
    width, height,
    viewMatrix=view_mat,
    projectionMatrix=proj_mat,
    renderer=p.ER_BULLET_HARDWARE_OPENGL
)
depth_buffer = np.array(img[3])
depth_image = far_near / (1 - depth_buffer * (1 - far_near))
```

### 激光雷达模拟

```python
# 手动实现激光雷达
def get_lidar_data(robot_id, num_rays=360, max_range=10):
    results = []
    base_pos, base_orn = p.getBasePositionAndOrientation(robot_id)
    euler = p.getEulerFromQuaternion(base_orn)
    yaw = euler[2]
    
    for i in range(num_rays):
        angle = yaw + (2 * np.pi * i / num_rays)
        direction = [np.cos(angle), np.sin(angle), 0]
        
        ray_from = base_pos
        ray_to = [
            base_pos[0] + direction[0] * max_range,
            base_pos[1] + direction[1] * max_range,
            base_pos[2] + direction[2] * max_range
        ]
        
        ray_result = p.rayTestBatch([ray_from], [ray_to])
        if ray_result[0][0] != -1:
            results.append(ray_result[0][2])
        else:
            results.append(max_range)
    
    return results
```

---

## 强化学习环境

### 创建 Gym 环境

```python
import gym
from gym import spaces
import numpy as np

class RobotEnv(gym.Env):
    def __init__(self):
        super().__init__()
        
        # 连接 PyBullet
        self.client = p.connect(p.DIRECT)
        
        # 动作空间
        self.action_space = spaces.Box(
            low=-1, high=1, shape=(4,), dtype=np.float32
        )
        
        # 观察空间
        self.observation_space = spaces.Box(
            low=-np.inf, high=np.inf, shape=(12,), dtype=np.float32
        )
        
    def reset(self):
        p.resetSimulation()
        p.setGravity(0, 0, -9.81)
        
        # 加载环境
        plane = p.loadURDF("plane.urdf")
        self.robot = p.loadURDF("robot.urdf", [0, 0, 0.5])
        
        return self._get_obs()
    
    def step(self, action):
        # 应用动作
        for i, joint in enumerate(range(1, 5)):
            p.setJointMotorControl2(
                self.robot, joint,
                p.POSITION_CONTROL,
                targetPosition=action[i],
                force=50
            )
        
        p.stepSimulation()
        
        obs = self._get_obs()
        reward = self._compute_reward()
        done = self._is_done()
        
        return obs, reward, done, {}
    
    def _get_obs(self):
        states = p.getJointStates(self.robot, range(1, 5))
        return np.array([s[0] for s in states] + [s[1] for s in states])
    
    def _compute_reward(self):
        # 自定义奖励
        return 0
    
    def _is_done(self):
        return False
    
    def close(self):
        p.disconnect()
```

### 使用 Stable-Baselines3

```python
from stable_baselines3 import PPO
from stable_baselines3.common.env_checker import check_env

# 检查环境
check_env(RobotEnv())

# 创建环境
env = RobotEnv()

# 创建模型
model = PPO("MlpPolicy", env, verbose=1)

# 训练
model.learn(total_timesteps=100000)

# 保存
model.save("ppo_robot")
```

---

## GPU 加速

### GPU 渲染

```python
# 使用 GPU 渲染
p.connect(p.GUI, options="--background_color_red=0.8 --background_color_green=0.8 --background_color_blue=0.8")

# 或在 DIRECT 模式下使用 GPU
p.connect(p.DIRECT, options="--gpu")
```

### 并行环境

```python
# 启用多线程
import multiprocessing as mp

def run_env(env_id):
    import pybullet as p
    p.connect(p.DIRECT)
    # 仿真...
    return result

with mp.Pool(4) as pool:
    results = pool.map(run_env, range(4))
```

---

## 碰撞检测

```python
# 检测碰撞
contact_points = p.getContactPoints(bodyA=robot_id, bodyB=plane_id)

if contact_points:
    for contact in contact_points:
        normal_force = contact[9]
        print(f"Normal force: {normal_force}")

# 设置碰撞过滤
p.setCollisionFilterGroupMask(
    bodyUniqueId=robot_id,
    linkIndex=-1,
    collisionFilterGroup=1,
    collisionFilterMask=1
)
```

---

## 常见问题

### 问题 1: 仿真不稳定

**解决方案**：
- 减小时间步长 (1/480 或 1/960)
- 增加迭代次数
- 调整约束公差

### 问题 2: 机器人穿模

**解决方案**：
- 启用连续碰撞检测 (CCD)
- 增加碰撞层精度
- 使用更厚的碰撞体

### 问题 3: GPU 内存不足

**解决方案**：
- 减少并行环境数
- 降低渲染分辨率
- 使用 DIRECT 模式

---

## 相关资源

- [PyBullet 文档](https://docs.google.com/document/d/10sXEhzHwRSRnQ0_2j7e0aJ6R5z5qz2/edit)
- [PyBullet Gym](https://github.com/benelot/pybullet-gym)
- [Bullet Physics](https://github.com/bulletphysics/bullet3)

---

## 另见

- [mujoco](../mujoco/) - MuJoCo 仿真
- [gazebo-harmonic](../gazebo-harmonic/) - Gazebo 仿真