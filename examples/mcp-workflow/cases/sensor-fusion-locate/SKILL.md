# sensor-fusion-locate SKILL — 多传感器融合定位指南

---

## 核心规则

1. **传感器时间同步**：各传感器消息必须对齐到同一时间戳（使用 `message_filters`）
2. **噪声参数先验**：通过实验标定传感器噪声参数（R、Q 矩阵）
3. **异常值剔除**：单次观测与预测偏差过大时降权或丢弃
4. **IMU 优先高频**：IMU 应以最高频率（≥ 100Hz）运行，作为 EKF 预测步

---

## 知识库

### EKF 预测步

```python
def ekf_predict(X, P, u, dt):
    """EKF 预测步（基于 IMU 角速度和加速度）"""
    F = np.eye(8)
    F[0,3] = dt; F[1,4] = dt  # 速度→位置
    F[3,6] = dt; F[4,7] = dt  # 加速度→速度
    F[2,5] = dt                 # 角速度→角度

    X_pred = F @ X
    P_pred = F @ P @ F.T + Q  # Q: 过程噪声
    return X_pred, P_pred
```

### EKF 修正步

```python
def ekf_update(X_pred, P_pred, Z, H, R):
    """EKF 修正步（基于 LiDAR/Wheel/GPS 观测）"""
    Y = Z - H @ X_pred          # 观测残差
    S = H @ P_pred @ H.T + R    # 残差协方差
    K = P_pred @ H.T @ np.linalg.inv(S)  # 卡尔曼增益
    X = X_pred + K @ Y
    P = (np.eye(8) - K @ H) @ P_pred
    return X, P
```

### message_filters 时间同步

```python
from message_filters import Subscriber, ApproximateTimeSynchronizer

laser_sub = Subscriber('/scan', LaserScan)
imu_sub   = Subscriber('/imu/data', Imu)
wheel_sub = Subscriber('/wheel/odom', Odometry)

ats = ApproximateTimeSynchronizer([laser_sub, imu_sub, wheel_sub], 10, 0.1)
ats.registerCallback(self.on_sensors_synced)
```

### ROS2 传感器话题

```bash
ros2 topic list | grep -E "scan|imu|odom|gps"
# /scan              — LaserScan
# /imu/data          — Imu
# /wheel/odom        — Odometry
# /gps/fix           — NavSatFix
```

---

## 快速启动

```bash
bash scripts/generators/ros2-package-generator.sh sensor_fusion python
# 编写 EKF 节点
bash scripts/ros2-build-verify-loop.sh sensor_fusion
```
