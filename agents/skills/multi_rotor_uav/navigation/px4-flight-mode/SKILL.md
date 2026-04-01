---
name: px4-flight-mode
description: PX4 飞行模式与任务规划 - 手动、姿态、自稳、定点、任务、Offboard等模式配置
argument-hint: "飞行模式" / "px4 mode" / "任务规划" / "Offboard模式"
user-invocable: true
---

# PX4 飞行模式与任务技能

> 用于配置和理解 PX4 各种飞行模式

---

## 何时使用

当需要以下帮助时使用此技能：
- 了解多旋翼飞行模式
- 配置飞行模式切换
- 规划自主任务航线
- 设置 Offboard 模式

---

## 快速参考

### 多旋翼飞行模式

| 模式 | 说明 | 用途 |
|------|------|------|
| **手动** | 手柄/RC 控制 | 测试、机动飞行 |
| **姿态** | 保持姿态，自稳 | 新手练习 |
| **高度** | 保持高度，位置自由 | 过渡模式 |
| **位置** | 保持位置和高度 | 自动飞行基础 |
| **任务** | 执行预设航线 | 自主巡检、测绘 |
| **Offboard** | 外部计算机控制 | 自主导航、避障 |

---

## 模式说明

### 手动模式 (Manual)

- 遥控器直接控制电机输出
- 无任何稳定辅助
- 仅用于调试

### 姿态模式 (Stabilized)

- 遥控器控制翻滚/俯仰角度
- 高度由油门控制
- 飞控保持水平稳定

### 高度模式 (Altitude)

- 位置模式下限制水平移动
- 保持设定高度
- 适合手动导航

### 位置模式 (Position)

- 保持位置和高度
- 支持 GPS 导航
- 最常用的自动模式

### 任务模式 (Mission)

- 执行 QGC 规划的任务
- 自动航线飞行
- 支持航点、航点动作

### Offboard 模式

- 由外部计算机通过 MAVLink 控制
- 发送位置/速度/姿态目标
- 需要位置定位可用

---

## 飞行模式配置

### 通过 RC 切换

```
QGC → Settings → Flight Modes
- 选择通道 (通常 CH5)
- 为每个开关位置分配模式
```

### 通过 MAVLink 切换

```bash
# 切换到位置模式
mavlink send COMMAND_LONG
  command: MAV_CMD_DO_SET_MODE
  mode: 4  # PX4_MODE_POSITION
```

---

## 任务规划

### 创建任务

1. 打开 QGroundControl
2. 点击 "Plan" 标签
3. 在地图上添加航点
4. 设置每个航点的动作
5. 发送任务到飞控

### 航点类型

| 类型 | 说明 |
|------|------|
| **Waypoint** | 飞向目标点 |
| **Takeoff** | 起飞 |
| **Land** | 降落 |
| **RTL** | 返回起飞点 |
| **Loiter** | 盘旋 |
| **Condition** | 条件等待 |

### 航点动作

```bash
# 设置盘旋圈数
LOITER_TIME

# 设置停留时间
LOITER_TIME

# 拍照 (触发相机)
DO_SET_CAMERA_TRIGGER

# 挂载控制
DO_MOUNT_CONTROL
```

---

## Offboard 模式

### ROS 2 + MAVROS

```bash
# 启动 MAVROS
ros2 launch mavros px4.launch fcu_url:="udp://:14540@"
```

### Offboard 控制示例 (Python)

```python
from pymavlink import mavutil

# 连接飞控
master = mavutil.mavlink_connection('udp:localhost:14540')

# 请求 Offboard 模式
master.mav.set_mode_send(
    master.target_system,
    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
    4)  # Offboard mode

# 发送位置目标
master.mav.set_position_target_local_ned_send(
    0,                      # 时间戳
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_FRAME_LOCAL_NED,
    0b110111000000,        # 类型掩码
    10, 0, -5,             # 位置 (x, y, z)
    0, 0, 0,               # 速度
    0, 0, 0,               # 加速度
    0, 0)                  # 偏航
```

---

## 安全功能

### 失效保护

```
QGC → Settings → Safety
- 低电量返航
- 失控保护
- 地理围栏
- 任务失效保护
```

### 地理围栏

```bash
# 启用地理围栏
FENCE_ENABLE    = 1

# 设置边界
FENCE_RADIUS    # 最大距离
FENCE_ALT_MAX   # 最大高度
```

---

## 模式切换条件

### 自动切换触发

- 电池低电量 → RTL/降落
- GPS 丢失 → 高度模式/降落
- 信号丢失 → RTL
- 地理围栏触发 → RTL

---

## 参数参考

```bash
# 默认飞行模式
COM_FLIGHTMODE

# Offboard 超时
COM_OF_TIMEOUT

# 任务持续时间
MIS_DIST_1WP     # 航点触发距离
MIS_DIST_WPS     # 全任务距离
```

---

## 相关文档

- [PX4 飞行模式](https://docs.px4.io/main/en/flight_modes_mc/)
- [任务规划](https://docs.px4.io/main/en/flight_modes/mission.html)
- [Offboard 模式](https://docs.px4.io/main/en/flight_modes/offboard.html)