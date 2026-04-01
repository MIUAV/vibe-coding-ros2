---
name: perception
description: 人形机器人感知系统 - 双目视觉、深度感知、触觉传感器、平衡感知
argument-hint: "人形感知" / "人形视觉" / "平衡感知" / "触觉"
user-invocable: true
---

# 人形机器人感知技能

> 用于配置和开发人形机器人的感知系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置双目视觉
- 实现深度感知
- 触觉反馈系统
- 平衡感知融合

---

## 快速参考

### 感知配置

```yaml
humanoid_perception:
  # 双目相机
  stereo_camera:
    type: realsense_d435i / zed2 / duo3d
    topics: [/stereo/left/image, /stereo/right/image]
    
  # IMU (平衡感知)
  imu:
    type: BMI160 / BMI088
    topics: [/imu/data, /imu/filtered]
    
  # 力矩传感器
  ft_sensor:
    topics: [/force_torque/left_foot, /force_torque/right_foot]
```

---

## 双目视觉

### 深度感知

```python
class HumanoidDepthPerception:
    def __init__(self):
        self.stereo = StereoCamera("/stereo")
        self.depth_filter = KalmanFilter()
        
    def get_depth(self, point_left, point_right):
        # 三角测量获取深度
        baseline = 0.12  # m
        focal_length = 800  # pixels
        
        disparity = abs(point_left.x - point_right.x)
        depth = focal_length * baseline / disparity
        
        return self.depth_filter.update(depth)
```

---

## 平衡感知

### ZMP 检测

```python
class BalancePerception:
    def __init__(self):
        self.ft_sensors = ForceTorqueSensor(['left_foot', 'right_foot'])
        self.imu = IMUSensor()
        
    def compute_zmp(self):
        """计算零力矩点"""
        forces = self.ft_sensors.get_forces()
        torques = self.ft_sensors.get_torques()
        
        # ZMP 公式
        F_total = sum(forces)
        x_zmp = sum(torques_y) / F_total.z
        y_zmp = -sum(torques_x) / F_total.z
        
        return np.array([x_zmp, y_zmp])
        
    def check_stability(self):
        """稳定性检测"""
        zmp = self.compute_zmp()
        support_polygon = self.compute_support_polygon()
        
        return self.point_in_polygon(zmp, support_polygon)
```

---

## 相关文档

- `./humanoid/localization/SKILL.md` - 定位系统
- `./humanoid/navigation/SKILL.md` - 导航系统
- `./humanoid/skill-planning/SKILL.md` - 技能规划
