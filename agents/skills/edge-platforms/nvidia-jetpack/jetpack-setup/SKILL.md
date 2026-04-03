---
name: jetpack-setup
description: JetPack环境配置 - SDK Manager 系统镜像 驱动安装
argument-hint: "JetPack安装" / "SDK Manager" / "Jetson系统" / "镜像烧录"
user-invocable: true
---

# JetPack 环境配置技能

> 配置Jetson开发环境

## 何时使用

- Jetson系统安装
- SDK组件配置
- 驱动更新

## 安装方式

### 1. SDK Manager (推荐)

```bash
# 设备进入Recovery模式
# 连接USB-C
sdkmanager --target os_image --components 10.0
```

### 2. 手动安装

```bash
# 下载JetPack
tar -xjf JetPack_6.0_Linux_Jetson_Linux_R36.3.0_aarch64.bz2

# 烧录SD卡
sudo chmod +x flash.sh
sudo ./flash.sh jetson-orin-nano-devkit internal
```

## 环境验证

```bash
# 检查CUDA
nvcc --version

# 检查TensorRT
python3 -c "import tensorrt; print(tensorrt.__version__)"

# 检查DeepStream
deepstream-app --version
```

## 系统配置

```bash
# 开启性能模式
sudo nvpmodel -m 0
sudo jetson_clocks

# 设置风扇
sudo bash -c 'echo 255 > /sys/class/hwmon/hwmon0/pwm1'
```