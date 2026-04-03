---
name: impedance-control
description: 阻抗控制技能 - 导纳控制、阻抗调节、力跟踪、ROS2 力控接口
argument-hint: 阻抗控制 OR impedance OR admittance OR force control
user-invocable: true
---

# 阻抗控制技能

> 机器人阻抗控制实现

---

## 何时使用

当需要以下帮助时使用此技能：
- 阻抗控制
- 导纳控制
- 力跟踪
- 末端柔顺控制
- ROS2 力控接口

---

## 核心实现

### 阻抗控制

```python
import numpy as np

class ImpedanceController:
    def __init__(self, M_d, B_d, K_d):
        """
        期望阻抗参数
        M_d: 期望惯性矩阵
        B_d: 期望阻尼矩阵
        K_d: 期望刚度矩阵
        """
        self.M_d = np.array(M_d)
        self.B_d = np.array(B_d)
        self.K_d = np.array(K_d)
        
    def compute_torque(self, q, q_dot, q_d, q_d_dot, q_d_ddot, F_ext):
        """
        计算控制力矩
        q, q_dot: 当前关节位置和速度
        q_d, q_d_dot, q_d_ddot: 期望轨迹
        F_ext: 外部力
        """
        # 末端位置误差
        e = q_d - q
        e_dot = q_d_dot - q_dot
        
        # 阻抗误差
        M_d_inv = np.linalg.inv(self.M_d)
        tau_impedance = M_d_inv @ (self.K_d @ e + self.B_d @ e_dot)
        
        # 添加外部力补偿
        J = self.compute_jacobian(q)
        tau_feedforward = J.T @ F_ext
        
        return tau_impedance + tau_feedforward
        
    def compute_jacobian(self, q):
        """计算雅可比"""
        # 简化版本
        return np.eye(6)
```

### 导纳控制

```python
class AdmittanceController:
    def __init__(self, M_a, B_a, K_a):
        """
        导纳参数
        """
        self.M_a = np.array(M_a)
        self.B_a = np.array(B_a)
        self.K_a = np.array(K_a)
        
    def compute_velocity(self, F_ext, F_d, e, e_dot):
        """
        根据力误差计算速度
        F_ext: 实际接触力
        F_d: 期望接触力
        e: 位置误差
        e_dot: 速度误差
        """
        # 力误差
        F_error = F_ext - F_d
        
        # 导纳控制
        M_a_inv = np.linalg.inv(self.M_a)
        acc_desired = M_a_inv @ (F_error - self.B_a @ e_dot - self.K_a @ e)
        
        # 速度积分
        v_desired = np.zeros(6)  # 积分初始化
        
        return v_desired
        
    def update_pose(self, pose, v, dt):
        """更新末端位姿"""
        pose_new = pose.copy()
        pose_new[:3, 3] += v[:3] * dt
        
        # 速度积分转旋转
        delta_rpy = v[3:] * dt
        # 更新旋转...
        
        return pose_new
```

### ROS2 力控接口

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Wrench
from sensor_msgs.msg import JointState

class ForceControlNode(Node):
    def __init__(self):
        super().__init__('force_control')
        
        # 力矩发布
        self.torque_pub = self.create_publisher(
            JointState, '/joint_group_effort_controller/command', 10)
            
        # 力传感器订阅
        self.force_sub = self.create_subscription(
            Wrench, '/wrench', self.force_callback, 10)
            
        self.impedance = ImpedanceController(
            M_d=np.diag([1.0, 1.0, 1.0, 0.1, 0.1, 0.1]),
            B_d=np.diag([10.0, 10.0, 10.0, 1.0, 1.0, 1.0]),
            K_d=np.diag([50.0, 50.0, 50.0, 5.0, 5.0, 5.0])
        )
        
    def force_callback(self, msg):
        # 外部力
        F_ext = np.array([
            msg.force.x, msg.force.y, msg.force.z,
            msg.torque.x, msg.torque.y, msg.torque.z
        ])
        
        # 计算控制力矩
        tau = self.impedance.compute_torque(
            q=self.current_q, q_dot=self.current_q_dot,
            q_d=self.target_q, q_d_dot=self.target_q_dot,
            q_d_ddot=self.target_q_ddot, F_ext=F_ext
        )
        
        # 发布
        cmd = JointState()
        cmd.effort = tau.tolist()
        self.torque_pub.publish(cmd)
```
