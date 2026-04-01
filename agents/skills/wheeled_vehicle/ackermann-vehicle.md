---
name: wheeled-ackermann
description: 阿克曼底盘轮式车辆开发 - 运动控制、SLAM建图、导航避障
argument-hint: "ROSMASTER" / "阿克曼底盘" / "轮式车辆导航" / "激光雷达"
user-invocable: true
---

# 阿克曼底盘轮式车辆技能

> 基于亚博 ROSMASTER R2 等阿克曼底盘机器人的开发指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置阿克曼底盘运动模型
- SLAM 建图
- 导航避障
- 视觉识别

---

## 快速参考

### 底盘参数

```yaml
chassis:
  type: ackermann
  wheelbase: 0.4      # 轴距 (m)
  track_width: 0.3    # 轮距 (m)
  wheel_radius: 0.1   # 轮子半径 (m)
  max_steer: 30      # 最大转向角 (度)
```

---

## 运动模型

### 阿克曼运动学

```python
class AckermannModel:
    def __init__(self, wheelbase, track_width):
        self.L = wheelbase
        self.T = track_width
        
    def forward(self, v, delta):
        """运动学正算"""
        # v: 前进速度
        # delta: 前轮转向角
        
        # 转向半径
        R = self.L / tan(delta)
        
        # 角速度
        omega = v / R
        
        return v, omega
        
    def inverse(self, v, omega):
        """运动学逆算"""
        # 计算转向角
        R = v / omega if omega != 0 else float('inf')
        delta = atan(self.L / R)
        
        return delta
```

---

## ROS2 控制

### 安装驱动

```bash
# 安装 rosmaster 驱动
sudo apt install ros-humble-rosmaster

# 或从源码安装
git clone https://github.com/yahboom/rosmaster.git
cd rosmaster
colcon build
```

### 订阅话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/odom` | `nav_msgs/Odometry` | 里程计 |
| `/imu` | `sensor_msgs/Imu` | IMU 数据 |
| `/scan` | `sensor_msgs/LaserScan` | 激光雷达 |
| `/camera/image` | `sensor_msgs/Image` | 相机图像 |

### 发布命令

| 话题 | 类型 | 说明 |
|------|------|------|
| `/cmd_vel` | `geometry_msgs/Twist` | 速度命令 |

---

## SLAM 建图

### 激光雷达建图

```bash
# gmapping
ros2 launch slam_toolbox online_async_launch.py slam_params_file:=./params.yaml

# cartographer
ros2 launch cartographer_ros cartographer.launch.py \\
    configuration_directory:=./config \\
    configuration_basename:=.lua
```

### 配置参数

```yaml
slam:
  laser_topic: /scan
  odom_topic: /odom
  
  # gmapping 参数
  max_range: 30.0
  max_update_rate: 10.0
  transform_tolerance: 0.1
```

---

## 导航避障

### Navigation2 配置

```bash
# 启动导航
ros2 launch nav2_bringup navigation_launch.py \\
    params_file:=./params.yaml
```

### 规划器配置

```yaml
planner:
  type: "GridBased"
  plugin: "nav2_navfn_planner/NavfnPlanner"
  
controller:
  type: "DWBCtrl"
  plugin: "dwb_core/DWBLocalPlanner"
  
  # TEB 局部规划 (推荐阿克曼)
  teb:
    type: "TebLocalPlanner"
    plugin: "teb_local_planner/TebLocalPlannerROS"
```

### 阿克曼专用参数

```yaml
robot_type: ackermann

# 运动约束
Robot:
  min_turning_radius: 0.4
  max_steering_angle: 0.52  # 30度
```

---

## 视觉应用

### 深度相机

```bash
# Astra 相机
ros2 launch astra_camera astra.launch.py

# ORB_SLAM2
ros2 run orb_slam2_ros orb_slam2_rgbdl params.yaml
```

### 目标检测

```bash
# YOLOv5 检测
ros2 run yolov5 yolov5_node

# 巡线自动驾驶
ros2 run line_follow line_follow_node
```

---

## 仿真

### Gazebo 仿真

```bash
# 启动仿真
ros2 launch rosmaster_gazebo r2l_robot.launch.py

# 控制
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

---

## 常见问题

### 建图偏移

1. 调整雷达频率参数
2. 检查里程计精度
3. 优化雷达安装位置

### 导航失败

1. 检查地图质量
2. 调整定位参数
3. 减小规划范围

---

## 相关文档

- [ROSMASTER R2 教程](https://www.yahboom.com/study/ROSMASTER-R2)
- [Navigation2](https://navigation.ros.org/)
- [SLAM Toolbox](https://github.com/SteveMacenski/slam_toolbox)