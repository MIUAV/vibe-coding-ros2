---
name: multi-sensor-timesync
description: 多传感器时间同步技能 - 硬件同步、软同步、NTP、ROS2 时间同步
argument-hint: 时间同步 OR hardware sync OR NTP OR timesync
user-invocable: true
---

# 多传感器时间同步技能

> 多传感器时间同步方案

---

## 何时使用

当需要以下帮助时使用此技能：
- 硬件同步配置
- 软件同步实现
- NTP/PTP 同步
- ROS2 同步机制
- 时间戳校正

---

## 核心实现

### 硬件同步

```yaml
# 硬件同步配置 (激光雷达 + 相机)
hardware_config:
  lidar:
    model: Velodyne VLP-16
    mode: phase_lock  # 相位锁定
    sync_frequency: 10  # Hz
    phase_offset: 0.0  # 秒
    
  camera:
    model:_basalt
    trigger_mode: hardware_external
    trigger_delay: 0.002  # 2ms 硬件延迟
    
  gps_imu:
    model: XSens MTi
    sync_mode: time_ins
```

### ROS2 软同步

```python
import rclpy
from rclpy.node import Node
from message_filters import Subscriber, ApproximateTimeSynchronizer
from sensor_msgs.msg import Image, PointCloud2, Imu
from geometry_msgs.msg import PoseWithCovarianceStamped

class MultiSensorSyncNode(Node):
    def __init__(self):
        super().__init__('multi_sensor_sync')
        
        # 创建同步订阅
        self.image_sub = Subscriber(self, Image, '/camera/image_raw')
        self.lidar_sub = Subscriber(self, PointCloud2, '/lidar/points')
        self.imu_sub = Subscriber(self, Imu, '/imu/data')
        self.gps_sub = Subscriber(self, PoseWithCovarianceStamped, '/gps/pose')
        
        # 时间同步器
        self.sync = ApproximateTimeSynchronizer(
            [self.image_sub, self.lidar_sub, self.imu_sub],
            queue_size=20,
            slop=0.05  # 50ms 容差
        )
        self.sync.registerCallback(self.sync_callback)
        
    def sync_callback(self, image, lidar, imu):
        # 时间已对齐
        stamp = image.header.stamp
        
        # 处理同步数据
        self.process_data(image, lidar, imu)
```

### 时间戳校正

```python
import numpy as np

class TimeSynchronizer:
    """软件时间同步"""
    
    def __init__(self, buffer_size=10):
        self.buffer_size = buffer_size
        self.timestamps = {
            'camera': [],
            'lidar': [],
            'imu': []
        }
        self.offsets = {
            'lidar_camera': 0.0,
            'imu_camera': 0.0
        }
        
    def add_timestamp(self, sensor, stamp):
        """添加时间戳"""
        self.timestamps[sensor].append(stamp)
        
        if len(self.timestamps[sensor]) > self.buffer_size:
            self.timestamps[sensor].pop(0)
            
        # 估计偏移
        self.estimate_offset()
        
    def estimate_offset(self):
        """估计传感器间时间偏移"""
        # 互相关估计
        for s1, s2 in [('lidar', 'camera'), ('imu', 'camera')]:
            if len(self.timestamps[s1]) > 5 and len(self.timestamps[s2]) > 5:
                offset = self.compute_offset(
                    self.timestamps[s1], 
                    self.timestamps[s2])
                self.offsets[f'{s1}_{s2}'] = offset
                
    def compute_offset(self, times1, times2):
        """计算时间差"""
        diffs = []
        for t1 in times1:
            closest = min(times2, key=lambda t2: abs(t2 - t1))
            diffs.append(t1 - closest)
        return np.median(diffs)
        
    def sync_data(self, sensor, stamp):
        """同步数据时间戳"""
        # 校正到主时钟
        if sensor == 'lidar':
            return stamp - self.offsets['lidar_camera']
        elif sensor == 'imu':
            return stamp - self.offsets['imu_camera']
        return stamp
```

### PTP 同步

```bash
# 配置 PTP (Precision Time Protocol)
# 交换机需要支持 PTP

# 查看网卡是否支持 PTP
ethtool -T eth0

# 启用 PTP
sudo ptp4l -i eth0 -m &
```
