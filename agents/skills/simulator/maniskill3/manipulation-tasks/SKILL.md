---
name: manipulation-tasks
description: ManiSkill3 操作任务技能 - 抓取、放置、装配任务配置
argument-hint: "ManiSkill3任务" / "机器人抓取" / "操作任务"
user-invocable: true
---

# ManiSkill3 Manipulation Tasks Skill

> 用于 ManiSkill3 中的机器人操作任务

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置操作任务环境
- 设置抓取和放置任务
- 设计奖励函数
- 评估任务完成

---

## 快速参考

### 启动任务

```bash
python -m mani_skill3_examples.example_env \
  --task-name="PickCube-v0" \
  --num-envs=16
```

---

## 任务类型

### 抓取任务

```python
from mani_skill3 import task

class PickCube(task.Task):
    def __init__(self):
        super().__init__()
        
        # 目标: 抓取立方体并移动到目标位置
        self.target_position = np.array([0.5, 0.0, 0.0])
        
    def compute_reward(self, info):
        # 奖励: 靠近目标
        dist = np.linalg.norm(info['object_pos'] - self.target_position)
        return -dist
```

### 放置任务

```python
class PlaceObject(task.Task):
    def __init__(self):
        super().__init__()
        self.target_region = np.array([0.5, 0.0, 0.05])
        
    def check_success(self, info):
        # 检查物体是否在目标区域
        in_region = np.linalg.norm(info['object_pos'][:2] - self.target_region[:2]) < 0.05
        return in_region
```

---

## 任务配置

### YAML 配置

```yaml
task:
  name: PickCube
  num_envs: 16
  
robot:
  type: Panda
  control_mode: "joint_position"
  
objects:
  cube:
    type: rigid
    size: [0.04, 0.04, 0.04]
    
reward:
  - type: distance
    weight: 1.0
  - type: success
    weight: 10.0
```

---

## 常见问题

### 问题 1: 抓取失败

**解决方案**：调整抓取姿态，增加探索

---

## 另见

- [environment-setup](../environment-setup/) - 环境配置
- [dataset-playback](../dataset-playback/) - 数据回放