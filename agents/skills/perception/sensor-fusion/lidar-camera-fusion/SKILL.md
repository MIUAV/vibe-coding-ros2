---
name: perception-lidar-camera-fusion
description: 激光-相机融合技能 - 深度学习融合、几何投影融合、3D检测、ROS2标定与同步
argument-hint: "激光相机融合" / "lidar camera fusion" / "深度学习融合" / "3D检测" / "多传感器融合"
user-invocable: true
---

# 激光-相机融合技能

> 用于实现激光雷达与相机的深度融合，涵盖几何投影融合、深度学习融合（CNN/Transformer）、3D目标检测和 ROS2 集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 激光雷达与相机外参标定
- 几何投影融合（LiDAR → 图像）
- 深度学习融合检测（PointPillars + 图像）
- 3D 目标检测（BEV + 相机融合）
- 多模态感知系统 ROS2 部署

---

## 快速参考

### 融合策略对比

```
融合层级:
├── 原始数据层 (Early Fusion) → 点云 + 图像原始数据 concat
├── 特征层 (Deep Fusion) → 点云特征 + 图像特征在网络内融合
├── 决策层 (Late Fusion) → 各自检测结果加权融合
└── 混合融合 (Hybrid) → 多层融合组合
```

### 核心依赖

```bash
# 基础
sudo apt install -y ros-humble-depthimage-to-laserscan
sudo apt install -y ros-humble-pointcloud-to-laserscan

# 标定
sudo apt install -y ros-humble-calibration-camera-lidar

# 深度学习（可选）
pip install open3d torch torchvision
```

### 核心话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/camera/color/image_raw` | sensor_msgs/Image | RGB 图像 |
| `/camera/depth/image_rect_raw` | sensor_msgs/Image | 深度图 |
| `/velodyne_points` | sensor_msgs/PointCloud2 | 激光点云 |
| `/ detections_3d` | DetectionArray | 3D 检测结果 |

---

## 外参标定

### 标定板法（棋盘格 + 激光）

```python
#!/usr/bin/env python3
"""相机-激光雷达外参标定"""

import numpy as np
import open3d as o3d
import cv2
from pathlib import Path


class CameraLidarCalibrator:
    """相机-激光雷达标定"""

    def __init__(self, camera_intrinsics, resolution=(1920, 1080)):
        self.K = camera_intrinsics  # 内参矩阵
        self.resolution = resolution
        self.T_cam_lidar = None  # 外参：激光雷达到相机的变换

    def calibrate_with_board(
        self,
        lidar_points: np.ndarray,
        board_corners_3d: np.ndarray,
        image: np.ndarray
    ) -> np.ndarray:
        """
        使用棋盘格标定板标定

        Args:
            lidar_points: 标定板上的激光点云 Nx3
            board_corners_3d: 标定板3D角点（从相机视角计算）4x3
            image: 相机图像

        Returns:
            T_lidar_cam: 4x4 激光雷达到相机的变换矩阵
        """
        # 步骤1: 检测图像中的棋盘格角点
        ret, img_corners = cv2.findChessboardCorners(
            image, (9, 6), None
        )

        # 步骤2: 亚像素精化
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
        img_corners = cv2.cornerSubPix(
            cv2.cvtColor(image, cv2.COLOR_BGR2GRAY),
            img_corners, (11, 11), (-1, -1), criteria
        )

        # 步骤3: PnP 求解相机位姿
        object_points = np.zeros((9*6, 3), np.float32)
        object_points[:, :2] = np.mgrid[:9, :6].T.reshape(-1, 2) * 0.04
        _, rvec, tvec = cv2.solvePnP(
            object_points, img_corners, self.K, None
        )
        R_cam_board, _ = cv2.Rodrigues(rvec)

        # 步骤4: 找激光点在标定板上的坐标
        # 标定板平面方程: ax + by + cz + d = 0
        normal = R_cam_board[:, 2]  # 标定板法向量
        d = -normal @ (R_cam_board @ np.array([0, 0, 0]) + tvec.flatten())

        # 将激光点投影到标定板平面
        lidar_on_board = []
        for pt in lidar_points:
            t = -(normal @ pt + d) / (normal @ normal)
            proj = pt + t * normal
            lidar_on_board.append(proj)

        lidar_on_board = np.array(lidar_on_board)

        # 步骤5: ICP 匹配
        # 变换到标定板坐标系
        T_cam_board = np.eye(4)
        T_cam_board[:3, :3] = R_cam_board
        T_cam_board[:3, 3] = tvec.flatten()

        T_board_cam = np.linalg.inv(T_cam_board)
        lidar_in_board = (T_board_cam @ np.hstack([lidar_on_board, np.ones((len(lidar_on_board), 1))]).T).T

        # ICP 求解变换
        # ... 简化：使用 SVD 计算最优变换

        return T_cam_lidar

    def project_lidar_to_image(
        self,
        points: np.ndarray,
        image: np.ndarray,
        T_lidar_cam: np.ndarray
    ) -> np.ndarray:
        """将点云投影到图像"""

        # 点云 -> 相机坐标系
        points_cam = (T_lidar_cam @ np.hstack([points, np.ones((len(points), 1))]).T).T

        # 过滤相机前方点
        valid = points_cam[:, 2] > 0
        points_cam = points_cam[valid]

        # 投影到像素
        uv = (self.K @ points_cam[:, :3].T).T
        uv[:, 0] /= uv[:, 2]
        uv[:, 1] /= uv[:, 2]

        return uv[:, :2].astype(np.int32)


def calibrate_automatic(lidar_topic, image_topic):
    """自动标定方法（使用边缘/纹理对齐）"""
    # 等待采集多帧数据后求解
    pass
```

