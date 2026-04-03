---
name: qgc-ground-station
description: QGC地面站故障排查 - MAVLink连接问题、串口/网络配置、视频流问题、参数同步失败
argument-hint: QGC故障 OR QGC连接 OR 地面站排查 OR MP连接问题
user-invocable: true
---

# QGC 地面站故障排查技能

> 用于诊断和解决 QGC (QGroundControl) / MP (Mission Planner) 地面站的连接和通信问题

---

## 何时使用

当需要以下帮助时使用此技能：
- QGC/MP 无法连接飞控
- 串口/网络通信异常
- 视频流无法显示
- 参数下载/上传失败
- 地面站频繁断开

---

## 快速参考

### 常见连接架构

```
QGC/MP <--USB/数传--> 飞控 (PX4)
         <--MAVLink--> ROS2 <--MAVROS--> PX4
```

### 快速检查清单

| 检查项 | 命令/方法 |
|--------|-----------|
| 串口权限 | `ls -l /dev/ttyACM*` / `sudo chmod 666 /dev/ttyACM0` |
| 波特率 | 115200 (SiK) / 57600 (3DR) / 921600 (USB) |
| MAVLink版本 | 检查地面站与飞控版本兼容性 |
| 防火墙 | `sudo ufw disable` 测试 |

---

## MAVLink 连接问题

### USB 连接故障

```bash
# 检查 USB 设备
lsusb | grep -i qair

# 查看串口
dmesg | grep ttyACM
# 输出示例: cdc_acm 1-1.2:1.0: ttyACM0: USB ACM device

# 测试串口权限
sudo usermod -a -G dialout $USER
logout  # 重新登录使权限生效
```

### 数传链路连接

```bash
# 检查网络配置
# 地面站 IP: 192.168.1.xxx
# 飞控链接 IP: 192.168.1.yyy

ping 192.168.1.yyy

# 检查 UDP 端口
netstat -u -an | grep 14550
# 或
ss -u -an | grep 14550
```

### MAVLink 握手失败

```python
# 使用 mavlink-cli 检查
mavlink start -d /dev/ttyACM0 -b 921600

# 检查 MAVLink 版本兼容性
# PX4 v1.14+ 使用 MAVLink v2
# 强制使用 v2:
param set MAV_PROTO_VER 2
```

---

## 地面站配置问题

### QGC 串口配置

```
1. 打开 QGC → 应用程序设置 → 通用
2. 通信链路 → 添加串口连接
3. 端口: /dev/ttyACM0
4. 波特率: 921600 (USB) 或 115200 (数传)
5. 流量控制: 无
```

### MP 串口配置

```
1. 打开 MP → 初始设置 → 可选硬件 → 通信端口
2. 波特率: 115200 (SiK) / 57600 (3DR Radio)
3. 链接状态应显示绿色
```

---

## 视频流问题

### RTSP 视频流配置

```bash
# 检查 GStreamer 安装
gst-inspect-1.0 rtspsrc

# 测试视频流
gst-launch-1.0 rtspsrc location=rtsp://192.168.1.1:8554/fpv ! rtph264depay ! avdec_h264 ! autovideosink
```

### MAVLink Camera 协议

```xml
<!-- Camera definition for QGC -->
<model name="Camera">
  <摄像 URL>rtsp://192.168.1.1:8554/fpv</摄像>
  <streamed>false</streamed>
  <recordable>true</recordable>
</model>
```

---

## 参数同步问题

### 参数下载失败

```bash
# 重置所有参数
param reset_all
reboot

# 检查参数系统
param status

# 强制保存
param save
```

### 参数值异常

```python
# 使用 MAVLink 检查参数
from pymavlink import mavutil

mav = mavutil.mavlink_connection('/dev/ttyACM0', baud=921600)

# 下载所有参数
mav.param_fetch_all()

# 等待参数列表
while not mav.params_complete:
    mav.wait_heartbeat()
    
# 打印特定参数
print(mav.params['MAV_SYS_ID'])
```

---

## 常见故障排查流程

### 流程 1: 连接排查

```
1. 物理检查
   ├─ USB 线缆是否支持数据 (非仅充电)
   ├─ 串口是否松动
   └─ 数传天线方向

2. 权限检查
   ├─ 用户是否在 dialout 组
   └─ /dev/ttyACM0 权限

3. 软件配置
   ├─ 波特率是否匹配
   ├─ 地面站是否正确选择端口
   └─ 防火墙是否阻止
```

### 流程 2: 频繁断开

```
1. 检查电源
   ├─ USB 供电不足 (使用带电源的 HUB)
   └─ 数传模块供电

2. 检查干扰
   ├─ 2.4GHz WiFi 干扰
   └─ 电磁干扰

3. 检查日志
   └─ QGC: 应用程序设置 → 分析工具 → 日志
```

---

## 相关文档

- `./multi_rotor_uav/action/px4-mavlink/SKILL.md` - MAVLink 通信配置
- `./multi_rotor_uav/action/px4-dev-env/SKILL.md` - 开发环境配置
- `./multi_rotor_uav/navigation/px4-debug-logging/SKILL.md` - 日志分析
