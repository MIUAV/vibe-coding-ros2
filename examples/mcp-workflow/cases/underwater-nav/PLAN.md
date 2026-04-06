# underwater-nav Case — 水下机器人导航

## 背景

水下机器人（ROV/AUV）无法使用 GPS，定位依赖 DVL（多普勒计程仪）、声呐、IMU 的融合。通信依赖水声调制解调器（Acoustic Modem），带宽极低（< 9600 bps）。

**传感器：**
- DVL：底部追踪速度
- IMU：姿态（航向、俯仰、横滚）
- 深度计：深度
- 前视声呐：障碍物检测
- USBL：水声定位（水面基准）

---

## 用户需求

```
用户：AUV 在 50m 水深执行管道巡检，从 dock 出发，沿管道前进 500m，返回 dock
```

---

## 技术方案

### 水下定位

```
DVL（速度积分） + IMU（姿态） → 航位推算（Dead Reckoning）
每 10m 用 USBL 修正一次累积误差
```

### 声呐图像处理

```
前视声呐 → 边缘检测 → 障碍物分割 → 路径重规划
```

---

## 执行流程

### Step 1: 生成包

```bash
bash scripts/generators/ros2-package-generator.sh underwater_nav cpp
```

### Step 2: 启动导航

```bash
ros2 launch underwater_nav nav.launch.py
```

### Step 3: 验证

```bash
bash scripts/ros2-build-verify-loop.sh underwater_nav
```
