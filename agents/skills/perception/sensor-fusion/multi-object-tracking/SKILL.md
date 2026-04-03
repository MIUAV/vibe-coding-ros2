---
name: multi-object-tracking
description: 多目标跟踪技能 - SORT、DeepSORT、ByteTrack、ROS2 跟踪节点
argument-hint: 多目标跟踪 OR MOT OR SORT OR DeepSORT OR tracking
user-invocable: true
---

# 多目标跟踪技能

> 视频序列中的多目标跟踪

---

## 何时使用

当需要以下帮助时使用此技能：
- 实时目标跟踪
- ID 分配与管理
- 遮挡处理
- 轨迹管理
- ROS2 跟踪节点

---

## 核心实现

### SORT 算法

```python
import numpy as np
from scipy.optimize import linear_sum_assignment

class SORTTracker:
    def __init__(self, max_age=1, min_hits=3, iou_threshold=0.3):
        self.max_age = max_age
        self.min_hits = min_hits
        self.iou_threshold = iou_threshold
        self.tracks = []
        self.track_id_count = 0
        
    def update(self, detections):
        """更新跟踪器"""
        # 预测所有轨迹
        for track in self.tracks:
            track.predict()
            
        # 匹配
        matched, unmatched_dets, unmatched_tracks = self.associate(
            detections, self.tracks)
            
        # 更新匹配轨迹
        for det_idx, track_idx in matched:
            self.tracks[track_idx].update(detections[det_idx])
            
        # 创建新轨迹
        for det_idx in unmatched_dets:
            self.tracks.append(self.create_track(detections[det_idx]))
            
        # 移除丢失轨迹
        self.tracks = [t for t in self.tracks if t.time_since_update <= self.max_age]
        
        return [t.get_state() for t in self.tracks]
        
    def associate(self, detections, tracks):
        """匈牙利算法匹配"""
        if len(tracks) == 0:
            return [], list(range(len(detections))), []
            
        iou_matrix = np.zeros((len(detections), len(tracks)))
        for d, det in enumerate(detections):
            for t, track in enumerate(tracks):
                iou_matrix[d, t] = self.compute_iou(det, track.get_bbox())
                
        # 匈牙利算法
        row_ind, col_ind = linear_sum_assignment(-iou_matrix)
        
        matched = []
        unmatched_dets = list(range(len(detections)))
        unmatched_tracks = list(range(len(tracks)))
        
        for r, c in zip(row_ind, col_ind):
            if iou_matrix[r, c] >= self.iou_threshold:
                matched.append([r, c])
                unmatched_dets.remove(r)
                unmatched_tracks.remove(c)
                
        return matched, unmatched_dets, unmatched_tracks
        
    @staticmethod
    def compute_iou(box1, box2):
        """计算 IOU"""
        x1 = max(box1[0], box2[0])
        y1 = max(box1[1], box2[1])
        x2 = min(box1[0] + box1[2], box2[0] + box2[2])
        y2 = min(box1[1] + box1[3], box2[1] + box2[3])
        
        inter = max(0, x2 - x1) * max(0, y2 - y1)
        area1 = box1[2] * box1[3]
        area2 = box2[2] * box2[3]
        union = area1 + area2 - inter
        
        return inter / union if union > 0 else 0
        
    def create_track(self, detection):
        return Track(detection, self.track_id_count++)
        
    def get_track_id(self):
        return self.track_id_count
```

### DeepSORT 算法

```python
class DeepSORTTracker:
    def __init__(self, max_age=30, min_hits=3, nn_budget=100):
        self.max_age = max_age
        self.min_hits = min_hits
        self.nn_budget = nn_budget
        
        # 外观描述符管理器
        self.descriptors = {}
        
        # 卡尔曼滤波器
        self.kf = KalmanBoxFilter()
        
    def update(self, detections, features=None):
        """DeepSORT 更新"""
        # 预测
        for track in self.tracks:
            track.predict()
            
        # 外观匹配
        if features is not None:
            self.update_descriptors(features)
            
        # 级联匹配
        matches, unmatched_dets, unmatched_tracks = self.matching(
            detections, features)
            
        # 更新轨迹
        for det_idx, track_idx in matches:
            self.tracks[track_idx].update(detections[det_idx], features[det_idx])
            
        # 处理未匹配
        for det_idx in unmatched_dets:
            self.tracks.append(Track(detections[det_idx], features[det_idx]))
            
        self.tracks = [t for t in self.tracks if t.time_since_update <= self.max_age]
        
        return self.tracks
        
    def cosine_distance(self, feat1, feat2):
        """余弦距离"""
        return 1 - np.dot(feat1, feat2) / (np.linalg.norm(feat1) * np.linalg.norm(feat2))
```

### ROS2 跟踪节点

```python
import rclpy
from rclpy.node import Node
from vision_msgs.msg import Detection2DArray
from geometry_msgs.msg import PoseArray
import numpy as np

class TrackingNode(Node):
    def __init__(self):
        super().__init__('tracking_node')
        
        self.det_sub = self.create_subscription(
            Detection2DArray, '/detections_2d', self.callback, 10)
        self.track_pub = self.create_publisher(PoseArray, '/tracked_objects', 10)
        
        self.tracker = DeepSORTTracker()
        
    def callback(self, msg):
        detections = []
        for det in msg.detections:
            bbox = [
                det.bbox.center.position.x - det.bbox.size_x / 2,
                det.bbox.center.position.y - det.bbox.size_y / 2,
                det.bbox.size_x,
                det.bbox.size_y
            ]
            detections.append(bbox)
            
        tracks = self.tracker.update(detections)
        
        # 发布跟踪结果
        pose_array = PoseArray()
        pose_array.header = msg.header
        
        for track in tracks:
            pose = Pose()
            pose.position.x = track['x']
            pose.position.y = track['y']
            pose.position.z = track.get('z', 0)
            pose_array.poses.append(pose)
            
        self.track_pub.publish(pose_array)
```
