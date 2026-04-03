---
name: sdf-xacro-model
description: 机械臂 SDF/XACRO 模型开发技能 - 关节臂模型、末端执行器、碰撞检测、轨迹规划配置
argument-hint: "创建机械臂" / "机械臂模型" / "关节臂" / "末端执行器"
user-invocable: true
---

# Manipulator Arm SDF/XACRO Model Skill

> 用于创建机械臂的 SDF 和 XACRO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建多关节机械臂
- 配置末端执行器
- 设置碰撞检测
- 添加力/力矩传感器
- 配置轨迹规划

---

## 快速参考

```
常见机械臂配置:
- 6轴工业机械臂
- 7轴冗余机械臂
- SCARA 结构
- Delta 并联机械臂
```

---

## 6轴工业机械臂

### SDF 模型 - 完整示例

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="manipulator_arm">
    <static>false</static>
    <self_collide>false</self_collide>
    
    <!-- 基座 -->
    <link name="base_link">
      <pose>0 0 0.15 0 0 0</pose>
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.02</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.02</iyy><iyz>0</iyz>
          <izz>0.02</izz>
        </inertia>
      </inertial>
      
      <collision name="base_collision">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <height>0.15</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="base_visual">
        <geometry>
          <cylinder>
            <radius>0.1</radius>
            <height>0.15</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
          <diffuse>0.3 0.3 0.3 1</diffuse>
        </material>
      </visual>
    </link>
    
    <!-- 关节1 - 基座旋转 (腰) -->
    <link name="link1">
      <pose>0 0 0.2 0 0 0</pose>
      <inertial>
        <mass>3.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      
      <collision name="link1_collision">
        <geometry>
          <cylinder>
            <radius>0.08</radius>
            <height>0.15</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="link1_visual">
        <geometry>
          <cylinder>
            <radius>0.08</radius>
            <height>0.15</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.5 0.5 0.5 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint1" type="revolute">
      <parent>base_link</parent>
      <child>link1</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
          <effort>100</effort>
          <velocity>1.5</velocity>
        </limit>
        <dynamics>
          <damping>0.5</damping>
          <friction>0.5</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 关节2 - 肩部俯仰 -->
    <link name="link2">
      <pose>0 0.15 0.2 0 0 0</pose>
      <inertial>
        <mass>4.0</mass>
        <inertia>
          <ixx>0.02</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.02</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      
      <collision name="link2_collision">
        <geometry>
          <box>
            <size>0.08 0.2 0.08</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="link2_visual">
        <geometry>
          <box>
            <size>0.08 0.2 0.08</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint2" type="revolute">
      <parent>link1</parent>
      <child>link2</child>
      <pose>0 0.1 0 0 0 0</pose>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
          <effort>80</effort>
          <velocity>1.0</velocity>
        </limit>
        <dynamics>
          <damping>0.3</damping>
          <friction>0.3</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 关节3 - 肘部 -->
    <link name="link3">
      <pose>0 0.35 0.2 0 0 0</pose>
      <inertial>
        <mass>2.5</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.005</izz>
        </inertia>
      </inertial>
      
      <collision name="link3_collision">
        <geometry>
          <box>
            <size>0.06 0.15 0.06</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="link3_visual">
        <geometry>
          <box>
            <size>0.06 0.15 0.06</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint3" type="revolute">
      <parent>link2</parent>
      <child>link3</child>
      <pose>0 0.15 0 0 0 0</pose>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.35</lower>
          <upper>2.35</upper>
          <effort>50</effort>
          <velocity>1.5</velocity>
        </limit>
        <dynamics>
          <damping>0.2</damping>
          <friction>0.2</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 关节4 - 手腕翻转 -->
    <link name="link4">
      <pose>0 0.45 0.2 0 0 0</pose>
      <inertial>
        <mass>1.0</mass>
        <inertia>
          <ixx>0.005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.005</iyy><iyz>0</iyz>
          <izz>0.005</izz>
        </inertia>
      </inertial>
      
      <collision name="link4_collision">
        <geometry>
          <cylinder>
            <radius>0.04</radius>
            <height>0.08</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="link4_visual">
        <geometry>
          <cylinder>
            <radius>0.04</radius>
            <height>0.08</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint4" type="revolute">
      <parent>link3</parent>
      <child>link4</child>
      <pose>0 0.1 0 0 0 0</pose>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
          <effort>30</effort>
          <velocity>2.0</velocity>
        </limit>
        <dynamics>
          <damping>0.1</damping>
          <friction>0.1</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 关节5 - 手腕俯仰 -->
    <link name="link5">
      <pose>0 0.53 0.2 0 0 0</pose>
      <inertial>
        <mass>0.8</mass>
        <inertia>
          <ixx>0.003</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.003</iyy><iyz>0</iyz>
          <izz>0.003</izz>
        </inertia>
      </inertial>
      
      <collision name="link5_collision">
        <geometry>
          <cylinder>
            <radius>0.035</radius>
            <height>0.06</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="link5_visual">
        <geometry>
          <cylinder>
            <radius>0.035</radius>
            <height>0.06</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint5" type="revolute">
      <parent>link4</parent>
      <child>link5</child>
      <pose>0 0.06 0 0 0 0</pose>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.09</lower>
          <upper>2.09</upper>
          <effort>20</effort>
          <velocity>2.5</velocity>
        </limit>
        <dynamics>
          <damping>0.1</damping>
          <friction>0.1</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 关节6 - 手腕旋转 -->
    <link name="link6">
      <pose>0 0.59 0.2 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.002</iyy><iyz>0</iyz>
          <zzz>0.002</zzz>
        </inertia>
      </inertial>
      
      <collision name="link6_collision">
        <geometry>
          <cylinder>
            <radius>0.03</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="link6_visual">
        <geometry>
          <cylinder>
            <radius>0.03</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.2 0.2 0.2 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="joint6" type="revolute">
      <parent>link5</parent>
      <child>link6</child>
      <pose>0 0.04 0 0 0 0</pose>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
          <effort>15</effort>
          <velocity>3.0</velocity>
        </limit>
        <dynamics>
          <damping>0.05</damping>
          <friction>0.05</friction>
        </dynamics>
      </axis>
    </joint>
    
    <!-- 末端法兰 -->
    <link name="flange">
      <pose>0 0.63 0.2 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      
      <collision name="flange_collision">
        <geometry>
          <cylinder>
            <radius>0.025</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
      </collision>
      
      <visual name="flange_visual">
        <geometry>
          <cylinder>
            <radius>0.025</radius>
            <height>0.02</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.6 0.6 0.6 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="flange_joint" type="fixed">
      <parent>link6</parent>
      <child>flange</child>
    </joint>
    
    <!-- 力矩传感器 -->
    <link name="torque_sensor">
      <pose>0 0 0 0 0 0</pose>
      <sensor name="joint_torque" type="force_torque">
        <update_rate>100</update_rate>
        <force_torque>
          <frame>child</frame>
          <measure_direction>child_to_parent</measure_direction>
        </force_torque>
        <plugin filename="gz-sim-joint-state-publisher-system" name="gz::sim::systems::JointStatePublisher">
          <ros>
            <namespace>/manipulator</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <!-- 控制器插件 -->
    <plugin filename="gz-sim-joint-position-controller-system" name="gz::sim::systems::JointPositionController">
      <robotNamespace>manipulator</robotNamespace>
      <control_period>0.01</control_period>
      <position_pid>
        <p>100</p>
        <i>0.1</i>
        <d>10</d>
        <i_clamp>1</i_clamp>
      </position_pid>
    </plugin>
  </model>
