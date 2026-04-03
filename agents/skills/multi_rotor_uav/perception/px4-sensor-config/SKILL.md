---
name: px4-sensor-config
description: PX4 传感器配置与校准 - 陀螺仪、加速度计、磁罗盘、GPS、光流等传感器设置
argument-hint: 传感器校准 OR px4 sensor OR 配置传感器 OR GPS配置
user-invocable: true
---

# PX4 传感器配置技能

> 用于配置和校准 PX4 飞控上的各种传感器

---

## 何时使用

当需要以下帮助时使用此技能：
- 校准 IMU 传感器（陀螺仪、加速度计）
- 配置磁罗盘（罗盘）
- 设置 GPS 和 RTK
- 配置光流和测距仪
- 传感器方向设置

---

## 快速参考

### 使用 QGroundControl 校准

1. 打开 QGroundControl
2. 点击左上角 "Q" 图标 → Vehicle Setup
3. 选择 "Sensors" 选项卡
4. 按照界面提示进行各传感器校准

---

## 必需传感器

| 传感器 | 说明 | 校准方法 |
|--------|------|----------|
| **陀螺仪 (Gyroscope)** | 测量角速度 | QGC 自动校准或原地静止 |
| **加速度计 (Accelerometer)** | 测量加速度 | QGC 6面校准法 |
| **磁罗盘 (Magnetometer)** | 测量航向 | QGC 旋转校准 |
| **气压计 (Barometer)** | 测量气压高度 | 自动，无需校准 |

---

## 传感器配置步骤

### 1. 陀螺仪校准

```
QGC → Sensors → Gyroscope
- 保持飞控静止
- 点击 "Calibrate"
- 等待完成
```

### 2. 加速度计校准

```
QGC → Sensors → Accelerometer
- 按提示将飞控6个面朝下放置
- 每个面保持静止2-3秒
```

### 3. 磁罗盘校准

```
QGC → Sensors → Magnetometer
- 手持飞控在空中画 "8" 字
- 直至进度条完成
- 多个罗盘时需分别校准
```

### 4. 水平校准 (Level Horizon)

```
QGC → Sensors → Level Horizon
- 将飞控水平放置
- 点击 "Calibrate"
```

---

## 推荐传感器

### GPS 配置

```bash
# 常用 GPS 参数
EKF2_GPS_POS_X    # GPS 相对于飞控的位置
EKF2_GPS_POS_Y    # (0.1m 精度)
EKF2_GPS_POS_Z

EKF2_GPS_CTRL     # GPS 融合模式
```

### RTK GPS 配置

```bash
# 启用 RTK
EKF2_RTK_CTRL     # 1 = 启用 RTK

# 设置 RTK 坐标参考
GPS_RTK_EMIT      # NTRIP 配置
```

---

## 可选传感器

### 光流 (Optical Flow)

配置参数：
```bash
EKF2_OF_CTRL      # 启用光流
EKF2_OF_POS_X     # 光流传感器位置
```

支持的传感器：
- PX4FLOW
- Generic optical flow sensor

### 测距仪 (Rangefinder)

```bash
# 配置测距仪
RNGFND_TYPE       # 传感器类型
RNGFND_MAX_CM     # 最大测距距离

# 用于:
# - 地形跟随
# - 精确着陆
# - 避障
```

---

## 传感器方向设置

### 配置传感器方向

```
QGC → Sensors → Sensor Orientation
- 选择旋转角度
- 应用到对应传感器
```

### 常用方向参数

```bash
# IMU 方向
SENS_IMU_MODE     # 旋转角度

# 外部罗盘方向
CAL_MAG0_ROT      # 外部罗盘旋转
```

---

## 常见问题

### 传感器校准失败

1. **确保飞控固定**
2. **避免磁场干扰**（远离金属、电机）
3. **校准时保持静止**
4. **检查传感器连接**

### GPS 不定位

1. 检查 GPS 模块供电
2. 确认天线朝上
3. 等待搜星（首次可能需要几分钟）
4. 检查 EKF2 配置

### 传感器数据异常

```bash
# 检查传感器状态
uorb top

# 查看传感器话题
orb list | grep sensor
```

---

## 参数参考

### EKF2 估计器参数

```bash
EKF2_CTRL         # 估计器控制
EKF2_HGT_MODE     # 高度源 (BARO/GPS/RANGE)
EKF2_GPS_CTRL     # GPS 融合控制
EKF2_NOAID_NOISE  # 无 GPS 时的噪声参数
```

### 传感器更新率

```bash
# IMU 默认 1kHz
# 陀螺仪融合 250Hz
# 位置估计 100Hz
```

---

## 相关文档

- [PX4 传感器文档](https://docs.px4.io/main/en/sensor/)
- [QGC 传感器校准](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/setup_view/sensors_setup.html)
- [配置指南](https://docs.px4.io/main/en/config/)