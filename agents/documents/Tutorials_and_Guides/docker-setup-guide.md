# Docker ROS2 开发环境配置指南

> 详细的 Docker 配置和使用指南，适用于 x86 和 ARM64 平台

---

## 1. Docker 基础

### 1.1 安装 Docker

```bash
# Ubuntu 22.04 安装 Docker
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# 添加 Docker GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 源
echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

# 安装 Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 将用户加入 docker 组 (免 sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### 1.2 Docker 基本操作

```bash
# 常用命令
docker ps                 # 查看运行中的容器
docker ps -a             # 查看所有容器
docker images            # 查看镜像
docker logs <container>  # 查看容器日志
docker exec -it <container> bash  # 进入容器
docker stop <container>  # 停止容器
docker rm <container>    # 删除容器
```

---

## 2. ROS2 Docker 镜像

### 2.1 官方镜像

| 镜像 | 说明 |
|------|------|
| `ros:humble` | ROS2 Humble 基础镜像 |
| `ros:humble-ros-base-jammy` | 仅 ROS2 base，无 GUI 工具 |
| `ros:humble-ros-core-jammy` | ROS2 core + CLI 工具 |

### 2.2 NVIDIA 容器

```bash
# 安装 NVIDIA Container Toolkit
distribution=ubuntu22.04
curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## 3. x86 开发环境

### 3.1 Dockerfile.x86_dev

```dockerfile
# Dockerfile.x86_dev
FROM ros:humble

# 基础工具
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    vim \
    tmux \
    wget \
    curl \
    unzip \
    python3-pip \
    python3-venv \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# ROS2 开发工具
RUN apt-get update && apt-get install -y \
    ros-humble-ros2launch \
    ros-humble-ros2run \
    ros-humble-ros2pkg \
    ros-humble-rqt* \
    ros-humble-rviz2 \
    ros-humble-ros2cli \
    ros-humble-ros2bag \
    ros-humble-ros2action \
    ros-humble-ros2service \
    && rm -rf /var/lib/apt/lists/*

# OpenCV
RUN apt-get update && apt-get install -y \
    libopencv-dev \
    python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# Navigation2
RUN apt-get update && apt-get install -y \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-slam-toolbox \
    && rm -rf /var/lib/apt/lists/*

# TensorRT (x86)
RUN apt-get update && apt-get install -y \
    libnvinfer-dev \
    libnvinfer-plugin-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 启动命令
CMD ["bash"]
```

### 3.2 构建和运行

```bash
# 构建镜像
docker build -f Dockerfile.x86_dev -t ros2-humble-x86:dev .

# 运行容器
docker run -it \
    --name ros2-x86-dev \
    --net=host \
    --privileged \
    -v /dev:/dev \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    ros2-humble-x86:dev

# 已有容器重新进入
docker exec -it ros2-x86-dev bash
```

---

## 4. ARM64 开发环境

### 4.1 NVIDIA JetPack 基础镜像

```bash
# 使用 NVIDIA JetPack 镜像
docker pull nvcr.io/nvidia/l4t-jetpack:r36.4

# 或使用第三方 ROS2 + JetPack 镜像
docker pull hcseok/zed_orinnx_ros2:1.2.0
```

### 4.2 交叉编译容器

```dockerfile
# Dockerfile.arm64_cross
FROM ros:humble

# 安装交叉编译工具链
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    crossbuild-essential-arm64 \
    qemu-user-static \
    && rm -rf /var/lib/apt/lists/*

# 复制 ARM64 根文件系统 (需要预先准备)
COPY Linux_for_Tegra/rootfs /opt/orin_sysroot

# 设置 sysroot
ENV SYSROOT=/opt/orin_sysroot
ENV CROSS_PREFIX=aarch64-linux-gnu-

WORKDIR /workspace

CMD ["bash"]
```

### 4.3 交叉编译配置

```bash
# 交叉编译工具链文件 aarch64.toolchain.cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}g++)

set(CMAKE_SYSROOT ${SYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

### 4.4 交叉编译命令

```bash
# 在 x86 机器上执行 ARM64 交叉编译
docker exec -it orin-cross-compile bash -c '
source /opt/ros/humble/setup.bash
cd /workspace/ros2_ws

colcon build \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/path/to/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_JETSON=ON \
        -DBUILD_TESTING=OFF
'
```

---

## 5. 设备访问配置

### 5.1 GPU 访问

```bash
# x86 NVIDIA GPU
docker run -it --gpus all \
    --runtime=nvidia \
    -e NVIDIA_VISIBLE_DEVICES=all \
    ros2-humble-x86:dev

