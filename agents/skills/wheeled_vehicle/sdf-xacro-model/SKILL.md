---
name: sdf-xacro-model
description: 轮式车辆 SDF/XACRO 模型开发技能 - 差速驱动车、阿克曼车、履带车模型创建与仿真配置
argument-hint: 创建轮式车辆模型 OR 差速驱动 OR 阿克曼模型 OR 履带车
user-invocable: true
---

# Wheeled Vehicle SDF/XACRO Model Skill

> 用于创建轮式移动机器人的 SDF 和 XACRO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建差速驱动轮式机器人
- 创建阿克曼转向车辆
- 创建履带式机器人
- 配置轮式车辆传感器
- 设置仿真环境参数

---

## 快速参考

### 车辆类型选择

```cpp
// 差速驱动 - 适合室内移动机器人
// 阿克曼转向 - 适合户外车辆
// 履带式 - 适合复杂地形
```

---

## 差速驱动车辆

### SDF 模型 - 完整示例

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="diff_drive_robot">
    <static>false</static>
    <self_collide>false</self_collide>
    
    <!-- 基座链接 -->
    <link name="base_link">
      <pose>0 0 0.1 0 0 0</pose>
      <inertial>
        <mass>10.0</mass>
        <inertia>
          <ixx>0.1</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.1</iyy><iyz>0</iyz>
          <izz>0.1</izz>
        </inertia>
      </inertial>
      
      <!-- 基座碰撞体 -->
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.5 0.4 0.1</size>
          </box>
        </geometry>
      </collision>
      
      <!-- 基座视觉体 -->
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.5 0.4 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
          <diffuse>0.3 0.3 0.3 1</diffuse>
        </material>
      </visual>
    </link>
    
    <!-- 左前轮 -->
    <link name="wheel_fl">
      <pose>0.2 0.25 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="wheel_fl_collision">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
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
      <visual name="wheel_fl_visual">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_fl_joint" type="continuous">
      <parent>base_link</parent>
      <child>wheel_fl</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 右前轮 -->
    <link name="wheel_fr">
      <pose>0.2 -0.25 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="wheel_fr_collision">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_fr_visual">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_fr_joint" type="continuous">
      <parent>base_link</parent>
      <child>wheel_fr</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 左后轮 -->
    <link name="wheel_rl">
      <pose>-0.2 0.25 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="wheel_rl_collision">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_rl_visual">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_rl_joint" type="continuous">
      <parent>base_link</parent>
      <child>wheel_rl</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 右后轮 -->
    <link name="wheel_rr">
      <pose>-0.2 -0.25 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="wheel_rr_collision">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_rr_visual">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <length>0.05</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_rr_joint" type="continuous">
      <parent>base_link</parent>
      <child>wheel_rr</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 激光雷达 -->
    <link name="laser_link">
      <pose>0.25 0 0.15 0 0 0</pose>
      <sensor name="laser" type="gpu_lidar">
        <update_rate>10</update_rate>
        <ray>
          <scan>
            <horizontal>
              <samples>360</samples>
              <resolution>1</resolution>
            </horizontal>
          </scan>
          <range>
            <min>0.1</min>
            <max>30</max>
          </range>
        </ray>
        <plugin filename="gz-sim-sensors-gpu-lidar" name="gz::sim::systems::GpuRaySensor">
          <ros>
            <namespace>/robot</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="laser_joint" type="fixed">
      <parent>base_link</parent>
      <child>laser_link</child>
    </joint>
    
    <!-- 差速驱动插件 -->
    <plugin filename="gz-sim-diff-drive-system" name="gz::sim::systems::DiffDrive">
      <left_joint>wheel_fl_joint</left_joint>
      <right_joint>wheel_fr_joint</right_joint>
      <left_joint>wheel_rl_joint</left_joint>
      <right_joint>wheel_rr_joint</right_joint>
      <wheel_radius>0.1</wheel_radius>
      <wheel_separation>0.5</wheel_separation>
      <max_wheel_torque>20</max_wheel_torque>
      <max_wheel_velocity>10</max_wheel_velocity>
    </plugin>
  </model>
