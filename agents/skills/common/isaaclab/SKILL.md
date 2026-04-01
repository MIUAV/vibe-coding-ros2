---
name: isaaclab
description: NVIDIA Isaac Lab 仿真开发技能 - 强化学习训练、GPU 加速仿真、机器人控制
argument-hint: "isaaclab仿真" / "强化学习训练" / "GPU仿真" / "机器人学习"
user-invocable: true
---

# NVIDIA Isaac Lab Simulation Skill

> 用于 Isaac Lab 仿真环境的配置和机器人训练

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 Isaac Lab
- 创建强化学习训练环境
- 使用 GPU 加速仿真
- 编写自定义环境
- 集成 Isaac Sim 传感器

---

## 快速参考

### 系统要求

- **操作系统**: Ubuntu 20.04/22.04
- **GPU**: NVIDIA GPU with CUDA 12.1+
- **显存**: 8GB+ (建议 16GB+)
- **内存**: 16GB+

### 安装 Isaac Lab

```bash
# 1. 安装 Isaac Sim (需要先安装 Omniverse)
# 下载 NVIDIA Isaac Sim 并解压

# 2. 克隆 Isaac Lab
cd ~/isaac-lab
git clone https://github.com/isaac-sim/IsaacLab.git
cd IsaacLab

# 3. 创建软链接到 Isaac Sim
ln -s /path/to/isaac-sim IsaacLab

# 4. 安装依赖
./scripts/setup.sh

# 5. 安装 Isaac Lab
pip install -e .
```

### 启动 Isaac Lab

```bash
# 激活 conda 环境
conda activate isaaclab

# 运行示例环境
python scripts/run.py --task IsaacReachGoal-v0

# 启动 GPU 加速环境
python scripts/run.py --task IsaacReachGoal-v0 --gpu
```

### 目录结构

```
IsaacLab/
├── isaaclab/                    # 核心框架
│   ├── assets/                 # 机器人资产
│   ├── envs/                   # 环境实现
│   ├── sensors/               # 传感器
│   ├── utils/                 # 工具函数
│   └── sim/                   # 仿真器接口
├── scripts/                    # 运行脚本
├── tools/                      # 开发工具
├── docs/                       # 文档
└── configs/                    # 默认配置
```

---

## 创建自定义环境

### 环境配置

```python
# configs/my_env.py
from dataclass import dataclass
from isaaclab.envs import ManagerBasedRLEnvCfg

@dataclass
class MyEnvCfg:
    # 奖励配置
    reward_scales = {
        "distance": -1.0,
        "velocity": -0.1,
        "action": -0.01,
    }
    
    # 奖励阈值
    reward_thresholds = {
        "success": 1.0,
    }
    
    # 终止条件
    termination = {
        "time_out": 1000,
        "position_limit": 10.0,
    }
    
    # 动作空间
    action_scale = 0.5
    
    # 观察空间
    num_obs = 20
    num_actions = 8
```

### 环境实现

```python
# isaaclab_envs/my_env/my_env.py
import torch
from isaaclab.envs import ManagerBasedRLEnv

class MyRobotEnv(ManagerBasedRLEnv):
    def __init__(self, cfg, sim_params, physics_engine, device, headless):
        super().__init__(cfg, sim_params, physics_engine, device, headless)
        
    def _reset_idx(self, env_ids: torch.Tensor):
        """重置指定环境"""
        # 重置位置
        self._robot.write_data_to_sim(env_ids)
        
        # 重置缓冲区
        self.reset_buf[env_ids] = 0
        self.extras[env_ids] = {}
        
    def _compute_reward(self, actions: torch.Tensor) -> torch.Tensor:
        """计算奖励"""
        # 距离奖励
        dist = torch.norm(self._robot.data.root_pos_w - self._goal, dim=-1)
        dist_reward = -dist * self.cfg.reward_scales["distance"]
        
        # 速度奖励
        vel_reward = -torch.sum(
            self._robot.data.root_lin_vel_w ** 2 + 
            self._robot.data.root_ang_vel_w ** 2, 
            dim=-1
        ) * self.cfg.reward_scales["velocity"]
        
        # 动作惩罚
        action_penalty = -torch.sum(actions ** 2, dim=-1) * self.cfg.reward_scales["action"]
        
        return dist_reward + vel_reward + action_penalty
    
    def _check_termination(self) -> torch.Tensor:
        """检查终止条件"""
        # 检查超时
        time_out = self.episode_length_buf >= self.max_episode_length_s / self.dt
        
        # 检查位置限制
        out_of_bounds = torch.any(
            torch.abs(self._robot.data.root_pos_w) > self.cfg.termination["position_limit"], 
            dim=-1
        )
        
        return time_out | out_of_bounds
```

### 注册环境

```python
# isaaclab/envs/__init__.py
from isaaclab.envs import (
    ManagerBasedRLEnv,
    differential_drive_flat,
)
from isaaclab.utils import register_class

register_class("MY_ENV", "my_env", "MyEnvCfg", my_env_cfg)
register_class("MY_ENV", "MyRobotEnv", "my_env", MyRobotEnv)
```

---

## 强化学习训练

### 训练配置

