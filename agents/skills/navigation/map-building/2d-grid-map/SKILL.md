---
name: 2d-grid-map
description: 2D 栅格地图技能 - 占据栅格地图、SLAM 建图、地图管理、ROS2 map_server
argument-hint: 2D地图 OR grid map OR 占据栅格 OR occupancy grid
user-invocable: true
---

# 2D 栅格地图技能

> 2D 占据栅格地图构建与管理

---

## 何时使用

当需要以下帮助时使用此技能：
- 占据栅格地图构建
- 概率更新
- 地图存储加载
- map_server 使用
- 动态地图更新

---

## 核心实现

### 占据栅格地图

```python
import numpy as np

class OccupancyGridMap:
    def __init__(self, resolution=0.05, width=20, height=20):
        self.resolution = resolution
        self.width = width
        self.height = height
        self.origin = np.array([-width/2 * resolution, -height/2 * resolution])
        
        # 概率 [0, 1], 0.5 = 未知
        self.probability = np.full((width, height), 0.5)
        
        # log odds
        self.log_odds = np.zeros((width, height))
        
        # 先验概率
        self.prior = 0.5
        self.p_occupied = 0.7
        self.p_free = 0.3
        
    def world_to_grid(self, x, y):
        """世界坐标转栅格索引"""
        gx = int((x - self.origin[0]) / self.resolution)
        gy = int((y - self.origin[1]) / self.resolution)
        return gx, gy
        
    def update(self, x, y, angle, ranges, max_range):
        """贝叶斯更新栅格"""
        # 射线追踪
        for r in ranges:
            if r >= max_range:
                continue
                
            # 击中点
            hit_x = x + r * np.cos(angle)
            hit_y = y + r * np.sin(angle)
            
            # 标记占用
            self.update_cell(hit_x, hit_y, occupied=True)
            
            # 路径上的空闲区域
            self.update_free_path(x, y, hit_x, hit_y)
            
    def update_cell(self, wx, wy, occupied=True):
        """更新单个栅格"""
        gx, gy = self.world_to_grid(wx, wy)
        
        if 0 <= gx < self.width and 0 <= gy < self.height:
            # log odds 更新
            if occupied:
                self.log_odds[gx, gy] += np.log(self.p_occupied / (1 - self.p_occupied))
            else:
                self.log_odds[gx, gy] -= np.log(self.p_free / (1 - self.p_free))
                
            # 转换回概率
            self.probability[gx, gy] = 1 - 1 / (1 + np.exp(self.log_odds[gx, gy]))
            
    def update_free_path(self, x1, y1, x2, y2):
        """更新射线经过的空闲栅格"""
        # Bresenham 算法
        gx1, gy1 = self.world_to_grid(x1, y1)
        gx2, gy2 = self.world_to_grid(x2, y2)
        
        cells = self.bresenham(gx1, gy1, gx2, gy2)
        
        for gx, gy in cells[:-1]:  # 不包括终点
            if 0 <= gx < self.width and 0 <= gy < self.height:
                self.log_odds[gx, gy] -= np.log(self.p_free / (1 - self.p_free))
                self.probability[gx, gy] = 1 - 1 / (1 + np.exp(self.log_odds[gx, gy]))
                
    def bresenham(self, x1, y1, x2, y2):
        """Bresenham 直线算法"""
        points = []
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy
        
        while True:
            points.append((x1, y1))
            if x1 == x2 and y1 == y2:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x1 += sx
            if e2 < dx:
                err += dx
                y1 += sy
                
        return points
```

### ROS2 map_server

```python
import rclpy
from rclpy.node import Node
from nav_msgs.msg import OccupancyGrid, MapMetaData
from nav_msgs.srv import GetMap

class MapServer(Node):
    def __init__(self):
        super().__init__('map_server')
        
        # 加载地图
        self.map = self.load_map('/path/to/map.yaml')
        
        # 发布地图
        self.map_pub = self.create_publisher(OccupancyGrid, '/map', 10)
        
        # 服务
        self.get_map_srv = self.create_service(
            GetMap, '/map_server/get_map', self.get_map_callback)
            
    def get_map_callback(self, request, response):
        response.map = self.map
        return response
        
    def publish_map(self):
        msg = OccupancyGrid()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'map'
        msg.data = (self.map.probability * 100).astype(np.int8)
        msg.info = MapMetaData()
        msg.info.resolution = self.map.resolution
        msg.info.width = self.map.width
        msg.info.height = self.map.height
        self.map_pub.publish(msg)
```
