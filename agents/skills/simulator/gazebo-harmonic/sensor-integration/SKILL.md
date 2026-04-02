---
name: sensor-integration
description: Gazebo 传感器集成技能 - LiDAR、相机、IMU、深度传感器配置
argument-hint: "gazebo传感器" / "添加激光雷达" / "相机配置"
user-invocable: true
---

# Gazebo Sensor Integration Skill

> 用于在 Gazebo Harmonic 中集成各类传感器

---

## 何时使用

当需要以下帮助时使用此技能：
- 添加激光雷达、摄像头、IMU 等传感器
- 配置传感器更新率和参数
- 设置 ROS 主题映射
- 传感器数据可视化

---

## 快速参考

### LiDAR 传感器

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

---

## LiDAR 配置

### 2D LiDAR

```xml
<sensor name="laser_2d" type="gpu_lidar">
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
```

### 3D LiDAR

```xml
<sensor name="laser_3d" type="gpu_lidar">
  <update_rate>10</update_rate>
  <ray>
    <scan>
      <horizontal>
        <samples>360</samples>
        <resolution>1</resolution>
        <min_angle>-3.14159</min_angle>
        <max_angle>3.14159</max_angle>
      </horizontal>
      <vertical>
        <samples>32</samples>
        <resolution>1</resolution>
        <min_angle>-0.26</min_angle>
        <max_angle>0.26</max_angle>
      </vertical>
    </scan>
    <range>
      <min>0.1</min>
      <max>100.0</max>
      <resolution>0.01</resolution>
    </range>
  </ray>
</sensor>
```

### 激光扫描参数

```xml
<ray>
  <range>
    <min>0.1</min>
    <max>50.0</max>
  </range>
  <scan>
    <horizontal>
      <samples>720</samples>  <!-- 增加采样提高分辨率 -->
      <resolution>0.5</resolution>
      <min_angle>-3.14159</min_angle>
      <max_angle>3.14159</max_angle>
    </horizontal>
  </scan>
  <noise>
    <type>gaussian</type>
    <mean>0.0</mean>
    <stddev>0.01</stddev>
  </noise>
</ray>
```

---

## 相机配置

### RGB 摄像头

```xml
<link name="camera_link">
  <pose>0.3 0 0.15 0 0 0</pose>
  <sensor name="rgb_camera" type="camera">
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
    <plugin filename="gz-sim-sensors-camera-system" name="gz::sim::systems::Camera">
      <ros>
        <namespace>/robot</namespace>
        <remap>/image:=rgb/image</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

### RGBD 摄像头

```xml
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
    <depth_camera>
      <image>
        <format>R_FLOAT32</format>
      </image>
    </depth_camera>
  </camera>
  <plugin filename="gz-sim-sensors-rgbd-camera-system" name="gz::sim::systems::RgbdCamera">
    <ros>
      <namespace>/robot</namespace>
      <remap>/image:=rgb/image</remap>
      <remap>/depth:=depth/image</remap>
    </ros>
  </plugin>
</sensor>
```

### 深度摄像头

```xml
<sensor name="depth_camera" type="depth_camera">
  <update_rate>30</update_rate>
  <camera>
    <horizontal_fov>1.047</horizontal_fov>
    <image>
      <width>640</width>
      <height>480</height>
      <format>R_FLOAT32</format>
    </image>
    <clip>
      <near>0.1</near>
      <far>10</far>
    </clip>
  </camera>
  <plugin filename="gz-sim-sensors-depth-camera-system" name="gz::sim::systems::DepthCamera">
    <ros>
      <namespace>/robot</namespace>
      <remap>/depth:=depth/image</remap>
    </ros>
  </plugin>
</sensor>
```

### 鱼眼/广角摄像头

```xml
<sensor name="fisheye_camera" type="camera">
  <camera>
    <horizontal_fov>3.14</horizontal_fov>  <!-- 180度 -->
    <image>
      <width>1920</width>
      <height>1080</height>
      <format>R8G8B8</format>
    </image>
    <lens>
      <type>fisheye</type>
      <intrinsics>
        <k1>0.0</k1>
        <k2>0.0</k2>
        <k3>0.0</k3>
        <p1>0.0</p1>
        <p2>0.0</p2>
        <cx>0.5</cx>
        <cy>0.5</cy>
        <fx>1.0</fx>
        <fy>1.0</fy>
      </intrinsics>
    </lens>
  </camera>
</sensor>
```

---

## IMU 传感器

```xml
<link name="imu_link">
  <pose>0 0 0.1 0 0 0</pose>
  <sensor name="imu_sensor" type="imu">
    <update_rate>100</update_rate>
    <orientation_enabled>true</orientation_enabled>
    <angular_velocity_enabled>true</angular_velocity_enabled>
    <linear_acceleration_enabled>true</linear_acceleration_enabled>
    <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu">
      <ros>
        <namespace>/robot</namespace>
        <remap>/imu:=imu/data</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

### IMU 噪声配置

