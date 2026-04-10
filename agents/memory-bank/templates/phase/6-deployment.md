# Phase 6: Deployment & Operation

## 启动顺序
```bash
# 1. 传感器 driver
ros2 launch <pkg> sensor_driver.launch.py
# 2. 感知节点
ros2 launch <pkg> perception.launch.py
# 3. 导航/规划
ros2 launch nav2_bringup bringup_launch.py
# 4. 控制节点
ros2 launch <pkg> control.launch.py
# 或统一入口
ros2 launch <pkg> robot_bringup.launch.py
```

## Docker 部署
```dockerfile
FROM ros:${ROS_DISTRO}-ros-base
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    && rm -rf /var/lib/apt/lists/*
COPY ./install /home/robot/install
RUN /bin/bash -c 'source /home/robot/install/setup.bash'
ENTRYPOINT ["/bin/bash", "-c", "source /home/robot/install/setup.bash && exec $@"]
```

## systemd 服务（边缘常驻）
```ini
[Unit]
Description=My Robot ROS2 Bringup
After=network.target

[Service]
Type=simple
User=robot
ExecStart=/usr/bin/bash -c 'source /opt/ros/humble/setup.bash && \
    source /home/robot/install/setup.bash && \
    ros2 launch my_robot robot_bringup.launch.py'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## 监控与日志
```bash
# 自动 bag 记录
ros2 bag record -a -o robot_run_$(date +%Y%m%d_%H%M%S)

# 关键日志
ls ~/.ros/log/

# 运行时监控
ros2 run rqt_graph rqt_graph
ros2 run rqt_plot rqt_plot
```

## 远程调试
```bash
# SSH 端口转发 rviz
ssh -L 11311:localhost:11311 robot@<robot-ip>

# 代码同步
rsync -avz --exclude='build/' --exclude='install/' \
    ./ robot@<robot-ip>:/home/robot/workspace/
```