# ARM64 (Jetson)
docker run -it --gpus all \
    --runtime=nvidia \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    hcseok/zed_orinnx_ros2:1.2.0
```

### 5.2 USB 设备

```bash
# 挂载 USB 设备
docker run -it \
    --device /dev/bus/usb/001/004:/dev/bus/usb/001/004 \
    --device /dev/video0:/dev/video0 \
    ros2-humble-x86:dev

# 或批量挂载
docker run -it \
    --device /dev/bus/usb \
    ros2-humble-x86:dev
```

### 5.3 串口设备

```bash
# 串口 (GPS, 串口转 USB 等)
docker run -it \
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    --device /dev/ttyACM0:/dev/ttyACM0 \
    --baudrate=115200 \
    ros2-humble-x86:dev

# 权限
docker run -it \
    --device /dev/ttyUSB0:/dev/ttyUSB0 \
    --group-add dialout \
    ros2-humble-x86:dev
```

---

## 6. 多容器编排

### 6.1 docker-compose.yml

```yaml
version: '3.8'

services:
  # x86 开发容器
  ros2-x86-dev:
    build:
      context: .
      dockerfile: Dockerfile.x86_dev
    container_name: ros2-x86-dev
    environment:
      - DISPLAY=${DISPLAY}
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
      - ./workspace:/workspace
    devices:
      - /dev/video0:/dev/video0
    network_mode: host
    privileged: true
    command: sleep infinity

  # ARM64 交叉编译容器
  orin-cross:
    build:
      context: .
      dockerfile: Dockerfile.arm64_cross
    container_name: orin-cross-compile
    volumes:
      - ./workspace:/workspace
      - /home/user/Linux_for_Tegra/rootfs:/opt/orin_sysroot:ro
    command: sleep infinity
```

### 6.2 使用 docker-compose

```bash
# 构建并启动
docker-compose up -d

# 进入容器
docker exec -it ros2-x86-dev bash
docker exec -it orin-cross-compile bash

# 停止
docker-compose down

# 重建
docker-compose up -d --build
```

---

## 7. VSCode 集成

### 7.1 .devcontainer.json

```json
{
    "name": "ROS2 Humble Dev",
    "dockerFile": "Dockerfile.x86_dev",
    "runArgs": [
        "--net=host",
        "--privileged",
        "-v/dev:/dev"
    ],
    "extensions": [
        "ms-vscode.cpptools",
        "ms-python.python",
        "thinker.ros"
    ],
    "postCreateCommand": "bash scripts/setup_dev.bash",
    "forwardPorts": [8000],
    "workspaceFolder": "/workspace"
}
```

### 7.2 setup_dev.bash

```bash
#!/bin/bash
# scripts/setup_dev.bash

# Source ROS2
source /opt/ros/humble/setup.bash

# 安装 VSCode 扩展 (可选)
code --install-extension ms-vscode.cpptools

echo "Development environment ready!"
```

---

## 8. 常见问题

### 8.1 容器中 rviz2 闪退

```bash
# 原因: OpenGL 问题
# 解决: 使用软件渲染

docker run -it \
    --env LIBGL_ALWAYS=software \
    --env MESA_GL_VERSION_OVERRIDE=3.3 \
    ros2-humble-x86:dev rviz2
```

### 8.2 找不到库文件

```bash
# 原因: sysroot 配置错误
# 解决: 确认 CMAKE_SYSROOT 指向正确的根文件系统

# 在容器中检查
ls -la /opt/orin_sysroot/usr/lib/aarch64-linux-gnu/
```

### 8.3 编译卡住

```bash
# 原因: 内存不足或并行编译太多
# 解决: 限制并行数

colcon build --parallel-workers 2
```

---

## 9. 最佳实践

### 9.1 Dockerfile 优化

```dockerfile
# 使用多阶段构建减小镜像
FROM ros:humble AS builder
COPY . /workspace
RUN colcon build

FROM ros:humble AS runtime
COPY --from=builder /workspace/install /opt/ros_ws/install
CMD ["bash"]

# 合并 RUN 指令减少层数
RUN apt-get update && \
    apt-get install -y pkg1 pkg2 pkg3 && \
    rm -rf /var/lib/apt/lists/*

# 使用 .dockerignore
echo "build" > .dockerignore
echo "log" >> .dockerignore
echo "*.bag" >> .dockerignore
```

### 9.2 数据管理

```bash
# 使用 volume 管理数据
docker volume create ros2_ws

# 运行时挂载
docker run -v ros2_ws:/workspace ros2-humble-x86:dev

# 备份 volume
docker run --rm -v ros2_ws:/workspace -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /workspace
```

---

*正确的 Docker 配置可以让 ROS2 开发环境快速搭建和迁移*
