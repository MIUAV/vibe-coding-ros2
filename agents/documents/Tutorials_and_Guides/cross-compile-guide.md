# ARM64 交叉编译指南

> 从 x86 开发机交叉编译 ROS2 项目到 ARM64 平台 (Jetson OrinNX / RDK-X5)

---

## 1. 交叉编译概述

### 1.1 什么是交叉编译

```
┌─────────────────┐         编译          ┌─────────────────┐
│   x86_64       │ ─────────────────────► │   ARM64         │
│   开发机        │      交叉编译          │   目标机         │
│   (Intel/AMD)   │ ◄───────────────────── │   (OrinNX)      │
└─────────────────┘        运行           └─────────────────┘
```

### 1.2 何时需要交叉编译

| 场景 | 推荐方式 | 说明 |
|------|----------|------|
| 目标机性能弱 | 交叉编译 | OrinNX 等 ARM64 板卡可用 |
| 加速编译 | 本机编译 | 开发阶段推荐直接在 OrinNX 上编译 |
| 大型项目 | 交叉编译 | OpenCV, TensorRT 等耗时库 |
| 调试不方便 | 交叉编译 | 无需频繁部署 |

---

## 2. 环境准备

### 2.1 x86_64 主机

```bash
# 安装交叉编译工具链
sudo apt update
sudo apt install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    crossbuild-essential-arm64 \
    qemu-user-static \
    binutils-aarch64-linux-gnu

# 验证
aarch64-linux-gnu-gcc --version
# 输出应包含 aarch64-linux-gnu

# 安装 CMake
sudo apt install -y cmake
cmake --version
```

### 2.2 ARM64 根文件系统

```bash
# NVIDIA Jetson OrinNX (JetPack 6.x)
# 下载 Linux_for_Tegra 来自 NVIDIA SDK Manager
# 解压后根文件系统在 Linux_for_Tegra/rootfs

# RDK-X5 (Horizon)
# 由 RDK 官方提供根文件系统
```

### 2.3 ROS2 ARM64 工具链文件

```cmake
# cmake/aarch64.toolchain.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 交叉编译工具
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

# 目标根文件系统
set(CMAKE_SYSROOT /opt/orin_sysroot)

# 查找路径
set(CMAKE_FIND_ROOT_PATH /opt/orin_sysroot)

# 查找模式
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 预处理器
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
```

---

## 3. Docker 交叉编译环境

### 3.1 交叉编译容器

```dockerfile
# Dockerfile.orin_cross_compile
FROM ros:humble

# 安装交叉编译工具
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    crossbuild-essential-arm64 \
    qemu-user-static \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# 复制工具链文件
COPY cmake/aarch64.toolchain.cmake /opt/

# 复制 ARM64 sysroot (通过 volume 挂载)
# 这个 COPY 只是示例，实际通过 -v 挂载
# COPY Linux_for_Tegra/rootfs /opt/orin_sysroot

WORKDIR /workspace

CMD ["bash"]
```

### 3.2 启动容器

```bash
# 构建镜像
docker build -f Dockerfile.orin_cross_compile \
    -t ros2-humble-cross-compile .

# 启动容器 (挂载 sysroot 和工作区)
docker run -d --name orin-cross-compile \
    --restart unless-stopped \
    -v /home/user/Linux_for_Tegra/rootfs:/opt/orin_sysroot:ro \
    -v /media/user/ros2_ws:/workspace/ros2_ws:rw \
    -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static:ro \
    ros2-humble-cross-compile sleep infinity
```

---

## 4. 交叉编译配置

### 4.1 CMakeLists.txt 配置

```cmake
# 检测目标架构
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(PLATFORM_ARM64 TRUE)
    message(STATUS "Building for ARM64")
else()
    set(PLATFORM_ARM64 FALSE)
    message(STATUS "Building for x86_64")
endif()

# ARM64 特定配置
if(PLATFORM_ARM64)
    # TensorRT
    find_package(TensorRT REQUIRED)
    
    # CUDA
    find_package(CUDA REQUIRED)
    
    # Jetson 特定库
    find_package(VPI REQUIRED)  # Vision Programming Interface
endif()

# 编译选项
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-O3 -DNDEBUG)
endif()
```

### 4.2 colcon 编译

```bash
# 基本编译命令
colcon build \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/opt/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_JETSON=ON \
        -DBUILD_TESTING=OFF

# 完整编译命令 (参考本项目)
colcon build \
    --packages-skip livox_ros_driver2 \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/opt/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_RDK_BPU=OFF \
        -DENABLE_JETSON=OFF \
        -DBUILD_TESTING=OFF \
        -DCMAKE_CXX_FLAGS="-Wno-dev" \
        -DCMAKE_EXE_LINKER_FLAGS="-L/opt/orin_sysroot/usr/lib/aarch64-linux-gnu" \
    --event-handlers console_direct+
```

### 4.3 环境变量

```bash
# 设置环境变量
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export SYSROOT=/opt/orin_sysroot
export PATH=$SYSROOT/usr/bin:$PATH

# ROS2 相关
export ROS_DISTRO=humble
export AMENT_PREFIX_PATH=/opt/orin_sysroot/opt/ros/humble
```

---

## 5. 依赖处理

### 5.1 缺少依赖问题

```bash
# 问题: 找不到 xxx.h
# 解决: 确保 sysroot 中有所需的头文件

ls /opt/orin_sysroot/usr/include/
# 如果缺少，复制到 sysroot
sudo cp -r /usr/include/xxx /opt/orin_sysroot/usr/include/

# 问题: 找不到 libxxx.so
# 解决: 确保 sysroot 中有库文件

ls /opt/orin_sysroot/usr/lib/aarch64-linux-gnu/
# 如果缺少，复制库
sudo cp /usr/lib/xxx.so* /opt/orin_sysroot/usr/lib/aarch64-linux-gnu/
```