---

## 几何投影融合

### LiDAR → 相机图像投影

```python
import numpy as np
import open3d as o3d
from typing import Tuple, List


class LidarCameraProjector:
    """激光雷达点云投影到图像"""

    def __init__(
        self,
        K: np.ndarray,
        D: np.ndarray,
        R: np.ndarray,
        t: np.ndarray,
        image_width: int,
        image_height: int
    ):
        """
        Args:
            K: 相机内参 3x3
            D: 畸变系数 5x1
            R: 旋转矩阵 (lidar -> camera) 3x3
            t: 平移向量 (lidar -> camera) 3x1
        """
        self.K = K
        self.D = D
        self.R = R
        self.t = t
        self.width = image_width
        self.height = image_height

        # 构建投影矩阵
        self.extrinsic = np.hstack([R, t])

        # 畸变校正映射
        self.map1, self.map2 = cv2.initUndistortRectifyMap(
            K, D, np.eye(3), K, (image_width, image_height), cv2.CV_16SC2
        )

    def project(self, cloud: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        将点云投影到图像平面

        Args:
            cloud: Nx3 点云 (lidar坐标系)

        Returns:
            uv: Nx2 像素坐标
            depth: N 对应深度
        """
        # 变换到相机坐标系
        cloud_hom = np.hstack([cloud, np.ones((len(cloud), 1))])  # Nx4
        cloud_cam = (self.extrinsic @ cloud_hom.T).T  # Nx3

        # 过滤后方点
        valid = cloud_cam[:, 2] > 0
        cloud_cam = cloud_cam[valid]

        # 去畸变
        cloud_undist = cv2.undistortPoints(
            cloud_cam[:, :2], self.K, self.D, P=self.K
        )

        # 投影
        x = cloud_undist[:, 0, 0]
        y = cloud_undist[:, 0, 1]
        z = cloud_cam[:, 2]

        # 透视投影
        u = self.K[0, 0] * x / z + self.K[0, 2]
        v = self.K[1, 1] * y / z + self.K[1, 2]

        # 过滤图像范围外
        in_image = (u >= 0) & (u < self.width) & (v >= 0) & (v < self.height)

        uv = np.column_stack([u[in_image], v[in_image]]).astype(np.int32)
        depth = z[in_image]

        return uv, depth

    def create_depth_image(self, cloud: np.ndarray) -> np.ndarray:
        """创建稠密深度图"""
        depth_img = np.zeros((self.height, self.width), dtype=np.float32)

        uv, depth = self.project(cloud)

        for (u, v), d in zip(uv, depth):
            if depth_img[v, u] == 0 or depth_img[v, u] > d:
                depth_img[v, u] = d

        return depth_img
```

---

## 深度学习融合检测

### PointPillars + 图像融合

