---
name: 3d-object-detection
description: 3D 目标检测技能 - PointPillars、PointRCNN、LaserNet++ ROS2 部署
argument-hint: "3D检测" / "PointPillars" / "pointcloud" / "3D detection" / "物体检测"
user-invocable: true
---

# 3D 目标检测技能

> 基于点云和图像融合的 3D 目标检测

---

## 何时使用

当需要以下帮助时使用此技能：
- 3D 目标检测网络
- 点云处理与分析
- 激光雷达-相机融合
- 障碍物检测与跟踪
- 自动驾驶感知

---

## 核心实现

### PointPillars ROS2 节点

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2
from vision_msgs.msg import Detection3DArray
import numpy as np
import torch
from torch import nn

class PointPillarsNode(Node):
    def __init__(self):
        super().__init__('pointpillars_node')
        
        self.pointcloud_sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.callback, 10)
        self.det_pub = self.create_publisher(Detection3DArray, '/detections_3d', 10)
        
        # 模型初始化
        self.init_model()
        
        self.declare_parameter('nms_iou_threshold', 0.5)
        self.declare_parameter('score_threshold', 0.5)
        
    def init_model(self):
        # 加载 PointPillars 模型
        # self.model = PointPillarsNet(...)
        # self.model.load_state_dict(torch.load('pointpillars.pth'))
        # self.model.cuda().eval()
        pass
        
    def callback(self, msg):
        # 解析点云
        points = self.parse_pointcloud(msg)
        
        # 预处理
        pillars, coords = self.create_pillars(points)
        
        # 推理
        with torch.no_grad():
            boxes = self.model(pillars, coords)
            
        # 后处理 (NMS)
        detections = self.nms(boxes)
        
        # 发布
        self.publish_detections(detections)
        
    def parse_pointcloud(self, msg):
        """解析 PointCloud2 消息"""
        points = []
        for i in range(0, len(msg.data), msg.point_step):
            x = msg.data[i:i+4]
            points.append([x[0], x[1], x[2], x[3]])
        return np.array(points, dtype=np.float32)
        
    def create_pillars(self, points):
        """创建 Pillar"""
        # 简化的 Pillar 创建
        pillar_features = np.random.randn(100, 32, 100)  # [num_pillars, D, N]
        coords = np.zeros((100, 3), dtype=np.int32)
        return pillar_features, coords
        
    def nms(self, boxes):
        """非极大值抑制"""
        # 实现 NMS
        return boxes
        
    def publish_detections(self, detections):
        msg = Detection3DArray()
        for det in detections:
            detection = Detection3D()
            detection.bbox.center.position.x = det['x']
            detection.bbox.center.position.y = det['y']
            detection.bbox.center.position.z = det['z']
            detection.bbox.size.x = det['length']
            detection.bbox.size.y = det['width']
            detection.bbox.size.z = det['height']
            detection.bbox.center.orientation = det['orientation']
            msg.detections.append(detection)
        self.det_pub.publish(msg)
```

### PointPillars 网络结构

```python
class PillarEncoder(nn.Module):
    """Pillar Encoder"""
    def __init__(self, in_channels=9, out_channels=64):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_channels, 32, 1),
            nn.BatchNorm2d(32),
            nn.ReLU(),
            nn.Conv2d(32, out_channels, 1),
            nn.BatchNorm2d(out_channels),
            nn.ReLU()
        )
        
    def forward(self, pillars, coords):
        # pillars: [N, D, H, W]
        # coords: [N, 3]
        x = self.conv(pillars)
        return x

class Backbone(nn.Module):
    """SSD Backbone"""
    def __init__(self, in_channels=64):
        super().__init__()
        self.conv = nn.Sequential(
            nn.Conv2d(in_channels, 128, 3, stride=2, padding=1),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.Conv2d(128, 256, 3, stride=2, padding=1),
            nn.BatchNorm2d(256),
            nn.ReLU(),
            nn.Conv2d(256, 256, 3, stride=2, padding=1),
            nn.BatchNorm2d(256),
            nn.ReLU()
        )
        
    def forward(self, x):
        return self.conv(x)

class DetectionHead(nn.Module):
    """检测头"""
    def __init__(self, in_channels=256, num_classes=3):
        super().__init__()
        self.cls = nn.Conv2d(in_channels, num_classes, 1)
        self.box = nn.Conv2d(in_channels, 7 * num_classes, 1)  # 7: dx, dy, dz, w, h, l, rot
        
    def forward(self, x):
        cls = self.cls(x)
        box = self.box(x)
        return cls, box
```
