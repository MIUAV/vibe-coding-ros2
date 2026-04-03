---
name: rl-training
description: Isaac Lab 强化学习训练技能 - RL 策略训练、奖励函数设计、环境配置
argument-hint: Isaac Lab RL OR 强化学习训练 OR 策略训练
user-invocable: true
---

# Isaac Lab RL Training Skill

> 用于 Isaac Lab 中的强化学习训练

---

## 何时使用

当需要以下帮助时使用此技能：
- 训练机器人 RL 策略
- 设计奖励函数
- 配置训练环境
- 评估训练结果

---

## 快速参考

### 安装 Isaac Lab

```bash
# 克隆仓库
git clone https://github.com/isaac-sim/IsaacLab.git
cd IsaacLab

# 创建符号链接到 Omniverse
./setup.sh

# 安装依赖
pip install -r requirements.txt
```

### 启动训练

```bash
# 运行示例
python scripts/reinforcement_learning/rl_games/train.py --task=Cartpole
```

---

## RL 环境配置

### 创建任务

```python
# tasks/my_task.py
from isaaclab.envs import ManagerBasedRLEnv

class MyTask(ManagerBasedRLEnv):
    def __init__(self, cfg, sim_params, physics_engine, device, headless):
        super().__init__(cfg, sim_params, physics_engine, device, headless)
        
    def _reset_idx(self, env_ids):
        # 重置环境
        pass
        
    def _compute_obs(self):
        # 计算观察
        pass
        
    def _compute_reward(self):
        # 计算奖励
        pass
```

### 奖励函数

```python
# 跟踪目标奖励
def tracking_reward():
    return -torch.norm(robot_pos - target_pos)

# 关节限流奖励
def joint_limit_penalty():
    return -torch.sum(torch.clamp(joint_pos - joint_limits, min=0))
    
# 能量惩罚
def energy_penalty():
    return -torch.sum(torch.abs(joint_vel * joint_effort))
```

---

## 训练配置

### 配置文件

```yaml
# 训练配置
agent:
  name: rsl_rl
  policy:
    actor_hidden_dims: [256, 256, 256]
    critic_hidden_dims: [256, 256, 256]
    
  algorithm:
    name: PPO
    num_steps_per_env: 24
    learning_rate: 0.0003
    num_learning_epochs: 5
    num_mini_batches: 4
    clip_param: 0.2
    gamma: 0.99
    lam: 0.95
    
  runner:
    policy_class: ActorCritic
    algorithm_class: RSL_RL
    num_steps_per_env: 24
    max_iterations: 1500
    save_interval: 50
```

### 启动训练

```bash
python scripts/reinforcement_learning/rl_games/train.py \
  --task=MyRobotTask \
  --headless \
  --num_envs=2048
```

---

## 评估

### 测试策略

```bash
python scripts/reinforcement_learning/rl_games/play.py \
  --task=MyRobotTask \
  --num_envs=10 \
  --checkpoint=outputs/model.pt
```

---

## 常见问题

### 问题 1: 训练不稳定

**解决方案**：调整学习率，降低批大小

---

## 另见

- [robot-sim](../robot-sim/) - 机器人仿真
- [sensor-sim](../sensor-sim/) - 传感器仿真