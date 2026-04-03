---
name: localization
description: 人形机器人定位系统 - SLAM、IMU融合、EKF、GPS/RTK定位
argument-hint: 人形定位 OR 人形SLAM OR 位置估计
user-invocable: true
---

# 人形机器人定位技能

> 用于开发人形机器人的定位和姿态估计系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现室内定位
- 融合多传感器数据
- 估计机器人姿态
- GPS/RTK室外定位

---

## 快速参考

### 定位配置

```yaml
humanoid_localization:
  # 传感器
  sensors:
    - imu: /imu/data
    - camera: /stereo/left/image
    - lidar: /scan
    
  # 滤波方法
  filter: ekf / ukf / particle
  
  # 地图
  map_type: occupancy_grid / pointcloud
```

---

## 姿态估计

### IMU-EKF 融合

```python
class HumanoidPoseEstimator:
    def __init__(self):
        self.imu = IMUSubscriber('/imu/data')
        self.ekf = ExtendedKalmanFilter(state_dim=15)
        
        # 状态: [pos, vel, quat, bias_gyro, bias_accel]
        self.state = np.zeros(15)
        
    def predict(self, dt):
        """预测步骤"""
        # IMU 积分
        self.state[3:6] += self.state[6:9] * dt  # velocity update
        # ... 
        
    def update(self, measurement, measurement_type):
        """更新步骤"""
        if measurement_type == 'vision':
            self.ekf.update_vision(measurement)
        elif measurement_type == 'gps':
            self.ekf.update_gps(measurement)
```

---

## 地图定位

### SLAM 集成

```python
class HumanoidSLAM:
    def __init__(self):
        self.lidar = LaserScanSubscriber('/scan')
        self.occupancy_map = OccupancyGrid(0.05)  # 5cm resolution
        
    def localization_step(self):
        # 扫描匹配
        scan = self.lidar.get_scan()
        pose_hint = self.occupancy_map.match(scan)
        
        return pose_hint
```

---

## 相关文档

- `./humanoid/perception/SKILL.md` - 感知系统
- `./humanoid/navigation/SKILL.md` - 导航系统
- `./humanoid/skill-planning/SKILL.md` - 技能规划
