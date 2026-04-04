# ROS2 Docker 开发环境配置指南

> 在 Docker 中搭建 ROS2 开发环境，避免污染宿主机

---

## 一、为什么用 Docker

- **环境隔离**：不同项目可能需要不同 ROS2 版本
- **可重现**：团队成员环境一致
- **安全**：不怕误操作破坏宿主机
- **CI/CD**：GitHub Actions 直接用 Docker 构建

---

## 二、基础镜像选择

| 镜像 | 大小 | 适用场景 |
|------|------|----------|
| `osrf/ros:humble-desktop` | ~3GB | 有桌面，RViz 可用 |
| `osrf/ros:humble-ros-base` | ~1GB | 仅命令行，无桌面 |
| `osrf/ros:humble-robot` | ~2GB | robot 镜像，含 SLAM/Nav2 |
| `px4io/ros2-humble-builder` | ~2GB | 含 PX4 工具链 |

---

## 三、快速启动

### 3.1 拉取镜像

```bash
docker pull osrf/ros:humble-desktop
```

### 3.2 运行容器

```bash
docker run -it --rm \
  --name ros2_dev \
  --network host \
  --privileged \
  -v /dev:/dev \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  osrf/ros:humble-desktop \
  bash
```

### 3.3 验证

```bash
# 在容器内
ros2 doctor
rviz2  # 如果需要图形界面
```

---

## 四、GPU 支持（Nvidia）

### 前提条件

```bash
# 安装 nvidia-container-toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 启动命令

```bash
docker run -it --rm \
  --name ros2_dev \
  --gpus all \
  --runtime nvidia \
  -e DISPLAY=$DISPLAY \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  osrf/ros:humble-desktop \
  bash
```

### 验证 GPU

```bash
# 容器内
ros2 run tf2_ros tf2_echo /map /odom  # GPU 用于点云处理
```

---

## 五、Docker Compose（推荐）

### docker-compose.yml

```yaml
version: '3.8'

services:
  ros2_humble:
    image: osrf/ros:humble-desktop
    container_name: ros2_dev
    network_mode: host
    privileged: true
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
      - ./workspace:/workspace
    environment:
      - DISPLAY=${DISPLAY}
      - ROS_DOMAIN_ID=42
    # GPU 支持（如果用 Nvidia）
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

  # 可选：启动 rviz 的辅助容器
  rviz_helper:
    image: osrf/ros:humble-desktop
    container_name: rviz2
    network_mode: host
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
    environment:
      - DISPLAY=${DISPLAY}
    command: rviz2
```

### 使用

```bash
# 启动
docker-compose up -d

# 进入容器
docker exec -it ros2_dev bash

# 停止
docker-compose down
```

---

## 六、构建自己的 ROS2 开发镜像

### Dockerfile

```dockerfile
FROM osrf/ros:humble-desktop

# 设置 locale
RUN apt-get update && apt-get install -y \
    locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# 安装开发工具
RUN apt-get update && apt-get install -y \
    git \
    python3-pip \
    python3-venv \
    curl \
    vim \
    tmux \
    htop \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# 安装 ROS2 开发依赖
RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-humble-ament-python \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 初始化 rosdep
RUN rosdep init && rosdep update

# 常用 pip 包
RUN pip3 install --no-cache-dir \
    pyyaml \
    jinja2 \
    ament_tools \
    flake8 \
    mypy

# Source ROS2 的 entrypoint
ENTRYPOINT ["bash", "/ros_entrypoint.sh"]
```

### 构建

```bash
docker build -t my_ros2_dev:humble .
```

---

## 七、VSCode 远程开发（容器内）

### .devcontainer/devcontainer.json

```json
{
  "name": "ROS2 Humble Dev",
  "image": "my_ros2_dev:humble",
  "runArgs": ["--network=host", "--privileged"],
  "forwardPorts": [6000],
  "extensions": [
    "ms-vscode.cpptools",
    "twilson63.ros",
    "ms-python.python",
    "redhat.vscode-yaml"
  ],
  "settings": {
    "ros.distro": "humble",
    "python.analysis.extraPaths": ["/opt/ros/humble/lib/python3.10/site-packages"]
  },
  "postCreateCommand": "bash -c 'source /opt/ros/humble/setup.bash && echo ROS2 environment ready'"
}
```

打开 VSCode → `Ctrl+Shift+P` → "Remote-Containers: Open Folder in Container"

---

## 八、桥接 Docker 内 ROS2 与宿主机

### 网络配置

```bash
# 宿主机设置
export ROS_DOMAIN_ID=42

# Docker 容器内也要相同
export ROS_DOMAIN_ID=42

# 测试
# 宿主机
ros2 topic list
# 容器内
ros2 topic list
# 应该看到相同的话题列表
```

### 共享 X Server（RViz）

```bash
# 宿主机允许 X 连接
xhost +local:docker

# 容器启动时加上
# -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix
```

---

## 九、Gazebo 仿真（特殊注意事项）

```bash
# 需要挂载 /dev 文件
docker run -it --rm \
  --name gazebo_dev \
  --network host \
  --privileged \
  -v /dev:/dev \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  osrf/ros:humble-desktop \
  bash -c "source /opt/ros/humble/setup.bash && gazebo"
```

---

## 十、故障排除

### 问题 1：容器内 `colcon build` 报错 "Permission denied"

```bash
# 创建用户并设置权限
RUN useradd -m rosdev && \
    usermod -aG sudo rosdev && \
    echo "rosdev:rosdev" | chpasswd
USER rosdev
```

### 问题 2：rosdep update 超时

```bash
# 使用国内镜像
sudo rosdep update --distro humble --rosdistro https://raw.githubusercontent.com/ros/rosdistro/master/rosdep/base.yaml --skip-keys '{"yaml":"https://mirrors.tuna.tsinghua.edu.cn/ros2/rosdep/base.yaml"}'
```

### 问题 3：Docker 内无法访问设备

```bash
# 确保 --privileged 和 --device 挂载
docker run --device /dev/ttyUSB0 ...
```

### 问题 4：colcon build 内存不足

```bash
# 限制并行构建
colcon build --parallel-workers 2

# 或限制单个包的构建线程
MAKEFLAGS="-j2"
```
