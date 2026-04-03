---
name: sdf-xacro-model
description: 足式机器人 SDF/XACRO 模型开发技能 - 四足机器人模型创建、腿部关节配置、步态仿真、环境交互
argument-hint: 创建四足机器人 OR 足式机器人 OR 步态仿真 OR 液压驱动
user-invocable: true
---

# Quadruped Robot SDF/XACRO Model Skill

> 用于创建足式机器人的 SDF 和 XACRO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建四足机器人模型
- 配置腿部关节和驱动器
- 设置步态参数
- 添加环境交互
- 配置触觉传感器

---

## 快速参考

```
常见四足布局:
- 脊椎式 (spine-type)   - 身体 + 4条腿
- 昆虫式 (insect-type)  - 身体 + 4条腿 (更简单)
- 哺乳动物式 (mammal-type) - 真实动物结构
```

---

## 四足机器人 - 完整示例

### SDF 模型

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="quadruped_robot">
    <static>false</static>
    <self_collide>false</self_collide>
    
    <!-- 躯干 -->
    <link name="torso">
      <pose>0 0 0.3 0 0 0</pose>
      <inertial>
        <mass>8.0</mass>
        <inertia>
          <ixx>0.1</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.15</iyy><iyz>0</iyz>
          <izz>0.1</izz>
        </inertia>
      </inertial>
      
      <!-- 躯干碰撞体 -->
      <collision name="torso_collision">
        <geometry>
          <box>
            <size>0.4 0.25 0.1</size>
          </box>
        </geometry>
      </collision>
      
      <!-- 躯干视觉体 -->
      <visual name="torso_visual">
        <geometry>
          <box>
            <size>0.4 0.25 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
          <diffuse>0.3 0.3 0.3 1</diffuse>
        </material>
      </visual>
    </link>
    
    <!-- 左前腿 -->
    <!-- 髋关节 -->
    <link name="hip_fl">
      <pose>0.2 0.15 0 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
        <inertia>
          <ixx>0.0005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0005</iyy><iyz>0</iyz>
          <izz>0.0005</izz>
        </inertia>
      </inertial>
      <visual name="hip_fl_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.2 0.2 0.2 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hip_fl_joint" type="revolute">
      <parent>torso</parent>
      <child>hip_fl</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 大腿 -->
    <link name="thigh_fl">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="thigh_fl_collision">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="thigh_fl_visual">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_fl_joint" type="revolute">
      <parent>hip_fl</parent>
      <child>thigh_fl</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 小腿 -->
    <link name="shin_fl">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
        <inertia>
          <ixx>0.0005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0005</iyy><iyz>0</iyz>
          <izz>0.0005</izz>
        </inertia>
      </inertial>
      <collision name="shin_fl_collision">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="shin_fl_visual">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
      
      <!-- 足尖传感器 -->
      <sensor name="foot_contact_fl" type="contact">
        <contact>
          <collision>shin_fl_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_fl_joint" type="revolute">
      <parent>thigh_fl</parent>
      <child>shin_fl</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-2.5</lower>
          <upper>-0.1</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 右前腿 -->
    <link name="hip_fr">
      <pose>0.2 -0.15 0 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
        <inertia>
          <ixx>0.0005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0005</iyy><iyz>0</iyz>
          <izz>0.0005</izz>
        </inertia>
      </inertial>
      <visual name="hip_fr_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
        <material>
          <ambient>0.2 0.2 0.2 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hip_fr_joint" type="revolute">
      <parent>torso</parent>
      <child>hip_fr</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="thigh_fr">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <collision name="thigh_fr_collision">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="thigh_fr_visual">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_fr_joint" type="revolute">
      <parent>hip_fr</parent>
      <child>thigh_fr</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="shin_fr">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
      </inertial>
      <collision name="shin_fr_collision">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="shin_fr_visual">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
      <sensor name="foot_contact_fr" type="contact">
        <contact>
          <collision>shin_fr_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_fr_joint" type="revolute">
      <parent>thigh_fr</parent>
      <child>shin_fr</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-2.5</lower>
          <upper>-0.1</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左后腿 -->
    <link name="hip_rl">
      <pose>-0.2 0.15 0 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
      </inertial>
      <visual name="hip_rl_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
      </visual>
    </link>
    
    <joint name="hip_rl_joint" type="revolute">
      <parent>torso</parent>
      <child>hip_rl</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="thigh_rl">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <collision name="thigh_rl_collision">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="thigh_rl_visual">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_rl_joint" type="revolute">
      <parent>hip_rl</parent>
      <child>thigh_rl</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="shin_rl">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
      </inertial>
      <collision name="shin_rl_collision">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="shin_rl_visual">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
      <sensor name="foot_contact_rl" type="contact">
        <contact>
          <collision>shin_rl_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_rl_joint" type="revolute">
      <parent>thigh_rl</parent>
      <child>shin_rl</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-2.5</lower>
          <upper>-0.1</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 右后腿 -->
    <link name="hip_rr">
      <pose>-0.2 -0.15 0 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
      </inertial>
      <visual name="hip_rr_visual">
        <geometry>
          <cylinder>
            <radius>0.02</radius>
            <height>0.04</height>
          </cylinder>
        </geometry>
      </visual>
    </link>
    
    <joint name="hip_rr_joint" type="revolute">
      <parent>torso</parent>
      <child>hip_rr</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="thigh_rr">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <collision name="thigh_rr_collision">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="thigh_rr_visual">
        <geometry>
          <box>
            <size>0.03 0.03 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_rr_joint" type="revolute">
      <parent>hip_rr</parent>
      <child>thigh_rr</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="shin_rr">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
      </inertial>
      <collision name="shin_rr_collision">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
      </collision>
      <visual name="shin_rr_visual">
        <geometry>
          <box>
            <size>0.02 0.02 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
      <sensor name="foot_contact_rr" type="contact">
        <contact>
          <collision>shin_rr_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_rr_joint" type="revolute">
      <parent>thigh_rr</parent>
      <child>shin_rr</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-2.5</lower>
          <upper>-0.1</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- IMU 传感器 -->
    <link name="imu_link">
      <pose>0 0 0.05 0 0 0</pose>
      <sensor name="imu" type="imu">
        <update_rate>200</update_rate>
        <plugin filename="gz-sim-sensors-imu-system" name="gz::sim::systems::Imu">
          <ros>
            <namespace>/quadruped</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="imu_joint" type="fixed">
      <parent>torso</parent>
      <child>imu_link</child>
    </joint>
    
    <!-- 关节状态发布 -->
    <plugin filename="gz-sim-joint-state-publisher-system" name="gz::sim::systems::JointStatePublisher">
      <update_period>0.01</update_period>
    </plugin>
  </model>