### 5.2 ament 依赖处理

```bash
# ROS2 包依赖必须在目标平台上存在
# 使用 rosdep 安装到 sysroot

# 方法1: 在容器中直接安装到 sysroot
chroot /opt/orin_sysroot apt-get update
chroot /opt/orin_sysroot apt-get install -y ros-humble-xxx

# 方法2: 预下载 deb 包
cd /tmp
apt-get download ros-humble-xxx
dpkg-cross --architecture arm64 -X ros-humble-xxx.deb /opt/orin_sysroot/
```

### 5.3 CMake 查找路径

```cmake
# 强制 CMake 在 sysroot 中查找
list(APPEND CMAKE_FIND_ROOT_PATH /opt/orin_sysroot)
list(APPEND CMAKE_FIND_ROOT_PATH /opt/orin_sysroot/usr/lib/aarch64-linux-gnu)
list(APPEND CMAKE_FIND_ROOT_PATH /opt/orin_sysroot/opt/ros/humble)

# 或者在命令行指定
# -DCMAKE_INCLUDE_PATH=/opt/orin_sysroot/usr/include
# -DCMAKE_LIBRARY_PATH=/opt/orin_sysroot/usr/lib/aarch64-linux-gnu
```

---

## 6. 编译示例

### 6.1 编译单个包

```bash
docker exec orin-cross-compile bash -c '
source /opt/ros/humble/setup.bash
cd /workspace/ros2_ws

colcon build \
    --packages-select milab_antiuav_helmet \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/opt/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_JETSON=OFF \
        -DBUILD_TESTING=OFF
'
```

### 6.2 编译产物

```bash
# 编译产物在 install/ 目录
docker exec orin-cross-compile ls -la /workspace/ros2_ws/install/

# 打包编译产物
docker exec orin-cross-compile tar czf /workspace/ros2_ws/install.tar.gz \
    -C /workspace/ros2_ws install/

# 复制到宿主机
docker cp orin-cross-compile:/workspace/ros2_ws/install.tar.gz ./

# 在目标机上解压
# sudo tar xzf install.tar.gz -C /opt/ros_ws/
# source /opt/ros_ws/install/setup.bash
```

---

## 7. 常见错误

### 7.1 工具链错误

```bash
# 错误: aarch64-linux-gnu-gcc: command not found
# 解决: 检查 PATH
export PATH=/usr/bin:$PATH

# 错误: cannot find crt1.o
# 解决: CMAKE_SYSROOT 设置错误，确保指向正确的根文件系统
ls $CMAKE_SYSROOT/usr/lib/aarch64-linux-gnu/crt1.o
```

### 7.2 库查找错误

```bash
# 错误: Cannot find library xxx
# 解决: 添加库路径
-DCMAKE_LIBRARY_PATH=/opt/orin_sysroot/usr/lib/aarch64-linux-gnu

# 或设置 LD_LIBRARY_PATH (运行时)
export LD_LIBRARY_PATH=/opt/orin_sysroot/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH
```

### 7.3 编译错误

```bash
# 错误: undefined reference to xxx
# 解决: 确保库链接正确
target_link_libraries(target ${CMAKE_DL_LIBS})

# 错误: -fPIC required
# 解决: 添加编译选项
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
```

---

## 8. 部署

### 8.1 部署脚本

```bash
#!/bin/bash
# scripts/deploy_orin.sh

set -e

HOST=${ORIN_NX_HOST:-192.168.1.110}
USER=${ORIN_NX_USER:-ubuntu}
PORT=${ORIN_NX_PORT:-22}

# 创建安装包
tar czf install.tar.gz install/

# 传输到目标机
scp -P $PORT install.tar.gz ${USER}@${HOST}:/tmp/

# 在目标机上安装
ssh -p $PORT ${USER}@${HOST} bash << 'REMOTE'
    sudo tar xzf /tmp/install.tar.gz -C /opt/ros_ws/
    rm /tmp/install.tar.gz
    source /opt/ros_ws/install/setup.bash
REMOTE

echo "Deployment complete!"
```

### 8.2 远程执行

```bash
# 在 OrinNX 上直接编译 (推荐用于调试)
ssh ubuntu@192.168.1.110

# 在 OrinNX 上编译
source /opt/ros/humble/setup.bash
cd ~/ros2_ws
colcon build --parallel-workers 4
```

---

## 9. 性能对比

| 编译方式 | OrinNX 本机编译 | x86 交叉编译 |
|----------|-----------------|--------------|
| 编译时间 | 30-60 分钟 | 10-20 分钟 |
| 便捷性 | 需在目标机上操作 | 可批量自动化 |
| 调试 | 直接调试 | 需部署后调试 |
| 推荐场景 | 开发调试阶段 | 最终构建发布 |

---

## 10. 最佳实践

```bash
# 1. 使用 ccache 加速
colcon build --cmake-args -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

# 2. 只编译修改的包
colcon build --packages-select <package_name>

# 3. 使用 make 可视化
colcon build --cmake-args -DCMAKE_VERBOSE_MAKEFILE=ON

# 4. 跳过不必要的包
colcon build --packages-skip \
    livox_ros_driver2 \
    rqt_plot \
    rviz2
```

---

*交叉编译是嵌入式开发的重要技能，掌握后可以大大提高开发效率*