</sdf>
```

### XACRO 模型

```xml
<?xml version="1.0" ?>
<robot name="diff_drive_robot" xmlns:xacro="http://www.ros.org/wiki/xacro">
  
  <!-- 参数定义 -->
  <xacro:property name="PI" value="3.14159265358979"/>
  <xacro:property name="base_mass" value="10.0"/>
  <xacro:property name="base_length" value="0.5"/>
  <xacro:property name="base_width" value="0.4"/>
  <xacro:property name="base_height" value="0.1"/>
  
  <xacro:property name="wheel_radius" value="0.1"/>
  <xacro:property name="wheel_width" value="0.05"/>
  <xacro:property name="wheel_mass" value="0.5"/>
  <xacro:property name="wheel_separation" value="0.5"/>
  <xacro:property name="wheel_base" value="0.4"/>
  
  <!-- 基座宏 -->
  <xacro:macro name="base_link">
    <link name="base_link">
      <inertial>
        <mass value="${base_mass}"/>
        <inertia
          ixx="${base_mass / 12 * (base_width**2 + base_height**2)}"
          ixy="0" ixz="0"
          iyy="${base_mass / 12 * (base_length**2 + base_height**2)}"
          iyz="0"
          izz="${base_mass / 12 * (base_length**2 + base_width**2)}"/>
      </inertial>
      <collision>
        <geometry>
          <box size="${base_length} ${base_width} ${base_height}"/>
        </geometry>
      </collision>
      <visual>
        <geometry>
          <box size="${base_length} ${base_width} ${base_height}"/>
        </geometry>
        <material name="grey">
          <color rgba="0.3 0.3 0.3 1"/>
        </material>
      </visual>
    </link>
  </xacro:macro>
  
  <!-- 轮子宏 -->
  <xacro:macro name="wheel" params="name x y">
    <joint name="${name}_joint" type="continuous">
      <origin xyz="${x} ${y} 0" rpy="-${PI/2} 0 0"/>
      <parent link="base_link"/>
      <child link="${name}"/>
      <axis xyz="0 0 1"/>
      <dynamics damping="0.1" friction="0.5"/>
    </joint>
    
    <link name="${name}">
      <inertial>
        <mass value="${wheel_mass}"/>
        <inertia
          ixx="${wheel_mass * wheel_radius**2 / 2}"
          ixy="0" ixz="0"
          iyy="${wheel_mass * wheel_radius**2 / 2}"
          iyz="0"
          izz="${wheel_mass * wheel_radius**2 / 2}"/>
      </inertial>
      <collision>
        <geometry>
          <cylinder radius="${wheel_radius}" length="${wheel_width}"/>
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
      <visual>
        <geometry>
          <cylinder radius="${wheel_radius}" length="${wheel_width}"/>
        </geometry>
        <material name="black">
          <color rgba="0.1 0.1 0.1 1"/>
        </material>
      </visual>
    </link>
  </xacro:macro>
  
  <!-- 构建机器人 -->
  <xacro:base_link/>
  <xacro:wheel name="wheel_fl" x="${wheel_base/2}" y="${wheel_separation/2}"/>
  <xacro:wheel name="wheel_fr" x="${wheel_base/2}" y="-${wheel_separation/2}"/>
  <xacro:wheel name="wheel_rl" x="-${wheel_base/2}" y="${wheel_separation/2}"/>
  <xacro:wheel name="wheel_rr" x="-${wheel_base/2}" y="-${wheel_separation/2}"/>
  
  <!-- Gazebo 配置 -->
  <gazebo>
    <plugin filename="libgazebo_ros_diff_drive.so" name="gazebo_ros_diff_drive">
      <ros>
        <namespace>/robot</namespace>
        <remap>cmd_vel:=cmd_vel</remap>
        <remap>odom:=odom</remap>
      </ros>
      <update_rate>50</update_rate>
      <left_joint>wheel_fl_joint</left_joint>
      <right_joint>wheel_fr_joint</right_joint>
      <wheel_separation>${wheel_separation}</wheel_separation>
      <wheel_radius>${wheel_radius}</wheel_radius>
      <max_wheel_torque>20</max_wheel_torque>
      <max_wheel_velocity>10</max_wheel_velocity>
    </plugin>
  </gazebo>
  
