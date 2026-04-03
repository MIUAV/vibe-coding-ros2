---
name: rl-hyperparameter-tuning
description: 强化学习超参数自动调优技能 - Optuna、Ray Tune、Population-Based Training
argument-hint: "超参数调优" / "Optuna" / "Ray Tune" / "PBT" / "hyperparameter"
user-invocable: true
---

# 强化学习超参数调优技能

> 自动优化 RL 算法超参数的技能

---

## 何时使用

当需要以下帮助时使用此技能：
- 自动化超参数搜索
- 学习率、折扣因子调优
- Population Based Training
- Optuna/Ray Tune 集成

---

## 核心方法

### Optuna 集成

```python
import optuna
import torch
import numpy as np

def objective(trial):
    # 采样超参数
    lr = trial.suggest_float('lr', 1e-5, 1e-2, log=True)
    gamma = trial.suggest_float('gamma', 0.9, 0.999)
    hidden_dim = trial.suggest_categorical('hidden_dim', [64, 128, 256, 512])
    entropy_coef = trial.suggest_float('entropy_coef', 1e-4, 1e-1, log=True)
    
    # 创建 Agent
    agent = PPOLearner(
        state_dim=STATE_DIM,
        action_dim=ACTION_DIM,
        lr=lr,
        gamma=gamma,
        hidden_dim=hidden_dim,
        entropy_coef=entropy_coef
    )
    
    # 训练
    for episode in range(MAX_EPISODES):
        state = env.reset()
        episode_reward = 0
        
        while not done:
            action = agent.select_action(state)
            next_state, reward, done, _ = env.step(action)
            agent.update(state, action, reward, next_state, done)
            state = next_state
            episode_reward += reward
            
        trial.report(episode_reward, episode)
        
        if trial.should_prune():
            raise optuna.TrialPruned()
            
    return episode_reward

# 运行优化
study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=100, timeout=3600)
```

### Population Based Training

```python
class PBTTrainer:
    def __init__(self, population_size=10):
        self.population_size = population_size
        self.population = []
        
    def evolve(self):
        # 选择最佳的一半
        sorted_pop = sorted(self.population, key=lambda x: x.fitness, reverse=True)
        survivors = sorted_pop[:self.population_size // 2]
        
        new_population = survivors.copy()
        
        for _ in range(self.population_size // 2):
            # 克隆并变异
            parent = np.random.choice(survivors)
            child = self.mutate(parent)
            new_population.append(child)
            
        self.population = new_population
        
    def mutate(self, parent):
        child = {
            'lr': parent['lr'] * np.random.uniform(0.8, 1.2),
            'gamma': parent['gamma'] * np.random.uniform(0.99, 1.01),
            'hidden_dim': parent['hidden_dim'],
            'noise_std': parent['noise_std'] * np.random.uniform(0.9, 1.1)
        }
        return child
```
