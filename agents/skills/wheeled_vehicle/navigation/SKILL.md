---
name: navigation
description: 轮式车辆导航系统 - 全局路径规划、局部路径规划、轨迹跟踪、动态避障
argument-hint: "车辆导航" / "路径规划" / "轨迹跟踪" / "动态避障"
user-invocable: true
---

# 轮式车辆导航技能

> 用于开发轮式车辆的导航和路径规划系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 全局路径规划
- 局部轨迹规划
- 轨迹跟踪控制
- 动态障碍物避障

---

## 快速参考

### 导航配置

```yaml
wheeled_vehicle_navigation:
  # 全局规划
  global_planner:
    type: A* / Dijkstra / Hybrid_A*
    
  # 局部规划
  local_planner:
    type: DWA / MPC / EM
    
  # 跟踪控制器
  controller:
    type: PurePursuit / Stanley / MPC
    
  # 速度参数
  speed:
    max: 30  # km/h
    cruise: 20
    min: 5
```

---

## 全局规划

### Hybrid A* 路径规划

```python
class HybridAStar:
    def __init__(self):
        self.grid_resolution = 0.5  # m
        self.angle_resolution = 15  # deg
        
    def plan(self, start, goal, vehicle_params):
        """Hybrid A* 路径规划"""
        # 构建状态格
        state_lattice = StateLattice(self.grid_resolution, 
                                      self.angle_resolution)
        
        # 搜索
        path = self.search(state_lattice, start, goal)
        
        # 平滑
        smoothed = self.smooth(path)
        
        return smoothed
```

---

## 轨迹跟踪

### Pure Pursuit 跟踪

```python
class PurePursuitController:
    def __init__(self, lookahead_dist=5.0):
        self.lookahead = lookahead_dist
        self.wheelbase = 2.5  # m
        
    def compute_steering(self, pose, trajectory):
        """计算转向角"""
        # 找到前瞻点
        lookahead_point = self.find_lookahead_point(pose, trajectory)
        
        # 计算角度误差
        dx = lookahead_point.x - pose.x
        dy = lookahead_point.y - pose.y
        alpha = atan2(dy, dx) - pose.theta
        
        # Pure pursuit 公式
        steering = atan2(2 * self.wheelbase * sin(alpha), 
                         self.lookahead)
        
        return steering
```

---

## 动态避障

### MPC 避障

```python
class MPCObstacleAvoidance:
    def __init__(self):
        self.horizon = 20  # 预测步数
        self.dt = 0.1  # s
        
    def compute_control(self, state, obstacles, reference_path):
        """MPC 避障控制"""
        # 构建优化问题
        J = 0
        constraints = []
        
        for t in range(self.horizon):
            # 代价函数
            J += self跟踪代价(state, reference_path, t)
            J += self障碍物代价(state, obstacles, t)
            
            # 车辆模型约束
            constraints.append(self.vehicle_model(state, t))
            
        # 求解
        solution = solve_qp(J, constraints)
        
        return solution.u[0]  # 第一个控制输入
```

---

## 相关文档

- `./wheeled_vehicle/perception/SKILL.md` - 感知系统
- `./wheeled_vehicle/localization/SKILL.md` - 定位系统
- `./wheeled_vehicle/action/SKILL.md` - 运动控制
