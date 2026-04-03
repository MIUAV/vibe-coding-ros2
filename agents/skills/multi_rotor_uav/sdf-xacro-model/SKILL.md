---
name: sdf-xacro-model
description: 多旋翼无人机 SDF/XACRO 模型开发技能 - 四旋翼、六旋翼、八旋翼模型创建、飞行物理配置、环境风力仿真
argument-hint: 创建无人机模型 OR 四旋翼 OR 六旋翼 OR 无人机仿真
user-invocable: true
---

# Multi-Rotor UAV SDF/XACRO Model Skill

> 用于创建多旋翼无人机的 SDF 和 XACRO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建多旋翼无人机模型
- 配置飞行物理参数
- 添加风力/扰动仿真
- 设置负载和传感器
- 配置起飞/降落状态

---

## 快速参考

### 常见配置

```
四旋翼 (Quadrotor)   - 简单、紧凑
六旋翼 (Hexrotor)    - 更大负载、更稳定
八旋翼 (Octrotor)    - 最大负载、高冗余
```

---

## 四旋翼无人机

### SDF 模型 - 完整示例

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="quadrotor">
    <static>false</static>
    <self_collide>false</self_collide>
    
    <!-- 机身 -->
    <link name="base_link">
      <pose>0 0 0.05 0 0 0</pose>
      <inertial>
        <mass>1.5</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.02</izz>
        </inertia>
      </inertial>
      
      <!-- 碰撞体 -->
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.2 0.2 0.05</size>
          </box>
        </geometry>
      </collision>
      
      <!-- 视觉体 -->
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.2 0.2 0.05</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
          <diffuse>0.3 0.3 0.3 1</diffuse>
        </material>
      </visual>
      
      <!-- 螺旋桨保护圈 -->
      <visual name="prop_guard">
        <pose>0 0 0.02 0 0 0</pose>
        <geometry>
          <cylinder>
            <radius>0.15</radius>
            <length>0.01</length>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.5 0.5 0.8 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 左前电机 (CW) -->
    <link name="motor_fl">
      <pose>0.15 0.15 0.03 0 0 0</pose>
      <inertial>
        <mass>0.05</mass>
        <inertia>
          <ixx>0.0001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0001</iyy><iyz>0</iyz>
          <izz>0.0001</izz>
        </inertia>
      </inertial>
      <collision name="motor_fl_collision">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
      </collision>
      <visual name="motor_fl_visual">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="motor_fl_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_fl</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1000</lower>
          <upper>1000</upper>
          <effort>10</effort>
          <velocity>1000</velocity>
        </limit>
      </axis>
    </joint>
    
    <!-- 右前电机 (CCW) -->
    <link name="motor_fr">
      <pose>0.15 -0.15 0.03 0 0 0</pose>
      <inertial>
        <mass>0.05</mass>
        <inertia>
          <ixx>0.0001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0001</iyy><iyz>0</iyz>
          <izz>0.0001</izz>
        </inertia>
      </inertial>
      <collision name="motor_fr_collision">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
      </collision>
      <visual name="motor_fr_visual">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="motor_fr_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_fr</child>
      <axis>
        <xyz>0 0 1</xyz>
      </axis>
    </joint>
    
    <!-- 左后电机 (CCW) -->
    <link name="motor_rl">
      <pose>-0.15 0.15 0.03 0 0 0</pose>
      <inertial>
        <mass>0.05</mass>
        <inertia>
          <ixx>0.0001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0001</iyy><iyz>0</iyz>
          <izz>0.0001</izz>
        </inertia>
      </inertial>
      <collision name="motor_rl_collision">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
      </collision>
      <visual name="motor_rl_visual">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="motor_rl_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_rl</child>
      <axis>
        <xyz>0 0 1</xyz>
      </axis>
    </joint>
    
    <!-- 右后电机 (CW) -->
    <link name="motor_rr">
      <pose>-0.15 -0.15 0.03 0 0 0</pose>
      <inertial>
        <mass>0.05</mass>
        <inertia>
          <ixx>0.0001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0001</iyy><iyz>0</iyz>
          <izz>0.0001</izz>
        </inertia>
      </inertial>
      <collision name="motor_rr_collision">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
      </collision>
      <visual name="motor_rr_visual">
        <geometry>
          <cylinder>
            <radius>0.015</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.1 0.1 0.1 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="motor_rr_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_rr</child>
      <axis>
        <xyz>0 0 1</xyz>
      </axis>
    </joint>
    
    <!-- 螺旋桨 (视觉) -->
    <link name="prop_fl">
      <pose>0.15 0.15 0.05 0 0 0</pose>
      <inertial>
        <mass>0.01</mass>
        <inertia>
          <ixx>0.00001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.00001</iyy><iyz>0</iyz>
          <izz>0.00001</izz>
        </inertia>
      </inertial>
      <visual name="prop_fl_visual">
        <geometry>
          <cylinder>
            <radius>0.08</radius>
            <height>0.005</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.8 0.8 0.8 0.5</ambient>
          <transparency>0.5</transparency>
        </material>
      </visual>
    </link>
    
    <joint name="prop_fl_joint" type="fixed">
      <parent>motor_fl</parent>
      <child>prop_fl</child>
    </joint>
    
    <!-- 传感器 - 激光雷达 -->
    <link name="laser_link">
      <pose>0 0 0.05 0 0 0</pose>
      <sensor name="laser" type="gpu_lidar">
        <update_rate>20</update_rate>
        <ray>
          <scan>
            <horizontal>
              <samples>360</samples>
              <resolution>1</resolution>
            </horizontal>
          </scan>
          <range>
            <min>0.1</min>
            <max>50</max>
          </range>
        </ray>
        <plugin filename="gz-sim-sensors-gpu-lidar" name="gz::sim::systems::GpuRaySensor">
          <ros>
            <namespace>/uav</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="laser_joint" type="fixed">
      <parent>base_link</parent>
      <child>laser_link</child>
    </joint>
    
    <!-- GPS -->
    <link name="gps_link">
      <pose>0 0.1 0.05 0 0 0</pose>
      <sensor name="gps" type="gps">
        <update_rate>10</update_rate>
        <plugin filename="gz-sim-sensors-gps-system" name="gz::sim::systems::Gps">
          <ros>
            <namespace>/uav</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="gps_joint" type="fixed">
      <parent>base_link</parent>
      <child>gps_link</child>
    </joint>
    
    <!-- IMU -->
    <link name="imu_link">
      <pose>0 0 0.02 0 0 0</pose>
      <sensor name="imu" type="imu">
        <update_rate>100</update_rate>
        <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu">
          <ros>
            <namespace>/uav</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="imu_joint" type="fixed">
      <parent>base_link</parent>
      <child>imu_link</child>
    </joint>
    
    <!-- 多旋翼控制器插件 -->
    <plugin filename="gz-sim-multirotor-physics-plugin" name="gz::sim::systems::MultirotorPhysics">
      <robotNamespace>uav</robotNamespace>
      <robotName>quadrotor</robotName>
      <motors>
        <motor>
          <name>motor_fl</name>
          <link>prop_fl</link>
          <direction>clockwise</direction>
          <thrust_coefficient>8.548e-6</thrust_coefficient>
          <torque_coefficient>1e-5</torque_coefficient>
        </motor>
        <motor>
          <name>motor_fr</name>
          <link>prop_fr</link>
          <direction>counter_clockwise</direction>
          <thrust_coefficient>8.548e-6</thrust_coefficient>
          <torque_coefficient>1e-5</torque_coefficient>
        </motor>
        <motor>
          <name>motor_rl</name>
          <link>prop_rl</link>
          <direction>counter_clockwise</direction>
          <thrust_coefficient>8.548e-6</thrust_coefficient>
          <torque_coefficient>1e-5</torque_coefficient>
        </motor>
        <motor>
          <name>motor_rr</name>
          <link>prop_rr</link>
          <direction>clockwise</direction>
          <thrust_coefficient>8.548e-6</thrust_coefficient>
          <torque_coefficient>1e-5</torque_coefficient>
        </motor>
      </motors>
      <control>
        <type>velocity</type>
        <takeoff>true</takeoff>
        <land>true</land>
      </control>
    </plugin>
  </model>
