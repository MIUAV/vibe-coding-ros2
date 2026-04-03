---
name: kalman-filtering
description: 卡尔曼滤波技能 - 线性KF、扩展EKF、无迹UKF、粒子滤波、ROS2机器人状态估计
argument-hint: 卡尔曼滤波 OR EKF OR UKF OR 粒子滤波 OR 状态估计 OR Kalman filter
user-invocable: true
---

# 卡尔曼滤波技能

> 用于实现机器人状态估计的卡尔曼滤波算法，涵盖线性KF、扩展EKF、无迹UKF、粒子滤波及 ROS2 集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 传感器融合（GPS + IMU、视觉 + 轮式里程计）
- 机器人状态估计（位置、速度、姿态）
- 噪声滤波和信号平滑
- 非线性系统状态估计
- ROS2 EKF 定位节点配置

---

## 快速参考

### 算法选择

```
线性系统 → 线性卡尔曼滤波 (KF)
↓
非线性系统 → 扩展卡尔曼滤波 (EKF) ← 最常用
         ↓
    非线性强 → 无迹卡尔曼滤波 (UKF) ← 更精确
             ↓
    非高斯分布 → 粒子滤波 (PF) ← 计算量大
```

### 核心公式

```
预测: x̂ₖ⁻ = Fx̂ₖ₋₁ + Buₖ        (先验)
      Pₖ⁻ = FPₖ₋₁Fᵀ + Q          (先验协方差)

更新: Kₖ = Pₖ⁻Hᵀ(HPₖ⁻Hᵀ + R)⁻¹  (卡尔曼增益)
      x̂ₖ = x̂ₖ⁻ + Kₖ(zₖ - Hx̂ₖ⁻) (后验)
      Pₖ = (I - KₖH)Pₖ⁻          (后验协方差)
```

### ROS2 依赖

```bash
sudo apt install -y ros-humble-robot-localization
```

---

## 线性卡尔曼滤波 (KF)

### Python 实现

```python
import numpy as np
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class KalmanFilter:
    """线性卡尔曼滤波器"""

    # 状态维度
    state_dim: int
    # 观测维度
    meas_dim: int

    # 状态转移矩阵 F
    F: np.ndarray = field(init=False)
    # 控制输入矩阵 B
    B: np.ndarray = field(init=False)
    # 观测矩阵 H
    H: np.ndarray = field(init=False)
    # 过程噪声协方差 Q
    Q: np.ndarray = field(init=False)
    # 观测噪声协方差 R
    R: np.ndarray = field(init=False)

    # 状态估计 x̂
    x: np.ndarray = field(init=False)
    # 估计协方差 P
    P: np.ndarray = field(init=False)

    def __post_init__(self):
        self.F = np.eye(self.state_dim)
        self.B = np.zeros((self.state_dim, self.state_dim))
        self.H = np.zeros((self.meas_dim, self.state_dim))
        self.Q = np.eye(self.state_dim) * 0.01
        self.R = np.eye(self.meas_dim) * 0.1
        self.x = np.zeros(self.state_dim)
        self.P = np.eye(self.state_dim)

    def predict(self, u: Optional[np.ndarray] = None, dt: float = 0.0):
        """
        预测步骤

        Args:
            u: 控制输入向量
            dt: 时间步长（用于更新 F）
        """
        if dt > 0:
            # 更新状态转移矩阵（以匀速模型为例）
            self.F[0, 2] = dt
            self.F[1, 3] = dt

        # 预测状态
        if u is not None:
            self.x = self.F @ self.x + self.B @ u
        else:
            self.x = self.F @ self.x

        # 预测协方差
        self.P = self.F @ self.P @ self.F.T + self.Q

        return self.x.copy()

    def update(self, z: np.ndarray) -> np.ndarray:
        """
        更新步骤

        Args:
            z: 观测向量
        """
        # 创新（测量残差）
        y = z - self.H @ self.x

        # 创新协方差
        S = self.H @ self.P @ self.H.T + self.R

        # 卡尔曼增益
        K = self.P @ self.H.T @ np.linalg.inv(S)

        # 更新状态
        self.x = self.x + K @ y

        # 对称更新协方差（数值稳定性）
        I_KH = np.eye(self.state_dim) - K @ self.H
        self.P = I_KH @ self.P @ I_KH.T + K @ self.R @ K.T

        return self.x.copy()

    def get_state(self) -> np.ndarray:
        return self.x.copy()

    def get_covariance(self) -> np.ndarray:
        return self.P.copy()
```

### 应用：2D 位置估计

