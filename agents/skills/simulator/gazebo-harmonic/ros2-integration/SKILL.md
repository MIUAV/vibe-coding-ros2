---
name: ros2-integration
description: Gazebo ROS2 集成技能 - ros_gz 桥接、控制器启动、launch 文件配置
argument-hint: "gazebo ros2集成" / "ros_gz桥接" / "控制器配置"
user-invocable: true
---

# Gazebo ROS2 Integration Skill

> 用于 Gazebo Harmonic 与 ROS2 的集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 ros_gz
- 创建机器人 launch 文件
- 配置话题桥接
- 设置控制器

---

## 快速参考

### 安装 ros_gz

```bash
# For ROS2 Humble
sudo apt install ros-humble-ros-gz-bridge ros-humble-ros-gz-sim ros-humble-ros-gz-image

# For ROS2 Iron
sudo apt install ros-iron-ros-gz-bridge ros-iron-ros-gz-sim ros-iron-ros-gz-image
```

---

## 话题桥接

### 基本桥接配置

```python
# launch/bridge.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # 	cmd_vel 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'
            ],
            output='screen'
        ),
        
        # 	激光扫描桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/scan@sensor_msgs/msg/LaserScan@gz.msgs.LaserScan'
            ],
            output='screen'
        ),
        
        # 	图像桥接
        Node(
            package='ros_gz_image',
            executable='image_bridge',
            arguments=['/camera/image_raw@sensor_msgs/msg/Image@gz.msgs.Image'],
            output='screen'
        ),
    ])
```

### 多传感器桥接

```python
from launch import LaunchDescription
from launch_ros.actions import Node
import os
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_name = 'robot_bringup'
    pkg_dir = get_package_share_directory(pkg_name)
    
    # 获取 robot_description
    robot_desc_path = os.path.join(pkg_dir, 'urdf', 'robot.urdf')
    with open(robot_desc_path, 'r') as f:
        robot_description = f.read()
    
    return LaunchDescription([
        # 里程计桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/odom@nav_msgs/msg/Odometry@gz.msgs.Odometry'
            ],
            output='screen'
        ),
        
        # IMU 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/imu@sensor_msgs/msg/Imu@gz.msgs.IMU'
            ],
            output='screen'
        ),
        
        # .pointcloud2 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/points@sensor_msgs/msg/PointCloud2@gz.msgs.PointCloudPacked'
            ],
            output='screen'
        ),
        
        # TF 静态变换
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            parameters=[{'robot_description': robot_description}],
            output='screen'
        ),
    ])
```

---

## Launch 文件

### 完整机器人启动

```python
# launch/robot.launch.py
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess
from launch_ros.actions import Node
from launch.substitutions import LaunchConfiguration
import os
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_name = 'robot_bringup'
    pkg_dir = get_package_share_directory(pkg_name)
    
    # 参数
    use_sim_time = LaunchConfiguration('use_sim_time', default='true')
    
    # 路径
    world_path = os.path.join(pkg_dir, 'worlds', 'robot.world')
    robot_desc_path = os.path.join(pkg_dir, 'urdf', 'robot.urdf')
    
    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time',
            default_value='true',
            description='Use sim time'
        ),
        
        # Gazebo 进程
        ExecuteProcess(
            cmd=['gz', 'sim', '-v4', world_path],
            output='screen'
        ),
        
        # 加载机器人到 Gazebo
        Node(
            package='ros_gz_sim',
            executable='create',
            arguments=[
                '-name', 'robot',
                '-file', robot_desc_path,
                '-x', '0',
                '-y', '0',
                '-z', '0.1'
            ],
            output='screen'
        ),
        
        # robot_state_publisher
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            parameters=[{
                'robot_description': open(robot_desc_path).read(),
                'use_sim_time': use_sim_time
            }],
            output='screen'
        ),
        
        # 关节状态控制器
        Node(
            package='controller_manager',
            executable='spawner',
            arguments=['joint_state_broadcaster'],
            output='screen'
        ),
        
        # 机器人控制器
        Node(
            package='controller_manager',
            executable='spawner',
            arguments=['diff_drive_controller'],
            output='screen'
        ),
        
        # ROS-GZ 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=[
                '/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist',
                '/odom@nav_msgs/msg/Odometry@gz.msgs.Odometry',
                '/scan@sensor_msgs/msg/LaserScan@gz.msgs.LaserScan',
                '/imu@sensor_msgs/msg/Imu@gz.msgs.IMU'
            ],
            output='screen'
        ),
        
        # 图像桥接
        Node(
            package='ros_gz_image',
            executable='image_bridge',
            arguments=['/camera/image_raw@sensor_msgs/msg/Image@gz.msgs.Image'],
            output='screen'
        ),
    ])
```

