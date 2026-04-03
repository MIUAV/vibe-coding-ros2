---
name: px4-vision-nav
description: PX4 视觉导航与避障 - 光流定位、深度相机、激光雷达融合、视觉里程计
argument-hint: "视觉导航" / "px4 vision" / "视觉避障" / "光流定位"
user-invocable: true
---

# PX4 视觉导航技能

> 用于配置和使用基于视觉的定位、导航和避障功能

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置光流定位
- 设置视觉里程计
- 配置激光雷达避障
- 实现室内自主飞行

---

## 快速参考

### 光流定位

```
QGC → Sensors → Optical Flow
→ 安装下视相机
→ 配置传感器
```

### 视觉里程计

```bash
# 使用 VIO
EKF2_AID_MASK |= 0b0010  # 启用视觉位置融合

# 配置视觉源
EKF2_EV_PRIO    # 视觉优先级
EKF2_EV_DELAY   # 视觉延迟
```

---

## 光流配置

### 支持的传感器

| 传感器 | 接口 | 说明 |
|--------|------|------|
| **PX4FLOW** | I2C | 官方光流模块 |
| **PMW3901** | SPI | 鼠标传感器 |
| **OA500VM** | Serial | 成品光流模块 |

### 配置步骤

1. **安装传感器**
   - 朝下安装
   - 确保视野无遮挡
   
2. **QGC 配置**
   ```
   QGC → Sensors → Optical Flow
   → 点击 "Start Setup"
   → 按照提示校准
   ```

### 参数

```bash
# 启用光流
EKF2_OF_CTRL = 1

# 光流参数
EKF2_OF_PRIO   # 光流优先级
EKF2_OF_QMIN   # 光流质量最小值

# 测距仪参数 (必需)
EKF2_RNG_AID   # 启用测距融合
RNGFND_MAX_CM  # 最大测距范围
```

---

## 视觉里程计 (VIO)

### ROS 2 + VIO 设置

```bash
# 1. 安装 VIO 软件
# 例如: VINS-Fusion, OKVIS, etc.

# 2. 配置 MAVROS
# 发布视觉里程计到 /mavros/odometry/out

# 3. PX4 配置
EKF2_AID_MASK |= 0b0010  # 视觉位置
EKF2_EV_DELAY = 0        # 视觉延迟

# 4. 启用估计器
EKF2_HGT_MODE = 2        # 使用视觉高度
```

### VIO 参数

```bash
# 视觉位置融合
EKF2_EV_PRIO = 50    # 优先级

# 视觉速度融合
EKF2_EV_VELO_PRIO = 50

# 外部位置重置
EKF2_EV_RESET_YAW = 1  # 允许重置航向
```

---

## 激光雷达/测距仪

### 支持的传感器

| 类型 | 型号 | 接口 |
|------|------|------|
| **声学测距** | MaxBotix | Serial |
| **超声波** | SRF02/HC-SR04 | I2C |
| **TOF 激光** | TFmini, TF-Luna | Serial |
| **激光雷达** | RPLidar, LEO | Serial |

### 配置

```bash
# 选择传感器类型
RNGFND_TYPE = 5  # 对应型号

# 配置参数
RNGFND_MAX_CM = 500    # 最大范围 (cm)
RNGFND_MIN_CM = 50     # 最小范围
RNGFND_QUALITY = 50     # 最小质量

# 测距融合
EKF2_RNG_AID = 1       # 启用测距辅助
```

---

## 避障功能

### 基于测距仪的避障

```bash
# 启用避障
OBS_CTRL = 1

# 障碍物检测范围
OBS_R_MAX = 5      # 前向检测范围 (m)
OBS_R_MIN = 0.5    # 最小检测距离

# 避障策略
OBS_TYPE = 1       # 1=停止, 2=绕行
```

### EKF 障碍物融合

```bash
# 在 EKF 中使用距离数据
EKF2_RNG_AID = 1

# 调整噪声参数
EKF2_RNG_NOISE = 0.1
```

---

## 室内定位方案

### 推荐方案

| 方案 | 适用场景 | 精度 |
|------|----------|------|
| **光流 + 测距** | 简单室内 | 10-30cm |
| **VIO** | 复杂环境 | 1-5cm |
| **UWB** | 大范围室内 | 10-30cm |
| **AprilTag** | 已知环境 | 1-5cm |

### 室内飞行配置

```bash
# 1. 禁用 GPS
EKF2_GPS_CTRL = 0

# 2. 启用视觉/光流
EKF2_AID_MASK = 0b0111

# 3. 设置高度源
EKF2_HGT_MODE = 3  # 视觉/测距

# 4. 调整参数
EKF2_NOAID_NOISE = 0.5  # 增加无GPS噪声
```

---

## 常见问题

### 光流不工作

1. **检查安装方向**
2. **检查地面纹理**
3. **确认测距仪数据**
4. **检查 EKF 配置**

### VIO 漂移

1. **校准相机内参**
2. **检查时间同步**
3. **调整延迟参数**
4. **检查 IMU 外参**

### 避障不触发

1. **检查传感器数据**
2. **调整检测距离参数**
3. **确认障碍物大小**
4. **检查模式设置**

---

## 相关文档

- [PX4 光流](https://docs.px4.io/main/en/sensor/optical_flow.html)
- [测距仪](https://docs.px4.io/main/en/sensor/rangefinders.html)
- [EKF 估计器](https://docs.px4.io/main/en/advanced_config/parameter_reference.html)