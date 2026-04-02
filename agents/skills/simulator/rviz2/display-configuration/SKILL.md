---
name: display-configuration
description: RViz2 显示配置技能 - 机器人模型、传感器显示、地图可视化配置
argument-hint: "rviz显示配置" / "添加显示" / "配置面板"
user-invocable: true
---

# RViz2 Display Configuration Skill

> 用于 RViz2 显示面板和显示类型的配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置机器人模型显示
- 设置传感器数据显示
- 调整显示参数和颜色
- 保存和加载配置文件

---

## 快速参考

### 启动 RViz2

```bash
# 启动 RViz2
rviz2

# 加载配置文件
rviz2 -d /path/to/config.rviz
```

---

## 显示类型

### RobotModel 显示

```yaml
# RobotModel 配置
RobotModel:
  Description Topic: /robot_description
  TF Prefix: ''
  Visual Enabled: True
  Collision Enabled: False
  Alpha: 1.0
  Update Interval: 0
```

### TF 显示

```yaml
# TF 配置
TF:
  Frame Timeout: 10
  All Enabled: True
  Frames:
    Enabled: True
    Tree:
      base_link:
        base_footprint:
          map:
            odom:
  Markers:
    All Enabled: True
    Axes Scale: 1
    Axis Length: 1
```

### LaserScan 显示

```yaml
# LaserScan 配置
LaserScan:
  Topic:
    Name: /scan
    Datatype: sensor_msgs/LaserScan
  Size (m): 0.1
  Color: 255; 255; 255; 255
  Alpha: 1
  Decay Time: 3
  Position Transformer: XYZ
  Intensity Transformer: ''
  Min Color: 0; 0; 0; 255
  Max Color: 255; 255; 255; 255
  Min Intensity: 0
  Max Intensity: 4.5
```

### PointCloud2 显示

```yaml
# PointCloud2 配置
PointCloud2:
  Topic:
    Name: /points
    Datatype: sensor_msgs/PointCloud2
  Color (r,g,b,a): 255; 255; 255; 255
  Decay Time: 1
  Decay Time (s): 1
  Position Transformer: XYZ
  Color Transformer: Intensity
  Selectable: False
  Billboard Size: 0.1
```

---

## 显示面板

### Displays 面板

```
[Displays]
  [+ add]
    - RobotModel
    - LaserScan
    - PointCloud2
    - Image
    - Map
    - Pose
    - Path
    - Odometry
    - Marker
    - MarkerArray
```

### Global Options

```yaml
Fixed Frame: map
Frame Rate: 30
Background Color: 48; 48; 48
Grid:
  Reference Frame: <Fixed Frame>
  Plane Cell Count: 100
  Cell Size: 1
```

### Time 面板

```
[Time]
  - Elapsed: 00:00:00.000
  - Wall Clock: 0.000
  - Use Simulation Time: False
```

---

## 机器人模型显示

### 配置机器人描述

```bash
# 发布 robot_description
ros2 run robot_state_publisher robot_state_publisher

# 或使用参数
ros2 param set /robot_state_publisher robot_description "$(xacro robot.urdf.xacro)"
```

### 设置显示选项

```
RobotModel:
  Description Topic: /robot_description
  Description Source: Topic
  
  Visual Enabled: ✓
    Mesh Alpha: 1.0
    Visual Ops:
      - Offset: 0,0,0
        Color: 255;255;255;255
  
  Collision Enabled: ✓
    Mesh Alpha: 1.0
```

---

## 传感器数据显示

### 图像显示

```yaml
Image:
  Topic:
    Name: /camera/image_raw
    Datatype: sensor_msgs/Image
  Transport Hint: raw
  Max Value: 1
  Min Value: 0
  Median Window Size: 5
```

### 深度图像显示

```yaml
Depth Image:
  Topic:
    Name: /camera/depth/image_raw
    Datatype: sensor_msgs/Image
  Color Scheme: Turbo
  Max Value: 10
  Min Value: 0
```

---

## 地图显示

### 2D 地图显示

```yaml
Map:
  Topic:
    Name: /map
    Datatype: nav_msgs/OccupancyGrid
  
  Color Scheme: map
  Draw Behind: False
  Alpha: 0.7
  Resolution: 0.05
  Map Width: 100
  Map Height: 100
```

### 3D 点云地图显示

```yaml
PointCloudMap:
  Topic:
    Name: /points_map
    Datatype: sensor_msgs/PointCloud2
  
  Color Transformer: AxisY
  Decay Time: 10
```

---

## 导航显示

### Odometry 显示

```yaml
Odometry:
  Topic:
    Name: /odom
    Datatype: nav_msgs/Oddometry
  
  Shape: Arrow
  Color: 255; 255; 0; 255
  Alpha: 1.0
  Scale:
    Length: 1.0
    Head Width: 0.2
    Head Length: 0.2
  Position Tolerance: 0.1
  Angle Tolerance: 0.1
  Keep: 100
```

### Path 显示

```yaml
Path:
  Topic:
    Name: /plan
    Datatype: nav_msgs/Path
  
  Color: 255; 255; 0; 255
  Alpha: 1.0
  Line Width: 0.1
  Offset: 0; 0; 0
```

---

## 配置文件

### 保存配置

```bash
# 在 RViz2 GUI 中
# File -> Save Config As -> config.rviz

# 命令行
rviz2 -d config.rviz
```

### 加载配置

```bash
rviz2 -d /path/to/config.rviz
```

### 配置文件结构

```yaml
Panels:
  - Class: rviz2_common/Displays
    Help Height: 78
    Name: Displays
    Property Tree Widget:
      Expanded:
        - /Global Options1
        - /RobotModel1
      Splitter Ratio: 0.5
    Tree Height: 557

Visualization Manager:
  Class: ""
  Displays:
    - Class: rviz_default_plugins/RobotModel
      Description Topic:
        Name: /robot_description
      Name: RobotModel
      Robot Description: robot_description
      Visual Enabled: true

  Property Tree Options:
    Splitter Sizes: 150 481
```

---

## 常见问题

### 问题 1: 机器人模型不显示

**解决方案**：检查 robot_description 话题是否发布，确认 Fixed Frame 设置正确

### 问题 2: 传感器数据不更新

**解决方案**：检查话题名称和消息类型，确认数据发布正常

---

## 另见

- [plugin-development](../plugin-development/) - 插件开发
- [marker-visualization](../marker-visualization/) - 标记可视化
- [tf-visualization](../tf-visualization/) - TF 可视化