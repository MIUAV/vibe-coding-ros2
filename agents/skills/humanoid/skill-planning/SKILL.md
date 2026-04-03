---
name: skill-planning
description: 人形机器人技能规划 - 行为树、状态机、强化学习、双手协调
argument-hint: 人形技能 OR 行为树 OR 双手协调 OR 强化学习
user-invocable: true
---

# 人形机器人技能规划技能

> 用于开发人形机器人的高级技能规划和决策系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现复杂任务规划
- 开发双手协调动作
- 构建行为状态机
- 强化学习训练

---

## 快速参考

### 技能配置

```yaml
humanoid_skill_planning:
  # 规划方法
  method: behavior_tree / state_machine / RL
  
  # 任务库
  skills:
    - walk
    - stand_up
    - pick_place
    - open_door
    - climb_stairs
    
  # 双手协调
  bi_manual:
    handedness: right / left / either
    coordination_mode: symmetric / asymmetric
```

---

## 行为树

### 双手抓取行为

```python
class HumanoidSkillTree(BehaviorTree):
    def __init__(self):
        super().__init__()
        self.build_tree()
        
    def build_tree(self):
        self.root = Sequence([
            # 感知目标物体
            CheckObjectVisible(),
            
            # 伸手
            Sequence([
                MoveArm("left", pre_grasp_pos),
                MoveArm("right", grasp_pos),
            ], parallel=True),
            
            # 抓取
            CloseGripper("both"),
            
            # 举起
            LiftObject(),
        ])
```

---

## 双手协调

### 双臂协调控制

```python
class BiManualCoordinator:
    def __init__(self):
        self.left_arm = ArmController("left")
        self.right_arm = ArmController("right")
        
    def pick_and_place(self, target_pos, place_pos):
        """双手搬运"""
        # 预抓取
        self.left_arm.move_to(PRE_GRASP_LEFT)
        self.right_arm.move_to(PRE_GRASP_RIGHT)
        
        # 同步抓取
        self.sync_move([target_pos.left, target_pos.right])
        
        # 抓取
        self.close_grippers()
        
        # 搬运
        self.sync_move([place_pos.left, place_pos.right])
        
        # 放置
        self.open_grippers()
```

---

## 相关文档

- `./humanoid/perception/SKILL.md` - 感知系统
- `./humanoid/localization/SKILL.md` - 定位系统
- `./humanoid/navigation/SKILL.md` - 导航系统