```python
# 2D 位置跟踪 (x, y, vx, vy)
kf = KalmanFilter(state_dim=4, meas_dim=2)

# 状态转移矩阵（匀速模型）
kf.F = np.array([
    [1, 0, 1, 0],  # x = x + vx*dt
    [0, 1, 0, 1],  # y = y + vy*dt
    [0, 0, 1, 0],  # vx = vx
    [0, 0, 0, 1],  # vy = vy
])

# 观测矩阵（只观测位置）
kf.H = np.array([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
])

# 观测噪声
kf.R = np.diag([0.5, 0.5])
# 过程噪声
kf.Q = np.diag([0.1, 0.1, 0.05, 0.05])

# 初始化状态
kf.x = np.array([0, 0, 1, 0])  # 从 (0,0) 开始，以速度 (1,0) 移动

# 模拟观测
observations = [
    np.array([1.2, 0.3]),
    np.array([2.1, 0.8]),
    np.array([3.3, 1.1]),
]

for z in observations:
    kf.predict(dt=1.0)
    kf.update(z)
    print(f"Estimated: x={kf.x[0]:.2f}, y={kf.x[1]:.2f}, vx={kf.x[2]:.2f}, vy={kf.x[3]:.2f}")
```

---

## 扩展卡尔曼滤波 (EKF)

### Python 实现

```python
import numpy as np
from typing import Callable, Tuple


class ExtendedKalmanFilter:
    """扩展卡尔曼滤波器（适用于非线性系统）"""

    def __init__(
        self,
        state_dim: int,
        meas_dim: int,
        f: Callable,      # 状态转移函数 f(x, u)
        h: Callable,       # 观测函数 h(x)
        jf: Callable,     # f 的雅可比矩阵
        jh: Callable,     # h 的雅可比矩阵
        Q: np.ndarray = None,
        R: np.ndarray = None
    ):
        self.state_dim = state_dim
        self.meas_dim = meas_dim
        self.f = f        # 非线性状态转移
        self.h = h        # 非线性观测
        self.jf = jf      # df/dx
        self.jh = jh      # dh/dx

        self.Q = Q if Q is not None else np.eye(state_dim) * 0.01
        self.R = R if R is not None else np.eye(meas_dim) * 0.1
        self.x = np.zeros(state_dim)
        self.P = np.eye(state_dim)

    def predict(self, u: np.ndarray = None, dt: float = 0.0):
        """预测步骤"""
        # 计算雅可比矩阵
        F = self.jf(self.x, u, dt)

        # 预测状态
        self.x = self.f(self.x, u, dt)

        # 预测协方差
        self.P = F @ self.P @ F.T + self.Q

        return self.x.copy()

    def update(self, z: np.ndarray) -> np.ndarray:
        """更新步骤"""
        # 计算观测雅可比
        H = self.jh(self.x)

        # 创新
        y = z - self.h(self.x)

        # 创新协方差
        S = H @ self.P @ H.T + self.R

        # 卡尔曼增益
        K = self.P @ H.T @ np.linalg.inv(S)

        # 更新状态
        self.x = self.x + K @ y

        # 更新协方差
        self.P = (np.eye(self.state_dim) - K @ H) @ self.P

        return self.x.copy()
```

### 应用：IMU + GPS 融合

```python
# 状态: [x, y, vx, vy, yaw, yaw_rate]
state_dim = 6
meas_dim = 4  # GPS (x, y) + yaw

def f(x, u, dt):
    """状态转移函数"""
    yaw = x[4]
    return np.array([
        x[0] + dt * x[2] * np.cos(yaw),
        x[1] + dt * x[2] * np.sin(yaw),
        x[2] + dt * u[0],  # 加速
        x[3] + dt * u[1],  # 横向
        x[4] + dt * x[5],
        x[5] + dt * u[2],  # yaw_accel
    ])

def h(x):
    """观测函数（GPS + yaw）"""
    return np.array([x[0], x[1], x[4]])

def jf(x, u, dt):
    """f 的雅可比矩阵"""
    yaw = x[4]
    cos_yaw = np.cos(yaw)
    sin_yaw = np.sin(yaw)
    F = np.eye(6)
    F[0, 2] = dt * cos_yaw
    F[0, 4] = -dt * x[2] * sin_yaw
    F[1, 2] = dt * sin_yaw
    F[1, 4] = dt * x[2] * cos_yaw
    F[4, 5] = dt
    return F

def jh(x):
    """h 的雅可比矩阵"""
    H = np.zeros((3, 6))
    H[0, 0] = 1
    H[1, 1] = 1
    H[2, 4] = 1
    return H

# 使用示例
ekf = ExtendedKalmanFilter(
    state_dim=6, meas_dim=3,
    f=f, h=h, jf=jf, jh=jh
)
ekf.x = np.array([0, 0, 0, 0, 0, 0])

# GPS 观测
gps_meas = np.array([10.5, 3.2, 0.1])
ekf.predict(u=np.array([0.5, 0, 0]), dt=0.1)
ekf.update(gps_meas)
print(f"Position: x={ekf.x[0]:.2f}, y={ekf.x[1]:.2f}")
```