</sdf>
```

---

## 六旋翼无人机

### SDF 模型

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="hexrotor">
    <static>false</static>
    
    <!-- 机身 -->
    <link name="base_link">
      <pose>0 0 0.08 0 0 0</pose>
      <inertial>
        <mass>3.0</mass>
        <inertia>
          <ixx>0.02</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.02</iyy><iyz>0</iyz>
          <izz>0.04</izz>
        </inertia>
      </inertial>
      
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.25 0.25 0.08</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.25 0.25 0.08</size>
          </box>
        </geometry>
        <material>
          <ambient>0.2 0.2 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 六轴位置 (等边六边形布局) -->
    <!-- 电机1: 前右 30度 -->
    <!-- 电机2: 右 90度 -->
    <!-- 电机3: 后右 150度 -->
    <!-- 电机4: 后左 210度 -->
    <!-- 电机5: 左 270度 -->
    <!-- 电机6: 前左 330度 -->
    
    <!-- 定义六轴位置 -->
    <link name="motor_1">
      <pose>0.2 0.115 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
      <visual name="motor_1_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.025</height>
          </cylinder>
        </geometry>
      </visual>
    </link>
    <joint name="motor_1_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_1</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <link name="motor_2">
      <pose>0.1 0.23 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
      <visual name="motor_2_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.025</height>
          </cylinder>
        </geometry>
      </visual>
    </link>
    <joint name="motor_2_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_2</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <link name="motor_3">
      <pose>-0.1 0.23 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
    </link>
    <joint name="motor_3_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_3</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <link name="motor_4">
      <pose>-0.2 0.115 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
    </link>
    <joint name="motor_4_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_4</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <link name="motor_5">
      <pose>-0.2 -0.115 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
    </link>
    <joint name="motor_5_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_5</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <link name="motor_6">
      <pose>-0.1 -0.23 0.05 0 0 0</pose>
      <inertial>
        <mass>0.08</mass>
        <inertia>
          <ixx>0.0002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0002</iyy><iyz>0</iyz>
          <izz>0.0002</izz>
        </inertia>
      </inertial>
    </link>
    <joint name="motor_6_joint" type="revolute">
      <parent>base_link</parent>
      <child>motor_6</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <!-- 六旋翼控制器 -->
    <plugin filename="gz-sim-multirotor-physics-plugin" name="gz::sim::systems::MultirotorPhysics">
      <robotNamespace>uav</robotNamespace>
      <motors>
        <motor><name>motor_1</name><direction>clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
        <motor><name>motor_2</name><direction>counter_clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
        <motor><name>motor_3</name><direction>clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
        <motor><name>motor_4</name><direction>counter_clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
        <motor><name>motor_5</name><direction>clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
        <motor><name>motor_6</name><direction>counter_clockwise</direction><thrust_coefficient>1.2e-5</thrust_coefficient></motor>
      </motors>
    </plugin>
  </model>
</sdf>
```