```xml
<sensor name="imu_sensor" type="imu">
  <update_rate>100</update_rate>
  <orientation_enabled>true</orientation_enabled>
  <angular_velocity_enabled>true</angular_velocity_enabled>
  <linear_acceleration_enabled>true</linear_acceleration_enabled>
  
  <!-- 陀螺仪噪声 -->
  <gyroscope>
    <x>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.002</stddev>
      </noise>
    </x>
    <y>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.002</stddev>
      </noise>
    </y>
    <z>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.002</stddev>
      </noise>
    </z>
  </gyroscope>
  
  <!-- 加速度计噪声 -->
  <accelerometer>
    <x>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.01</stddev>
      </noise>
    </x>
    <y>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.01</stddev>
      </noise>
    </y>
    <z>
      <noise type="gaussian">
        <mean>0.0</mean>
        <stddev>0.01</stddev>
      </noise>
    </z>
  </accelerometer>
  
  <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu" />
</sensor>
```

---

## GPS / GNSS

```xml
<link name="gps_link">
  <pose>0 0 0.2 0 0 0</pose>
  <sensor name="gps_sensor" type="gps">
    <update_rate>10</update_rate>
    <position_sensing>
      <horizontal>
        <noise type="gaussian">
          <mean>0.0</mean>
          <stddev>0.01</stddev>
        </noise>
      </horizontal>
    </position_sensing>
    <vertical_sensing>
      <horizontal>
        <noise type="gaussian">
          <mean>0.0</mean>
          <stddev>0.01</stddev>
        </noise>
      </horizontal>
    </vertical_sensing>
    <plugin filename="gz-sim-sensors-gps-system" name="gz::sim::systems::Gps">
      <ros>
        <namespace>/robot</namespace>
        <remap>/gps:=gps/data</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

---

## 超声波传感器

```xml
<sensor name="ultrasonic_sensor" type="ultrasonic">
  <update_rate>20</update_rate>
  <ray>
    <scan>
      <horizontal>
        <samples>5</samples>
        <resolution>1</resolution>
        <min_angle>-0.26</min_angle>
        <max_angle>0.26</max_angle>
      </horizontal>
    </scan>
    <range>
      <min>0.02</min>
      <max>2.0</max>
      <resolution>0.01</resolution>
    </range>
  </ray>
  <plugin filename="gz-sim-sensors-ultrasonic-system" name="gz::sim::systems::Ultrasonic">
    <ros>
      <namespace>/robot</namespace>
      <remap>/ultrasonic:=ultrasonic/scan</remap>
    </ros>
  </plugin>
</sensor>
```

---

## 接触/力传感器

```xml
<sensor name="contact_sensor" type="contact">
  <update_rate>100</update_rate>
  <contact>
    <collision>base_collision</collision>
  </contact>
  <plugin filename="gz-sim-sensors-contact-system" name="gz::sim::systems::Contact">
    <ros>
      <namespace>/robot</namespace>
      <remap>/contact:=contact/force</remap>
    </ros>
  </plugin>
</sensor>
```

---

## 传感器位置和方向

### 传感器安装位置

```xml
<!-- 车顶激光雷达 -->
<link name="lidar_mount">
  <pose>0 0 0.3 0 0 0</pose>
  <sensor name="top_lidar" type="gpu_lidar">...</sensor>
</link>

<!-- 前保险杠摄像头 -->
<link name="front_camera">
  <pose>0.5 0 0.2 0 0 0</pose>
  <sensor name="front_cam" type="camera">...</sensor>
</link>

<!-- 后保险杠超声波 -->
<link name="rear_ultrasonic">
  <pose>-0.5 0 0.1 0 0 0</pose>
  <sensor name="rear_ultra" type="ultrasonic">...</sensor>
</link>

<!-- IMU 安装位置 -->
<link name="imu_mount">
  <pose>0 0 0 0 0 0</pose>
  <sensor name="imu" type="imu">...</sensor>
</link>
```

---

## ROS 主题映射

### 主题重映射

```xml
<plugin filename="gz-sim-sensors-lidar-system" name="gz::sim::systems::GpuRaySensor">
  <ros>
    <namespace>/my_robot</namespace>
    <remap>/scan:=sensors/scan</remap>
    <remap>/points:=sensors/points</remap>
    <remap>/cloud:=sensors/pointcloud</remap>
  </ros>
</plugin>
```

### 多传感器融合

```xml
<!-- 相机和激光雷达外参标定 -->
<link name="sensor_fusion">
  <pose>0.2 0 0.15 0 0 0</pose>
  <!-- 相机和激光雷达安装在一起 -->
</link>
```

---

## 常见问题

### 问题 1: 传感器无数据

**解决方案**：确认传感器已正确附加到链接，ROS 主题名称正确

### 问题 2: 传感器延迟高

**解决方案**：增加 update_rate，减少采样数

### 问题 3: 数据噪声大

**解决方案**：添加噪声配置，调整 stddev 参数

---

## 相关资源

- [Gazebo Sensors](https://gazebosim.org/docs/harmonic/sensors)
- [sensor_msgs](https://docs.ros.org/en/humble/p/sensor_msgs/)

---

## 另见

- [robot-modeling](../robot-modeling/) - 机器人建模
- [ros2-integration](../ros2-integration/) - ROS2 集成