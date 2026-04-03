---
name: docker-ros2-deployment
description: Docker ROS2 部署技能 - Docker Compose、ROS2 容器化、设备映射、多机器人部署
argument-hint: "Docker" / "ROS2" / "容器化" / "docker-compose" / "deployment"
user-invocable: true
---

# Docker ROS2 部署技能

> ROS2 Docker 容器化部署

---

## 何时使用

当需要以下帮助时使用此技能：
- ROS2 Docker 镜像
- Docker Compose 部署
- 设备映射
- 多机器人部署
- 容器网络

---

## 核心实现

### ROS2 Dockerfile

```dockerfile
# ros2.Dockerfile
FROM ros:iron-ros-base-jammy

# 安装 ROS2 包
RUN apt-get update && \
    apt-get install -y \
        ros-iron-rclcpp \
        ros-iron-rclpy \
        ros-iron-std-msgs \
        ros-iron-geometry-msgs \
        ros-iron-sensor-msgs \
        ros-iron-nav-msgs \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 复制代码
COPY . /workspace/src/

# 编译
RUN . /opt/ros/iron/setup.sh && \
    colcon build --merge-install

# 设置环境
ENV ROS_DOMAIN_ID=42

CMD ["bash"]
```

### Docker Compose 配置

```yaml
# docker-compose.yml
version: '3.8'

services:
  robot:
    build:
      context: .
      dockerfile: ros2.Dockerfile
    container_name: robot_01
    environment:
      - ROS_DOMAIN_ID=42
      - ROS_IP=192.168.1.101
    devices:
      - /dev/video0:/dev/video0
      - /dev/ttyUSB0:/dev/ttyUSB0
    volumes:
      - ./config:/workspace/config
      - ./data:/workspace/data
    network_mode: host
    restart: unless-stopped
    
  perception:
    build:
      context: .
      dockerfile: perception.Dockerfile
    container_name: perception_01
    environment:
      - ROS_DOMAIN_ID=42
    depends_on:
      - robot
    network_mode: host
```

### 多机器人 Docker 部署

```yaml
# docker-compose.multi-robot.yml
version: '3.8'

services:
  robot_01:
    build: ./robot
    container_name: robot_01
    environment:
      - ROS_DOMAIN_ID=1
      - ROBOT_ID=1
      - ROS_IP=192.168.1.101
    devices:
      - /dev/video0:/dev/video0
    network_mode: host
    
  robot_02:
    build: ./robot
    container_name: robot_02
    environment:
      - ROS_DOMAIN_ID=2
      - ROBOT_ID=2
      - ROS_IP=192.168.1.102
    devices:
      - /dev/video1:/dev/video0
    network_mode: host
    
  central:
    build: ./central
    container_name: central_station
    environment:
      - ROS_DOMAIN_ID=0
    network_mode: host
    ports:
      - "8080:8080"  # Web 界面
```

### 设备映射和权限

```yaml
# 设备映射配置
services:
  robot:
    devices:
      # 相机
      - /dev/video0:/dev/video0
      # 激光雷达
      - /dev/ttyUSB0:/dev/ttyUSB0
      # 串口
      - /dev/ttyACM0:/dev/ttyACM0
    group_add:
      - dialout
      - video
    tmpfs:
      - /run:exec
```

### 资源限制

```yaml
# 资源限制配置
services:
  robot:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    shm_size: 256mb  # 共享内存
```