---

## 飞行物理参数

### 空气动力学配置

```xml
<!-- 空气阻力 -->
<gazebo reference="base_link">
  <velocity_decay>
    <linear>0.1</linear>
    <angular>0.1</angular>
  </velocity_decay>
</gazebo>

<!-- 螺旋桨气动参数 -->
<plugin filename="gz-sim-multirotor-physics-plugin" name="gz::sim::systems::MultirotorPhysics">
  <!-- 推力系数 (N/(rad/s)^2) -->
  <thrust_coefficient>8.548e-6</thrust_coefficient>
  
  <!-- 扭矩系数 (Nm/(rad/s)^2) -->
  <torque_coefficient>1e-5</torque_coefficient>
  
  <!-- 电机时间常数 -->
  <motor_time_constant>0.05</motor_time_constant>
  
  <!-- 螺旋桨直径 (m) -->
  <propeller_diameter>0.15</propeller_diameter>
  
  <!-- 电机常数 -->
  <motor_constant>2827.0</motor_constant>
</plugin>
```

---

## 环境条件仿真

### 风力扰动

```xml
<!-- 世界文件添加风力 -->
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="windy_world">
    <!-- 风力系统 -->
    <plugin filename="gz-sim-wind-system" name="gz::sim::systems::Wind">
      <frame_id>world</frame_id>
      <namespace>wind</namespace>
      
      <!-- 基础风向 (北偏东30度) -->
      <direction>
        <x>0.5</x>
        <y>0.866</y>
        <z>0</z>
      </direction>
      
      <!-- 基础风速 (m/s) -->
      <magnitude>
        <type>constant</type>
        <value>5.0</value>
      </magnitude>
      
      <!-- 风速变化 (湍流) -->
      <variation>
        <type>gaussian</type>
        <mean>0</mean>
        <stddev>1.5</stddev>
        <period>2.0</period>
      </variation>
    </plugin>
    
    <!-- 阵风 (Gust) -->
    <plugin filename="gz-sim-wind-gust-system" name="gz::sim::systems::WindGust">
      <start_time>5.0</start_time>
      <duration>3.0</duration>
      <direction>
        <x>1</x>
        <y>0</y>
        <z>0.2</z>
      </direction>
      <magnitude>
        <type>pulse</type>
        <min_value>3.0</min_value>
        <max_value>8.0</max_value>
      </magnitude>
    </plugin>
  </world>
</sdf>
```

### 无人机风力响应

```xml
<!-- 在无人机模型中添加风力响应 -->
<gazebo reference="base_link">
  <!-- 风力扰动系数 -->
  <wind>
    <linear_drag>0.1</linear_drag>
    <angular_drag>0.05</angular_drag>
  </wind>
</gazebo>
```

---

## 负载配置

### 云台相机