```python
# configs/train.py
from isaaclab.envs import manager_based_rl_cfg

# RL 训练器配置
TRAIN_CFG = {
    "algorithm": "PPO",
    "num_steps_per_env": 24,
    "learning_rate": 1e-3,
    "num_learning_epochs": 5,
    "num_mini_batches": 10,
    "clip_param": 0.2,
    "gamma": 0.99,
    "lam": 0.95,
    "value_loss_coef": 1.0,
    "entropy_coef": 0.01,
    "num_transitions_per_env": 128,
    "learning_rate_schedule": "adaptive",
    "schedule_decay": 0.5,
}

# 环境配置
ENV_CFG = manager_based_rl_cfg.ManagerBasedRLEnvCfg(
    env_spacing=2.5,
    episode_length_s=10,
)
```

### 训练脚本

```python
# scripts/train.py
import torch
from isaaclab.algos import PPO
from isaaclab.envs import make_env

def train():
    # 创建环境
    env = make_env("IsaacReachGoal-v0", num_envs=256)
    
    # 创建 PPO 智能体
    ppo = PPO(
        actor_lr=1e-3,
        critic_lr=1e-3,
        num_steps_per_env=24,
        num_learning_epochs=5,
        num_mini_batches=32,
        clip_param=0.2,
        gamma=0.99,
        lam=0.95,
        value_loss_coef=1.0,
        entropy_coef=0.01,
    )
    
    # 训练循环
    for i in range(1000):
        # 收集经验
        ppo.collect_rollout(env)
        
        # 更新策略
        ppo.update()
        
        # 日志记录
        if i % 10 == 0:
            print(f"Step {i}, Reward: {env.reward_buf.mean():.4f}")
    
    # 保存模型
    ppo.save("policy.pt")

if __name__ == "__main__":
    train()
```

---

## 传感器配置

### RGB 摄像头

```python
from isaaclab.sensors import Camera

# 创建摄像头
camera = Camera(
    name="front_camera",
    width=640,
    height=480,
    horizontal_fov=90.0,
    update_period=0.1,
)
robot.add_sensor("front_camera", camera)

# 获取图像
def _compute_obs(self):
    camera_data = self._cameras.data.image["front_camera"]
    return camera_data
```

### 深度摄像头

```python
# 深度摄像头配置
camera = Camera(
    name="depth_camera",
    width=640,
    height=480,
    colorize=False,
    semantic_type=None,
)

# 启用深度
camera.set_mode("depth")
```

### 激光雷达

```python
from isaaclab.sensors import RayCaster

# 激光雷达
ray_caster = RayCaster(
    name="lidar",
    sensor_type="lidar",
    max_distance=30.0,
    num_rays=1024,
)
robot.add_sensor("lidar", ray_caster)
```

---

## 机器人配置

### 加载 URDF

```python
from isaaclab.assets import Robot

# 加载机器人
robot = Robot(
    name="manipulator",
    file_path="assets/urdf/robot.urdf",
    fix_base=True,
    collision_group="default",
)

# 设置初始位置
robot.write_data_to_sim()
```

### 加载 MJCF

```python
from isaaclab.assets import FlexBody

# 加载 MJCF
robot = FlexBody(
    name="humanoid",
    file_path="assets/mjcf/humanoid.xml",
    mass=10.0,
    friction=1.0,
)
```

---

## GPU 加速仿真

### 启用 PhysX GPU

```python
# sim_params 配置
physx_params = {
    "worker_thread_count": 4,
    "solver_type": 1,  # TGS
    "use_gpu": True,
    "num_position_iterations": 4,
    "num_velocity_iterations": 0,
    "contact_offset": 0.02,
    "rest_offset": 0.001,
    "bounce_threshold_velocity": 0.2,
    "friction_offset_threshold": 0.04,
    "friction_correlation_distance": 0.025,
    "enable_sleeping": True,
    "enable_stabilization": True,
}

sim_params = {
    "device": "cuda:0",
    "enable_cuda_raycast": True,
    "physx": physx_params,
}
```

### 多 GPU 训练

```python
# 分布式训练配置
torch.distributed.init_process_group(
    backend="nccl",
    init_method="env://",
    world_size=8,
    rank=local_rank,
)

# 多个环境
env = make_env(
    "IsaacReachGoal-v0",
    num_envs=2048,
    num_leaves_per_env=2,
)
```

---

## 常见问题

### 问题 1: Isaac Sim 启动失败

**解决方案**：
- 检查 CUDA 版本 (需要 12.1+)
- 验证 GPU 驱动版本
- 确认显存充足

### 问题 2: 训练速度慢

**解决方案**：
- 增加并行环境数
- 启用 GPU 加速
- 优化观察空间

### 问题 3: 传感器数据为空

**解决方案**：
- 检查渲染设置
- 验证传感器初始化
- 确认 Update Rate

---

## 相关资源

- [Isaac Lab 官方文档](https://docs.isaacsim.omniverse.nvidia.com/5.0.0/installation/download.html)
- [Isaac Sim 文档](https://docs.isaacsim.omniverse.nvidia.com/)
- [NVIDIA Isaac](https://developer.nvidia.com/isaac)

---

## 另见

- [Gazebo Harmonic](../gazebo-harmonic/) - 仿真配置
- [RViz2 开发技能](../rviz2/) - 可视化配置
- [ManiSkill3](./maniskill3/) - 机器人操作技能