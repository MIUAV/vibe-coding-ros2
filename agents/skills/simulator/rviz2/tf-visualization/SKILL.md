---
name: tf-visualization
description: RViz2 TF 可视化技能 - 坐标变换显示、帧调试、时间轴可视化
argument-hint: rviz tf OR 坐标变换 OR tf调试
user-invocable: true
---

# RViz2 TF Visualization Skill

> 用于在 RViz2 中可视化坐标变换关系

---

## 何时使用

当需要以下帮助时使用此技能：
- 可视化坐标变换树
- 调试 TF 关系
- 检查坐标系对齐
- 诊断坐标问题

---

## 快速参考

### 发布 TF

```python
import rclpy
from rclpy.node import Node
from tf2_ros import TransformBroadcaster
from geometry_msgs.msg import TransformStamped

class TFBroadcaster(Node):
    def __init__(self):
        super().__init__('tf_broadcaster')
        self.broadcaster = TransformBroadcaster(self)
        
    def broadcast_tf(self, parent, child, x, y, z, qx, qy, qz, qw):
        t = TransformStamped()
        t.header.stamp = self.get_clock().now().to_msg()
        t.header.frame_id = parent
        t.child_frame_id = child
        
        t.transform.translation.x = x
        t.transform.translation.y = y
        t.transform.translation.z = z
        t.transform.rotation.x = qx
        t.transform.rotation.y = qy
        t.transform.rotation.z = qz
        t.transform.rotation.w = qw
        
        self.broadcaster.sendTransform(t)
```

---

## TF 树结构

### 常见机器人 TF 树

```
map
  └── odom (里程计)
        └── base_link (机器人基座)
              ├── base_scan (激光雷达)
              ├── camera_link (相机)
              ├── imu_link (IMU)
              ├── wheel_left (左轮)
              └── wheel_right (右轮)
```

### TF 配置参数

```yaml
# RViz TF 显示配置
TF:
  Frame Timeout: 10  # 帧超时时间 (秒)
  All Frames: True  # 显示所有帧
  
  Frames:
    All Enabled: True
    Show Names: True
    Show Axes: True
    Show Arrows: True
    
  Tree:
    map:
      enabled: true
      parent: ''  # 无父节点
      odom:
        enabled: true
        parent: map
      base_link:
        enabled: true
        parent: odom
```

---

## 可视化选项

### 显示轴

```yaml
Axes:
  Frame: base_link
  Length: 1.0  # 轴长度
  Radius: 0.1  # 轴半径
```

### 显示设置

```yaml
TF:
  Show Axes: True  # 显示坐标轴
  Show Names: True  # 显示帧名称
  Show Arrows: True  # 显示箭头
  
  Axis Length: 1.0  # 默认轴长度
  Axis Radius: 0.05  # 默认轴半径
  
  Head Length: 0.2  # 箭头头部长度
  Head Width: 0.1  # 箭头头部宽度
  Shaft Length: 0.8  # 箭头杆长度
  Shaft Width: 0.05  # 箭头杆宽度
```

---

## TF 调试

### 检查 TF 关系

```bash
# 查看所有 TF 帧
ros2 run tf2_ros view_frames

# 监听 TF 变换
ros2 run tf2_ros tf2_echo source_frame target_frame

# 示例
ros2 run tf2_ros tf2_echo base_link map
```

### TF 缓冲区

```python
from tf2_ros import TransformBroadcaster, Buffer, TransformListener

# 创建缓冲区
buffer = Buffer()
listener = TransformListener(buffer)

# 查找变换
try:
    transform = buffer.lookup_transform(
        'target_frame',
        'source_frame',
        rclpy.time.Time()
    )
    print(f"Transform: {transform}")
except Exception as e:
    print(f"Error: {e}")
```

---

## 时间同步

### 使用仿真时间

```bash
# 启动节点时启用仿真时间
ros2 run my_node my_node --ros-args -p use_sim_time:=true

# 在 RViz 中启用
# Global Options -> Use Simulation Time: True
```

### 检查时间延迟

```python
# 检查变换时间戳
transform = buffer.lookup_transform('base_link', 'scan', rclpy.time.Time())

now = node.get_clock().now()
age = now - transform.header.stamp

print(f"TF age: {age.nanoseconds / 1e9} seconds")
```

---

## 坐标对齐问题

### 常见问题

```python
# 问题 1: TF 不可用
# 解决方案: 检查变换是否发布

# 问题 2: TF 时间过期
# 解决方案: 调整 TF 缓冲区大小

# 问题 3: 循环依赖
# 解决方案: 简化 TF 树结构
```

### 修复建议

```yaml
# 增加超时时间
TF:
  Frame Timeout: 30
```

---

## 批量 TF 操作

### 静态变换

```python
from geometry_msgs.msg import TransformStamped
from tf2_ros import StaticTransformBroadcaster

static_broadcaster = StaticTransformBroadcaster(node)

# 发布静态变换
transform = TransformStamped()
transform.header.frame_id = "base_link"
transform.child_frame_id = "laser"
transform.transform.translation.x = 0.2
transform.transform.translation.y = 0.0
transform.transform.translation.z = 0.1

static_broadcaster.sendTransform(transform)
```

### 动态变换

```python
# 定时发布
timer = node.create_timer(0.1, publish_transform)

def publish_transform(self):
    # 计算当前变换
    t = TransformStamped()
    t.header.stamp = self.get_clock().now().to_msg()
    t.header.frame_id = "odom"
    t.child_frame_id = "base_link"
    
    # 设置变换
    t.transform.translation.x = current_x
    t.transform.translation.y = current_y
    t.transform.translation.z = 0.0
    
    self.broadcaster.sendTransform(t)
```

---

## 坐标系颜色和标签

### 自定义颜色

```yaml
TF:
  Tree:
    map:
      Color: 255; 0; 0; 255  # 红色
    odom:
      Color: 0; 255; 0; 255  # 绿色
    base_link:
      Color: 0; 0; 255; 255  # 蓝色
```

### 标签设置

```yaml
TF:
  Labels:
    Show: True
    Color: 255; 255; 255; 255
    Size: 12
```

---

## 常见问题

### 问题 1: 坐标系抖动

**解决方案**：检查传感器数据延迟，调整滤波器参数

### 问题 2: TF 坐标系偏移

**解决方案**：检查外参是否正确，确认父坐标系设置

---

## 另见

- [display-configuration](../display-configuration/) - 显示配置
- [marker-visualization](../marker-visualization/) - 标记可视化