</sdf>
```

---

## 液压驱动四足

```xml
<!-- 液压缸配置 -->
<link name="hydraulic_cylinder">
  <pose>0 0 0 0 0 0</pose>
  <inertial>
    <mass>0.2</mass>
  </inertial>
  <visual name="hydraulic_visual">
    <geometry>
      <cylinder>
        <radius>0.015</radius>
        <length>0.1</length>
      </cylinder>
    </geometry>
    <material>
      <ambient>0.5 0.5 0.5 1</ambient>
    </material>
  </visual>
</link>

<joint name="hydraulic_joint" type="prismatic">
  <parent>thigh_fl</parent>
  <child>hydraulic_cylinder</child>
  <axis>
    <xyz>0 1 0</xyz>
    <limit>
      <lower>-0.05</lower>
      <upper>0.05</upper>
      <effort>50</effort>
      <velocity>0.1</velocity>
    </limit>
  </axis>
</joint>
```

---

## 步态配置

###  trot (小跑) 步态

```xml
<!-- 步态参数 -->
<gazebo>
  <plugin filename="quadruped_controller" name="quadruped::GaitController">
    <!-- 步态周期 -->
    <gait_period>0.4</gait_period>
    
    <!-- 步幅 -->
    <step_height>0.08</step_height>
    <step_length>0.15</step_length>
    
    <!-- 站立相位 -->
    <stance_phase>0.5</stance_phase>
    <swing_phase>0.5</swing_phase>
    
    <!-- 对角线同步 -->
    <diagonal_phase_offset>0.5</diagonal_phase_offset>
  </plugin>
