---
name: dynamic-obstacle
description: 动态障碍物检测技能 - 移动物体跟踪、预测、碰撞预测、ROS2 避障
argument-hint: 动态避障 OR 移动物体 OR collision prediction OR dynamic obstacle
user-invocable: true
---

# 动态障碍物检测技能

> 动态障碍物检测与预测

---

## 何时使用

当需要以下帮助时使用此技能：
- 移动障碍物检测
- 轨迹预测
- 碰撞时间计算
- 动态 costmap
- 安全导航

---

## 核心实现

### 移动障碍物检测

```python
import numpy as np
from scipy.spatial import distance

class DynamicObstacleDetector:
    def __init__(self):
        self.tracker = MultiObjectTracker()
        self.history = []
        
    def detect(self, obstacles, dt=0.1):
        """检测动态障碍物"""
        # 跟踪
        tracks = self.tracker.update(obstacles)
        
        dynamic_obstacles = []
        
        for track in tracks:
            # 计算速度
            if len(track.history) >= 2:
                velocity = (track.current_position - track.history[-2]) / dt
                speed = np.linalg.norm(velocity)
                
                # 判断是否动态
                if speed > 0.1:  # 阈值 m/s
                    track.velocity = velocity
                    track.speed = speed
                    dynamic_obstacles.append(track)
                    
        return dynamic_obstacles
        
    def predict_trajectory(self, track, horizon=3.0):
        """预测轨迹"""
        predictions = []
        dt = 0.1
        
        for t in np.arange(0, horizon, dt):
            # 匀速预测
            future_pos = track.current_position + track.velocity * t
            predictions.append({
                'position': future_pos,
                'time': t
            })
            
        return predictions
        
    def compute_ttc(self, robot_pos, robot_vel, obstacle_pos, obstacle_vel):
        """计算碰撞时间 (Time to Collision)"""
        rel_pos = obstacle_pos - robot_pos
        rel_vel = obstacle_vel - robot_vel
        
        a = np.dot(rel_vel, rel_vel)
        b = 2 * np.dot(rel_pos, rel_vel)
        c = np.dot(rel_pos, rel_pos) - (0.3 + 0.3) ** 2  # 碰撞半径
        
        if a < 1e-6:
            return float('inf')
            
        discriminant = b ** 2 - 4 * a * c
        
        if discriminant < 0:
            return float('inf')
            
        t1 = (-b - np.sqrt(discriminant)) / (2 * a)
        t2 = (-b + np.sqrt(discriminant)) / (2 * a)
        
        if t1 > 0:
            return t1
        elif t2 > 0:
            return t2
            
        return float('inf')
```

### ROS2 动态障碍发布

```python
import rclpy
from rclpy.node import Node
from visualization_msgs.msg import MarkerArray
from geometry_msgs.msg import Point

class DynamicObstaclePublisher(Node):
    def __init__(self):
        super().__init__('dynamic_obstacle_publisher')
        
        self.marker_pub = self.create_publisher(
            MarkerArray, '/dynamic_obstacles', 10)
            
        self.detector = DynamicObstacleDetector()
        
        # 订阅检测结果
        self.det_sub = self.create_subscription(
            Detection3DArray, '/detections_3d', self.callback, 10)
            
    def callback(self, msg):
        obstacles = self.parse_detections(msg)
        dynamic = self.detector.detect(obstacles)
        
        # 发布预测轨迹
        markers = MarkerArray()
        
        for i, track in enumerate(dynamic):
            predictions = self.detector.predict_trajectory(track)
            
            marker = self.create_path_marker(predictions, i)
            markers.markers.append(marker)
            
        self.marker_pub.publish(markers)
```
