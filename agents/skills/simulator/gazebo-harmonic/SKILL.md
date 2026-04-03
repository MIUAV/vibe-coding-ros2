---
name: gazebo-harmonic
description: Gazebo Harmonic 仿真器开发技能 - 机器人建模、仿真世界创建、传感器集成、插件开发
argument-hint: "创建gazebo仿真" / "添加传感器" / "编写gazebo插件"
user-invocable: true
---

# Gazebo Harmonic Simulation Skill

> 用于 Gazebo Harmonic 仿真器的机器人开发和仿真配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 在 Gazebo Harmonic 中创建机器人模型
- 构建仿真环境和场景
- 添加激光雷达、摄像头、IMU 等传感器
- 编写 Gazebo 插件
- 配置物理参数和物理引擎
- ROS2 与 Gazebo 集成

---

## 快速参考

### 安装 Gazebo Harmonic

```bash
# Ubuntu 22.04
sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt update
sudo apt install gz-harmonic
```

### 启动 Gazebo

```bash
# 启动空世界
gz sim -v4

# 启动指定世界文件
gz sim /path/to/world.sdf

# 启动 GUI
gz sim -g
```

### SDF 机器人模型基本结构

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="my_robot">
    <!-- 静态模型 -->
    <static>false</static>
    
    <!-- 链接 -->
    <link name="base_link">
      <!-- 惯性 -->
      <pose>0 0 0.1 0 0 0</pose>
      <inertial>
        <mass>1.0</mass>
        <inertia>
          <ixx>0.001</ixx>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyy>0.001</iyy>
          <iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      
      <!-- 碰撞体 -->
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
      </collision>
      
      <!-- 视觉 -->
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
        <material>
          <diffuse>0.5 0.5 0.5 1</diffuse>
        </material>
      </visual>
    </link>
    
    <!-- 关节 -->
    <joint name="wheel_joint" type="revolute">
      <parent>base_link</parent>
      <child>wheel_link</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>-1e16 1e16</limit>
      </axis>
    </joint>
  </model>
</sdf>
```

---

## 常用传感器配置

### 激光雷达 (LiDAR)

```xml
<link name="laser_link">
  <pose>0.2 0 0.1 0 0 0</pose>
  <sensor name="laser_sensor" type="gpu_lidar">
    <pose>0 0 0 0 0 0</pose>
    <update_rate>10</update_rate>
    <ray>
      <scan>
        <horizontal>
          <samples>360</samples>
          <resolution>1</resolution>
          <min_angle>-3.14159</min_angle>
          <max_angle>3.14159</max_angle>
        </horizontal>
      </scan>
      <range>
        <min>0.1</min>
        <max>30.0</max>
        <resolution>0.01</resolution>
      </range>
    </ray>
    <plugin filename="gz-sim-sensors-gpu-lidar" name="gz::sim::systems::GpuRaySensor">
      <ros>
        <namespace>/robot</namespace>
        <remap>/scan:=scan</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

### RGBD 摄像头

```xml
<link name="camera_link">
  <pose>0.3 0 0.15 0 0 0</pose>
  <sensor name="rgbd_camera" type="rgbd_camera">
    <update_rate>30</update_rate>
    <camera>
      <horizontal_fov>1.047</horizontal_fov>
      <image>
        <width>640</width>
        <height>480</height>
        <format>R8G8B8</format>
      </image>
      <clip>
        <near>0.1</near>
        <far>100</far>
      </clip>
    </camera>
    <plugin filename="gz-sim-sensors-rgbd-camera-system" name="gz::sim::systems::RgbdCamera">
      <ros>
        <namespace>/robot</namespace>
        <remap>/image:=rgb/image</remap>
        <remap>/depth:=depth/image</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

### IMU 传感器

```xml
<link name="imu_link">
  <pose>0 0 0.1 0 0 0</pose>
  <sensor name="imu_sensor" type="imu">
    <update_rate>100</update_rate>
    <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu">
      <ros>
        <namespace>/robot</namespace>
        <remap>/imu:=imu/data</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

---

## ROS2 集成

### 安装 ros_gz

```bash
# For ROS2 Humble
sudo apt install ros-humble-ros-gz-bridge ros-humble-ros-gz-sim ros-humble-ros-gz-image

# For ROS2 Iron
sudo apt install ros-iron-ros-gz-bridge ros-iron-ros-gz-sim ros-iron-ros-gz-image
```

### 桥接配置示例

