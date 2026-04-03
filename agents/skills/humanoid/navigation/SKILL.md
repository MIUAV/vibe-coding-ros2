---
name: navigation
description: 人形机器人导航系统 - 路径规划、双足行走导航、动态避障、地形适应
argument-hint: "人形导航" / "双足路径规划" / "动态避障"
user-invocable: true
---

# 人形机器人导航技能

> 用于开发人形机器人的导航和运动规划系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现双足路径规划
- 动态障碍物避障
- 复杂地形导航
- 全身协调运动

---

## 快速参考

### 导航配置

```yaml
humanoid_navigation:
  # 规划器
  planner:
    type: RRT / A* / D*
    
  # 步态参数
  gait:
    step_height: 0.05  # m
    step_length: 0.25  # m
    step_period: 0.6   # s
    
  # 避障
  obstacle_avoidance:
    method: MPC / DWA
    horizon: 2.0  # m
```

---

## 双足导航

### 路径到步态

```python
class BipedNavigation:
    def __init__(self):
        self.path_planner = AStarPlanner()
        self.footstep_planner = FootstepPlanner()
        self.balance_controller = BalanceController()
        
    def plan_walk(self, goal_pos):
        # 全局路径
        global_path = self.path_planner.plan(self.current_pos, goal_pos)
        
        # 生成步序
        footsteps = self.footstep_planner.generate(global_path)
        
        # 逐步执行
        for step in footsteps:
            self.execute_step(step)
            self.balance_controller.update()
```

---

## 全身协调

### CoM 轨迹规划

```python
class WholeBodyCoordinator:
    def __init__(self):
        self.centroidal_model = CentroidalModel()
        
    def plan_com_trajectory(self, footsteps):
        """质心轨迹规划"""
        # 计算支撑多边形序列
        support_polygons = self.compute_support_polygons(footsteps)
        
        # CoM 轨迹 (preview control)
        com_trajectory = []
        for i, poly in enumerate(support_polygons):
            # 在支撑多边形内生成 CoM 位置
            com = self.centroidal_model.generate_com(poly)
            com_trajectory.append(com)
            
        return com_trajectory
```

---

## 相关文档

- `./humanoid/perception/SKILL.md` - 感知系统
- `./humanoid/localization/SKILL.md` - 定位系统
- `./humanoid/skill-planning/SKILL.md` - 技能规划
