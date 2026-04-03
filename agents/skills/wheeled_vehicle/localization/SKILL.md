---
name: localization
description: 轮式车辆定位系统 - GNSS/RTK、SLAM、IMU融合、里程计
argument-hint: 车辆定位 OR GPS定位 OR 车辆SLAM OR RTK
user-invocable: true
---

# 轮式车辆定位技能

> 用于开发轮式车辆的定位和地图系统

---

## 何时使用

当需要以下帮助时使用此技能：
- GNSS/RTK 定位
- 激光雷达 SLAM
- 多传感器融合
- 车辆里程计

---

## 快速参考

### 定位配置

```yaml
wheeled_vehicle_localization:
  # GPS/RTK
  gnss:
    type: ublox / septentrio
    rtk_base: local  # 或 NTRIP
    
  # SLAM
  slam:
    type: lio_sam / FAST_LIO / cartographer
    
  # 融合
  fusion:
    method: ekf / ukf
    sensors: [gnss, lidar, imu, wheel_odom]
```

---

## GNSS/RTK 定位

### RTK 配置

```python
class RTKLocalization:
    def __init__(self):
        self.gnss = GNSSReceiver('/dev/ttyGNSS')
        self.rtk_base = NTRIPClient('rtk.base.com', 2101)
        
    def get_pose(self):
        """获取 RTK 定位"""
        gnss_data = self.gnss.read()
        
        if gnss_data.rtk_status == 'FIXED':
            # RTK 固定解
            return self.enu_to_xy(gnss_data.position)
        else:
            # 标准 GPS
            return self.enu_to_xy(gnss_data.position, accuracy=3.0)
```

---

## 传感器融合

### EKF 融合

```python
class VehicleEKF:
    def __init__(self):
        self.state_dim = 6  # x, y, z, roll, pitch, yaw
        self.ekf = ExtendedKalmanFilter(self.state_dim)
        
        # 状态转移矩阵
        self.F = np.eye(6)
        
    def predict(self, dt, v, omega):
        """预测步骤"""
        self.F[0, 2] = -v * sin(self.state[5]) * dt
        self.F[1, 2] = v * cos(self.state[5]) * dt
        
        self.ekf.predict(self.F)
        
    def update_gnss(self, gnss_pose):
        """GPS 更新"""
        H = np.eye(2, 6)
        R = np.diag([0.1, 0.1])  # GPS 噪声
        
        self.ekf.update(gnss_pose, H, R)
```

---

## 相关文档

- `./wheeled_vehicle/perception/SKILL.md` - 感知系统
- `./wheeled_vehicle/navigation/SKILL.md` - 导航系统
- `./wheeled_vehicle/action/SKILL.md` - 运动控制