```python
# launch/robot.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
import os
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_name = 'my_robot_bringup'
    pkg_dir = get_package_share_directory(pkg_name)
    
    # Gazebo 世界
    world_path = os.path.join(pkg_dir, 'worlds', 'robot.world')
    
    # 机器人描述
    robot_desc_path = os.path.join(pkg_dir, 'urdf', 'robot.urdf')
    
    # 关节状态控制器
    joint_state_broadcaster = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['joint_state_broadcaster'],
        output='screen'
    )
    
    # 关节控制器
    joint_controller = Node(
        package='controller_manager',
        executable='spawner',
        arguments=['joint_trajectory_controller'],
        output='screen'
    )
    
    return LaunchDescription([
        # Gazebo
        ExecuteProcess(
            cmd=['gz', 'sim', '-v4', world_path],
            output='screen'
        ),
        
        # ROS-GZ 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist'],
            output='screen'
        ),
        
        Node(
            package='ros_gz_image',
            executable='image_bridge',
            arguments=['/camera/image_raw@sensor_msgs/msg/Image@gz.msgs.Image'],
            output='screen'
        ),
    ])
```

### 创建 SDF 文件

```xml
<!-- worlds/robot.world -->
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="robot_world">
    <!-- 物理引擎 -->
    <physics name="physics" default="true">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    
    <!-- 光照 -->
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <intensity>1</intensity>
      <diffuse>0.8 0.8 0.8 1</diffuse>
    </light>
    
    <!-- 地面 -->
    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
            </plane>
          </geometry>
          <surface>
            <friction>
              <ode>
                <mu>1</mu>
                <mu2>1</mu2>
              </ode>
            </friction>
          </surface>
        </collision>
        <visual name="visual">
          <geometry>
            <plane>
              <size>100 100</size>
              <normal>0 0 1</normal>
            </plane>
          </geometry>
          <material>
            <ambient>0.5 0.5 0.5 1</ambient>
            <diffuse>0.5 0.5 0.5 1</diffuse>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

---

## Gazebo 插件开发

### 创建插件步骤

1. 创建包结构：
```bash
mkdir -p ~/gz_plugin_ws/src/gz_robot_plugin
cd ~/gz_plugin_world/src
git clone https://github.com/gazebosim/gz-sim.git
```

2. CMakeLists.txt：
```cmake
cmake_minimum_required(VERSION 3.10.2)
project(gz_robot_plugin)

find_package(gz-sim7 REQUIRED)
set(CMAKE_CXX_STANDARD 17)

add_library(robot_system SHARED
  src/robot_system.cc
)

target_link_libraries(robot_system
  gz-sim7::gz-sim
)

ament_target_dependencies(robot_system
  rclcpp
  geometry_msgs
)
```

3. 插件实现：
```cpp
#include <gz/sim/System.hh>
#include <gz/sim/Model.hh>
#include <gz/sim/EntityComponentManager.hh>

namespace robot_system
{
  class RobotSystem :
    public gz::sim::System,
    public gz::sim::ISystemConfigure
  {
    public: void Configure(
        const gz::sim::Entity &_entity,
        const std::shared_ptr<const sdf::Element> &_sdf,
        gz::sim::EntityComponentManager &_ecm,
        gz::sim::EventManager &_eventMgr) override
    {
      this->model = gz::sim::Model(_entity);
      RCLCPP_INFO(rclcpp::get_logger("robot_system"), 
                  "Robot system initialized");
    }

    private:
      gz::sim::Model model;
  };
}

// Register plugin
#include <gz/plugin/Register.hh>
GZ_ADD_PLUGIN(
  robot_system::RobotSystem,
  gz::sim::ISystemConfigure)
```

---

## 常见问题

### 问题 1: 模型无法加载

**解决方案**：
- 检查 SDF 语法
- 验证文件路径
- 确认惯性参数正确（非零）

### 问题 2: 传感器无数据

**解决方案**：
- 确认插件已加载
- 检查 ROS 命名空间
- 验证话题名称

### 问题 3: 物理仿真不稳定

**解决方案**：
- 增加 `max_step_size`
- 调整 `real_time_factor`
- 检查关节限位

---

## 相关资源

- [Gazebo 官方文档](https://gazebosim.org/docs/harmonic/building_robot/)
- [Gazebo 教程](https://gazebosim.org/docs/harmonic/tutorials)
- [ros_gz 仓库](https://github.com/gazebosim/ros_gz)
- [SDF 规范](http://sdformat.org/spec)

---

## 另见

- [robot-modeling](./robot-modeling/) - 机器人建模
- [sensor-integration](./sensor-integration/) - 传感器集成
- [plugin-development](./plugin-development/) - 插件开发
- [world-creation](./world-creation/) - 世界创建
- [ros2-integration](./ros2-integration/) - ROS2 集成
- [gazebo-simulation-env](./gazebo-simulation-env/) - 环境仿真
- [ROS2 Topic Communication](../../common/ros2-topic-communication/) - 话题通信
- [ROS2 Launch Advanced](../../common/ros2-launch-advanced/) - 启动配置
- [RViz2 开发技能](../rviz2/) - 可视化配置