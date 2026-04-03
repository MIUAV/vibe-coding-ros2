---
name: navigation
description: 四足机器人导航 - 路径规划、动态避障、导航2配置、地形适应导航
argument-hint: "四足导航" / "路径规划" / "避障" / "导航"
user-invocable: true
---

# 四足机器人导航技能

> 用于配置和开发四足机器人的导航系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 Navigation2
- 实现路径规划
- 设置动态避障
- 复杂地形导航

---

## 快速参考

### Navigation2 配置

```yaml
nav2_params:
  planner_server:
    plugin: smac_planner/SmacPlanner
    tolerance: 0.1
    
  controller_server:
    plugin: dwb_controller/DWBLocalPlanner
    max_vel_x: 0.5
    max_vel_theta: 1.0
```

---

## 全局路径规划

### 规划器

| 规划器 | 特点 |
|--------|------|
| **NavFn** | 简单快速 |
| **SmacPlanner** | 支持复杂约束 |
| **RRT*** | 概率完备 |
| **A*** | 最优路径 |

### 配置

```bash
ros2 launch nav2_planner planner.launch.py
```

---

## 局部路径规划

### DWB

```yaml
dwb_controller:
  plugin: dwb_controller/DWBLocalPlanner
  
  # 速度限制
  max_vel_x: 0.5
  max_vel_theta: 1.0
  
  # 加速度限制
  acc_lim_x: 0.5
  acc_lim_theta: 1.0
```

### TEB

```yaml
teb_local_planner:
  plugin: teb_local_planner/TebLocalPlannerROS
  
  # 足式特殊参数
  footprint_margin: 0.3
  max_vel_x: 0.5
  max_vel_x_backwards: 0.2
```

---

## 避障

### 静态避障

```yaml
obstacle_layer:
  enabled: true
  voxel_plugin: voxel_layer/VoxelLayer
  
  obstacle_range: 3.0
  raytrace_range: 3.5
```

### 动态避障

```python
class DynamicObstacleAvoidance:
    def process(self, obstacles, robot_pose):
        # 检测动态障碍物速度
        velocities = self.estimate_velocities(obstacles)
        
        # 预测障碍物轨迹
        trajectories = self.predict_trajectories(
            obstacles, velocities)
        
        # 规划避障路径
        return self.plan_avoidance_path(
            robot_pose, trajectories)
```

---

## 地形适应导航

### 地形感知导航

```python
class TerrainAdaptiveNavigation:
    def __init__(self):
        self.terrain_classifier = TerrainClassifier()
        self.step_planner = StepPlanner()
        
    def navigate(self, goal, terrain_data):
        # 分类地形
        terrain_type = self.terrain_classifier.classify(terrain_data)
        
        # 调整导航参数
        params = self.adapt_params(terrain_type)
        
        # 特殊路径规划
        if terrain_type == 'stairs':
            return self.plan_stair_path(goal, params)
        elif terrain_type == 'rough':
            return self.plan_rough_terrain_path(goal, params)
        else:
            return self.plan_standard_path(goal, params)
```

### 楼梯导航

```yaml
stairs_navigation:
  max_step_height: 0.15
  max_step_length: 0.25
  
  body_height:
    up: 0.35
    down: 0.15
    
  velocity:
    step_duration: 0.6
```

---

## 导航启动

### 启动文件

```bash
# 完整导航启动
ros2 launch quadruped_navigation navigation.launch.py

# 分别启动
ros2 launch nav2_bringup navigation_launch.py
ros2 launch slam_toolbox online_async_launch.py
```

### 参数文件

```yaml
# quadruped_nav.yaml
amcl:
  ros__parameters:
    alpha1: 0.1
    alpha2: 0.1
    alpha3: 0.2
    alpha4: 0.2
    alpha5: 0.1
    
controller_server:
  ros__parameters:
    FollowPath:
      plugin: dwb_controller/DWBLocalPlanner
```

---

## 常用功能包

| 包 | 功能 |
|----|------|
| `nav2_bringup` | 导航启动 |
| `nav2_planner` | 全局规划 |
| `dwb_controller` | 局部规划 |
| `teb_local_planner` | TEB 规划 |
| `swarmac_controller` | 多机协调 |

---

## 相关文档

- [Navigation2文档](https://navigation.ros.org/)
- [DWB控制器](https://github.com/locusrobotics/dwb_controller)
- [TEB规划器](http://wiki.ros.org/teb_local_planner)