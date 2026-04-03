---
name: robot-sdf-modeling
description: 机器人 SDF 建模技能 - SDF 模型结构、链接关节、摩擦阻尼、ROS2 gazebo_ros
argument-hint: "SDF建模" / "sdf" / "robot model" / "link" / "joint"
user-invocable: true
---

# 机器人 SDF 建模技能

> Gazebo SDF 模型创建

---

## 何时使用

当需要以下帮助时使用此技能：
- SDF 模型结构
- 链接 (link) 定义
- 关节 (joint) 配置
- 碰撞和摩擦
- ROS2 Gazebo 模型

---

## 核心实现

### SDF 模型结构

```xml
<?xml version="1.0"?>
<sdf version="1.9">
  <model name="robot_name">
    <!-- 静态模型 -->
    <static>false</static>
    
    <!-- 物理引擎 -->
    <physics name="default_physics" type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    
    <!-- 链接定义 -->
    <link name="base_link">
      <pose>0 0 0.1 0 0 0</pose>
      
      <!-- 惯性 -->
      <inertial>
        <mass>10.0</mass>
        <inertia>
          <ixx>0.01</ixx>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyy>0.01</iyy>
          <iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      
      <!-- 碰撞几何 -->
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
        <surface>
          <friction>
            <ode>
              <mu>1.0</mu>
              <mu2>1.0</mu2>
            </ode>
          </friction>
        </surface>
      </collision>
      
      <!-- 视觉几何 -->
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.8 0.8 0.8 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 关节定义 -->
    <joint name="joint1" type="revolute">
      <parent>base_link</parent>
      <child>link1</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
          <effort>100</effort>
          <velocity>10</velocity>
        </limit>
      </axis>
    </joint>
  </model>
</sdf>
```

### ROS2 Gazebo 模型加载

```python
# launch/gazebo.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import ExecuteProcess

def generate_launch_description():
    return LaunchDescription([
        # 启动 Gazebo
        ExecuteProcess(
            cmd=['gzserver', '-s', 'libgazebo_ros_factory.so'],
            output='screen'
        ),
        
        # 加载模型
        Node(
            package='gazebo_ros',
            executable='spawn_entity',
            arguments=['-entity', 'robot_name', '-file', '/path/to/model.sdf'],
            output='screen'
        ),
        
        # ROS2-Gazebo 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/model/robot_name/pose@tf2_msgs/msg/TF@gz.msgs.Pose'],
            output='screen'
        )
    ])
```

### 摩擦和阻尼配置

```xml
<!-- 摩擦配置 -->
<surface>
  <friction>
    <ode>
      <mu>0.8</mu>        <!-- 静摩擦系数 -->
      <mu2>0.8</mu2>      <!-- 动摩擦系数 -->
      <fdir1>1 0 0</fdir1> <!-- 摩擦方向 -->
      <slip1>0</slip1>     <!-- 滑动摩擦 -->
      <slip2>0</slip2>
    </ode>
  </friction>
  <contact>
    <ode>
      <kp>1e7</kp>         <!-- 接触刚度 -->
      <kd>1e6</kd>         <!-- 接触阻尼 -->
      <max_vel>0.1</max_vel>
      <min_depth>0.001</min_depth>
    </ode>
  </contact>
</surface>

<!-- 关节阻尼 -->
<joint name="wheel_joint" type="revolute">
  <physics>
    <ode>
      <suspension>
        <cfm>0</cfm>
        <erp>0.2</erp>
      </suspension>
    </ode>
  </physics>
</joint>
```
