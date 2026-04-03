---
name: omniverse-setup
description: Omniverse 配置技能 - Isaac Sim 安装、USD 场景、ROS2 环境配置
argument-hint: Omniverse OR Isaac Sim OR USD OR 安装配置
user-invocable: true
---

# Omniverse 配置技能

> Isaac Sim / Omniverse 环境配置

---

## 何时使用

当需要以下帮助时使用此技能：
- Isaac Sim 安装
- Omniverse 配置
- USD 场景创建
- 机器人 USD 模型
- 环境变量

---

## 核心配置

### Isaac Sim 安装

```bash
# 下载 Isaac Sim from NVIDIA
# https://developer.nvidia.com/isaac-sim

# 安装依赖
sudo apt install python3-pip libzmqpp-dev

# 设置环境
source /isaac-sim/setup_ros2.sh
```

### USD 场景配置

```python
# Python omniverse 脚本
from omni.isaac.kit import SimulationApp

# 创建仿真应用
simulation_app = SimulationApp({"headless": False})

from omni.isaac.core import World
from omni.isaac.core.objects import DynamicCuboid

# 创建世界
world = World()
world.scene.add_default_ground_plane()

# 添加物体
cube = world.scene.add(
    DynamicCuboid(
        prim_path="/World/random_cube",
        position=np.array([0.0, 0.0, 1.0]),
        scale=np.array([0.2, 0.2, 0.2]),
        color=np.array([1.0, 0.0, 0.0])
    )
)

# 运行仿真
while simulation_app.is_running():
    world.step()
```

### ROS2 环境配置

```bash
# isaac-sim-setup.sh
export ISAAC_SIM_PATH=/isaac-sim
export PATH=$PATH:$ISAAC_SIM_PATH
export PYTHONPATH=$ISAAC_SIM_PATH/python:$PYTHONPATH

# ROS2 桥接
source /opt/ros/galactic/setup.bash
source $ISAAC_SIM_PATH/setup_ros2_bridge.bash
```
