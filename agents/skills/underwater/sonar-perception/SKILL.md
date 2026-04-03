---
name: underwater-sonar-perception
description: 声呐感知技能 - 前视声呐、侧扫声呐、多波束声呐、目标检测、SLAM、ROS2 集成
argument-hint: "声呐" / "sonar" / "水下感知" / "前视声呐" / "多波束" / "AUV"
user-invocable: true
---

# 声呐感知技能

> 用于开发水下机器人的声呐感知系统，涵盖前视声呐(Forward-Looking sonar)、侧扫声呐(Side-Scan)、多波束声呐、目标检测和 ROS2 集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置和标定前视声呐
- 声呐图像处理和目标检测
- 声呐 SLAM 和地图构建
- 水下定位和障碍规避
- 声呐-视觉融合

---

## 快速参考

### 声呐类型

```
声呐类型:
├── 前视声呐 (FLS/sonar) → 主动发射，扇形扫描，2D/3D成像
├── 侧扫声呐 (SSS) → 拖曳式，条带图像，地形测绘
├── 多波束测深声呐 (MBES) → 3D点云，高精度地形
└── 声学调制解调器 (Modem) → 通信用，非成像
```

### 声呐参数

```yaml
sonar:
  frequency: 675 kHz        # 工作频率
  range: 50 m              # 最大探测距离
  resolution: 0.01 m      # 距离分辨率
  field_of_view: 120°      # 水平波束宽度
  ping_rate: 30 Hz         # 扫描频率
  beam_count: 512          # 波束数量
```

### ROS2 依赖

```bash
sudo apt install -y ros-humble-pointcloud-to-laserscan
```

---

## 前视声呐 (Forward-Looking Sonar)

### 工作原理

```
发射器 → 声波 → 障碍物 → 反射 → 接收器
         ↓
      扇形扫描区域 (120° x 20°)
```

### 声呐图像表示

```python
import numpy as np
from dataclasses import dataclass
from typing import List, Tuple


@dataclass
class SonarBeam:
    """单个声呐波束"""
    angle: float          # 波束角度 (rad)
    ranges: np.ndarray    # 每个采样点的距离
    intensities: np.ndarray  # 回波强度 (dB)
    timestamp: float      # 时间戳


class SonarImage:
    """声呐图像"""

    def __init__(
        self,
        beams: List[SonarBeam],
        sonar_pose: np.ndarray,  # 声呐位置姿态
        range_max: float,
        beam_count: int
    ):
        self.beams = beams
        self.sonar_pose = sonar_pose
        self.range_max = range_max
        self.beam_count = beam_count

        # 极坐标 → 直角坐标 图像
        self.cartesian_image = self._polar_to_cartesian()

    def _polar_to_cartesian(self, resolution: float = 0.01) -> np.ndarray:
        """将极坐标声呐图像转换为笛卡尔坐标图像"""
        # 图像尺寸
        img_size = int(2 * self.range_max / resolution)
        image = np.zeros((img_size, img_size), dtype=np.float32)

        for beam in self.beams:
            angle = beam.angle
            for r, intensity in zip(beam.ranges, beam.intensities):
                if r < self.range_max and r > 0:
                    x = int(r * np.cos(angle) / resolution) + img_size // 2
                    y = int(r * np.sin(angle) / resolution) + img_size // 2
                    if 0 <= x < img_size and 0 <= y < img_size:
                        image[y, x] = intensity

        return image


class SonarSimulator:
    """声呐仿真器"""

    def __init__(
        self,
        range_max: float = 50.0,
        beam_count: int = 512,
        fov: float = np.pi * 2 / 3,  # 120 度
        frequency: float = 675e3
    ):
        self.range_max = range_max
        self.beam_count = beam_count
        self.fov = fov
        self.frequency = frequency

        # 声速 (m/s, 淡水)
        self.sound_speed = 1480.0

        # 分辨率
        self.range_resolution = self.sound_speed / (2 * self.frequency)

    def simulate(
        self,
        robot_pose: np.ndarray,
        obstacles: List[Tuple[np.ndarray, float]]
    ) -> SonarImage:
        """
        仿真声呐图像

        Args:
            robot_pose: 机器人位置 [x, y, z, roll, pitch, yaw]
            obstacles: [(position, radius), ...] 障碍物列表

        Returns:
            模拟的声呐图像
        """
        beams = []
        angle_step = self.fov / self.beam_count
        start_angle = -self.fov / 2

        for i in range(self.beam_count):
            angle = start_angle + i * angle_step
            ranges = []
            intensities = []

            # 发射方向
            direction = np.array([
                np.cos(angle),
                np.sin(angle),
                0
            ])

            # 检测障碍物
            for obs_pos, obs_radius in obstacles:
                # 计算相对位置
                rel_pos = obs_pos - robot_pose[:3]

                # 计算在波束方向上的投影
                projection = np.dot(rel_pos, direction)

                if projection < 0:
                    continue  # 障碍在后方

                # 计算到障碍的距离
                perp_dist = np.linalg.norm(
                    rel_pos - projection * direction
                )

                if perp_dist > obs_radius:
                    continue  # 不在波束内

                # 计算命中点
                hit_dist = projection - np.sqrt(obs_radius**2 - perp_dist**2)

                if 0 < hit_dist < self.range_max:
                    # 回波强度（简化）
                    intensity = 20 * np.log10(obs_radius / hit_dist + 0.01)
                    intensity = max(0, min(255, intensity + 100))

                    ranges.append(hit_dist)
                    intensities.append(intensity)

            if not ranges:
                ranges.append(self.range_max)
                intensities.append(0)

            beams.append(SonarBeam(
                angle=angle,
                ranges=np.array(ranges),
                intensities=np.array(intensities),
                timestamp=0.0
            ))

        return SonarImage(beams, robot_pose, self.range_max, self.beam_count)
```

