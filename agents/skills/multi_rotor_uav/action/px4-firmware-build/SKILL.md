---
name: px4-firmware-build
description: PX4 固件编译与烧录 - 支持 NuttX/Pixhawk 系列飞控的固件构建和上传
argument-hint: 编译PX4 OR px4 build OR 烧录固件 OR 构建飞控
user-invocable: true
---

# PX4 固件构建技能

> 用于编译和烧录 PX4 固件到飞控硬件

---

## 何时使用

当需要以下帮助时使用此技能：
- 从源码编译 PX4 固件
- 烧录固件到飞控板
- 自定义 PX4 构建配置
- 支持新的飞控硬件

---

## 快速参考

### 获取源码

```bash
# 克隆最新源码
git clone https://github.com/PX4/PX4-Autopilot.git --recursive
cd PX4-Autopilot

# 或获取特定版本
git checkout v1.14.0
git submodule update --recursive
```

---

### 编译 SITL (仿真)

```bash
cd PX4-Autopilot

# Gazebo 仿真
make px4_sitl gz_x500

# jMAVSim 仿真
make px4_sitl jmavsim
```

---

### 编译飞控固件

```bash
# Pixhawk 4 (FMUv5)
make px4_fmu-v5_default

# Pixhawk 6C (FMUv6C)
make px4_fmu-v6c_default

# Pixhawk 6X (FMUv6X)
make px4_fmu-v6x_default

# CUAV V5+
make px4_fmu-v5_default
```

### 烧录固件

```bash
# 编译并上传到飞控
make px4_fmu-v5_default upload

# 指定烧录方式
make px4_fmu-v5_default upload # 通过 USB
```

---

## 飞控板构建命令参考

| 飞控板 | 构建命令 |
|--------|----------|
| Pixhawk 4 | `make px4_fmu-v5_default` |
| Pixhawk 4 Mini | `make px4_fmu-v5_default` |
| Pixhawk 5X | `make px4_fmu-v5x_default` |
| Pixhawk 6C | `make px4_fmu-v6c_default` |
| Pixhawk 6X | `make px4_fmu-v6x_default` |
| Holybro Pixhawk 6X-RT | `make px4_fmu-v6xrt_default` |
| CUAV V5+ | `make px4_fmu-v5_default` |
| CUAV V5 nano | `make px4_fmu-v5_default` |
| Pixracer | `make px4_fmu-v4_default` |
| mRo Pixhawk | `make px4_fmu-v3_default` |

---

## 构建变体

```bash
# 默认配置
make px4_fmu-v5_default

# 带调试信息
make px4_fmu-v5_default DEBUG=1

# 最小配置 (减小固件体积)
make px4_fmu-v5_default_min

# 带 ROS2 支持
make px4_fmu-v5_default_uxrce_dds
```

---

## 固件上传步骤

1. **连接飞控**：通过 USB 将飞控连接到电脑
2. **进入 Bootloader**：飞控上电时按住 BOOT 按钮
3. **执行烧录**：

```bash
make px4_fmu-v5_default upload
```

4. **等待完成**：看到 "Rebooting..." 表示成功

---

## 故障排除

### 编译错误

```bash
# 清理构建缓存
make distclean

# 更新子模块
git submodule update --recursive

# 重新编译
make px4_fmu-v5_default
```

### 固件过大

```bash
# 检查 Flash 使用情况
# 减少不需要的模块

# 或使用更小的配置
make px4_fmu-v5_default_min
```

### 烧录失败

```bash
# 检查 USB 连接
ls /dev/ttyACM*

# 确认飞控处于 Bootloader 模式
# 尝试重新按住 BOOT 按钮上电
```

### Python 包缺失

```bash
# 安装依赖
pip3 install --user -r Tools/setup/requirements.txt
```

---

## 使用 Docker 构建

```bash
# 使用 PX4 Docker 容器
cd PX4-Autopilot
./Tools/docker_run.sh 'make px4_fmu-v5_default'
```

---

## 相关文档

- [PX4 构建文档](https://docs.px4.io/main/en/dev_setup/building_px4.html)
- [飞控硬件列表](https://docs.px4.io/main/en/flight_controller/)
- [开发者工具链](https://docs.px4.io/main/en/dev_setup/dev_env.html)