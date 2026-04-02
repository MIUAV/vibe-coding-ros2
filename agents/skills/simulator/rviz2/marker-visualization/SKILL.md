---
name: marker-visualization
description: RViz2 标记可视化技能 - Marker、MarkerArray、交互式标记配置
argument-hint: "rviz标记" / "可视化标记" / "MarkerArray"
user-invocable: true
---

# RViz2 Marker Visualization Skill

> 用于在 RViz2 中显示可视化标记

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建和发布 Marker 消息
- 配置不同类型的标记
- 使用交互式标记
- 动态更新标记

---

## 快速参考

### Marker 消息类型

```python
from visualization_msgs.msg import Marker, MarkerArray
import rospy

# 创建球体标记
marker = Marker()
marker.header.frame_id = "base_link"
marker.header.stamp = rospy.Time.now()
marker.ns = "my_markers"
marker.id = 0
marker.type = Marker.SPHERE
marker.action = Marker.ADD
marker.pose.position.x = 1.0
marker.pose.position.y = 0.0
marker.pose.position.z = 0.0
marker.pose.orientation.w = 1.0
marker.scale.x = 0.1
marker.scale.y = 0.1
marker.scale.z = 0.1
marker.color.r = 1.0
marker.color.g = 0.0
marker.color.b = 0.0
marker.color.a = 1.0
```

---

## 标记类型

### 基本形状

```python
# 球体
marker.type = Marker.SPHERE

# 立方体
marker.type = Marker.CUBE

# 圆柱体
marker.type = Marker.CYLINDER

# 箭头
marker.type = Marker.ARROW
# 需要两点
marker.points.append(Point(0, 0, 0))
marker.points.append(Point(1, 0, 0))

# 线条
marker.type = Marker.LINE_STRIP
# 多个点
for i in range(10):
    marker.points.append(Point(i*0.1, 0, 0))

# 线段列表
marker.type = Marker.LINE_LIST

# 三角形条带
marker.type = Marker.TRIANGLE_LIST

# 文本
marker.type = Marker.TEXT_VIEW_FACING
marker.text = "Hello World"

# 网格/模型
marker.type = Marker.MESH_RESOURCE
marker.mesh_resource = "package://robot/meshes/model.dae"
```

### 标记操作

```python
# 添加/更新标记
marker.action = Marker.ADD

# 删除标记
marker.action = Marker.DELETE

# 删除所有标记
marker.action = Marker.DELETEALL

# 删除命名空间中的所有标记
marker.ns = "my_markers"
marker.action = Marker.DELETE
```

---

## 颜色和缩放

### 颜色设置

```python
# RGBA 颜色
marker.color.r = 1.0  # 红色 0-1
marker.color.g = 0.0
marker.color.b = 0.0
marker.color.a = 1.0  # 透明度 0-1

# 使用 ARGB 整数
marker.color.a = 1.0
marker.color.r = 1.0
marker.color.g = 0.5
marker.color.b = 0.0
```

### 缩放设置

```python
# 缩放因子 (单位: 米)
marker.scale.x = 0.5  # 宽度
marker.scale.y = 0.5  # 高度/直径
marker.scale.z = 0.5  # 深度

# 箭头专用
marker.scale.x = 0.2  # 箭头杆直径
marker.scale.y = 0.1  # 箭头头部直径
marker.scale.z = 0.1  # 箭头头部长度
```

---

## MarkerArray

### 批量发布标记

```python
from visualization_msgs.msg import MarkerArray

marker_array = MarkerArray()

# 添加多个标记
for i in range(10):
    marker = Marker()
    marker.header.stamp = rospy.Time.now()
    marker.header.frame_id = "map"
    marker.ns = "waypoints"
    marker.id = i
    marker.type = Marker.SPHERE
    marker.action = Marker.ADD
    marker.pose.position.x = i * 1.0
    marker.pose.position.y = 0
    marker.pose.position.z = 0
    marker.pose.orientation.w = 1.0
    marker.scale.x = 0.2
    marker.scale.y = 0.2
    marker.scale.z = 0.2
    marker.color.g = 1.0
    marker.color.a = 1.0
    
    marker_array.markers.append(marker)

# 发布
marker_pub.publish(marker_array)
```

### 更新部分标记

```python
# 只更新单个标记
def update_marker(index, position):
    marker = Marker()
    marker.header.frame_id = "map"
    marker.header.stamp = rospy.Time.now()
    marker.ns = "dynamic"
    marker.id = index
    marker.type = Marker.SPHERE
    marker.action = Marker.ADD
    marker.pose.position = position
    marker.pose.orientation.w = 1.0
    marker.scale.x = 0.1
    marker.scale.y = 0.1
    marker.scale.z = 0.1
    marker.color.b = 1.0
    marker.color.a = 1.0
    
    publisher.publish(marker)
```