---

## 声呐图像处理

### 目标检测

```python
import numpy as np
import cv2
from scipy import ndimage


class SonarDetector:
    """声呐目标检测"""

    def __init__(self, min_blob_size: int = 5):
        self.min_blob_size = min_blob_size

    def detect(
        self,
        sonar_image: np.ndarray,
        threshold: float = 100.0
    ) -> List[Tuple[float, float, float]]:
        """
        检测声呐图像中的目标

        Returns:
            [(x, y, radius), ...] 目标位置和大小
        """
        # 阈值化
        binary = (sonar_image > threshold).astype(np.uint8)

        # 连通域分析
        labeled, num_features = ndimage.label(binary)
        centers = ndimage.center_of_mass(
            sonar_image, labeled, range(1, num_features + 1)
        )

        # 计算大小
        targets = []
        for i, center in enumerate(centers):
            y, x = int(center[0]), int(center[1])

            # 找目标边界
            blob_mask = labeled == (i + 1)
            ys, xs = np.where(blob_mask)
            radius = max(
                (xs.max() - xs.min()) / 2,
                (ys.max() - ys.min()) / 2
            )

            if radius >= self.min_blob_size:
                targets.append((
                    (x - sonar_image.shape[1] // 2) * 0.01,  # 转换为米
                    (y - sonar_image.shape[0] // 2) * 0.01,
                    radius * 0.01
                ))

        return targets


class SonarFilter:
    """声呐图像滤波"""

    @staticmethod
    def median_filter(image: np.ndarray, kernel_size: int = 5) -> np.ndarray:
        """中值滤波"""
        return cv2.medianBlur(image.astype(np.uint8), kernel_size)

    @staticmethod
    def bilateral_filter(
        image: np.ndarray,
        d: int = 9,
        sigma_color: float = 75,
        sigma_space: float = 75
    ) -> np.ndarray:
        """双边滤波（保边）"""
        return cv2.bilateralFilter(image.astype(np.uint8), d, sigma_color, sigma_space)

    @staticmethod
    def adaptive_threshold(
        image: np.ndarray,
        block_size: int = 21,
        c: float = 10
    ) -> np.ndarray:
        """自适应阈值"""
        return cv2.adaptiveThreshold(
            image.astype(np.uint8), 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            block_size, c
        )

    @staticmethod
    def morphological_close(image: np.ndarray, kernel_size: int = 5) -> np.ndarray:
        """形态学闭运算（填充空洞）"""
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))
        return cv2.morphologyEx(image, cv2.MORPH_CLOSE, kernel)
```

---

## 声呐 SLAM

