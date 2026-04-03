---
name: laser-slam
description: 激光 SLAM 技能 - Cartographer、FAST-LIO、Karto、ROS2 SLAM 节点
argument-hint: "激光SLAM" / "Cartographer" / "FAST-LIO" / "laser slam"
user-invocable: true
---

# 激光 SLAM 技能

> 激光雷达 SLAM 算法与 ROS2 实现

---

## 何时使用

当需要以下帮助时使用此技能：
- Cartographer 配置
- FAST-LIO 实现
- 激光里程计
- 栅格地图构建
- 子图管理

---

## 核心实现

### Cartographer ROS2 配置

```yaml
# cartographer.lua
include "map_builder.lua"
include "trajectory_builder.lua"

MAP_BUILDER = {
  num_background_threads = 4,
  publish_batch_period = 0.001,
}

TRAJECTORY_BUILDER_2D = {
  min_range = 0.1,
  max_range = 30.0,
  num_accumulated_range_data = 1,
  
  scan_matcher = {
    occupied_space_weight = 20.0,
    resolution = 0.05,
  },
  
  adaptive_voxel_filter = {
    max_range = 30.0,
    min_num_points = 100,
  },
}

POSE_GRAPH = {
  optimize_every_n_nodes = 90,
  global_constraint_search_after_n_seconds = 10,
}
```

### ROS2 启动

```python
# launch/slam.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='cartographer_ros',
            executable='cartographer_node',
            parameters=[{
                'configuration_directory': '/path/to/config',
                'configuration_basename': 'cartographer.lua',
            }],
            remappings=[
                ('scan', '/scan'),
                ('imu', '/imu'),
            ]
        ),
        
        Node(
            package='cartographer_ros',
            executable='cartographer_occupancy_grid_node',
            parameters=[{
                'resolution': 0.05,
            }]
        )
    ])
```

### FAST-LIO 实现

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2, Imu
from nav_msgs.msg import Odometry
import numpy as np
from scipy.spatial import cKDTree

class FASTLIONode(Node):
    def __init__(self):
        super().__init__('fast_lio')
        
        self.scan_sub = self.create_subscription(
            PointCloud2, '/lidar_points', self.scan_callback, 10)
        self.imu_sub = self.create_subscription(
            Imu, '/imu', self.imu_callback, 10)
            
        self.odom_pub = self.create_publisher(Odometry, '/odom', 10)
        self.map_pub = self.create_publisher(PointCloud2, '/map', 10)
        
        # FAST-LIO 参数
        self.declare_parameter('map_resolution', 0.1)
        self.declare_parameter('max_iterations', 10)
        
        # 状态
        self.T = np.eye(4)  # 当前位姿
        self.map_points = []
        self.kdtree = None
        
    def imu_callback(self, msg):
        # IMU 预积分
        pass
        
    def scan_callback(self, msg):
        # 解析点云
        points = self.parse_pointcloud(msg)
        
        # 降采样
        downsampled = self.voxel_downsample(points, 0.1)
        
        # 配准
        delta_T = self.icp_match(downsampled)
        
        # 更新位姿
        self.T = self.T @ delta_T
        
        # 发布
        self.publish_odom()
        
    def icp_match(self, points):
        """ICP 匹配"""
        # 简化的 ICP
        # 实际使用 IKDFastLCD 或 NDT
        return np.eye(4)
        
    def voxel_downsample(self, points, voxel_size):
        """体素降采样"""
        idx = (points / voxel_size).astype(int)
        _, unique_idx = np.unique(idx, axis=0, return_index=True)
        return points[unique_idx]
```

### 激光里程计

```python
class LaserOdometry:
    def __init__(self):
        self.prev_cloud = None
        self.prev_transform = np.eye(4)
        
    def compute_odometry(self, current_cloud):
        """计算激光里程计"""
        if self.prev_cloud is None:
            self.prev_cloud = current_cloud
            return np.eye(4)
            
        # ICP 匹配
        transform, fitness = self.icp(current_cloud, self.prev_cloud)
        
        self.prev_cloud = current_cloud
        return transform
        
    def icp(self, source, target):
        """ICP 配准"""
        # 使用 PCL 或 Open3D
        # 返回变换矩阵和适应度分数
        return np.eye(4), 1.0
```
