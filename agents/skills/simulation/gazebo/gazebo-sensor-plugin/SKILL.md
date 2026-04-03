---
name: gazebo-sensor-plugin
description: Gazebo 传感器插件技能 - 激光雷达、相机、IMU、深度相机插件配置
argument-hint: "Gazebo传感器" / "laser" / "camera" / "imu" / "sensor plugin"
user-invocable: true
---

# Gazebo 传感器插件技能

> Gazebo 传感器插件配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 激光雷达插件
- 相机插件
- IMU 插件
- 深度相机插件
- ROS2 Gazebo 桥接

---

## 核心实现

### 激光雷达插件

```xml
<!-- Gazebo 激光雷达 -->
<link name="lidar_link">
  <sensor name="lidar_sensor" type="ray">
    <pose>0 0 0 0 0 0</pose>
    <visualize>true</visualize>
    <update_rate>10</update_rate>
    
    <ray>
      <scan>
        <horizontal>
          <samples>720</samples>
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
      
      <noise>
        <type>gaussian</type>
        <mean>0.0</mean>
        <stddev>0.01</stddev>
      </noise>
    </ray>
    
    <plugin name="gazebo_ros_ray_sensor" filename="libgazebo_ros_ray_sensor.so">
      <ros>
        <namespace>/robot</namespace>
        <remapping>out:=scan</remapping>
      </ros>
      <output_type>sensor_msgs/LaserScan</output_type>
    </plugin>
  </sensor>
</link>
```

### 相机插件

```xml
<!-- Gazebo 相机 -->
<link name="camera_link">
  <sensor name="camera_sensor" type="camera">
    <update_rate>30</update_rate>
    <camera name="rgb_camera">
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
    
    <plugin name="gazebo_ros_camera" filename="libgazebo_ros_camera.so">
      <ros>
        <namespace>/robot</namespace>
        <remapping>image_raw:=camera/image_raw</remapping>
        <remapping>camera_info:=camera/camera_info</remapping>
      </ros>
      <camera_name>rgb</camera_name>
      <frame_name>camera_link</frame_name>
    </plugin>
  </sensor>
</link>
```

### IMU 插件

```xml
<!-- Gazebo IMU -->
<link name="imu_link">
  <sensor name="imu_sensor" type="imu">
    <always_on>true</always_on>
    <update_rate>100</update_rate>
    
    <imu>
      <angular_velocity>
        <x>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.0002</stddev>
          </noise>
        </x>
        <y>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.0002</stddev>
          </noise>
        </y>
        <z>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.0002</stddev>
          </noise>
        </z>
      </angular_velocity>
      
      <linear_acceleration>
        <x>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.017</stddev>
          </noise>
        </x>
        <y>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.017</stddev>
          </noise>
        </y>
        <z>
          <noise type="gaussian">
            <mean>0</mean>
            <stddev>0.017</stddev>
          </noise>
        </z>
      </linear_acceleration>
    </imu>
    
    <plugin name="gazebo_ros_imu" filename="libgazebo_ros_imu.so">
      <ros>
        <namespace>/robot</namespace>
        <remapping>imu:=imu</remapping>
      </ros>
      <frame_name>imu_link</frame_name>
    </plugin>
  </sensor>
</link>
```

### ROS2 Gazebo 桥接

```python
# launch/gazebo_bridge.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # 激光扫描桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/lidar/scan@sensor_msgs/msg/LaserScan@gz.msgs.LaserScan'],
            remappings=[('/lidar/scan', '/scan')]
        ),
        
        # 图像桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/camera/image_raw@sensor_msgs/msg/Image@gz.msgs.Image'],
            remappings=[('/camera/image_raw', '/image_raw')]
        ),
        
        # TF 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/tf@tf2_msgs/msg/TFMessage@gz.msgs.Pose_V']
        ),
        
        # IMU 桥接
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['/imu/data@sensor_msgs/msg/Imu@gz.msgs.IMU']
        )
    ])
```
