---
name: skill-planning
description: 四足机器人技能规划 - 任务规划、行为树、强化学习、模仿学习
argument-hint: "四足技能" / "任务规划" / "行为树" / "强化学习"
user-invocable: true
---

# 四足机器人技能规划技能

> 用于开发和配置四足机器人的高级技能规划系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现任务级规划
- 配置行为树
- 强化学习训练
- 模仿学习部署

---

## 快速参考

### 技能层次

```
任务层 (Task)
    ↓
行为层 (Behavior)
    ↓
步态层 (Gait)
    ↓
关节层 (Joint)
```

---

## 行为树

### BT 结构

```xml
<root>
  <Sequence name="patrol">
    <Selector name="mode_select">
      <Sequence name="explore">
        <CheckBattery level="0.3"/>
        <Explore/>
      </Sequence>
      <Sequence name="return">
        <GoHome/>
        <Recharge/>
      </Sequence>
    </Selector>
  </Sequence>
</root>
```

### Python 实现

```python
from py_trees import BehaviorTree, Selector, Sequence, Behaviour

class Explore(Behaviour):
    def __init__(self, name="Explore"):
        super().__init__(name)
        
    def update(self):
        # 执行探索行为
        if self.robot.explore():
            return Status.SUCCESS
        return Status.RUNNING
```

---

## 状态机

### 状态机实现

```python
class RobotStateMachine:
    def __init__(self):
        self.states = {
            'idle': IdleState(),
            'walk': WalkState(),
            'trot': TrotState(),
            'balance': BalanceState(),
            'recover': RecoverState()
        }
        self.current_state = 'idle'
        
    def transition(self, event):
        next_state = self.states[self.current_state].next(event)
        if next_state:
            self.states[self.current_state].exit()
            self.current_state = next_state
            self.states[self.current_state].enter()
```

---

## 强化学习

### 训练框架

```python
# 使用 Unitree RL Gym
from unitree_rl_gym import Go2Env

# 创建环境
env = Go2Env(
    estate=Go2State(),
    use_visual_observation=False,
    use_foot_local_position=False
)

# 训练 PPO
from stable_baselines3 import PPO

model = PPO("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=1000000)

# 保存模型
model.save("go2_policy")
```

### 奖励函数

```python
def compute_reward(state, action):
    # 速度奖励
    vx = state.base_velocity[0]
    v_desired = 0.5
    reward_velocity = -abs(vx - v_desired)
    
    # 平滑奖励
    reward_smooth = -0.01 * sum(action**2)
    
    # 能量效率
    reward_energy = -0.001 * sum(action**2)
    
    # 存活奖励
    reward_survival = 0.1
    
    return reward_velocity + reward_smooth + reward_energy + reward_survival
```

---

## 模仿学习

### 数据采集

```python
from unitree_sdk2_python import Teleoperation

# 遥操作采集
teleop = Teleoperation(robot)

# 记录轨迹
trajectories = []
while collecting:
    state = robot.get_state()
    action = teleop.get_action()
    trajectories.append((state, action))
    
# 保存数据
save_dataset(trajectories, "go2_walk_dataset.pkl")
```

### 策略部署

```python
# 使用 ACT (Action Chunking Transformer)
from act import ACTPolicy

policy = ACTPolicy.load("go2_act_model.pth")

# 推理
observation = env.get_observation()
action = policy.predict(observation)
robot.execute(action)
```

---

## 任务规划

### 任务分解

```python
class TaskPlanner:
    def __init__(self):
        self.skills = {
            'walk': WalkSkill(),
            'climb': ClimbStairsSkill(),
            'avoid': AvoidObstacleSkill(),
            'follow': FollowPersonSkill()
        }
        
    def plan(self, high_level_command):
        """将高层命令分解为技能序列"""
        if "patrol" in high_level_command:
            return [
                ('walk', destination1),
                ('avoid', obstacle1),
                ('walk', destination2)
            ]
        elif "explore" in high_level_command:
            return [
                ('explore', None),
                ('follow', person_if_found)
            ]
```

---

## 多机器人协同

### 编队控制

```python
class FormationController:
    def __init__(self, num_robots):
        self.num = num_robots
        self.formation = self.compute_formation()
        
    def compute_formation(self):
        """计算编队形状"""
        if self.num == 3:
            return [(0, 0), (-1, -1), (-1, 1)]  # 三角
        elif self.num == 4:
            return [(0, 0), (0, -1), (-1, 0), (-1, -1)]  # 方阵
        return [(i * 1.0, 0) for i in range(self.num)]  # 直线
        
    def compute_target_positions(self, leader_pose):
        """计算各机器人目标位置"""
        targets = []
        for offset in self.formation:
            target = offset + leader_pose
            targets.append(target)
        return targets
```

---

## 常用框架

| 框架 | 用途 |
|------|------|
| **py_trees** | 行为树 |
| **SMACH** | 状态机 |
| **stable-baselines3** | 强化学习 |
| **unitree_rl_gym** | Unitree RL |
| **lerobot** | 模仿学习 |

---

## 相关文档

- [py_trees](https://py-trees.readthedocs.io/)
- [stable-baselines3](https://stable-baselines3.readthedocs.io/)
- [Unitree RL Gym](https://github.com/unitreerobotics/unitree_rl_gym)
- [LeRobot](https://github.com/huggingface/lerobot)