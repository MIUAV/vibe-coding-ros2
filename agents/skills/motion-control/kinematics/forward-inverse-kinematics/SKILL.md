---
name: forward-inverse-kinematics
description: 正逆运动学技能 - 解析法、雅可比迭代、数值IK、ROS2 IK服务器
argument-hint: 逆运动学 OR IK OR 数值IK OR 雅可比 OR inverse kinematics
user-invocable: true
---

# 正逆运动学技能

> 机器人正逆运动学求解

---

## 何时使用

当需要以下帮助时使用此技能：
- 正运动学计算
- 逆运动学解析求解
- 雅可比矩阵
- 数值 IK
- ROS2 IK 服务

---

## 核心实现

### 正运动学

```python
import numpy as np

class SerialChainFK:
    def __init__(self, dh_params):
        """
        dh_params: [(theta, d, a, alpha), ...]
        """
        self.dh_params = dh_params
        
    def forward_kinematics(self, joint_angles):
        """计算正运动学"""
        T = np.eye(4)
        
        for i, (theta, d, a, alpha) in enumerate(self.dh_params):
            theta += joint_angles[i]
            
            ct = np.cos(theta)
            st = np.sin(theta)
            ca = np.cos(alpha)
            sa = np.sin(alpha)
            
            # DH 变换矩阵
            Ti = np.array([
                [ct, -st*ca, st*sa, a*ct],
                [st, ct*ca, -ct*sa, a*st],
                [0, sa, ca, d],
                [0, 0, 0, 1]
            ])
            
            T = T @ Ti
            
        return T
        
    def get_jacobian(self, joint_angles):
        """计算雅可比矩阵"""
        n_joints = len(joint_angles)
        J = np.zeros((6, n_joints))
        
        # 末端位置
        T_end = self.forward_kinematics(joint_angles)
        p_end = T_end[:3, 3]
        
        # 计算每个关节的雅可比列
        T = np.eye(4)
        
        for i in range(n_joints):
            # 关节轴方向
            z_i = T[:3, 2]
            p_i = T[:3, 3]
            
            # 线速度部分
            J[:3, i] = np.cross(z_i, p_end - p_i)
            
            # 角速度部分
            J[3:, i] = z_i
            
            # 更新 T
            Ti = self.compute_dh_transform(self.dh_params[i], joint_angles[i])
            T = T @ Ti
            
        return J
```

### 逆运动学

```python
class IKResolver:
    def __init__(self, fk_solver):
        self.fk = fk_solver
        
    def solve(self, target_pose, initial_angles=None, max_iter=100, tol=1e-4):
        """数值 IK 求解"""
        if initial_angles is None:
            q = np.zeros(len(self.fk.dh_params))
        else:
            q = np.array(initial_angles)
            
        for _ in range(max_iter):
            # 当前末端位姿
            T_current = self.fk.forward_kinematics(q)
            p_current = T_current[:3, 3]
            R_current = T_current[:3, :3]
            
            # 位置误差
            p_error = target_pose[:3, 3] - p_current
            
            # 旋转误差 (使用罗德里格斯公式)
            R_error = target_pose[:3, :3] @ R_current.T
            theta_error = self.rotation_to_angle_axis(R_error)
            
            # 组合误差
            error = np.concatenate([p_error, theta_error])
            
            if np.linalg.norm(error) < tol:
                break
                
            # 雅可比
            J = self.fk.get_jacobian(q)
            
            # 伪逆求解
            q_delta = np.linalg.lstsq(J, error, rcond=None)[0]
            
            # 更新
            q = q + 0.5 * q_delta
            
        return q
        
    def rotation_to_angle_axis(self, R):
        """旋转矩阵转轴角"""
        theta = np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))
        
        if theta < 1e-6:
            return np.zeros(3)
            
        axis = np.array([
            R[2, 1] - R[1, 2],
            R[0, 2] - R[2, 0],
            R[1, 0] - R[0, 1]
        ]) / (2 * np.sin(theta))
        
        return theta * axis
```

### ROS2 IK 服务器

```python
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Pose
from manipulation_msgs.srv import SolveIK, SolveIKRequest

class IKServer(Node):
    def __init__(self):
        super().__init__('ik_server')
        
        self.ik_resolver = IKResolver(self.fk_solver)
        
        self.srv = self.create_service(
            SolveIK, 'solve_ik', self.solve_ik_callback)
            
    def solve_ik_callback(self, request, response):
        target_pose = self.pose_to_matrix(request.target_pose)
        
        q_solution = self.ik_resolver.solve(
            target_pose, 
            request.seed,
            max_iter=100
        )
        
        response.joint_angles = q_solution.tolist()
        response.success = True
        return response
```
