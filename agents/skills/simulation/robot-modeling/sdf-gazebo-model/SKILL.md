---
name: sdf-gazebo-model
description: SDF Gazebo 模型技能 - SDF vs URDF、插件配置、Gazebo 特定标签
argument-hint: "SDF" / "Gazebo模型" / "plugin" / "sdf gazebo"
user-invocable: true
---

# SDF Gazebo 模型技能

> SDF 与 Gazebo 特有配置

---

## 何时使用

当需要以下帮助时使用此技能：
- SDF vs URDF
- Gazebo 插件
- 模型配置
- 状态发布
- Gazebo 特定参数

---

## 核心实现

### SDF Gazebo 特有标签

```xml
<?xml version="1.0"?>
<sdf version="1.9">
  <model name="gazebo_robot">
    
    <!-- Gazebo 特有配置 -->
    <static>false</static>
    <self_collide>false</self_collide>
    <enable_wind>false</enable_wind>
    <kinematic>false</kinematic>
    
    <!-- 物理引擎 -->
    <pose>0 0 0 0 0 0</pose>
    
    <!-- Gazebo 插件 -->
    <plugin name="gazebo_ros_diff_drive" filename="libgazebo_ros_diff_drive.so">
      <ros>
        <namespace>/robot</namespace>
        <remapping>cmd_vel:=diff_drive/cmd_vel</remapping>
        <remapping>odom:=diff_drive/odom</remapping>
      </ros>
      
      <!-- 车轮配置 -->
      <update_rate>50</update_rate>
      <left_joint>left_wheel_joint</left_joint>
      <right_joint>right_wheel_joint</right_joint>
      
      <!--  kinematics -->
      <wheel_separation>0.4</wheel_separation>
      <wheel_diameter>0.2</wheel_diameter>
      
      <!-- Limits -->
      <max_wheel_torque>20</max_wheel_torque>
      <max_wheel_acceleration>1.0</max_wheel_acceleration>
      
      <!-- Output -->
      <publish_odom>true</publish_odom>
      <publish_odom_tf>true</publish_odom_tf>
      <publish_wheel_tf>true</publish_wheel_tf>
      
      <odometry_frame>odom</odometry_frame>
      <robot_base_frame>base_footprint</robot_base_frame>
    </plugin>
    
    <!-- 差分驱动插件 -->
    <plugin name="gazebo_ros_kinect" filename="libgazebo_ros_kinect.so">
      <baseline>0.2</baseline>
      <alwaysOn>true</alwaysOn>
      <updateRate>1.0</updateRate>
      <cameraName>depth</cameraName>
      <frameName>camera_depth_optical_frame</frameName>
      <channelType>depth</channelType>
      <hackBaseline>0.07</hackBaseline>
    </plugin>
    
  </model>
</sdf>
```

### Gazebo ROS 控制插件

```xml
<!-- gazebo_ros_control -->
<plugin name="gazebo_ros_control" filename="libgazebo_ros_control.so">
  <robotNamespace>/robot</robotNamespace>
  <robotParam>robot_description</robotParam>
  <robotSimType>gazebo_ros_control/DefaultRobotHWSim</robotSimType>
  <parameters>/path/to/controllers.yaml</parameters>
</plugin>
```
