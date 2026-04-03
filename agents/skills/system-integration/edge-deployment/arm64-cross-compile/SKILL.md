---
name: arm64-cross-compile
description: ARM64 交叉编译技能 - aarch64 交叉编译工具链、ROS2 交叉编译、Docker 交叉编译
argument-hint: ARM64 OR 交叉编译 OR aarch64 OR cross compile OR toolchain
user-invocable: true
---

# ARM64 交叉编译技能

> ARM64 平台交叉编译

---

## 何时使用

当需要以下帮助时使用此技能：
- ARM64 交叉编译
- aarch64 工具链
- ROS2 交叉编译
- Docker 交叉编译
- Buildroot 配置

---

## 核心配置

### 交叉编译工具链

```bash
# 安装 ARM64 工具链 (x86_64 -> aarch64)
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 验证
aarch64-linux-gnu-gcc --version
aarch64-linux-gnu-g++ --version
```

### CMake 交叉编译配置

```cmake
# toolchain-aarch64.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 工具链路径
set(CMAKE_C_COMPILER /usr/bin/aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)

# sysroot
set(CMAKE_SYSROOT /usr/aarch64-linux-gnu)

# 搜索路径
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)

# 搜索模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

### ROS2 交叉编译

```bash
# 1. 安装 ROS2 ARM64 依赖
sudo apt install python3-colcon-common-extensions

# 2. 创建交叉编译构建
mkdir -p cross_ws/src
colcon build --merge-install \
  --cmake-args \
    -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain-aarch64.cmake \
    -DCMAKE_PREFIX_PATH=/opt/ros/foxy/aarch64 \
    -DBUILD_TESTING=OFF
```

### Docker 交叉编译

```dockerfile
# Dockerfile.cross
FROM --platform=linux/arm64/v8 ubuntu:22.04

# 安装 ARM64 依赖
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y \
        ros-humble-rclcpp=0.25.2 \
        python3-colcon-common-extensions \
    && apt-get clean

# 复制源码
COPY . /workspace

# 编译
RUN colcon build --merge-install

CMD ["bash"]
```

```bash
# 使用 Docker Buildx 交叉编译
docker buildx build --platform linux/arm64 -t robot-image .
```

### 多平台构建

```bash
# build_all.sh
#!/bin/bash

PLATFORMS="amd64 arm64"
IMAGE_NAME="robot-ros2"

for platform in $PLATFORMS; do
    docker buildx build \
        --platform linux/$platform \
        -t ${IMAGE_NAME}:${platform} \
        --push .
done
```
