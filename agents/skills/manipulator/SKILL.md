---
name: manipulator
description: 机械臂控制与运动规划 - 逆运动学、轨迹规划、力控、抓取
argument-hint: 机械臂控制 OR 逆运动学 OR 轨迹规划 OR 抓取
user-invocable: true
---

# 机械臂技能

> 用于开发机械臂的运动控制、轨迹规划和抓取系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现逆运动学求解
- 规划无碰撞轨迹
- 配置力控模式
- 视觉引导抓取

---

## 快速参考

### 自由度配置

| 类型 | DOF | 典型用途 |
|------|-----|----------|
| 3-DOF | 基本定位 | 点对点搬运 |
| 4-DOF | 增加姿态 | 门把手操作 |
| 5-DOF | 完整操作 | 抓取+放置 |
| 6-DOF | 完整姿态 | 复杂装配 |
| 7-DOF | 冗余关节 | 避障+灵巧 |

---

## 逆运动学

### 解析法 (6-DOF)

```python
def inverse_kinematics(target_pose):
    """6轴机械臂逆运动学"""
    # 输入: 目标末端位姿 (位置 + 四元数)
    # 输出: 6个关节角度
    
    # 1. 计算腕部位置
    wrist_pos = target_pos - d6 * target_rot[:, 2]
    
    # 2. 计算肩部角度
    theta1 = atan2(wrist_pos[1], wrist_pos[0])
    
    # 3. 计算肘部角度
    # ... (省略具体公式)
    
    # 4. 计算腕部角度
    # ... 
    
    return [theta1, theta2, theta3, theta4, theta5, theta6]
```

### 数值法 (通用)

```python
def ik_numeric(link_lengths, target_pose, initial_guess=None):
    """数值迭代法 IK"""
    if initial_guess is None:
        joints = [0] * len(link_lengths)
    
    for i in range(MAX_ITERATIONS):
        # 正运动学计算当前末端
        current_pose = forward_kinematics(joints, link_lengths)
        
        # 计算误差
        error = target_pose - current_pose
        
        # 雅可比矩阵逆
        J = jacobian(joints, link_lengths)
        delta = pinv(J) @ error
        
        # 更新关节
        joints += delta * learning_rate
        
        if norm(error) < TOLERANCE:
            return joints
            
    return None  # 无解
```

---

## 轨迹规划

### 关节空间规划

```python
def plan_joint_trajectory(start, end, duration, waypoints=50):
    """关节空间五次多项式插值"""
    t = linspace(0, duration, waypoints)
    
    # 五次多项式系数
    q_t = []
    for ti in t:
        # 计算各关节位置、速度、加速度
        qi = quintic_interpolation(start, end, ti, duration)
        q_t.append(qi)
    
    return q_t
```

### 笛卡尔空间规划

```python
def plan_cartesian_trajectory(path_points, max_velocity, max_accel):
    """笛卡尔空间直线/圆弧插补"""
    
    # 1. 速度规划
    velocity_profile = compute_velocity_profile(
        path_points, max_velocity, max_accel)
    
    # 2. 时间参数化
    trajectory = []
    for i, (pos, vel) in enumerate(zip(path_points, velocity_profile)):
        timestamp = compute_time(vel)
        trajectory.append((timestamp, pos, vel))
        
    return trajectory
```

---

## 力控

### 阻抗控制

```python
class ImpedanceController:
    def __init__(self, M, B, K):
        self.M = M  # 目标惯性矩阵
        self.B = B  # 阻尼矩阵
        self.K = K  # 刚度矩阵
        
    def compute_force(self, error, error_dot, measured_force):
        # 阻抗方程: M*acc + B*vel + K*pos = F
        desired_force = self.K @ error + self.B @ error_dot
        
        # 叠加环境力
        total_force = desired_force - measured_force
        
        return total_force
```

### 力矩控制

```python
def force_control(desired_force, measured_force):
    # 简单力跟踪
    error = desired_force - measured_force
    
    # PID 控制
    force_output = Kp * error + Ki * integral(error) + Kd * derivative(error)
    
    return force_output
```

---

## 视觉引导

### 手眼标定

```yaml
hand_eye_calibration:
  method: "Tsai"  # 或 "Park"
  
  transformations:
    base_to_eye: T_base_eye    # 相机到基座
    tool_to_marker: T_tool_mk   # 标定板到末端
    
  calibration_motion:
    - type: joint_motion
      joint_poses: 10           # 标定姿态数
```

### 目标检测与定位

```python
def detect_and_locate(object_class):
    # 1. 检测目标
    bbox = yolo_detect(image, object_class)
    
    # 2. 深度信息
    depth = realsense.get_depth(bbox.center)
    
    # 3. 相机坐标转基座坐标
    point_cam = [bbox.center.x, bbox.center.y, depth]
    point_base = transform(point_cam, T_base_eye)
    
    return point_base
```

---

## 抓取规划

### 抓取点计算

```python
def compute_grasp_points(object_mesh, gripper_width):
    """计算抓取候选点"""
    
    # 1. 分割对象
    parts = segment_mesh(object_mesh)
    
    # 2. 计算对称轴
    axis = compute_symmetry_axis(parts)
    
    # 3. 搜索抓取点
    candidates = []
    for approach_angle in range(0, 360, 15):
        for width in [0.5 * gripper_width, gripper_width]:
            grasp = compute_grasp(parts, approach_angle, width)
            if is_valid_grasp(grasp):
                candidates.append(grasp)
    
    return candidates
```

---

## 常用框架

### ROS 2 功能包

| 包 | 功能 |
|----|------|
| `moveit2` | 运动规划 |
| `ros2_control` | 硬件控制 |
| `manipulator_kinematics` | 运动学求解 |
| `vision_msgs` | 视觉消息 |

### 开源项目

- **MoveIt 2**: https://moveit.ros.org/
- **OpenRave**: http://openrave.org/
- **PyBullet**: https://pybullet.org/

---

## 相关文档

- [MoveIt 2 文档](https://moveit.picknik.ai/)
- [ROS2 Control](https://control.ros.org/)