</robot>
```

---

## 阿克曼转向车辆

### SDF 模型

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="ackermann_vehicle">
    <static>false</static>
    
    <!-- 车身 -->
    <link name="chassis">
      <pose>0 0 0.2 0 0 0</pose>
      <inertial>
        <mass>50.0</mass>
        <inertia>
          <ixx>0.5</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.8</iyy><iyz>0</iyz>
          <izz>0.8</izz>
        </inertia>
      </inertial>
      
      <collision name="chassis_collision">
        <geometry>
          <box>
            <size>1.0 0.5 0.2</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="chassis_visual">
        <geometry>
          <box>
            <size>1.0 0.5 0.2</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.2 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 前轴 - 可转向 -->
    <link name="front_axle">
      <pose>0.4 0 0.1 0 0 0</pose>
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="front_axle_collision">
        <geometry>
          <box>
            <size>0.1 0.4 0.1</size>
          </box>
        </geometry>
      </collision>
      <visual name="front_axle_visual">
        <geometry>
          <box>
            <size>0.1 0.4 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.2 0.2 0.2 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="front_steering_joint" type="revolute">
      <parent>chassis</parent>
      <child>front_axle</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-0.5</lower>
          <upper>0.5</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左前轮 -->
    <link name="wheel_fl">
      <pose>0.4 0.3 0.1 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="wheel_fl_collision">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_fl_visual">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_fl_joint" type="continuous">
      <parent>front_axle</parent>
      <child>wheel_fl</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 右前轮 -->
    <link name="wheel_fr">
      <pose>0.4 -0.3 0.1 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="wheel_fr_collision">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_fr_visual">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_fr_joint" type="continuous">
      <parent>front_axle</parent>
      <child>wheel_fr</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 后轮 (固定轴) -->
    <link name="wheel_rl">
      <pose>-0.4 0.25 0.1 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="wheel_rl_collision">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_rl_visual">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_rl_joint" type="continuous">
      <parent>chassis</parent>
      <child>wheel_rl</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <link name="wheel_rr">
      <pose>-0.4 -0.25 0.1 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="wheel_rr_collision">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="wheel_rr_visual">
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.1</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_rr_joint" type="continuous">
      <parent>chassis</parent>
      <child>wheel_rr</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 阿克曼驱动插件 -->
    <plugin filename="gz-sim-ackermann-steering-system" name="gz::sim::systems::AckermannSteering">
      <left_joint>wheel_fl_joint</left_joint>
      <right_joint>wheel_fr_joint</right_joint>
      <left_rear_joint>wheel_rl_joint</left_rear_joint>
      <right_rear_joint>wheel_rr_joint</right_rear_joint>
      <steering_joint>front_steering_joint</steering_joint>
      <wheel_radius>0.15</wheel_radius>
      <wheel_separation>0.6</wheel_separation>
      <axle_length>0.8</axle_length>
      <max_steering_angle>0.5</max_steering_angle>
    </plugin>
  </model>
</sdf>
```

---

## 履带式车辆

### SDF 模型

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="tracked_vehicle">
    <static>false</static>
    
    <!-- 车身 -->
    <link name="chassis">
      <pose>0 0 0.15 0 0 0</pose>
      <inertial>
        <mass>30.0</mass>
        <inertia>
          <ixx>0.3</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.5</iyy><iyz>0</iyz>
          <izz>0.5</izz>
        </inertia>
      </inertial>
      
      <collision name="chassis_collision">
        <geometry>
          <box>
            <size>0.8 0.4 0.15</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="chassis_visual">
        <geometry>
          <box>
            <size>0.8 0.4 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.2 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 左履带轮 -->
    <link name="track_left">
      <pose>0 0.25 0 0 0 0</pose>
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.05</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.05</iyy><iyz>0</iyz>
          <izz>0.05</izz>
        </inertia>
      </inertial>
      <collision name="track_left_collision">
        <geometry>
          <box>
            <size>0.8 0.1 0.1</size>
          </box>
        </geometry>
        <surface>
          <friction>
            <ode>
              <mu>2.0</mu>
              <mu2>2.0</mu2>
            </ode>
          </friction>
        </surface>
      </collision>
      <visual name="track_left_visual">
        <geometry>
          <box>
            <size>0.8 0.1 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="track_left_joint" type="continuous">
      <parent>chassis</parent>
      <child>track_left</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 右履带轮 -->
    <link name="track_right">
      <pose>0 -0.25 0 0 0 0</pose>
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.05</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.05</iyy><iyz>0</iyz>
          <izz>0.05</izz>
        </inertia>
      </inertial>
      <collision name="track_right_collision">
        <geometry>
          <box>
            <size>0.8 0.1 0.1</size>
          </box>
        </geometry>
        <surface>
          <friction>
            <ode>
              <mu>2.0</mu>
              <mu2>2.0</mu2>
            </ode>
          </friction>
        </surface>
      </collision>
      <visual name="track_right_visual">
        <geometry>
          <box>
            <size>0.8 0.1 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="track_right_joint" type="continuous">
      <parent>chassis</parent>
      <child>track_right</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>
    
    <!-- 差速驱动插件 -->
    <plugin filename="gz-sim-diff-drive-system" name="gz::sim::systems::DiffDrive">
      <left_joint>track_left_joint</left_joint>
      <right_joint>track_right_joint</right_joint>
      <wheel_radius>0.1</wheel_radius>
      <wheel_separation>0.5</wheel_separation>
      <max_wheel_torque>50</max_wheel_torque>
      <max_wheel_velocity>5</max_wheel_velocity>
    </plugin>
  </model>
