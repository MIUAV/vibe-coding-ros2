---
name: urdf-xacro-creation
description: URDF/Xacro 创建技能 - URDF 语法、宏定义、传输配置、ROS2 控制器
argument-hint: "URDF" / "xacro" / "robot_description" / "URDF创建"
user-invocable: true
---

# URDF/Xacro 创建技能

> 机器人 URDF/Xacro 模型创建

---

## 何时使用

当需要以下帮助时使用此技能：
- URDF 语法
- Xacro 宏
- 传输配置 (transmission)
- 控制器配置
- ROS2 机器人状态发布

---

## 核心实现

### URDF 模型

```xml
<!-- robot.urdf -->
<?xml version="1.0"?>
<robot name="robot_name">
  
  <!-- 链接定义 -->
  <link name="base_link">
    <visual>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry>
        <box size="0.5 0.5 0.2"/>
      </geometry>
      <material name="blue">
        <color rgba="0 0 0.8 1"/>
      </material>
    </visual>
    
    <collision>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry>
        <box size="0.5 0.5 0.2"/>
      </geometry>
    </collision>
    
    <inertial>
      <mass value="10.0"/>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <inertia ixx="0.1" ixy="0" ixz="0" iyy="0.1" iyz="0" izz="0.1"/>
    </inertial>
  </link>
  
  <!-- 关节定义 -->
  <joint name="joint1" type="revolute">
    <parent link="base_link"/>
    <child link="link1"/>
    <origin xyz="0.25 0 0" rpy="0 0 0"/>
    <axis xyz="0 0 1"/>
    <limit lower="-3.14" upper="3.14" effort="100" velocity="10"/>
    <dynamics damping="0.7" friction="0.5"/>
  </joint>
  
  <!-- 传输 -->
  <transmission name="joint1_trans">
    <type>transmission_interface/SimpleTransmission</type>
    <joint name="joint1">
      <hardwareInterface>hardware_interface/EffortJointInterface</hardwareInterface>
    </joint>
    <actuator name="motor1">
      <hardwareInterface>hardware_interface/EffortJointInterface</hardwareInterface>
      <mechanicalReduction>1</mechanicalReduction>
    </actuator>
  </transmission>
  
</robot>
```

### Xacro 宏

```xml
<!-- robot.xacro -->
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro">
  
  <!-- 常量定义 -->
  <xacro:property name="PI" value="3.14159"/>
  <xacro:property name="robot_name" value="my_robot"/>
  
  <!-- 宏定义 -->
  <xacro:macro name="box_inertia" params="mass width height depth *origin">
    <inertial>
      <xacro:insert_block name="origin"/>
      <mass value="${mass}"/>
      <inertia ixx="${mass/12*(height**2 + depth**2)}" 
               iyy="${mass/12*(width**2 + depth**2)}" 
               izz="${mass/12*(width**2 + height**2)}"/>
    </inertial>
  </xacro:macro>
  
  <!-- 包含其他文件 -->
  <xacro:include filename="$(find my_robot_description)/urdf/materials.xacro"/>
  
  <!-- 条件参数 -->
  <xacro:if value="$(arg use_gazebo)">
    <gazebo>
      <plugin name="gazebo_ros_control" filename="libgazebo_ros_control.so"/>
    </gazebo>
  </xacro:if>
  
</robot>
```

### ROS2 控制器配置

```yaml
# config/robot_controllers.yaml
controller_manager:
  ros__parameters:
    update_rate: 100
    
    joint_trajectory_controller:
      type: joint_trajectory_controller/JointTrajectoryController
    
    joint_state_broadcaster:
      type: joint_state_broadcaster/JointStateBroadcaster

joint_trajectory_controller:
  ros__parameters:
    joints:
      - joint1
      - joint2
    command_interfaces:
      - position
    state_interfaces:
      - position
      - velocity
```
