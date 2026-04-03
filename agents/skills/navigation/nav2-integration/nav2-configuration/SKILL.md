---
name: nav2-configuration
description: Navigation2 配置技能 - param 文件、launch 编写、控制器调参、生命周期管理
argument-hint: Navigation2 OR nav2 param OR 配置 OR nav2 configuration
user-invocable: true
---

# Navigation2 配置技能

> Navigation2 完整配置指南

---

## 何时使用

当需要以下帮助时使用此技能：
- Nav2 参数配置
- Controller 调参
- Planner 调参
- Lifecycle 管理
- 完整导航栈搭建

---

## 核心配置

### Controller 配置

```yaml
# config/dwb_controller.yaml
dwb_controller:
  ros__parameters:
    # 发布频率
    controller_frequency: 20.0
    
    #  lookahead 距离
    lookahead_time: 1.0
    lookahead_distance: 0.5
    
    # 速度限制
    max_speed_xy: 0.5
    max_speed_theta: 1.0
    
    # 加速度限制
    max_accel_xy: 2.5
    max_accel_theta: 3.5
    
    # DWA 参数
    min_velocity_xy: 0.0
    min_speed_theta: 0.0
    
    # 评分函数权重
    wx: 1.0
    wt: 1.0
    wc: 1.0
   wv: 0.5
    ws: 0.05
```

### Planner 配置

```yaml
# config/nav2_planner.yaml
planner_server:
  ros__parameters:
    planner_plugin: 'nav2_smac_planner/SmacPlanner2D'
    
    smac_planner:
      tolerance: 0.25
      downsample_costmap: 2
      allow_unknown: true
      max_iterations: 1000000
      max_on_approaches_cost: 0.5
      terminal_binding_padding: 0.65
```

### Lifecycle launch

```python
# launch/nav2.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import TimerAction

def generate_launch_description():
    # 等待时钟
    clock_node = TimerAction(
        period=2.0,
        actions=[
            Node(
                package='nav2_controller',
                executable='controller_server',
                parameters=['config/controller.yaml'],
                output='screen'
            ),
            Node(
                package='nav2_planner',
                executable='planner_server',
                parameters=['config/planner.yaml'],
                output='screen'
            ),
            Node(
                package='nav2_recoveries',
                executable='recoveries_server',
                parameters=['config/recoveries.yaml'],
                output='screen'
            ),
            Node(
                package='nav2_bt_navigator',
                executable='bt_navigator',
                parameters=['config/bt_navigator.yaml'],
                output='screen'
            ),
        ]
    )
    
    return LaunchDescription([clock_node])
```

### AMCL 配置

```yaml
# config/amcl.yaml
amcl:
  ros__parameters:
    use_sim_time: True
    alpha1: 0.2
    alpha2: 0.2
    alpha3: 0.2
    alpha4: 0.2
    alpha5: 0.2
    
    laser_model_type: likelihood_field_prob
    laser_z_max: 0.5
    laser_z_hit: 0.5
    laser_z_rand: 0.5
    
    min_particles: 500
    max_particles: 2000
    recovery_alpha_slow: 0.0
    recovery_alpha_fast: 0.0
```
