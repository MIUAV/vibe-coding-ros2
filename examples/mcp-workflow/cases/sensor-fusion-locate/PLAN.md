# sensor-fusion-locate Case — 多传感器融合定位

## 背景

移动机器人需要精确的定位能力。单一传感器（Lidar SLAM、视觉 odometry、IMU、GPS）都有局限，多传感器融合（Sensor Fusion）可以取长补短，实现厘米级定位精度。

**传感器：**
- 激光雷达（LiDAR）：环境轮廓扫描
- IMU：高频加速度 + 角速度
- 轮式里程计（Wheel Odometry）：直接测量位移
- GPS/RTK：绝对位置（室外）

**融合算法：EKF（扩展卡尔曼滤波）**

---

## 用户需求

```
用户：室外机器人，融合 LiDAR SLAM + IMU + Wheel Odometry，定位精度目标 < 5cm
```

---

## 技术方案

### EKF 状态向量

```
X = [x, y, theta, vx, vy, omega, ax, ay]ᵀ
```

### 传感器观测模型

| 传感器 | 观测 | 噪声模型 |
|--------|------|---------|
| LiDAR | (x, y, theta) from scan matching | 高斯噪声 |
| IMU | (ax, ay, omega) | 偏置+高斯 |
| Wheel | (vx, vy) | 高斯噪声 |
| GPS | (x, y) | 高斯噪声 |

---

## 执行流程

### Step 1: 生成包

```bash
bash scripts/generators/ros2-package-generator.sh sensor_fusion python
```

### Step 2: 配置 EKF 参数

```bash
# 编辑 config/ekf.yaml
ros2 launch sensor_fusion ekf.launch.py
```

### Step 3: 验证

```bash
bash scripts/ros2-build-verify-loop.sh sensor_fusion
```