---

## 坐标系和时间戳

### 坐标 frame

```python
# 设置坐标系
marker.header.frame_id = "base_link"  # 机器人基座
marker.header.frame_id = "map"        # 地图坐标
marker.header.frame_id = "odom"       # 里程计坐标
marker.header.frame_id = "world"       # 世界坐标
```

### 时间戳

```python
# 设置时间戳
marker.header.stamp = rospy.Time.now()  # 当前时间
marker.header.stamp = rospy.Time(0)     # 始终为 0 表示永久

# 持续时间
marker.lifetime = rospy.Duration(5.0)   # 显示 5 秒后消失
marker.lifetime = rospy.Duration()     # 永久显示 (rospy.Duration() 表示 0)
```

---

## 交互式标记

### 基本交互标记

```python
from visualization_msgs.msg import InteractiveMarker, InteractiveMarkerControl, MenuEntry

# 创建交互式标记
interactive_marker = InteractiveMarker()
interactive_marker.header.frame_id = "base_link"
interactive_marker.header.stamp = rospy.Time.now()
interactive_marker.name = "my_interactive_marker"
interactive_marker.description = "Click me!"

# 添加控制
control = InteractiveMarkerControl()
control.name = "move_x"
control.orientation.w = 1
control.orientation.x = 1
control.interaction_mode = InteractiveMarkerControl.MOVE_AXIS

interactive_marker.controls.append(control)

# 发布
interactive_marker_server.insert(interactive_marker)
interactive_marker_server.applyChanges()
```

### 交互模式

```python
# 移动轴
control.interaction_mode = InteractiveMarkerControl.MOVE_AXIS

# 旋转轴
control.interaction_mode = InteractiveMarkerControl.ROTATE_AXIS

# 移动平面
control.interaction_mode = InteractiveMarkerControl.MOVE_PLANE

# 3D 移动
control.interaction_mode = InteractiveMarkerControl.MOVE_3D

# 3D 旋转
control.interaction_mode = InteractiveMarkerControl.ROTATE_3D

# 3D 移动和旋转
control.interaction_mode = InteractiveMarkerControl.FULL
```

---

## 菜单和反馈

### 添加菜单项

```python
from visualization_msgs.msg import MenuEntry

# 添加菜单
menu_entry = MenuEntry()
menu_entry.id = 1
menu_entry.label = "Option 1"
menu_entry.command = "option1"
interactive_marker.menu_entries.append(menu_entry)

menu_entry2 = MenuEntry()
menu_entry2.id = 2
menu_entry2.label = "Option 2"
menu_entry2.parent_id = 1  # 子菜单
interactive_marker.menu_entries.append(menu_entry2)
```

### 处理反馈

```python
def processFeedback(feedback):
    if feedback.event_type == InteractiveMarkerFeedback.MENU_SELECT:
        if feedback.menu_entry_id == 1:
            print("Option 1 selected")
        elif feedback.menu_entry_id == 2:
            print("Option 2 selected")
    
    elif feedback.event_type == InteractiveMarkerFeedback.POSE_UPDATE:
        print(f"New pose: {feedback.pose}")
    
    interactive_marker_server.applyChanges()

server.setCallback(processFeedback)
```

---

## 路径和轨迹可视化

### 路径显示

```python
from nav_msgs.msg import Path

# 从路径点创建线
marker = Marker()
marker.header.frame_id = "map"
marker.header.stamp = rospy.Time.now()
marker.type = Marker.LINE_STRIP
marker.action = Marker.ADD

for pose in path.poses:
    point = Point()
    point.x = pose.pose.position.x
    point.y = pose.pose.position.y
    point.z = pose.pose.position.z
    marker.points.append(point)

marker.scale.x = 0.05  # 线宽
marker.color.b = 1.0
marker.color.a = 1.0
```

### 轨迹显示

```python
# 轨迹动画 (箭头)
trajectory_marker = Marker()
trajectory_marker.type = Marker.ARROW
trajectory_marker.action = Marker.ADD

for i, point in enumerate(trajectory_points):
    arrow = Marker()
    arrow.header.frame_id = "map"
    arrow.header.stamp = rospy.Time.now()
    arrow.id = i
    arrow.type = Marker.ARROW
    arrow.action = Marker.ADD
    
    # 设置箭头位置和方向
    ...
```

---

## 常见问题

### 问题 1: 标记不显示

**解决方案**：检查 frame_id 是否正确，确认时间戳不是未来时间

### 问题 2: 标记闪烁

**解决方案**：确保每次更新使用相同的 ID 和 namespace

---

## 另见

- [display-configuration](../display-configuration/) - 显示配置
- [plugin-development](../plugin-development/) - 插件开发