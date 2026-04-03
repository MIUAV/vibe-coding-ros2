---
name: perception
description: 轮式车辆感知系统 - 视觉感知、激光雷达、深度学习、传感器融合
argument-hint: 轮式感知 OR 车辆视觉 OR 障碍物检测 OR 车道线
user-invocable: true
---

# 轮式车辆感知技能

> 用于配置和开发轮式车辆的感知系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置车载相机
- 激光雷达感知
- 障碍物检测
- 车道线识别

---

## 快速参考

### 感知配置

```yaml
wheeled_vehicle_perception:
  # 相机
  cameras:
    front: [1280, 720, 60]  # W, H, FPS
    rear: [1280, 720, 30]
    
  # 激光雷达
  lidar:
    type: hesai / ouster / velodyne
    range: 100  # m
    points: 2M  # 每秒点数
    
  # 毫米波雷达
  radar:
    type: continental / delphi
    range: 200  # m
```

---

## 视觉感知

### 车道线检测

```python
class LaneDetection:
    def __init__(self):
        self.model = LaneNet('lanenet.ckpt')
        self.perspective_transformer = PerspectiveTransformer()
        
    def detect_lanes(self, image):
        """检测车道线"""
        # 鸟瞰图变换
        bird_view = self.perspective_transformer.transform(image)
        
        # 车道线检测
        lane_mask = self.model.predict(bird_view)
        
        # 拟合曲线
        left_coeffs = self.fit_poly(lane_mask.left)
        right_coeffs = self.fit_poly(lane_mask.right)
        
        return left_coeffs, right_coeffs
```

---

## 激光雷达感知

### 障碍物检测

```python
class LidarPerception:
    def __init__(self):
        self.segmentation = PointNetSeg('pointnet.ckpt')
        self.tracker = MultiObjectTracker()
        
    def detect_obstacles(self, point_cloud):
        """检测障碍物"""
        # 地面分割
        ground = self.ground_segmentation.segment(point_cloud)
        obstacles = point_cloud - ground
        
        # 实例分割
        clusters = self.clustering.segment(obstacles)
        
        # 分类
        obstacles = []
        for cluster in clusters:
            cls = self.classification.predict(cluster)
            bbox = self.bbox_fitting.fit(cluster)
            obstacles.append(BoundingBox(cls, bbox))
            
        return obstacles
```

---

## 相关文档

- `./wheeled_vehicle/localization/SKILL.md` - 定位系统
- `./wheeled_vehicle/navigation/SKILL.md` - 导航系统
- `./wheeled_vehicle/action/SKILL.md` - 运动控制
