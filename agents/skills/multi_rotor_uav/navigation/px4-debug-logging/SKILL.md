---
name: px4-debug-logging
description: PX4 调试与日志分析 - 使用 uORB、Flight Review、日志分析工具排查飞控问题
argument-hint: PX4调试 OR px4 debug OR 日志分析 OR 排查问题
user-invocable: true
---

# PX4 调试与日志技能

> 用于调试 PX4 问题和分析飞行日志

---

## 何时使用

当需要以下帮助时使用此技能：
- 调试飞行问题
- 分析飞行日志
- 监控系统状态
- 使用开发者控制台

---

## 快速参考

### 查看系统状态

```bash
# 在 SITL 控制台或 NSH 中
top              # 查看运行的模块
status          # 查看系统状态
free            # 查看内存使用
```

### 查看 uORB 话题

```bash
# 列出所有话题
orb list

# 查看话题发布率
uorb top

# 订阅特定话题
listener sensor_accel
listener sensor_gyro
listener vehicle_attitude
```

---

## 日志记录

### 飞行日志

```bash
# SITL 中
logger start     # 开始记录
logger stop      # 停止记录
logger status    # 查看状态
```

### 日志位置

- **SITL**: `logs/`
- **飞控 (SD卡)**: `/fs/microsd/Logs/`

---

## 日志格式

### ULog 文件

PX4 使用 ULog 格式记录日志

```bash
# 转换为 CSV
ulog2csv logfile.ulg

# 使用 Flight Review 分析
# https://logs.px4.io/
```

---

## 调试工具

### 发送调试值

```bash
# 在代码中
PX4_WARN("debug value: %f", value);
debug_float("my_debug", value);
```

### 绘制实时数据

```bash
# 启动数据绘图
qgc &

# 在 QGC 中:
# Analyze → Flight Review
# 或: Analyze → MAVLink Inspector
```

---

## 常用诊断命令

### 检查模块状态

```bash
# 查看所有模块
top

# 启动/停止模块
module start <module_name>
module stop <module_name>

# 查看参数
param show
param get <param_name>
```

### 网络诊断

```bash
# 查看 MAVLink 状态
mavlink status

# 查看连接
```

---

## 常见问题排查

### 飞行不稳定

1. 检查传感器数据 (`listener sensor_*`)
2. 检查姿态估计 (`listener vehicle_attitude`)
3. 检查电池电压
4. 查看 EKF 状态 (`listener estimator_status`)

### GPS 问题

```bash
# 检查 GPS 状态
listener gps

# 查看卫星数
param show GPS

# 检查 EKF GPS 融合
listener ekf2_timestamps
```

### 通信问题

```bash
# 检查 MAVLink
mavlink status

# 查看消息丢失
```

---

## 使用 Flight Review

1. 打开 https://logs.px4.io/
2. 上传 .ulg 日志文件
3. 查看分析报告

分析报告包括：
- 飞行时间
- 电池消耗
- 飞行模式
- 警告/错误
- 传感器健康状态

---

## 参数调试

### 查看参数

```bash
param show | grep <pattern>
param get <param_name>
```

### 设置参数

```bash
param set <param_name> <value>
```

### 保存/加载参数

```bash
# 保存到文件
param save /fs/microsd/params.txt

# 加载参数
param load /fs/microsd/params.txt
```

---

## 高级调试

### 使用 GDB 调试 (SITL)

```bash
# 启动带调试的 SITL
make px4_sitl gz_x500_debug

# 或
make px4_sitl gz_x500 gdb
```

### 系统回放

```bash
# 使用 ULog 回放
replay.py --log logfile.ulg
```

---

## 日志加密

```bash
# 启用日志加密
MDM_ENC_ENABLE = 1

# 设置密钥
# (需要配置密钥文件)
```

---

## 相关文档

- [PX4 调试文档](https://docs.px4.io/main/en/debug/)
- [Flight Review](https://logs.px4.io/)
- [ULog 格式](https://docs.px4.io/main/en/dev_log/ulog_file_format.html)