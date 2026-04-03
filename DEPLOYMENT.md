# ROS2 跨平台部署指南

> 从 x86 开发机到 ARM 机器人（OrinNX / RDK-X5 / Jetson）

---

## 快速部署流程

```
开发机 (x86 Ubuntu 22.04)
    │
    │  1. 开发 + 编译（--symlink-install）
    │  2. 测试验证
    │
    ▼
打包（tar + requirements.txt）
    │
    ▼
目标机 (ARM Ubuntu 22.04 / OrinNX / RDK-X5)
    │
    │  3. 解压
    │  4. 安装 ROS2 依赖
    │  5. source + 运行
    │
    ▼
验证（ros2 topic list / ros2 node list）
```

---

## 方式一：文件拷贝（最简单）

### 开发机

```bash
# 在工作区根目录打包
cd ~/ros2_ws
tar czvf ~/robot_pkg.tar.gz \
  install/ \
  src/my_robot_pkg/ \
  --exclude='*.so' \
  --exclude='build' \
  --exclude='log'

# 复制到目标机
scp ~/robot_pkg.tar.gz ubuntu@192.168.1.100:~/robot_pkg.tar.gz
```

### 目标机

```bash
# 解压到工作区
mkdir -p ~/ros2_ws
cd ~/ros2_ws
tar xzf ~/robot_pkg.tar.gz

# 安装依赖
source /opt/ros/humble/setup.bash
rosdep install --from-paths src --ignore-src -r -y

# 运行
source install/setup.bash
ros2 run my_robot_pkg my_node
```

---

## 方式二：交叉编译（推荐大规模部署）

### 安装交叉编译工具链

```bash
# 对于 ARM64 (aarch64)
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 对于 Jetson OrinNX (ARM64 + CUDA)
# 使用 NVIDIA JetPack 提供的交叉编译环境
```

### CMake 工具链文件

创建 `toolchain-aarch64.cmake`:

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)

set(CMAKE_SYSROOT /usr/aarch64-linux-gnu)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

### 交叉编译 ROS2 包

```bash
colcon build \
  --cmake-init-cache-file toolchain-aarch64.cmake \
  --packages-select my_robot_pkg \
  --cmake-args \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake
```

---

## 方式三：Docker 交叉编译（推荐，无需搭建工具链）

### 开发机

```dockerfile
# Dockerfile.crosscompile
FROM osrf/ros:humble-ros-base-jammy

RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . .

RUN colcon build \
    --cmake-args \
      -DCMAKE_TOOLCHAIN_FILE=/usr/aarch64-linux-gnu/cmake \
      -DCMAKE_BUILD_TYPE=Release
```

```bash
docker build -t ros2-cross:aarch64 -f Dockerfile.crosscompile .
docker run --rm -v $(pwd)/output:/output ros2-cross:aarch64 \
  tar czvf /output/robot_pkg.tar.gz install/
```

### 目标机安装

```bash
scp output/robot_pkg.tar.gz ubuntu@192.168.1.100:~
ssh ubuntu@192.168.1.100
tar xzf robot_pkg.tar.gz -C ~/ros2_ws
source ~/ros2_ws/install/setup.bash
ros2 run my_robot_pkg my_node
```

---

## 目标机环境配置

### ROS2 环境变量

```bash
# ~/.bashrc 添加
echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
echo 'export ROS_DOMAIN_ID=42' >> ~/.bashrc          # 与开发机一致
echo 'export ROS_LOCALHOST_ONLY=0' >> ~/.bashrc      # 允许跨机通信

# 常用网络配置
export ROS_IP=192.168.1.100      # 目标机 IP
export ROS_MASTER_URI=http://192.168.1.50:11311   # 开发机作 master
```

### 跨机器通信验证

```bash
# 开发机
ros2 daemon stop
export ROS_MASTER_URI=http://192.168.1.50:11311
ros2 daemon start

# 目标机
export ROS_IP=192.168.1.100
export ROS_MASTER_URI=http://192.168.1.50:11311
ros2 node list     # 应该能看到开发机的节点
ros2 topic list    # 应该能看到开发机的话题
```

---

## 常见部署问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `package not found` | install/setup.bash 未 source | `source install/setup.bash` |
| 跨机通信失败 | ROS_DOMAIN_ID 不一致 | 两台机器设为相同值 |
| 跨机通信失败 | 防火墙阻止 | `sudo ufw allow 11311/tcp` |
| 跨机通信失败 | ROS_LOCALHOST_ONLY=1 | 设为 0 |
| 段错误 (Segfault) | ARM/x86 架构不匹配 | 确认是交叉编译版本 |
| 找不到 .so | 库路径未设置 | `export LD_LIBRARY_PATH=install/my_pkg/lib:$LD_LIBRARY_PATH` |
| 节点启动失败 | 权限不足 | `chmod +x install/my_pkg/lib/my_node` |
| 仿真时间 vs 真实时间 | `/use_sim_time` 参数 | 确认是否需要 `ros2 param set /node use_sim_time true` |

---

## 自动化部署脚本

```bash
#!/bin/bash
# deploy.sh — 一键部署到目标机
TARGET_IP="192.168.1.100"
TARGET_USER="ubuntu"
PKG_NAME="my_robot_pkg"
WS_DIR="~/ros2_ws"

echo "=== 打包 ==="
tar czvf /tmp/${PKG_NAME}.tar.gz install/ src/${PKG_NAME}/

echo "=== 上传 ==="
scp /tmp/${PKG_NAME}.tar.gz ${TARGET_USER}@${TARGET_IP}:~/

echo "=== 安装 ==="
ssh ${TARGET_USER}@${TARGET_IP} "
  mkdir -p ${WS_DIR}
  tar xzf ~/${PKG_NAME}.tar.gz -C ${WS_DIR}
  cd ${WS_DIR}
  source /opt/ros/humble/setup.bash
  rosdep install --from-paths src --ignore-src -r -y || true
  echo '=== 部署完成 ==='
"
```

---

## ROS2 包发布到 GitHub Package（可选）

```bash
# 在目标机上直接从 GitHub 安装
sudo apt install git
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
git clone https://github.com/MIUAV/vibe-coding-ros2.git src/
rosdep install --from-paths src -r -y
colcon build --packages-select my_robot_pkg
```