---

## 无迹卡尔曼滤波 (UKF)

```python
import numpy as np


class UnscentedKalmanFilter:
    """无迹卡尔曼滤波器"""

    def __init__(self, state_dim: int, meas_dim: int, alpha=0.001, beta=2.0, kappa=0.0):
        self.n = state_dim
        self.m = meas_dim
        self.alpha = alpha
        self.beta = beta
        self.kappa = kappa

        # UKF 参数
        self.lam = self.alpha**2 * (self.n + self.kappa) - self.n
        self.gamma = np.sqrt(self.n + self.lam)

        # 权重
        self.Wm = np.zeros(2 * self.n + 1)
        self.Wc = np.zeros(2 * self.n + 1)
        self.Wm[0] = self.lam / (self.n + self.lam)
        self.Wc[0] = self.lam / (self.n + self.lam) + (1 - self.alpha**2 + self.beta)
        for i in range(1, 2 * self.n + 1):
            self.Wm[i] = self.Wc[i] = 0.5 / (self.n + self.lam)

        self.x = np.zeros(state_dim)
        self.P = np.eye(state_dim)
        self.Q = np.eye(state_dim) * 0.01
        self.R = np.eye(meas_dim) * 0.1

    def sigma_points(self):
        """生成 Sigma 点"""
        sigma = np.zeros((2 * self.n + 1, self.n))
        sigma[0] = self.x
        sqrt_P = np.linalg.cholesky((self.n + self.lam) * self.P)
        for i in range(self.n):
            sigma[i + 1] = self.x + sqrt_P[:, i]
            sigma[i + 1 + self.n] = self.x - sqrt_P[:, i]
        return sigma

    def predict(self, f, dt=0.0):
        """预测步骤"""
        sigma = self.sigma_points()
        sigma_pred = np.zeros_like(sigma)

        for i, sp in enumerate(sigma):
            sigma_pred[i] = f(sp, dt)

        # 加权计算均值和协方差
        self.x = np.sum(self.Wm[:, None] * sigma_pred, axis=0)
        diff = sigma_pred - self.x[None, :]
        self.P = diff.T @ np.diag(self.Wc) @ diff + self.Q

        return self.x.copy()

    def update(self, z, h):
        """更新步骤"""
        sigma = self.sigma_points()
        sigma_z = np.zeros((2 * self.n + 1, self.m))

        for i, sp in enumerate(sigma):
            sigma_z[i] = h(sp)

        # 观测均值
        z_pred = np.sum(self.Wm[:, None] * sigma_z, axis=0)

        # 创新协方差
        diff_z = sigma_z - z_pred[None, :]
        diff_x = sigma - self.x[None, :]
        S = diff_z.T @ np.diag(self.Wc) @ diff_z + self.R
        cross = diff_x.T @ np.diag(self.Wc) @ diff_z

        # 卡尔曼增益
        K = cross @ np.linalg.inv(S)

        # 更新状态
        self.x = self.x + K @ (z - z_pred)
        self.P = self.P - K @ S @ K.T

        return self.x.copy()
```

---

## 粒子滤波 (PF)

```python
import numpy as np
from typing import Callable


class ParticleFilter:
    """粒子滤波器（非高斯非线性系统）"""

    def __init__(
        self,
        state_dim: int,
        num_particles: int = 1000,
        process_noise: float = 0.1,
        measurement_noise: float = 0.5
    ):
        self.n = state_dim
        self.N = num_particles
        self.q = process_noise
        self.r = measurement_noise

        # 粒子
        self.particles = np.zeros((self.N, self.n))
        self.weights = np.ones(self.N) / self.N

        # 状态估计
        self.x = np.zeros(self.n)
        self.P = np.zeros((self.n, self.n))

    def initialize(self, mean: np.ndarray, cov: np.ndarray):
        """初始化粒子"""
        self.particles = np.random.multivariate_normal(mean, cov, self.N)
        self.weights.fill(1.0 / self.N)

    def predict(self, f: Callable, u=None):
        """预测步骤"""
        for i in range(self.N):
            noise = np.random.randn(self.n) * self.q
            self.particles[i] = f(self.particles[i], u) + noise

    def update(self, z: np.ndarray, h: Callable):
        """更新步骤（重要性采样）"""
        for i in range(self.N):
            expected = h(self.particles[i])
            error = z - expected
            likelihood = np.exp(-0.5 * error @ error / self.r**2)
            self.weights[i] *= likelihood

        # 归一化
        self.weights += 1e-10
        self.weights /= np.sum(self.weights)

        # 有效粒子数
        Neff = 1.0 / np.sum(self.weights**2)

        # 重采样（如果有效粒子数过低）
        if Neff < self.N / 2:
            self._resample()

        # 估计状态
        self.x = np.sum(self.weights[:, None] * self.particles, axis=0)
        diff = self.particles - self.x[None, :]
        self.P = diff.T @ np.diag(self.weights) @ diff

        return self.x.copy()

    def _resample(self):
        """系统重采样"""
        cumsum = np.cumsum(self.weights)
        cumsum[-1] = 1.0  # 防止浮点误差

        indices = np.searchsorted(cumsum, np.random.rand(self.N))
        self.particles = self.particles[indices]
        self.weights.fill(1.0 / self.N)
```