```python
import torch
import torch.nn as nn
import numpy as np


class PointPillarsBackbone(nn.Module):
    """PointPillars 特征提取（简化版）"""

    def __init__(self, in_channels=64):
        super().__init__()
        self.pillar_encode = nn.Conv1d(in_channels, 128, 1)
        self.scales = nn.Sequential(
            nn.Conv2d(128, 128, 3, padding=1, stride=2),
            nn.BatchNorm2d(128),
            nn.ReLU(),
            nn.Conv2d(128, 256, 3, padding=1),
        )

    def forward(self, pillars, coordinates, batch_size=1):
        # pillars: (num_points, channels)
        x = self.pillar_encode(pillars.t())  # (channels, num_points)
        x = x.unsqueeze(0).unsqueeze(0)  # placeholder
        return x


class Fusion3DDetector(nn.Module):
    """融合检测器：PointPillars + 图像"""

    def __init__(self):
        super().__init__()

        # 点云分支
        self.pillar_backbone = PointPillarsBackbone()

        # 图像分支
        self.image_backbone = nn.Sequential(
            nn.Conv2d(3, 64, 7, stride=2, padding=3),
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.Conv2d(64, 128, 3, stride=2, padding=1),
            nn.Conv2d(128, 256, 3, padding=1),
        )

        # 融合模块
        self.fusion_conv = nn.Conv2d(256 + 128, 256, 3, padding=1)

        # 检测头
        self.bbox_head = nn.Conv2d(256, 7, 1)  # (x, y, z, h, w, l, rot)
        self.conf_head = nn.Conv2d(256, 1, 1)

    def forward(self, pillars, image):
        # 点云特征
        lidar_feat = self.pillar_backbone(pillars)

        # 图像特征
        img_feat = self.image_backbone(image)

        # 上采样对齐尺寸
        img_feat = torch.nn.functional.interpolate(
            img_feat, size=lidar_feat.shape[-2:], mode='bilinear'
        )

        # 融合
        fused = torch.cat([lidar_feat, img_feat], dim=1)
        fused = self.fusion_conv(fused)

        # 检测
        bbox = self.bbox_head(fused)
        confidence = torch.sigmoid(self.conf_head(fused))

        return {'bbox': bbox, 'confidence': confidence}


def inference_pointcloud_and_image(detector, pcd, image):
    """推理接口"""
    # 预处理
    pillars = preprocess_pointcloud(pcd)  # Nx64
    img_tensor = torch.from_numpy(image).permute(2, 0, 1).unsqueeze(0).float() / 255.0

    with torch.no_grad():
        outputs = detector(pillars, img_tensor)

    return postprocess_detections(outputs)
```

### Late Fusion（检测结果融合）

```python
from dataclasses import dataclass
from typing import List


@dataclass
class Detection2D:
    bbox: List[float]  # [x1, y1, x2, y2]
    score: float
    class_id: int


@dataclass
class Detection3D:
    position: np.ndarray  # 3D位置
    size: np.ndarray      # (h, w, l)
    orientation: float     # 朝向角
    score: float
    class_id: int
    associated_2d: Detection2D = None


class LateFusionDetector:
    """后融合方案：各自检测后再融合"""

    def __init__(self):
        self.lidar_detector = None  # 点云3D检测器
        self.image_detector = None  # 图像2D检测器

    def fuse(self, cloud, image) -> List[Detection3D]:
        # 1. 各自独立检测
        lidar_detections = self.lidar_detector.detect(cloud)  # List[Detection3D]
        image_detections = self.image_detector.detect(image)  # List[Detection2D]

        # 2. 几何关联：将2D框投影到3D空间
        fused = []
        for det_3d in lidar_detections:
            # 投影3D框到图像
            projected_2d = self.project_3d_to_2d(det_3d)

            # 匹配2D检测
            matched_2d = self.match_2d(projected_2d, image_detections)

            if matched_2d:
                det_3d.associated_2d = matched_2d
                det_3d.score = 0.5 * det_3d.score + 0.5 * matched_2d.score  # 分数融合
                det_3d.class_id = matched_2d.class_id  # 用图像分类

            fused.append(det_3d)

        return fused

    def project_3d_to_2d(self, det: Detection3D) -> List[float]:
        # 将3D边界框角点投影到2D图像
        corners = self.compute_box_corners(det)
        uv = self.projector.project(corners)
        x1, y1 = uv.min(axis=0)
        x2, y2 = uv.max(axis=0)
        return [x1, y1, x2, y2]

    def match_2d(self, projected: List[float], image_dets: List[Detection2D]) -> Detection2D:
        # IoU 匹配
        best_iou = 0.3
        best_det = None
        for det in image_dets:
            iou = self.compute_iou(projected, det.bbox)
            if iou > best_iou:
                best_iou = iou
                best_det = det
        return best_det

    @staticmethod
    def compute_iou(box1, box2):
        x1 = max(box1[0], box2[0])
        y1 = max(box1[1], box2[1])
        x2 = min(box1[2], box2[2])
        y2 = min(box1[3], box2[3])
        inter = max(0, x2 - x1) * max(0, y2 - y1)
        area1 = (box1[2] - box1[0]) * (box1[3] - box1[1])
        area2 = (box2[2] - box2[0]) * (box3[3] - box2[1])
        return inter / (area1 + area2 - inter)
```

