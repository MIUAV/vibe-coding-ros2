---
name: maniskill3
description: ManiSkill3 机器人操作技能开发 - 高保真操作任务、GPU 加速学习、丰富数据集
argument-hint: "maniskill3仿真" / "机器人操作" / "操作技能训练" / "抓取任务"
user-invocable: true
---

# ManiSkill3 Robot Manipulation Skill

> 用于 ManiSkill3 机器人操作仿真环境的配置和训练

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 ManiSkill3
- 运行操作任务仿真
- 使用 GPU 加速训练
- 评估操作策略
- 准备操作数据集

---

## 快速参考

### 系统要求

- **操作系统**: Ubuntu 20.04/22.04
- **GPU**: NVIDIA GPU with CUDA 12.0+
- **显存**: 16GB+ (强烈建议)
- **内存**: 32GB+

### 安装 ManiSkill3

```bash
# 1. 创建 conda 环境
conda create -n maniskill3 python=3.10
conda activate maniskill3

# 2. 安装 PyTorch
pip install torch==2.1.0 torchvision==0.16.0 --index-url https://download.pytorch.org/whl/cu121

# 3. 克隆仓库
git clone https://github.com/haosulab/ManiSkill3.git
cd ManiSkill3

# 4. 安装依赖
pip install -e .

# 5. 安装演示环境
pip install -e ".[demo]"
```

### 启动示例环境

```python
# 运行抓取任务
python -m mani_skill3.examples.demo_basic_env \
    --env "PickCube-v1" \
    --robot "panda" \
    --sim-backend "gpu"  # 或 "cpu"
```

### 目录结构

```
ManiSkill3/
├── mani_skill3/            # 核心库
│   ├── envs/              # 环境实现
│   ├── agents/            # 机器人代理
│   ├── solvers/           # 求解器
│   ├── sensors/           # 传感器
│   └── utils/             # 工具函数
├── examples/              # 示例代码
├── tools/                 # 开发工具
├── docs/                  # 文档
└── data/                  # 数据集
```

---

## 环境配置

### 选择机器人

```python
# 支持的机器人
ROBOTS = {
    "panda": "Franka Emika Panda",
    "allegro": "Allegro Hand",
    "shadow_hand": "Shadow Hand",
    "xarm": "xArm 7",
    "dobot": "Dobot MG400",
    "ur5": "Universal Robots UR5",
}

# 配置机器人
from mani_skill3.agents import PandaAgent

agent = PandaAgent(
    control_freq=20,
    obs_frames=2,
    enable_planner=False,
)
```

### 配置相机

```python
# 相机配置
camera_cfg = {
    "width": 512,
    "height": 512,
    "fov": 2.0,  # 弧度
    "near": 0.01,
    "far": 100.0,
    "intrinsics": {
        "fx": 256,
        "fy": 256,
        "cx": 256,
        "cy": 256,
    }
}

# 添加相机
env.add_camera(
    name="hand_camera",
    config=camera_cfg,
    transform=[[1, 0, 0, 0],
               [0, 1, 0, 0],
               [0, 0, 1, 0.1],
               [0, 0, 0, 1]]
)
```

### 物理参数

```python
# 物理配置
physics_cfg = {
    "sim_backend": "gpu",  # gpu 或 cpu
    "dt": 0.002,           # 时间步长
    "gravity": [0, 0, -9.81],
    "num_substeps": 2,
    
    # 接触参数
    "contact_offset": 0.02,
    "rest_offset": 0.001,
    "bounce_threshold_velocity": 0.2,
    
    # GPU 求解器
    "solver_type": 1,  # TGS
    "num_position_iterations": 8,
    "num_velocity_iterations": 0,
}
```

---

## 环境类型

### 物体搬运

```python
# PickCube-v1
env = gym.make("PickCube-v1", robot="panda", render_mode="rgb_array")

# 观察空间
obs = env.reset()
print(f"State: {obs['agent']['state'].shape}")  # (19,)
print(f"Image: {obs['main_camera']['rgb'].shape}")  # (512, 512, 3)

# 执行动作
action = {
    "target_pos": [0.3, 0, 0.1],  # 目标位置
    "target_quat": [1, 0, 0, 0],   # 目标姿态
    "gripper": 0.5,                 # 夹爪开合
}
obs, reward, done, info = env.step(action)
```

### 物体堆叠

```python
# StackCube-v1
env = gym.make("StackCube-v1", num_envs=16)

# 批量观察
obs = env.reset()
for key in obs:
    if isinstance(obs[key], torch.Tensor):
        print(f"{key}: {obs[key].shape}")
```

### 工具使用

```python
# PushCube-v1
env = gym.make("PushCube-v1")

# 使用策略
policy = load_policy("push_policy.pt")
action = policy(obs)
obs, reward, done, info = env.step(action)
```

### 双手操作

```python
# 双手机器人配置
env = gym.make(
    "TwoPandaStackCube-v1",
    num_envs=8,
    sim_backend="gpu"
)
```

---

## 强化学习训练

### 安装 RL 库

```bash
# 安装 SB3
pip install stable-baselines3

# 安装 RL Games
pip install rl-games
```