</sdf>
```

---

## 7轴冗余机械臂

```xml
<!-- 7轴配置 - 添加冗余关节 -->
<joint name="joint7" type="revolute">
  <parent>flange</parent>
  <child>link7</child>
  <axis>
    <xyz>1 0 0</xyz>
    <limit>
      <lower>-2.09</lower>
      <upper>2.09</upper>
      <effort>10</effort>
      <velocity>3.0</velocity>
    </limit>
  </axis>
</joint>

<link name="link7">
  <pose>0 0.05 0 0 0 0</pose>
  <inertial>
    <mass>0.3</mass>
  </inertial>
  <visual name="link7_visual">
    <geometry>
      <cylinder radius="0.02" height="0.05"/>
    </geometry>
  </visual>
</link>
```

---

## 末端执行器

### 夹爪

```xml
<!-- 两指夹爪 -->
<link name="gripper_base">
  <pose>0 0.65 0.2 0 0 0</pose>
  <inertial>
    <mass>0.2</mass>
  </inertial>
  <visual name="gripper_base_visual">
    <geometry>
      <box size="0.04 0.03 0.02"/>
    </geometry>
  </visual>
</link>

<joint name="gripper_base_joint" type="fixed">
  <parent>flange</parent>
  <child>gripper_base</child>
</joint>

<!-- 夹爪手指1 -->
<link name="finger_l">
  <pose>0.015 0.02 0 0 0 0</pose>
  <inertial>
    <mass>0.05</mass>
  </inertial>
  <collision name="finger_l_collision">
    <geometry>
      <box size="0.01 0.02 0.01"/>
    </geometry>
  </collision>
  <visual name="finger_l_visual">
    <geometry>
      <box size="0.01 0.02 0.01"/>
    </geometry>
  </visual>
</link>

