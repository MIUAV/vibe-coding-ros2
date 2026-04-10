# Simulation Task Context

## 仿真平台对比
| 平台 | 优势 | 劣势 | 推荐场景 |
|------|------|------|---------|
| Gazebo | ROS2 原生、物理丰富 | 渲染一般 | 通用机器人首选 |
| Isaac Sim | NVIDIA 渲染、物理精准 | 资源消耗大 | 室内视觉导航 |
| Mujoco | 接触动力学好、速度快 | 传感器少 | 机械臂、RL |
| Carla | 自动驾驶仿真 | 非 ROS2 原生 | 自动驾驶 |
| Webots | 跨平台、易上手 | 物理精度一般 | 教育、快速原型 |

## Gazebo SDF 物理配置
```xml
<physics name="gz_physics" type="ode">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
</physics>
```

## Gazebo sensor plugin 示例
```xml
<!-- 激光雷达_plugin -->
<plugin name="gazebo_ros_ray_sensor"
        filename="libgazebo_ros_ray_sensor.so">
  <ros>
    <namespace>/</namespace>
    <remapping>~/out:=scan</remapping>
  </ros>
  <output_type>sensor_msgs/LaserScan</output_type>
</plugin>

<!-- IMU plugin -->
<plugin name="gazebo_ros_imu_sensor"
        filename="libgazebo_ros_imu_sensor.so">
  <ros>
    <remapping>~/out:=imu</remapping>
  </ros>
  <frame_id>imu_link</frame_id>
</plugin>
```

## Gazebo-ROS2 桥接
```python
# launch.py
from launch_ros.actions import Node

Node(package='ros_gz_bridge', executable='parameter_bridge',
     arguments=['/model/vehicle_blue/odometry@nav_msgs/Odometry@gz.msgs.Odometry'],
     remappings=[('/model/vehicle_blue/odometry', '/odom')])
```

## 生成器选择
- `ros2-simulator-generator.sh` — diff|manipulator|drone|quadruped|wheeled
- `ros2-gazebo-world-generator.sh` — warehouse|office|outdoor|maze|factory