</gazebo>
```

###  walk (行走) 步态

```xml
<!-- 行走步态 - 单腿依次移动 -->
<gazebo>
  <plugin filename="quadruped_controller" name="quadruped::GaitController">
    <gait_period>0.8</gait_period>
    <step_height>0.05</step_height>
    <step_length>0.08</step_length>
    <stance_phase>0.75</stance_phase>
    <swing_phase>0.25</swing_phase>
    <phase_sequence>sequential</phase_sequence>
  </plugin>
</gazebo>
```

###  pace (慢跑) 步态

```xml
<!-- 同侧腿同步 -->
<gazebo>
  <plugin filename="quadruped_controller" name="quadruped::GaitController">
    <gait_period>0.5</gait_period>
    <step_height>0.1</step_height>
    <step_length>0.2</step_length>
    <stance_phase>0.5</swing_phase>
    <swing_phase>0.5</swing_phase>
    <lateral_sequence>true</lateral_sequence>
  </plugin>
</gazebo>
```

---

## 环境交互

### 地面检测

```xml
<!-- 足尖接触传感器 -->
<link name="shin_fl">
  <sensor name="foot_contact" type="contact">
    <update_rate>100</update_rate>
    <contact>
      <collision>shin_fl_collision</collision>
    </contact>
    <plugin filename="gz-sim-contact-system" name="gz::sim::systems::Contact">
      <ros>
        <namespace>/quadruped</namespace>
        <remap>/foot_contact:=contact/FL</remap>
      </ros>
    </plugin>
  </sensor>
</link>
```

### 足尖力传感器

```xml
<!-- 力感应 -->
<gazebo reference="shin_fl">
  <sensor type="force_torque">
    <force>
      <noise type="gaussian">
        <mean>0</mean>
        <stddev>0.1</stddev>
      </noise>
    </force>
  </sensor>
</gazebo>
```

---

## 地形适配

### 可变形地形

```xml
<!-- 软地面参数 -->
<gazebo reference="shin_fl">
  <surface>
    <friction>
      <ode>
        <mu>0.8</mu>
        <mu2>0.8</mu2>
        <slip1>0.1</slip1>
        <slip2>0.1</slip2>
      </ode>
    </friction>
    <contact>
      <kp>1e6</kp>
      <kd>100</kd>
      <restitution>0.1</restitution>
    </contact>
  </surface>
</gazebo>

<!-- 沙地参数 -->
<gazebo reference="shin_fl">
  <surface>
    <friction>
      <ode>
        <mu>0.4</mu>
        <mu2>0.4</mu2>
        <slip1>0.2</slip1>
        <slip2>0.2</slip2>
      </ode>
    </friction>
  </surface>
</gazebo>
```

---

## 常见问题

### 问题 1: 机器人倾倒

**解决方案**：
- 检查重心位置
- 调整关节限位
- 验证平衡控制器

### 问题 2: 腿部抖动

**解决方案**：
- 增加阻尼系数
- 降低控制频率
- 调整 PID 参数

### 问题 3: 爬坡困难

**解决方案**：
- 增加足尖摩擦
- 调整步态参数
- 验证关节扭矩

---

## 相关资源

- [Gazebo Legged Robot](https://gazebosim.org/docs/harmonic/legged_robot)
- [MIT Cheetah](https://biomimetics.mit.edu/)
- [Unitree](https://www.unitree.com/)

---

## 另见

- [motion-control/](../motion-control/) - 运动控制
- [navigation/](../navigation/) - 导航配置