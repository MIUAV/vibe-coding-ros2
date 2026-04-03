---
name: localization
description: 机械臂定位系统 - 末端执行器定位、工作空间标定、手眼标定
argument-hint: 机械臂定位 OR 手眼标定 OR 末端定位
user-invocable: true
---

# 机械臂定位技能

> 用于开发机械臂的定位和标定系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 末端执行器标定
- 手眼关系标定
- 工作空间映射
- 工具定位

---

## 快速参考

### 标定配置

```yaml
manipulator_calibration:
  # 手眼类型
  eye_to_hand: true  # false = eye in hand
  
  # 标定板
  target:
    type: charuco / checkerboard / aprilgrid
    
  # 末端工具
  tool:
    type: gripper / suction / custom
```

---

## 手眼标定

### Eye-to-Hand 标定

```python
class EyeToHandCalibration:
    def __init__(self, eye_to_hand=True):
        self.eye_to_hand = eye_to_hand
        self.calib_poses = []
        
    def capture_pose(self, robot_pose, camera_pose):
        """采集标定数据"""
        self.calib_poses.append({
            'robot': robot_pose,  # 末端位姿 (6D)
            'camera': camera_pose  # 相机观测位姿
        })
        
    def compute_transform(self):
        """计算手眼关系"""
        # AX = XB 解算
        if self.eye_to_hand:
            # 相机固定, 末端移动
            return self.solve_AX_XB(self.calib_poses)
        else:
            # 相机在手上
            return self.solve_AX_XB(self.calib_poses)
```

---

## 工具标定

### TCP 标定

```python
class TCPCalibration:
    def __init__(self):
        self.poses = []
        
    def calibrate(self, robot, n_poses=8):
        """标定工具中心点"""
        # 移动到不同姿态的固定点
        for i in range(n_poses):
            input("移动到固定点, 按回车继续...")
            pose = robot.get_tcp_pose()
            self.poses.append(pose)
            
        # 计算 TCP
        return self.compute_tcp_from_poses(self.poses)
```

---

## 相关文档

- `./manipulator/perception/SKILL.md` - 感知系统
- `./manipulator/motion-control/SKILL.md` - 运动控制
- `./manipulator/skill-planning/SKILL.md` - 技能规划