---

## ROS2 融合节点

### 融合检测发布节点

```python
#!/usr/bin/env python3
"""激光-相机融合3D检测节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, PointCloud2
from vision_msgs.msg import Detection3DArray
import numpy as np
import torch


class FusionDetectionNode(Node):
    def __init__(self):
        super().__init__('fusion_detection')

        # 参数
        self.declare_parameter('conf_threshold', 0.3)
        self.declare_parameter('nms_iou_threshold', 0.5)

        # 融合检测器
        self.detector = Fusion3DDetector()
        # self.detector.load_weights('/path/to/weights.pth')

        # 订阅
        self.cloud_sub = self.create_subscription(
            PointCloud2, '/velodyne_points', self.cloud_callback, 10
        )
        self.image_sub = self.create_subscription(
            Image, '/camera/color/image_raw', self.image_callback, 10
        )

        # 发布
        self.det_pub = self.create_publisher(
            Detection3DArray, '/detections_3d_fused', 10
        )

        self.get_logger().info('Fusion Detection Node ready')

    def cloud_callback(self, msg: PointCloud2):
        # 点云已收到，等待图像
        self.latest_cloud = msg

    def image_callback(self, msg: Image):
        # 同步检测
        if not hasattr(self, 'latest_cloud'):
            return

        # 预处理
        cloud = self.pointcloud2_to_array(self.latest_cloud)
        image = self.image_to_array(msg)

        # 检测
        detections = self.detector.detect(cloud, image)

        # 发布
        det_array = self.to_ros_msg(detections)
        self.det_pub.publish(det_array)

    def pointcloud2_to_array(self, cloud: PointCloud2) -> np.ndarray:
        # PointCloud2 -> Nx3 numpy
        import sensor_msgs.py3 as point_cloud
        pc = point_cloud.read_points(cloud, field_names=("x", "y", "z"), skip_nans=True)
        return np.array(list(pc), dtype=np.float32)

    def image_to_array(self, image: Image) -> np.ndarray:
        from cv_bridge import CvBridge
        bridge = CvBridge()
        return bridge.imgmsg_to_cv2(image, desired_encoding='bgr8')

    def to_ros_msg(self, detections):
        # 转换为 ROS2 Detection3DArray
        msg = Detection3DArray()
        for det in detections:
            det3d = Detection3D()
            det3d.bbox.center.position.x = det.position[0]
            det3d.bbox.center.position.y = det.position[1]
            det3d.bbox.center.position.z = det.position[2]
            det3d.bbox.size.x, det3d.bbox.size.y, det3d.bbox.size.z = det.size
            msg.detections.append(det3d)
        return msg


def main(args=None):
    rclpy.init(args=args)
    node = FusionDetectionNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 投影偏差大 | 外参标定错误 | 重新标定，验证 R/t 矩阵 |
| 深度图有空洞 | 点云稀疏 | 使用双边滤波插值或上采样 |
| 融合检测漏检 | 同步失败 | 检查时间戳同步，添加缓冲 |
| 内存爆炸 | 点云处理过大 | 体素化下采样（voxel_size=0.1） |
| GPU 显存不足 | 模型太大 | 减小 batch size，量化 INT8 |

### 调试命令

```bash
# 查看投影效果
ros2 run image_view image_view image:=/lidar_projected_image

# 标定结果验证
ros2 run calibration_camera_lidar viewExtrinsics

# 点云和图像同步检查
ros2 topic hz /velodyne_points /camera/color/image_raw

# RViz 可视化
ros2 run rviz2 rviz2 -d fusion.rviz
# 添加: PointCloud2 + Image + Detection3D
```

---

## 相关技能

- `perception/kalman-filtering` — 卡尔曼滤波状态估计
- `perception/lidar-perception` — 激光雷达感知
- `perception/vision-perception` — 视觉感知
- `perception/sensor-fusion/multi-object-tracking` — 多目标跟踪
- `perception/sensor-fusion/spatial-temporal-sync` — 时空同步
- `perception/edge-inference/tensorrt-deployment` — TensorRT 推理加速