```python
import numpy as np
from typing import List, Tuple, Optional


class SonarICP:
    """
    声呐点云 ICP 匹配

    用于声呐 SLAM 的扫描匹配
    """

    def __init__(self, max_iterations: int = 50):
        self.max_iterations = max_iterations
        self.max_distance = 0.5  # 匹配阈值 (m)

    def align(
        self,
        source: np.ndarray,
        target: np.ndarray,
        initial_transform: np.ndarray = np.eye(3)
    ) -> Tuple[np.ndarray, float]:
        """
        ICP 对齐

        Args:
            source: 源点云 Nx2
            target: 目标点云 Mx2
            initial_transform: 初始变换矩阵 3x3

        Returns:
            (transform, fitness_score)
        """
        T = initial_transform.copy()
        prev_error = float('inf')

        for iteration in range(self.max_iterations):
            # 步骤1: 用当前变换变换源点云
            source_transformed = (T[:2, :2] @ source.T).T + T[:2, 2]

            # 步骤2: 找最近邻
            indices = self._nearest_neighbor(source_transformed, target)

            # 步骤3: 过滤远距离匹配
            distances = np.linalg.norm(source_transformed - target[indices], axis=1)
            valid = distances < self.max_distance

            if np.sum(valid) < 10:
                break  # 匹配点太少

            # 步骤4: SVD 计算最优变换
            source_valid = source_transformed[valid]
            target_valid = target[indices[valid]]

            centroid_s = np.mean(source_valid, axis=0)
            centroid_t = np.mean(target_valid, axis=0)

            ss = (source_valid - centroid_s).T @ (target_valid - centroid_t)
            U, _, Vt = np.linalg.svd(ss)
            R = Vt.T @ U.T

            if np.linalg.det(R) < 0:
                Vt[-1, :] *= -1
                R = Vt.T @ U.T

            t = centroid_t - R @ centroid_s

            # 更新变换
            T_new = np.eye(3)
            T_new[:2, :2] = R
            T_new[:2, 2] = t

            # 计算误差
            error = np.mean(distances[valid])

            if error < prev_error:
                T = T_new
                prev_error = error
            else:
                break  # 误差增大，停止

        # 计算 fitness score
        source_transformed = (T[:2, :2] @ source.T).T + T[:2, 2]
        distances = np.linalg.norm(source_transformed - target[indices], axis=1)
        fitness = np.mean(distances[distances < self.max_distance])

        return T, fitness

    @staticmethod
    def _nearest_neighbor(source: np.ndarray, target: np.ndarray) -> np.ndarray:
        """找最近邻"""
        from scipy.spatial import KDTree
        tree = KDTree(target)
        distances, indices = tree.query(source)
        return indices


class SonarSLAM:
    """声呐 SLAM（简化版）"""

    def __init__(self):
        self.scans = []  # 声呐扫描历史
        self.poses = []  # 机器人轨迹
        self.map_resolution = 0.05  # 5cm
        self.map_size = (2000, 2000)  # 100m x 100m

        # 占据栅格地图
        self.occupancy = np.zeros(self.map_size, dtype=np.float32)
        self.occupancy_prob = 0.7  # 占据概率

    def add_scan(self, scan: np.ndarray, odometry: np.ndarray):
        """
        添加新的声呐扫描

        Args:
            scan: 声呐点云 Nx2
            odometry: 里程计变化 [dx, dy, dtheta]
        """
        if not self.poses:
            # 第一个扫描
            pose = np.array([self.map_size[0] // 2, self.map_size[1] // 2, 0])
            self.poses.append(pose)
            self.scans.append(scan)
            return

        # 里程计更新
        last_pose = self.poses[-1]
        new_pose = self._apply_odometry(last_pose, odometry)
        self.poses.append(new_pose)

        # ICP 匹配
        icp = SonarICP()
        T, fitness = icp.align(scan, self.scans[-1])

        if fitness < 0.1:
            # 好匹配，校正位姿
            correction = self._transform_to_correction(T)
            new_pose = self._apply_correction(new_pose, correction)

        # 更新地图
        self._update_map(scan, new_pose)

        self.scans.append(scan)

    def _apply_odometry(self, pose: np.ndarray, odom: np.ndarray) -> np.ndarray:
        """应用里程计"""
        x, y, theta = pose
        dx, dy, dtheta = odom
        new_x = x + dx * np.cos(theta) - dy * np.sin(theta)
        new_y = y + dx * np.sin(theta) + dy * np.cos(theta)
        new_theta = theta + dtheta
        return np.array([new_x, new_y, new_theta])

    def _transform_to_correction(self, T: np.ndarray) -> np.ndarray:
        """ICP 变换 → 校正量"""
        return np.array([T[0, 2], T[1, 2], np.arctan2(T[1, 0], T[0, 0])])

    def _apply_correction(self, pose: np.ndarray, correction: np.ndarray) -> np.ndarray:
        return pose + correction * 0.5  # 阻尼

    def _update_map(self, scan: np.ndarray, pose: np.ndarray):
        """更新占据栅格地图"""
        x, y, theta = pose
        cx, cy = int(x / self.map_resolution), int(y / self.map_resolution)

        for point in scan:
            # 转换到全局坐标
            gx = cx + int(point[0] / self.map_resolution)
            gy = cy + int(point[1] / self.map_resolution)

            if 0 <= gx < self.map_size[0] and 0 <= gy < self.map_size[1]:
                # 占据更新
                self.occupancy[gy, gx] += np.log(self.occupancy_prob / (1 - self.occupancy_prob))
```

