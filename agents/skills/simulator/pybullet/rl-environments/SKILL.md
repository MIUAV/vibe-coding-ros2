---
name: rl-environments
description: PyBullet RL 环境技能 - Gymnasium 环境、奖励函数、并行训练
argument-hint: "PyBullet RL" / "Gymnasium环境" / "强化学习"
user-invocable: true
---

# PyBullet RL Environments Skill

> 用于创建 PyBullet 强化学习环境

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建 Gymnasium 环境
- 设计奖励函数
- 配置并行训练

---

## 快速参考

### 安装

```bash
pip install pybullet gymnasium
```

---

## 环境创建

### 基本环境

```python
import gymnasium as gym
import pybullet as p
import pybullet_data

class MyEnv(gym.Env):
    def __init__(self):
        super().__init__()
        self.client = p.connect(p.DIRECT)
        p.setAdditionalSearchPath(pybullet_data.getDataPath())
        
    def reset(self, seed=None):
        p.resetSimulation()
        p.loadURDF("plane.urdf")
        return obs, info
        
    def step(self, action):
        p.stepSimulation()
        return obs, reward, done, info
```

---

## 奖励函数

### 距离奖励

```python
def compute_reward(self):
    distance = np.linalg.norm(self.agent_pos - self.target_pos)
    return -distance
```

---

## 另见

- [physics-simulation](../physics-simulation/) - 物理仿真
- [robot-control](../robot-control/) - 机器人控制