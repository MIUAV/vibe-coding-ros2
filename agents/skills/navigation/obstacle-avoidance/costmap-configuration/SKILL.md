---
name: costmap-configuration
description: 成本图配置技能 - 层级配置、膨胀半径、障碍物阈值、动态更新
argument-hint: "costmap" / "成本图" / "inflation" / "costmap configuration"
user-invocable: true
---

# 成本图配置技能

> Navigation2 成本图配置与优化

---

## 何时使用

当需要以下帮助时使用此技能：
- 成本图层级配置
- 膨胀参数调整
- 障碍物阈值设置
- 动态成本图更新
- 地图过滤

---

## 核心配置

### 全局成本图

```yaml
# config/global_costmap.yaml
global_costmap:
  ros__parameters:
    global_frame: map
    robot_base_frame: base_link
    update_frequency: 1.0
    publish_frequency: 1.0
    cost_scaling_factor: 1.0
    
    # 障碍层
    obstacles:
      enabled: true
      observation_sources: scan
      scan:
        sensor_frame: base_scan
        topic: /scan
        data_type: LaserScan
        obstacle_range: 5.0
        raytrace_range: 5.5
        
    # 膨胀层
    inflation:
      enabled: true
      cost_scaling_factor: 1.0
      inflation_radius: 0.55
      
    # 静态地图层
    static_map:
      enabled: true
      map_topic: /map
```

### 局部成本图

```yaml
# config/local_costmap.yaml
local_costmap:
  ros__parameters:
    global_frame: odom
    robot_base_frame: base_link
    update_frequency: 5.0
    publish_frequency: 2.0
    
    width: 3.0
    height: 3.0
    resolution: 0.05
    
    plugins:
      - obstacle_layer
      - inflation_layer
      
    obstacle_layer:
      enabled: true
      observation_sources: pointcloud
      pointcloud:
        topic: /lidar_points
        data_type: PointCloud2
        obstacle_range: 2.5
        raytrace_range: 3.0
        
    inflation_layer:
      enabled: true
      cost_scaling_factor: 1.5
      inflation_radius: 0.35
```

### 成本值

```
Costmap 成本值 (0-255):
  0     = NO obstacle
  1-127 = Lethal obstacle (最近障碍物)
  128   = Inscribed radius (内切圆半径)
  129-252 = Possibly circumscribed radius (可能的外接圆)
  253-254 = No information
  255   = Unknown
```
