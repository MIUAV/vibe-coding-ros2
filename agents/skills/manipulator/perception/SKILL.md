---
name: perception
description: 机械臂感知系统 - 视觉引导、深度感知、力矩感知、触觉反馈
argument-hint: 机械臂感知 OR 视觉引导 OR 力矩感知 OR 触觉
user-invocable: true
---

# 机械臂感知技能

> 用于配置和开发机械臂的感知系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置视觉引导系统
- 实现深度感知抓取
- 力矩传感器融合
- 接触检测

---

## 快速参考

### 感知配置

```yaml
manipulator_perception:
  # 相机
  camera:
    type: realsense / zed / azure_kinect
    topics: [/rgb/image, /depth/image]
    
  # 力矩传感器
  ft_sensor:
    type: ati / robotiq / builtin
    topics: [/ft_sensor/data]
    
  # 触觉数组
  tactile:
    type: biomimetic / gelSight
    topics: [/tactile/array]
```

---

## 视觉感知

### 目标识别与定位

```python
class ManipulatorVision:
    def __init__(self):
        self.camera = RGBCamera('/rgb/image')
        self.depth = DepthCamera('/depth/image')
        self.detector = YOLODetector('grasp_pose.onnx')
        
    def detect_grasp_pose(self):
        """检测抓取姿态"""
        rgb = self.camera.get_image()
        depth = self.depth.get_image()
        
        # 检测物体
        boxes = self.detector.detect(rgb)
        
        # 计算3D位置
        grasp_poses = []
        for box in boxes:
            center = box.center
            z = depth[center.y, center.x]
            pos_3d = self.depth.pixel_to_3d(center, z)
            grasp_poses.append((pos_3d, box.label))
            
        return grasp_poses
```

---

## 力感知

### 力控感知

```python
class ForcePerception:
    def __init__(self):
        self.ft_sensor = ForceTorqueSensor('/ft_sensor/data')
        self.filter = LowPassFilter(30.0)  # 30Hz
        
    def get_task_wrench(self):
        """获取任务空间力/力矩"""
        raw = self.ft_sensor.get_wrench()
        return self.filter.filter(raw)
        
    def detect_collision(self, threshold=10.0):
        """碰撞检测"""
        wrench = self.get_task_wrench()
        return np.linalg.norm(wrench[:3]) > threshold
```

---

## 相关文档

- `./manipulator/localization/SKILL.md` - 定位系统
- `./manipulator/motion-control/SKILL.md` - 运动控制
- `./manipulator/skill-planning/SKILL.md` - 技能规划