---

## ROS2 robot_localization

### EKF 配置 (YAML)

```yaml
# ekf.yaml
ekf_filter_node:
  ros__parameters:
    # 状态维度 (x, y, z, roll, pitch, yaw, vx, vy, vz, vroll, vpitch, vyaw)
    state_dim: 15

    # 频率
    frequency: 50.0

    # 传感器输入
    odom0: /diff_driver/odom               # 轮式里程计
    odom0_config: [true, true, false,       # x, y, z
                    false, false, false,       # roll, pitch, yaw
                    true, true, false,         # vx, vy, vz
                    false, false, true,         # vroll, vpitch, vyaw
                    false, false, false]        # 偏航角（从里程计推算）

    odom1: /imu/data                        # IMU
    odom1_config: [false, false, false,
                   true, true, true,          # roll, pitch, yaw from IMU
                   false, false, false,
                   true, true, true,           # angular velocities
                   false, false, false]       # 偏航角速率

    odom2: /gps/fix                         # GPS
    odom2_config: [true, true, false,
                   false, false, false,
                   false, false, false,
                   false, false, false,
                   false, false, false]

    # 协方差
    odom0_pose_covariance: [0.1, 0, 0, 0, 0, 0,
                            0, 0.1, 0, 0, 0, 0,
                            0, 0, 0.05, 0, 0, 0,
                            0, 0, 0, 0.01, 0, 0,
                            0, 0, 0, 0, 0.01, 0,
                            0, 0, 0, 0, 0, 0.05]

    # 过程噪声（调试重点）
    process_noise_covariance: [0.05, 0, 0, 0, 0, 0,
                               0, 0.05, 0, 0, 0, 0,
                               0, 0, 0.06, 0, 0, 0,
                               0, 0, 0, 0.03, 0, 0,
                               0, 0, 0, 0, 0.03, 0,
                               0, 0, 0, 0, 0, 0.01]
```

### Launch 文件

```python
# launch/ekf_localization.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    return LaunchDescription([
        Node(
            package='robot_localization',
            executable='ekf_node',
            name='ekf_filter_node',
            parameters=['/path/to/ekf.yaml'],
            remappings=[
                ('/odom0', '/diff_driver/odom'),
                ('/imu/data', '/imu/data'),
                ('/gps/fix', '/gps/fix'),
            ],
        ),
    ])
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| EKF 发散 | Q 太小或 R 太大 | 增加 Q，减少 R |
| 状态跳变 | 异常测量值 | 添加异常值检测，过滤野值 |
| 滤波器响应慢 | 平滑过度 | 降低 Q，重新调整权重 |
| 估计偏离真实值 | 状态转移模型错误 | 检查 f() 函数是否正确 |
| 粒子退化严重 | 似然函数太尖锐 | 增加粒子数，调整 R |

### 调试命令

```bash
# 查看 EKF 状态输出
ros2 topic echo /odometry/filtered

# 动态调参
ros2 param set /ekf_filter_node process_noise_covariance "[0.1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]"

# 绘制状态曲线
ros2 run rqt_plot rqt_plot /odometry/filtered/pose/pose/position/x:x

# 发布测试观测
ros2 topic pub /odom0 nav_msgs/msg/Odometry '{header: {stamp: {sec: 0}}, pose: {pose: {position: {x: 1.0}}}}' --once
```

---

## 相关技能

- `perception/sensor-fusion/lidar-camera-fusion` — 激光-相机融合
- `perception/sensor-fusion/multi-object-tracking` — 多目标跟踪
- `perception/sensor-fusion/spatial-temporal-sync` — 时空同步
- `manipulator/localization` — 机械臂定位
- `wheeled_vehicle/localization` — 轮式车辆定位
- `humanoid/localization` — 人形机器人定位
- `quadruped/localization` — 四足机器人定位
- `multi_rotor_uav/localization` — 无人机定位
