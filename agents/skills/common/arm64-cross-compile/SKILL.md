---
name: arm64-cross-compile
description: ARM64 交叉编译技能 - 配置 x86 到 ARM64 (Jetson OrinNX/RDK-X5) 的交叉编译环境
---

# ARM64 Cross Compile Skill

> x86 开发机到 ARM64 目标机的交叉编译配置与实践

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置交叉编译工具链
- 在 Docker 中设置 ARM64 编译环境
- 解决交叉编译依赖问题
- 部署编译产物到目标机

---

## 快速参考

### 交叉编译原理

```
x86_64 (编译) ──► ARM64 (运行)
    │
    ├── aarch64-linux-gnu-gcc
    ├── aarch64-linux-gnu-g++
    └── CMAKE_SYSROOT=arm64_rootfs
```

### 工具链配置

```cmake
# cmake/aarch64.toolchain.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

set(CMAKE_SYSROOT /opt/orin_sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

### Docker 启动

```bash
docker run -d --name orin-cross \
  -v /path/to/rootfs:/opt/orin_sysroot:ro \
  -v /workspace/ros2_ws:/workspace/ros2_ws \
  ros2-humble-cross-compile sleep infinity
```

### 编译命令

```bash
colcon build \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/opt/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_JETSON=ON
```

---

## 环境准备

### 1. x86 主机工具链

```bash
sudo apt install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    crossbuild-essential-arm64
```

### 2. ARM64 根文件系统

```bash
# NVIDIA Jetson: 来自 SDK Manager
# 路径: Linux_for_Tegra/rootfs

# RDK-X5: 来自 Horizon 官方
```

### 3. ROS2 ARM64 环境

```bash
# 官方 ROS2 ARM64 包
docker pull arm64v8/ros:humble

# 或第三方定制镜像
docker pull hcseok/zed_orinnx_ros2:1.2.0
```

---

## 依赖处理

### 常见问题

| 问题 | 解决 |
|------|------|
| 找不到 xxx.h | 复制到 sysroot/usr/include |
| 找不到 libxxx.so | 复制到 sysroot/usr/lib/aarch64-linux-gnu |
| 找不到 cmake 模块 | 设置 CMAKE_MODULE_PATH |

### 解决方案

```bash
# 复制头文件
sudo cp -r /usr/include/xxx /opt/orin_sysroot/usr/include/

# 复制库文件
sudo cp /usr/lib/xxx.so* /opt/orin_sysroot/usr/lib/aarch64-linux-gnu/

# 重新配置 ldconfig
sudo chroot /opt/orin_sysroot ldconfig
```

---

## 常见错误

### 1. 工具链错误

```
aarch64-linux-gnu-gcc: command not found
```

**解决**: 检查 PATH 和 CMAKE_C_COMPILER

### 2. crt1.o 找不到

```
cannot find crt1.o: No such file or directory
```

**解决**: CMAKE_SYSROOT 设置错误，确保指向正确的根文件系统

### 3. 库版本不匹配

```
library libxxx.so.1.2.3 was built for AArch64
```

**解决**: 确保所有库都是 ARM64 版本

---

## 部署

### 打包

```bash
tar czf install.tar.gz install/
```

### 传输

```bash
scp install.tar.gz ubuntu@192.168.1.110:/tmp/
```

### 安装

```bash
ssh ubuntu@192.168.1.110
sudo tar xzf /tmp/install.tar.gz -C /opt/ros_ws/
source /opt/ros_ws/install/setup.bash
```

---

## 最佳实践

1. **开发阶段**: 直接在 OrinNX 上编译，方便调试
2. **发布阶段**: 使用交叉编译，加快编译速度
3. **使用 ccache**: 加速重复编译
4. **跳过测试**: `--packages-skip` 跳过 livox 等 SDK 相关包
5. **模块化编译**: 只编译修改的包 `--packages-select pkg_name`
