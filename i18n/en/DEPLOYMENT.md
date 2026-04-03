# ROS2 Cross-Platform Deployment Guide

> Deploy from x86 development machines to ARM robots (OrinNX / RDK-X5 / Jetson).

---

## Fast Deployment Flow

```
Development machine (x86 Ubuntu 22.04)
    |
    | 1) develop + build (--symlink-install)
    | 2) validate
    v
Package (tar + dependency metadata)
    |
    v
Target machine (ARM Ubuntu 22.04 / OrinNX / RDK-X5)
    |
    | 3) extract
    | 4) install ROS2 dependencies
    | 5) source + run
    v
Verify (ros2 topic list / ros2 node list)
```

---

## Method 1: File Copy (Simplest)

### On development machine

```bash
cd ~/ros2_ws
tar czvf ~/robot_pkg.tar.gz \
  install/ \
  src/my_robot_pkg/ \
  --exclude='*.so' \
  --exclude='build' \
  --exclude='log'

scp ~/robot_pkg.tar.gz ubuntu@192.168.1.100:~/robot_pkg.tar.gz
```

### On target machine

```bash
mkdir -p ~/ros2_ws
cd ~/ros2_ws
tar xzf ~/robot_pkg.tar.gz

source /opt/ros/humble/setup.bash
rosdep install --from-paths src --ignore-src -r -y

source install/setup.bash
ros2 run my_robot_pkg my_node
```

---

## Method 2: Cross-Compile (Best for scale)

### Install toolchain

```bash
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
```

### CMake toolchain file

Create `toolchain-aarch64.cmake`:

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

### Build with colcon

```bash
colcon build \
  --cmake-init-cache-file toolchain-aarch64.cmake \
  --packages-select my_robot_pkg \
  --cmake-args \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake
```

---

## Method 3: Docker Cross-Compile (Recommended)

### Dockerfile

```dockerfile
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

### Install on target

```bash
scp output/robot_pkg.tar.gz ubuntu@192.168.1.100:~
ssh ubuntu@192.168.1.100
tar xzf robot_pkg.tar.gz -C ~/ros2_ws
source ~/ros2_ws/install/setup.bash
ros2 run my_robot_pkg my_node
```

---

## Target Environment Setup

### ROS2 environment variables

```bash
# Add to ~/.bashrc
echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
echo 'export ROS_DOMAIN_ID=42' >> ~/.bashrc
echo 'export ROS_LOCALHOST_ONLY=0' >> ~/.bashrc

export ROS_IP=192.168.1.100
export ROS_MASTER_URI=http://192.168.1.50:11311
```

### Cross-machine communication check

```bash
# Development machine
ros2 daemon stop
export ROS_MASTER_URI=http://192.168.1.50:11311
ros2 daemon start

# Target machine
export ROS_IP=192.168.1.100
export ROS_MASTER_URI=http://192.168.1.50:11311
ros2 node list
ros2 topic list
```

---

## Common Deployment Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| `package not found` | `install/setup.bash` not sourced | `source install/setup.bash` |
| Cross-machine comm fails | Different `ROS_DOMAIN_ID` | Use same value on both machines |
| Cross-machine comm fails | Firewall blocked | `sudo ufw allow 11311/tcp` |
| Cross-machine comm fails | `ROS_LOCALHOST_ONLY=1` | Set to `0` |
| Segfault | x86/ARM binary mismatch | Deploy correct architecture build |
| Missing `.so` | Library path not set | Set `LD_LIBRARY_PATH` |
| Node startup failed | Missing execute permission | `chmod +x install/my_pkg/lib/my_node` |
| Sim time vs wall time mismatch | `/use_sim_time` not configured | Set node param as needed |

---

## One-Click Deployment Script

```bash
#!/bin/bash
TARGET_IP="192.168.1.100"
TARGET_USER="ubuntu"
PKG_NAME="my_robot_pkg"
WS_DIR="~/ros2_ws"

echo "=== Packaging ==="
tar czvf /tmp/${PKG_NAME}.tar.gz install/ src/${PKG_NAME}/

echo "=== Uploading ==="
scp /tmp/${PKG_NAME}.tar.gz ${TARGET_USER}@${TARGET_IP}:~/

echo "=== Installing ==="
ssh ${TARGET_USER}@${TARGET_IP} "
  mkdir -p ${WS_DIR}
  tar xzf ~/${PKG_NAME}.tar.gz -C ${WS_DIR}
  cd ${WS_DIR}
  source /opt/ros/humble/setup.bash
  rosdep install --from-paths src --ignore-src -r -y || true
  echo '=== Deployment done ==='
"
```

---

## Optional: Install from GitHub Source

```bash
sudo apt install git
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
git clone https://github.com/MIUAV/vibe-coding-ros2.git src/
rosdep install --from-paths src -r -y
colcon build --packages-select my_robot_pkg
```