```xml
<!-- 云台连接 -->
<link name="gimbal_link">
  <pose>0 0 -0.05 0 0 0</pose>
  <inertial>
    <mass>0.3</mass>
    <inertia>
      <ixx>0.0001</ixx><ixy>0</ixy><ixz>0</ixz>
      <iyy>0.0001</iyy><iyz>0</iyz>
      <izz>0.0001</izz>
    </inertia>
  </inertial>
  <visual name="gimbal_visual">
    <geometry>
      <box>
        <size>0.08 0.06 0.04</size>
      </box>
    </geometry>
  </visual>
  <collision name="gimbal_collision">
    <geometry>
      <box>
        <size>0.08 0.06 0.04</size>
      </box>
    </geometry>
  </collision>
</link>

<!-- 两轴云台关节 -->
<joint name="gimbal_pitch_joint" type="revolute">
  <parent>base_link</parent>
  <child>gimbal_link</child>
  <axis>
    <xyz>1 0 0</xyz>
    <limit>
      <lower>-1.57</lower>
      <upper>1.57</upper>
    </limit>
  </axis>
</joint>

<joint name="gimbal_yaw_joint" type="revolute">
  <parent>gimbal_link</parent>
  <child>gimbal_camera_link</child>
  <axis>
    <xyz>0 1 0</xyz>
    <limit>
      <lower>-3.14</lower>
      <upper>3.14</upper>
    </limit>
  </axis>
</joint>
```

### 货物挂载

```xml
<!-- 货物挂钩 -->
<link name="cargo_hook">
  <pose>0 0 -0.15 0 0 0</pose>
  <inertial>
    <mass>0.1</mass>
  </inertial>
  <visual name="cargo_hook_visual">
    <geometry>
      <sphere>
        <radius>0.02</radius>
      </sphere>
    </geometry>
  </visual>
</link>

<joint name="cargo_hook_joint" type="fixed">
  <parent>base_link</parent>
  <child>cargo_hook</child>
</joint>
```

---

## 传感器配置

### 无人机常用传感器

```xml
<!-- 向下测距传感器 -->
<link name="range_link">
  <pose>0 0 -0.1 0 0 0</pose>
  <sensor name="range" type="ray">
    <update_rate>50</update_rate>
    <ray>
      <scan>
        <horizontal>
          <samples>1</samples>
          <resolution>1</resolution>
        </horizontal>
        <vertical>
          <samples>1</samples>
        </vertical>
      </scan>
      <range>
        <min>0.1</min>
        <max>5.0</max>
        <resolution>0.01</resolution>
      </range>
    </ray>
    <plugin filename="gz-sim-sensors-ray-system" name="gz::sim::systems::Ray">
      <ros>
        <namespace>/uav</namespace>
        <remap>/range:=sensor/range</remap>
      </ros>
    </plugin>
  </sensor>
</link>

<!-- 双目相机 -->
<link name="stereo_camera_link">
  <pose>0 0.1 -0.02 0 0 0</pose>
  <sensor name="stereo_camera" type="multicamera">
    <update_rate>30</update_rate>
    <camera name="left">
      <pose>0 0.06 0 0 0 0</pose>
      <horizontal_fov>1.047</horizontal_fov>
      <image>
        <width>640</width>
        <height>480</height>
      </image>
    </camera>
    <camera name="right">
      <pose>0 -0.06 0 0 0 0</pose>
      <horizontal_fov>1.047</horizontal_fov>
      <image>
        <width>640</width>
        <height>480</height>
      </image>
    </camera>
    <plugin filename="gz-sim-sensors-multicamera-system" name="gz::sim::systems::Multicamera">
      <ros>
        <namespace>/uav</namespace>
      </ros>
    </plugin>
  </sensor>
</link>
```

---

## 飞行模式配置

### 起降模式

```xml
<!-- 垂直起降配置 -->
<plugin filename="gz-sim-multirotor-physics-plugin" name="gz::sim::systems::MultirotorPhysics">
  <control>
    <type>velocity</type>
    <takeoff>
      <vertical_speed>0.5</vertical_speed>
      <takeoff_altitude>1.5</takeoff_altitude>
    </takeoff>
    <land>
      <vertical_speed>0.3</vertical_speed>
      <descent_angle>0.1</descent_angle>
    </land>
  </control>
</plugin>
```

---

## 常见问题

### 问题 1: 无人机失控

**解决方案**：
- 检查电机旋转方向
- 验证推力系数
- 确认电调配置

### 问题 2: 飞行不稳定

**解决方案**：
- 调整 PID 参数
- 检查 IMU 校准
- 验证重心位置

### 问题 3: 风力影响过大

**解决方案**：
- 增加飞行器质量
- 调整阻力系数
- 降低飞行高度

---

## 相关资源

- [Gazebo Multirotor](https://gazebosim.org/docs/harmonic/multirotor)
- [PX4 SITL](https://docs.px4.io/en/simulation/gazebo.html)
- [ArduPilot](https://ardupilot.org/)

---

## 另见

- [navigation/](../navigation/) - 无人机导航
- [action/](../action/) - 飞行控制