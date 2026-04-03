---
name: skill-planning
description: 机械臂技能规划 - 任务规划、抓取规划、行为树、模仿学习
argument-hint: "机械臂任务" / "抓取规划" / "行为树" / "模仿学习"
user-invocable: true
---

# 机械臂技能规划技能

> 用于开发机械臂的高级任务规划和决策系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 抓取姿态规划
- 任务序列规划
- 行为树构建
- 模仿学习应用

---

## 快速参考

### 技能配置

```yaml
manipulator_skill_planning:
  # 规划方法
  planner: behavior_tree / SMACH / task_planner
  
  # 抓取配置
  grasping:
    method: gpd / graspnet / analytical
    num_candidates: 10
    
  # 任务库
  primitive_skills:
    - pick
    - place
    - push
    - align
    - insert
```

---

## 抓取规划

### 6-DOF 抓取

```python
class GraspPlanner:
    def __init__(self):
        self.grasp_sampler = GPDSampler('grasp_config.yaml')
        self.ik_solver = NumericalIK()
        
    def plan_grasp(self, point_cloud, target_object=None):
        """抓取规划"""
        # 1. 采样抓取候选
        grasp_candidates = self.grasp_sampler.sample(point_cloud)
        
        # 2. 评估抓取质量
        ranked = []
        for grasp in grasp_candidates:
            score = self.evaluate_grasp(grasp)
            
            # 3. IK 求解
            joints = self.ik_solver.solve(grasp.pose)
            if joints is not None:
                ranked.append((score, grasp, joints))
                
        # 4. 返回最佳
        ranked.sort(key=lambda x: x[0], reverse=True)
        return ranked[0] if ranked else None
```

---

## 任务规划

### 行为树

```python
class ManipulatorSkillTree(BehaviorTree):
    def __init__(self):
        super().__init__()
        self.build_pick_place_tree()
        
    def build_pick_place_tree(self):
        self.root = Sequence([
            # 感知目标
            Selector([
                DetectObject("target"),
                Retry(3, ["LookForObject"])
            ]),
            
            # 移动到目标
            MoveToTarget(),
            
            # 抓取
            GraspObject(),
            
            # 移动到放置位置
            MoveToPlace(),
            
            # 放置
            ReleaseObject(),
        ])
```

---

## 模仿学习

### 演示学习

```python
class ImitationLearning:
    def __init__(self):
        self.trajectory_buffer = []
        self.policy_network = PolicyNetwork()
        
    def record_demonstration(self, trajectory):
        """记录演示轨迹"""
        self.trajectory_buffer.append(trajectory)
        
    def train(self):
        """行为克隆训练"""
        # 聚合演示
        all_states = []
        all_actions = []
        
        for traj in self.trajectory_buffer:
            states, actions = self.process_trajectory(traj)
            all_states.extend(states)
            all_actions.extend(actions)
            
        # 监督学习
        self.policy_network.fit(all_states, all_actions)
        
    def predict_action(self, state):
        """预测动作"""
        return self.policy_network.predict(state)
```

---

## 相关文档

- `./manipulator/perception/SKILL.md` - 感知系统
- `./manipulator/localization/SKILL.md` - 定位系统
- `./manipulator/motion-control/SKILL.md` - 运动控制
