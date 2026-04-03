---
name: px4-mavlink
description: PX4 MAVLink 通信配置 - 地面站连接、数传配置、参数设置、消息订阅
argument-hint: "MAVLink配置" / "px4 mavlink" / "数传配置" / "QGC连接"
user-invocable: true
---

# PX4 MAVLink 通信技能

> 用于配置 PX4 与地面站、数传、 companion computer 的通信

---

## 何时使用

当需要以下帮助时使用此技能：
- 连接 QGroundControl
- 配置数传模块
- 设置 MAVLink 参数
- 与 companion computer 通信

---

## 快速参考

### 默认端口

| 用途 | 端口 | 说明 |
|------|------|------|
| 地面站 (GCS) | 14550 | UDP |
| Offboard API | 14540 | UDP |
| 日志下载 | 18570 | UDP |

### 连接方式

```bash
# USB 连接 (自动识别)
# 串口连接
mavlink start -d /dev/ttyS1 -b 921600

# UDP 连接
mavlink start -u 14550 -r 40000
```

---

## MAVLink 配置

### 启动 MAVLink

```bash
# 在 NSH 控制台
mavlink start -u 14550 -r 40000 -m onboard
```

### 参数配置

```bash
# 设置波特率
MAV_0_BAUD       # 串口波特率

# 设置速率
MAV_0_RATE       # 消息发送速率 (Hz)

# 启用不同协议
MAV_0_MODE       # 0=Normal, 1=Custom, 2=Onboard
```

---

## 串口配置

### GPS/数传端口

```bash
# 配置串口
SER_TEL1_BAUD    # 波特率
SER_TEL1_MODE    # 模式 (MAVLink)

# 常用波特率
# 115200 - GPS
# 57600 - 旧版数传
# 921600 - 高速数传
```

### Telemetry 端口

```
QGC → Settings → Comm Links
→ Add Link
→ Serial
→ 选择端口和波特率
```

---

## 与 Companion Computer 连接

### 通过 UDP (推荐)

```bash
# 飞控端 (自动)
mavlink start -u 14540 -r 40000 -m onboard
```

### 通过 Serial

```bash
# 飞控端
mavlink start -d /dev/ttyS6 -b 921600

# 串口参数
SER_TEL2_BAUD = 921600
SER_TEL2_MODE = MAVLink
```

---

## MAVLink 消息

### 常用消息

| 消息 ID | 名称 | 说明 |
|---------|------|------|
| 0 | HEARTBEART | 心跳 |
| 0 | PARAM_REQUEST_LIST | 参数列表 |
| 0 | PARAM_SET | 设置参数 |
| 0 | MISSION_ITEM | 航点 |
| 0 | COMMAND_LONG | 命令 |
| 0 | HIGHSPEED_LOGGING | 日志 |
| 0 | HOME_POSITION | 家庭位置 |

### 订阅消息

```bash
# 监听消息
listener vehicle_attitude
listener vehicle_local_position
```

---

## QGroundControl 连接

### USB 连接

1. 通过 USB 连接飞控和电脑
2. QGC 自动识别
3. 确认连接状态

### 网络连接

```
QGC → Settings → Comm Links
→ Add → UDP
→ Host: <飞控IP>
→ Port: 14550
→ Connect
```

### 串口连接

```
QGC → Settings → Comm Links
→ Add → Serial
→ Port: /dev/ttyUSB0
→ Baud: 57600
→ Connect
```

---

## 数传配置

### 地面端数传

```
串口连接:
TX → 飞控 RX
RX → 飞控 TX
GND → 地
```

### 参数设置

```bash
# 飞控端
MAV_0_BAUD = 57600

# 地面端
数传波特率 = 57600
```

---

## 消息速率控制

### 设置消息速率

```bash
# MAVLink 总速率
MAV_0_RATE = 100  # Hz

# 单独消息速率 (通过 MAV_CMD)
MAV_CMD_SET_MESSAGE_INTERVAL
```

### QGC 中配置

```
QGC → Analyze → MAVLink Inspector
→ 选择消息
→ 设置速率
```

---

## 故障排除

### 无法连接

1. **检查线缆**
2. **检查端口**
   ```bash
   ls /dev/tty*
   ```
3. **检查波特率**
4. **检查防火墙**

### 消息丢失

```bash
# 检查 MAVLink 状态
mavlink status

# 降低速率
MAV_0_RATE = 50
```

### 数据中断

```bash
# 增加缓冲区
MAV_0_LENGTH = 200

# 检查超时
COM_RC_LOSS_T    # RC 丢失超时
```

---

## MAVProxy 使用

```bash
# 安装 MAVProxy
pip install MAVProxy

# 连接飞控
mavproxy.py --master=/dev/ttyUSB0

# 多个连接
mavproxy.py --master=/dev/ttyUSB0 --master=udp:127.0.0.1:14540
```

---

## 相关文档

- [PX4 MAVLink](https://docs.px4.io/main/en/middleware/mavlink.html)
- [QGC 连接](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/setup_view/comm_links.html)
- [MAVLink 协议](https://mavlink.io/)