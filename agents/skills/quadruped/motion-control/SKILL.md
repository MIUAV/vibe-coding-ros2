---
name: motion-control
description: 四足机器人运动控制 - 步态规划、平衡控制、力控、关节控制
argument-hint: 四足运动控制 OR 步态控制 OR 平衡 OR 力控
user-invocable: true
---

# 四足机器人运动控制技能

> 用于开发和配置四足机器人的运动控制系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现步态规划
- 配置平衡控制
- 力控开发
- 关节控制

---

## 快速参考

### 步态类型

| 步态 | 特点 | 速度 | 适用场景 |
|------|------|------|----------|
| **Walk** | 对角线顺序 | 慢 | 复杂地形 |
| **Trot** | 对角线同时 | 中 | 普通行走 |
| **Pace** | 同侧同时 | 中 | 平滑地面 |
| **Gallop** | 连续跳跃 | 快 | 奔跑 |
| **Bound** | 前后同时 | 快 | 直线冲刺 |

---

## 步态规划

### 步态周期控制

```python
class GaitPlanner:
    def __init__(self, gait_type='trot'):
        self.gait_type = gait_type
        self.phase = 0.0
        self.step_period = 0.5
        
    def get_foot_contacts(self):
        """返回4个足端的接触状态"""
        if self.gait_type == 'trot':
            # 对角线配对
            return [
                self.phase < 0.5,  # FL
                self.phase >= 0.5,  # FR
                self.phase >= 0.5,  # BL
                self.phase < 0.5   # BR
            ]
        
    def get_foot_positions(self):
        """返回4个足端的目标位置"""
        positions = []
        for i in range(4):
            if self.is_swing_phase(i):
                pos = self.compute_swing_position(i)
            else:
                pos = self.compute_stance_position(i)
            positions.append(pos)
        return positions
```

### 摆动腿轨迹

```python
def swing_trajectory(start, end, t, step_height=0.05):
    """摆动腿的抛物线轨迹"""
    progress = t / step_duration
    
    x = start[0] + (end[0] - start[0]) * progress
    y = start[1] + (end[1] - start[1]) * progress
    
    # 抛物线高度
    z = start[2] + 4 * step_height * progress * (1 - progress)
    
    return [x, y, z]
```

---

## 平衡控制

### 身体姿态控制

```python
class BalanceController:
    def __init__(self):
        self.Kp_pitch = 0.5
        self.Kp_roll = 0.5
        
    def compute_joint_commands(self, imu_data, desired_force):
        """根据IMU数据调整力分配"""
        pitch_correction = imu_data.pitch * self.Kp_pitch
        roll_correction = imu_data.roll * self.Kp_roll
        
        # 调整前后腿力
        front_rear_adjust = pitch_correction * 0.5
        # 调整左右腿力
        left_right_adjust = roll_correction * 0.5
        
        return {
            'front_left': desired_force + front_rear_adjust - left_right_adjust,
            'front_right': desired_force + front_rear_adjust + left_right_adjust,
            'back_left': desired_force - front_rear_adjust - left_right_adjust,
            'back_right': desired_force - front_rear_adjust + left_right_adjust
        }
```

### 触地检测

```python
def detect_contacts(force_sensors, threshold=5.0):
    """检测每条腿是否接触地面"""
    return [fs > threshold for fs in force_sensors]
```

---

## 力控

### 阻抗控制

```python
class ImpedanceController:
    def __init__(self, M, B, K):
        self.M = M  # 惯性矩阵
        self.B = B  # 阻尼矩阵
        self.K = K  # 刚度矩阵
        
    def compute_force(self, pos_error, vel_error, measured_force):
        # F = M*acc + B*vel + K*pos
        desired = self.M @ self.acc_desired + \
                  self.B @ vel_error + \
                  self.K @ pos_error
        return desired - measured_force
```

### 力分配

```python
def force_allocation(total_force, contact_states):
    """根据接触状态分配各腿力"""
    n_contacts = sum(contact_states)
    if n_contacts == 0:
        return [0, 0, 0, 0]
    
    force_per_leg = total_force / n_contacts
    
    return [force_per_leg if contact else 0 
            for contact in contact_states]
```

---

## 关节控制

### 关节控制循环

```python
class JointController:
    def __init__(self, joint_names):
        self.joints = {name: Joint() for name in joint_names}
        self.Kp = 1.0
        self.Kd = 0.1
        
    def control(self, desired_positions, current_positions, dt):
        for name in self.joints:
            error = desired_positions[name] - current_positions[name]
            
            torque = self.Kp * error + \
                    self.Kd * (error - self.prev_error[name]) / dt
            
            self.joints[name].set_torque(torque)
            self.prev_error[name] = error
```

### 逆运动学

```python
def inverse_kinematics(foot_pos, leg_index):
    """计算单腿IK"""
    L1, L2 = 0.1, 0.2  # 上腿和下腿长度
    
    x, y, z = foot_pos
    r = sqrt(x**2 + y**2 + z**2)
    
    # 膝关节角度
    cos_knee = (L1**2 + L2**2 - r**2) / (2 * L1 * L2)
    knee = acos(cos_knee)
    
    # 髋关节角度
    alpha = atan2(z, sqrt(x**2 + y**2))
    beta = acos((r**2 + L1**2 - L2**2) / (2 * L1 * r))
    hip = alpha - beta
    
    return [hip, knee]
```

---

## Unitree SDK 集成

### Python SDK 使用

```python
from unitree_sdk2_python import Go2

# 初始化
robot = Go2()
robot.set_mode("stand")

# 设置速度
robot.move(x=0.5, y=0, yaw=0)

# 读取状态
state = robot.get_state()
print(f"Position: {state.position}")
```

### ROS2 接口

```bash
# 启动 ROS2 控制
ros2 launch unitree_ros2 go2_control.launch.py

# 订阅状态
ros2 topic echo /robot_state

# 发送命令
ros2 topic pub /cmd_vel geometry_msgs/Twist "..."
```

---

## 常用框架

| 框架 | 语言 | 说明 |
|------|------|------|
| **Unitree SDK2** | Python/C++ | 官方SDK |
| **quadruped_control** | Python | 通用控制 |
| **legged_control** | C++ | MIT开源 |

---

## 相关文档

- [Unitree SDK2](https://github.com/unitreerobotics/unitree_sdk2)
- [MIT Cheetah](https://github.com/mit-biomimetics/Cheetah-Software)
- [ROS2 Control](https://control.ros.org/)