</sdf>
```

---

## 传感器配置

### 轮式车辆常用传感器

```xml
<!-- 激光雷达 - 前置 -->
<link name="front_laser_link">
  <pose>0.4 0 0.15 0 0 0</pose>
  <sensor name="front_laser" type="gpu_lidar">
    <update_rate>10</update_rate>
    <ray>
      <scan>
        <horizontal>
          <samples>360</samples>
          <resolution>1</resolution>
        </horizontal>
      </scan>
      <range>
        <min>0.1</min>
        <max>30</max>
      </range>
    </ray>
    <plugin filename="gz-sim-sensors-gpu-lidar" name="gz::sim::systems::GpuRaySensor">
      <ros>
        <namespace>/robot</namespace>
      </ros>
    </plugin>
  </sensor>
</link>

<!-- 深度摄像头 -->
<link name="camera_link">
  <pose>0.3 0 0.2 0 0.3 0</pose>
  <sensor name="camera" type="rgbd_camera">
    <update_rate>30</update_rate>
    <camera>
      <horizontal_fov>1.57</horizontal_fov>
      <image>
        <width>640</width>
        <height>480</height>
      </image>
    </camera>
    <plugin filename="gz-sim-sensors-rgbd-camera-system" name="gz::sim::systems::RgbdCamera">
      <ros>
        <namespace>/robot</namespace>
      </ros>
    </plugin>
  </sensor>
</link>

<!-- IMU -->
<link name="imu_link">
  <pose>0 0 0.1 0 0 0</pose>
  <sensor name="imu" type="imu">
    <update_rate>100</update_rate>
    <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu">
      <ros>
        <namespace>/robot</namespace>
      </ros>
    </plugin>
  </sensor>
</link>

<!-- GPS -->
<link name="gps_link">
  <pose>0 0 0.2 0 0 0</pose>
  <sensor name="gps" type="gps">
    <update_rate>10</update_rate>
    <plugin filename="gz-sim-sensors-gps-system" name="gz::sim::systems::Gps">
      <ros>
        <namespace>/robot</namespace>
      </ros>
    </plugin>
  </sensor>
</link>
```

---

## 环境参数配置

### 地面摩擦参数

```xml
<gazebo reference="wheel">
  <surface>
    <friction>
      <ode>
        <mu>1.0</mu>
        <mu2>1.0</mu2>
        <fdir1>0 0 1</fdir1>
        <slip1>0</slip1>
        <slip2>0</slip2>
      </ode>
      <contact>
        <kp>1e7</kp>
        <kd>1</kd>
      </contact>
    </friction>
  </surface>
</gazebo>
```

### 负载配置

```xml
<gazebo reference="base_link">
  <!-- 附加负载质量 -->
  <mass>2.0</mass>
</gazebo>
```

---

## 常见问题

### 问题 1: 机器人滑动

**解决方案**：
- 增加轮子摩擦系数 (mu > 1.0)
- 检查关节阻尼设置
- 验证驱动扭矩

### 问题 2: 转向不准

**解决方案**：
- 调整阿克曼转向角度限制
- 验证前轴位置
- 检查转向关节限位

---

## 相关资源

- [Gazebo DiffDrive](https://gazebosim.org/docs/harmonic/diff_drive)
- [ROS2 Ackermann](https://github.com/ros-drivers/ackermann_msgs)
- [Wheeled Robot Models](https://gazebosim.org/models)

---

## 另见

- [navigation/](../navigation/) - 导航配置
- [perception/](../perception/) - 感知配置