### PPO 训练示例

```python
import torch
import numpy as np
from mani_skill3.envs import ManiSkillEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CheckpointCallback

# 创建环境包装器
class ManiSkillWrapper(gym.Wrapper):
    def __init__(self, env_id):
        super().__init__(gym.make(env_id))
        
    def reset(self, seed=None):
        obs = self.env.reset(seed=seed)
        return obs
    
    def step(self, action):
        return self.env.step(action)

# 训练
model = PPO(
    "MlpPolicy",
    ManiSkillWrapper("PickCube-v1"),
    learning_rate=3e-4,
    n_steps=2048,
    batch_size=64,
    n_epochs=10,
    gamma=0.99,
    verbose=1,
)

model.learn(total_timesteps=1_000_000)
model.save("policy_pick_cube")
```

### BC (行为克隆) 训练

```python
# 行为克隆
from mani_skill3.utils import collect_demos
from torch.utils.data import DataLoader

# 收集演示数据
demos = collect_demos(
    env_id="PickCube-v1",
    solver="motion_planning",
    num_demos=1000,
)

# 创建数据集
dataset = DemonstrationDataset(demos)

# 训练
loader = DataLoader(dataset, batch_size=32, shuffle=True)
for epoch in range(100):
    for obs, action in loader:
        loss = policy.loss(obs, action)
        loss.backward()
        optimizer.step()
```

---

## 数据集工具

### 演示数据收集

```python
from mani_skill3.utils import collect_demos

# 使用运动规划器收集演示
demos = collect_demos(
    env_id="PickCube-v1",
    solver="motion_planning",
    num_demos=100,
    obs_mode="state",  # state, rgb, depth, point_cloud
    record_trajectory=True,
)

# 保存演示
from mani_skill3.utils.io import save_demo
save_demo(demos, "demos/pick_cube.pkl")
```

### 数据集格式

```python
# 演示数据结构
demo = {
    "episode_id": "xxx",
    "env_id": "PickCube-v1",
    "trajectory": [
        {
            "observation": {
                "agent": {"state": np.array},
                "camera": {"rgb": np.array, "depth": np.array}
            },
            "action": np.array,
            "reward": float,
            "done": bool,
        },
        ...
    ],
    "info": {
        "success": True,
        "total_reward": 1.0,
    }
}
```

### 数据集加载

```python
from mani_skill3.utils.io import load_demo

# 加载演示
demos = load_demo("demos/pick_cube.pkl")

# 遍历演示
for demo in demos:
    for step in demo["trajectory"]:
        obs = step["observation"]
        action = step["action"]
```

---

## 评估工具

### 成功率评估

```python
from mani_skill3.utils import evaluate_policy

# 评估策略
results = evaluate_policy(
    policy=model,
    env_id="PickCube-v1",
    num_episodes=100,
    render=False,
)

print(f"Success Rate: {results['success_rate']:.2%}")
print(f"Mean Reward: {results['mean_reward']:.2f}")
print(f"Mean Episode Length: {results['mean_episode_length']:.1f}")
```

### 详细指标

```python
# 评估指标
eval_metrics = {
    "success_rate": True,
    "partial_success_rate": True,
    "mean_reward": True,
    "std_reward": True,
    "mean_episode_length": True,
    "max_episode_length": True,
}

results = evaluate_policy(
    policy=model,
    env_id="PickCube-v1",
    num_episodes=100,
    metrics=eval_metrics,
    save_video="eval.mp4",
)
```

---

## GPU 加速

### GPU 仿真配置

```python
# 使用 GPU 仿真
env = gym.make(
    "PickCube-v1",
    sim_backend="gpu",
    num_envs=256,  # 并行环境
    device="cuda:0",
)

# GPU 批量执行
actions = torch.randn(256, 9, device="cuda:0")
obs, reward, done, info = env.step(actions)
```

### 批量数据处理

```python
# GPU 图像处理
rgb_images = obs["main_camera"]["rgb"].cuda()  # (B, H, W, 3)
depth_images = obs["main_camera"]["depth"].cuda()

# 批量处理
processed = model.process_images(rgb_images)
```

---

## 常见问题

### 问题 1: 仿真启动失败

**解决方案**：
- 检查 CUDA 版本
- 验证 GPU 驱动
- 确认显存充足

### 问题 2: 训练不稳定

**解决方案**：
- 调整学习率
- 使用更大的批量
- 归一化观察空间

### 问题 3: 策略评估失败

**解决方案**：
- 检查动作空间
- 验证策略输出
- 确认环境重置

---

## 相关资源

- [ManiSkill3 官方文档](https://www.maniskill.ai/ManiSkill3)
- [ManiSkill3 GitHub](https://github.com/haosulab/ManiSkill3)
- [ManiSkill3 数据集](https://maniskill-dataset.github.io/)

---

## 另见

- [IsaacLab](../isaaclab/) - Isaac Lab 仿真
- [Gazebo Harmonic](../gazebo-harmonic/) - 仿真配置
- [RViz2 开发技能](../rviz2/) - 可视化配置