---

## ROS2 声呐节点

```python
#!/usr/bin/env python3
"""声呐感知节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, PointCloud2
from geometry_msgs.msg import PoseArray, PoseStamped
from nav_msgs.msg import Odometry
import numpy as np
from dataclasses import dataclass


@dataclass
class SonarConfig:
    range_max: float = 50.0
    beam_count: int = 512
    fov: float = 2.094  # 120 度
    frequency: float = 675e3
    frame_id: str = 'sonar_link'


class SonarPerceptionNode(Node):
    def __init__(self):
        super().__init__('sonar_perception')

        self.config = SonarConfig()

        # 检测器
        self.detector = SonarDetector()
        self.slam = SonarSLAM()

        # 状态
        self.last_odom = None
        self.scan_count = 0

        # 订阅
        self.odom_sub = self.create_subscription(
            Odometry,
            '/odom',
            self.odom_callback,
            10
        )

        # 发布
        self.detection_pub = self.create_publisher(
            PoseArray,
            '/sonar/detections',
            10
        )
        self.map_pub = self.create_publisher(
            Image,
            '/sonar/map',
            10
        )

        self.get_logger().info('Sonar Perception Node ready')

    def odom_callback(self, msg: Odometry):
        """处理里程计消息（触发声呐处理）"""
        # 提取声呐数据（实际从声呐硬件获取）
        # 简化：模拟数据
        current_odom = np.array([
            msg.pose.pose.position.x,
            msg.pose.pose.position.y,
            0.0
        ])

        if self.last_odom is not None:
            odom_delta = current_odom - self.last_odom

            # 模拟声呐扫描
            scan = self._simulate_scan(current_odom)

            # 添加到 SLAM
            self.slam.add_scan(scan, odom_delta)

            # 目标检测
            targets = self.detector.detect(self.slam.occupancy)

            # 发布检测结果
            self._publish_detections(targets)

        self.last_odom = current_odom

    def _simulate_scan(self, pose: np.ndarray) -> np.ndarray:
        """模拟声呐扫描"""
        # 简化：返回空点云
        return np.zeros((0, 2))

    def _publish_detections(self, targets):
        """发布检测结果"""
        msg = PoseArray()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'map'

        for x, y, r in targets:
            pose = PoseStamped()
            pose.pose.position.x = x
            pose.pose.position.y = y
            msg.poses.append(pose.pose)

        self.detection_pub.publish(msg)


def main(args=None):
    rclpy.init(args=args)
    node = SonarPerceptionNode()
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
| 声呐图像噪声大 | 水体散射/气泡 | 增加滤波，使用自适应阈值 |
| 目标检测漏检 | 阈值过高 | 降低检测阈值，添加形态学处理 |
| SLAM 漂移大 | ICP 匹配失败 | 减小scan_period，增加特征密度 |
| 声呐数据丢失 | 硬件连接问题 | 检查 Ethernet/USB 连接 |
| 图像畸变 | 坐标系配置错误 | 验证 frame_id 和 TF 变换 |

### 调试命令

```bash
# 查看声呐话题
ros2 topic list | grep sonar

# 监听声呐数据
ros2 topic echo /sonar/image

# 查看声呐可视化
ros2 run rqt_image_view rqt_image_view /sonar/image:=/sonar/rendered

# 录制声呐数据
ros2 bag record /sonar/detections /odom -o sonar_data
```

---

## 相关技能

- `underwater/auv-control` — AUV 控制
- `perception/sensor-fusion/lidar-camera-fusion` — 传感器融合
- `navigation/slam` — SLAM 算法
- `perception/sensor-fusion/multi-object-tracking` — 多目标跟踪