---

## 控制器配置

### 差速驱动控制器

```yaml
# config/diff_drive_controller.yaml
controller_manager:
  ros__parameters:
    update_rate: 50
    
    diff_drive_controller:
      type: diff_drive_controller/DiffDriveController

diff_drive_controller:
  ros__parameters:
    left_wheel_names: ['left_wheel_joint']
    right_wheel_names: ['right_wheel_joint']
    
    wheel_separation: 0.4
    wheel_radius: 0.1
    
    max_wheel_odom_velocity: 10.0
    max_wheel_acceleration: 10.0
    publish_rate: 50.0
    
    command_timeout: 0.1
    
    base_frame_id: base_link
    odom_frame_id: odom
    
    enable_odom_tf: true
    enable_odom_computation: true
    
    velocity_aggregation: "mean"
    
    # PID 控制器参数
    vel_timeout: 0.5
    
    # 发布话题
    publish_cmd: true
    publish_odom: true
    publish_wheel_states: true
```

### Joint 控制器

```yaml
# config/joint_trajectory_controller.yaml
controller_manager:
  ros__parameters:
    update_rate: 100
    
    joint_trajectory_controller:
      type: joint_trajectory_controller/JointTrajectoryController

joint_trajectory_controller:
  ros__parameters:
    joints:
      - arm_joint_1
      - arm_joint_2
      - arm_joint_3
      - arm_joint_4
      - arm_joint_5
      - arm_joint_6
    
    command_interfaces:
      - position
    
    state_interfaces:
      - position
      - velocity
    
    gains:
      arm_joint_1: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
      arm_joint_2: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
      arm_joint_3: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
      arm_joint_4: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
      arm_joint_5: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
      arm_joint_6: {p: 100.0, d: 10.0, i: 0.0, i_clamp: 1.0}
    
    state_publish_rate: 25.0
    action_monitor_rate: 20.0
    
    allow_partial_joints_goal: false
    constraints:
      stopped_velocity_tolerance: 0.05
      goal_time: 0.6
```

---

## 参数配置

### 使用 xacro 生成 URDF

```xml
<!-- urdf/robot.urdf.xacro -->
<?xml version="1.0" ?>
<robot name="robot" xmlns:xacro="http://www.ros.org/wiki/xacro">
  
  <!-- 参数 -->
  <xacro:property name="robot_name" value="my_robot" />
  <xacro:property name="mesh_dir" value="package://robot_description/meshes" />
  
  <!-- 包含其他文件 -->
  <xacro:include filename="$(find robot_description)/urdf/robot.gazebo" />
  
  <!-- 链接 -->
  <link name="base_link">
    ...
  </link>
  
  <!-- 关节 -->
  <joint name="wheel_joint" type="revolute">
    ...
  </joint>
  
</robot>
```

```bash
# 生成 URDF
xacro robot.urdf.xacro > robot.urdf
```

---

## 常用命令

### 启动 Gazebo

```bash
# 空世界
gz sim -v4

# 指定世界文件
gz sim -v4 /path/to/world.sdf

# GUI 模式
gz sim -g

# 服务器模式 (无 GUI)
gz sim -s
```

### 调试

```bash
# 查看话题列表
ros2 topic list

# 查看话题数据
ros2 topic echo /scan

# 手动加载模型
ros2 run ros_gz_sim create -name my_robot -file /path/to/robot.sdf
```

---

## 常见问题

### 问题 1: 桥接不工作

**解决方案**：确认 ROS2 和 Gazebo 的话题名称匹配，检查日志输出

### 问题 2: 控制器无法启动

**解决方案**：确认 joint 名称与 URDF 中一致，检查 controller_manager 配置

### 问题 3: 模型加载失败

**解决方案**：检查模型路径是否正确，确认 SDF/URDF 语法正确

---

## 相关资源

- [ros_gz](https://github.com/gazebosim/ros_gz)
- [ros2_control](https://control.ros.org/)

---

## 另见

- [robot-modeling](../robot-modeling/) - 机器人建模
- [sensor-integration](../sensor-integration/) - 传感器集成
- [world-creation](../world-creation/) - 世界创建