<joint name="finger_l_joint" type="revolute">
  <parent>gripper_base</parent>
  <child>finger_l</child>
  <axis>
    <xyz>0 0 1</xyz>
    <limit>
      <lower>0</lower>
      <upper>0.5</upper>
      <effort>5</effort>
      <velocity>1.0</velocity>
    </limit>
  </axis>
</joint>

<!-- 夹爪手指2 -->
<link name="finger_r">
  <pose>-0.015 0.02 0 0 0 0</pose>
  <inertial>
    <mass>0.05</mass>
  </inertial>
  <collision name="finger_r_collision">
    <geometry>
      <box size="0.01 0.02 0.01"/>
    </geometry>
  </collision>
  <visual name="finger_r_visual">
    <geometry>
      <box size="0.01 0.02 0.01"/>
    </geometry>
  </visual>
</link>

<joint name="finger_r_joint" type="revolute">
  <parent>gripper_base</parent>
  <child>finger_r</child>
  <axis>
    <xyz>0 0 1</xyz>
    <limit>
      <lower>-0.5</lower>
      <upper>0</upper>
      <effort>5</effort>
      <velocity>1.0</velocity>
    </limit>
  </axis>
</joint>
```

### 吸盘

```xml
<!-- 真空吸盘 -->
<link name="suction_cup">
  <pose>0 0 0.03 0 0 0</pose>
  <inertial>
    <mass>0.05</mass>
  </inertial>
  <visual name="suction_visual">
    <geometry>
      <sphere>
        <radius>0.02</radius>
      </sphere>
    </geometry>
    <material>
      <ambient>0.8 0.8 0.8 1</ambient>
      <transparency>0.3</transparency>
    </material>
  </visual>
</link>

<joint name="suction_joint" type="fixed">
  <parent>flange</parent>
  <child>suction_cup</child>
</joint>
```

---

## 碰撞检测配置

### 自碰撞

```xml
<!-- 启用自碰撞 -->
<gazebo>
  <model>
    <allow_auto_self_collision>true</allow_auto_self_collision>
  </model>
</gazebo>
```

### 碰撞组

```xml
<!-- 定义碰撞组 -->
<gazebo reference="link2">
  <collision>
    <laser_retro>0</laser_retro>
    <max_contacts>10</max_contacts>
  </collision>
</gazebo>

<gazebo reference="link3">
  <collision>
    <laser_retro>0</laser_retro>
    <max_contacts>10</max_contacts>
  </collision>
</gazebo>
```

---

## 力控配置

### 力矩传感器

```xml
<!-- 关节力矩感应 -->
<gazebo reference="joint2">
  <force_torque>
    <force>
      <noise type="gaussian">
        <mean>0</mean>
        <stddev>0.1</stddev>
      </noise>
    </force>
    <torque>
      <noise type="gaussian">
        <mean>0</mean>
        <stddev>0.05</stddev>
      </noise>
    </torque>
  </force_torque>
</gazebo>
```

### 阻抗控制

```xml
<!-- 阻抗控制参数 -->
<gazebo>
  <plugin filename="gazebo_ros_joint_impedance_controller" name="gazebo_ros_joint_impedance_controller">
    <robotNamespace>/manipulator</robotNamespace>
    <control_method>impedance</control_method>
    <spring_constant>100</spring_constant>
    <damping_constant>10</damping_constant>
  </plugin>
</gazebo>
```

---

## 轨迹规划配置

### MoveIt! 集成

```xml
<!-- 规划组配置 -->
<gazebo>
  <plugin filename="gazebo_ros_moveit" name="gazebo_ros_moveit">
    <robotNamespace>/manipulator</robotNamespace>
    
    <!-- 规划组 -->
    <planning_groups>
      <group name="manipulator">
        <chain>
          <base>base_link</base>
          <tip>flange</tip>
        </chain>
      </group>
    </planning_groups>
    
    <!-- 碰撞检测 -->
    <collision_detect>true</collision_detect>
    <collision_padding>0.01</collision_padding>
  </plugin>
</gazebo>
```

---

## 常见问题

### 问题 1: 关节震动

**解决方案**：
- 增加阻尼系数
- 调整 PID 参数
- 检查电机配置

### 问题 2: 碰撞检测失败

**解决方案**：
- 检查碰撞体几何
- 验证碰撞组配置
- 增加碰撞容差

### 问题 3: 轨迹不平滑

**解决方案**：
- 调整速度限制
- 使用样条插值
- 检查加速度限制

---

## 相关资源

- [Gazebo Manipulator](https://gazebosim.org/docs/harmonic/manipulator)
- [MoveIt! Documentation](https://moveit.ros.org/)
- [ROS Control](https://ros-controls.github.io/)

---

## 另见

- [motion-control/](../motion-control/) - 运动控制
- [perception/](../perception/) - 视觉引导