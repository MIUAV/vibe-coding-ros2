---
name: robotics-learning
description: 机器人学习技能库 - 强化学习、持续学习、迁移学习、联邦学习、增量学习
argument-hint: 强化学习 OR 持续学习 OR 迁移学习 OR 联邦学习 OR 增量学习 OR robotics learning
user-invocable: true
---

# 机器人学习技能库

> 面向机器人学习的五大范式完整技能集合

---

## 何时使用

当需要以下帮助时使用此技能：
- 机器人强化学习训练
- 多任务持续学习
- 跨域迁移学习
- 联邦学习协同训练
- 增量学习不遗忘

---

## 学习范式

| 范式 | 描述 | 适用场景 |
|---|---|---|
| 强化学习 (RL) | 智能体通过与环境交互学习最优策略 | 运动控制、导航、Manipulation |
| 持续学习 (CL) | 学习连续任务而不遗忘之前知识 | 多任务机器人、终身学习 |
| 迁移学习 (TL) | 将一个领域知识迁移到另一个领域 | 仿真到现实、知识复用 |
| 联邦学习 (FL) | 分布式协作学习保护数据隐私 | 多机器人协同、云边协同 |
| 增量学习 (IL) | 增量式学习新类别/任务 | 动态环境适应、新技能获取 |

---

## 子技能

### 强化学习 (reinforcement_learning)
- `rl-policy-gradient` - 策略梯度方法 (PPO、A3C、SAC)
- `rl-value-based` - 值函数方法 (DQN、Double DQN、PER)
- `rl-model-based` - 模型-based RL (World Models、MPC)
- `rl-multi-agent` - 多智能体强化学习
- `rl-hyperparameter-tuning` - 超参数自动调优
- `rl-ros2-integration` - ROS2 集成部署

### 持续学习 (continual_learning)
- `cl-catastrophic-forgetting` - 灾难性遗忘预防
- `cl-elastic-weight-consolidation` - 弹性权重巩固
- `cl-progressive-networks` - 渐进式网络
- `cl-memory-replay` - 记忆回放方法
- `cl-ros2-integration` - ROS2 集成部署

### 迁移学习 (transfer_learning)
- `tl-domain-adaptation` - 域适应技术
- `tl-fine-tuning` - 模型微调策略
- `tl-curriculum-learning` - 课程学习
- `tl-cross-robot-transfer` - 跨机器人知识迁移
- `tl-ros2-integration` - ROS2 集成部署

### 联邦学习 (federated_learning)
- `fl-fedavg` - FedAvg 联邦平均算法
- `fl-differential-privacy` - 差分隐私保护
- `fl-horizontal-federation` - 水平联邦学习
- `fl-vertical-federation` - 垂直联邦学习
- `fl-ros2-integration` - ROS2 集成部署

### 增量学习 (incremental_learning)
- `il-class-incremental` - 类别增量学习
- `il-task-incremental` - 任务增量学习
- `il-representation-learning` - 表示学习保持
- `il-ros2-integration` - ROS2 集成部署
