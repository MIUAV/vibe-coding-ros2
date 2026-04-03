---
name: sdf-xacro-model
description: 人形机器人 SDF/XACRO 模型开发技能 - 双足机器人模型、全身关节配置、平衡控制、环境交互
argument-hint: 创建人形机器人 OR 双足机器人 OR 人形 OR 仿人机器人
user-invocable: true
---

# Humanoid Robot SDF/XACRO Model Skill

> 用于创建人形机器人的 SDF 和 XACRO 模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建双足人形机器人
- 配置全身关节
- 添加平衡传感器
- 设置步态规划
- 配置环境交互

---

## 快速参考

```
人形机器人关键组件:
- 躯干 (Torso)
- 头部 (Head)
- 手臂 x2 (Arm)
- 腿部 x2 (Leg)
- 手部 x2 (Hand)
```

---

## 人形机器人 - 完整示例

### SDF 模型

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="humanoid_robot">
    <static>false</static>
    <self_collide>false</self_collide>
    <allow_auto_self_collision>true</allow_auto_self_collision>
    
    <!-- 骨盆/躯干基座 -->
    <link name="pelvis">
      <pose>0 0 0.9 0 0 0</pose>
      <inertial>
        <mass>10.0</mass>
        <inertia>
          <ixx>0.05</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.08</iyy><iyz>0</iyz>
          <izz>0.05</izz>
        </inertia>
      </inertial>
      
      <collision name="pelvis_collision">
        <geometry>
          <box>
            <size>0.25 0.15 0.1</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="pelvis_visual">
        <geometry>
          <box>
            <size>0.25 0.15 0.1</size>
          </box>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <!-- 躯干/脊柱 -->
    <link name="torso">
      <pose>0 0 0.15 0 0 0</pose>
      <inertial>
        <mass>8.0</mass>
        <inertia>
          <ixx>0.04</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.06</iyy><iyz>0</iyz>
          <izz>0.04</izz>
        </inertia>
      </inertial>
      
      <collision name="torso_collision">
        <geometry>
          <box>
            <size>0.25 0.2 0.25</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="torso_visual">
        <geometry>
          <box>
            <size>0.25 0.2 0.25</size>
          </box>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="torso_joint" type="revolute">
      <parent>pelvis</parent>
      <child>torso</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-0.5</lower>
          <upper>0.5</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 头部 -->
    <link name="neck">
      <pose>0 0 0.2 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <visual name="neck_visual">
        <geometry>
          <cylinder radius="0.03" height="0.05"/>
        </geometry>
      </visual>
    </link>
    
    <joint name="neck_joint" type="revolute">
      <parent>torso</parent>
      <child>neck</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="head">
      <pose>0 0.05 0 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.01</izz>
        </inertia>
      </inertial>
      
      <collision name="head_collision">
        <geometry>
          <box>
            <size>0.15 0.12 0.15</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="head_visual">
        <geometry>
          <box>
            <size>0.15 0.12 0.15</size>
          </box>
        </geometry>
        <material>
          <ambient>0.5 0.5 0.5 1</ambient>
        </material>
      </visual>
      
      <!-- 眼睛/视觉传感器 -->
      <visual name="eye_l">
        <pose>0.04 0.04 -0.02 0 0.3 0</pose>
        <geometry>
          <sphere radius="0.015"/>
        </geometry>
        <material>
          <ambient>0.8 0.8 0 1</ambient>
        </material>
      </visual>
      <visual name="eye_r">
        <pose>0.04 -0.04 -0.02 0 -0.3 0</pose>
        <geometry>
          <sphere radius="0.015"/>
        </geometry>
        <material>
          <ambient>0.8 0.8 0 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="head_joint" type="fixed">
      <parent>neck</parent>
      <child>head</child>
    </joint>
    
    <!-- 左臂 (定义右侧类似) -->
    <!-- 左肩 -->
    <link name="shoulder_l">
      <pose>0.15 0 0.15 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
        <inertia>
          <ixx>0.0005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.0005</iyy><iyz>0</iyz>
          <izz>0.0005</izz>
        </inertia>
      </inertial>
      <visual name="shoulder_l_visual">
        <geometry>
          <sphere radius="0.03"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="shoulder_l_joint" type="revolute">
      <parent>torso</parent>
      <child>shoulder_l</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左大臂 -->
    <link name="upper_arm_l">
      <pose>0.1 0 0 0 1.57 0</pose>
      <inertial>
        <mass>1.0</mass>
        <inertia>
          <ixx>0.002</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.002</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="upper_arm_l_collision">
        <geometry>
          <cylinder radius="0.03" height="0.2"/>
        </geometry>
      </collision>
      <visual name="upper_arm_l_visual">
        <geometry>
          <cylinder radius="0.03" height="0.2"/>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="upper_arm_l_joint" type="revolute">
      <parent>shoulder_l</parent>
      <child>upper_arm_l</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.09</lower>
          <upper>2.09</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左前臂 -->
    <link name="forearm_l">
      <pose>0.2 0 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.001</iyy><iyz>0</iyz>
          <izz>0.0005</izz>
        </inertia>
      </inertial>
      <collision name="forearm_l_collision">
        <geometry>
          <cylinder radius="0.025" height="0.2"/>
        </geometry>
      </collision>
      <visual name="forearm_l_visual">
        <geometry>
          <cylinder radius="0.025" height="0.2"/>
        </geometry>
        <material>
          <ambient>0.35 0.35 0.35 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="forearm_l_joint" type="revolute">
      <parent>upper_arm_l</parent>
      <child>forearm_l</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.35</lower>
          <upper>0</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左手 -->
    <link name="hand_l">
      <pose>0.2 0 0 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
      </inertial>
      <collision name="hand_l_collision">
        <geometry>
          <box size="0.04 0.08 0.02"/>
        </geometry>
      </collision>
      <visual name="hand_l_visual">
        <geometry>
          <box size="0.04 0.08 0.02"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hand_l_joint" type="revolute">
      <parent>forearm_l</parent>
      <child>hand_l</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>0</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 右臂 (镜像左侧) -->
    <link name="shoulder_r">
      <pose>-0.15 0 0.15 0 0 0</pose>
      <inertial>
        <mass>0.3</mass>
      </inertial>
      <visual name="shoulder_r_visual">
        <geometry>
          <sphere radius="0.03"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="shoulder_r_joint" type="revolute">
      <parent>torso</parent>
      <child>shoulder_r</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>
          <lower>-3.14</lower>
          <upper>3.14</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="upper_arm_r">
      <pose>-0.1 0 0 0 1.57 0</pose>
      <inertial>
        <mass>1.0</mass>
      </inertial>
      <collision name="upper_arm_r_collision">
        <geometry>
          <cylinder radius="0.03" height="0.2"/>
        </geometry>
      </collision>
      <visual name="upper_arm_r_visual">
        <geometry>
          <cylinder radius="0.03" height="0.2"/>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="upper_arm_r_joint" type="revolute">
      <parent>shoulder_r</parent>
      <child>upper_arm_r</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.09</lower>
          <upper>2.09</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="forearm_r">
      <pose>-0.2 0 0 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <collision name="forearm_r_collision">
        <geometry>
          <cylinder radius="0.025" height="0.2"/>
        </geometry>
      </collision>
      <visual name="forearm_r_visual">
        <geometry>
          <cylinder radius="0.025" height="0.2"/>
        </geometry>
        <material>
          <ambient>0.35 0.35 0.35 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="forearm_r_joint" type="revolute">
      <parent>upper_arm_r</parent>
      <child>forearm_r</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-2.35</lower>
          <upper>0</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="hand_r">
      <pose>-0.2 0 0 0 0 0</pose>
      <inertial>
        <mass>0.2</mass>
      </inertial>
      <collision name="hand_r_collision">
        <geometry>
          <box size="0.04 0.08 0.02"/>
        </geometry>
      </collision>
      <visual name="hand_r_visual">
        <geometry>
          <box size="0.04 0.08 0.02"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hand_r_joint" type="revolute">
      <parent>forearm_r</parent>
      <child>hand_r</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>0</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左腿 -->
    <!-- 左髋 -->
    <link name="hip_l">
      <pose>0 0.1 -0.1 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <visual name="hip_l_visual">
        <geometry>
          <sphere radius="0.04"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hip_l_joint" type="revolute">
      <parent>pelvis</parent>
      <child>hip_l</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左大腿 -->
    <link name="thigh_l">
      <pose>0 0 -0.25 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
        <inertia>
          <ixx>0.01</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.01</iyy><iyz>0</iyz>
          <izz>0.005</izz>
        </inertia>
      </inertial>
      <collision name="thigh_l_collision">
        <geometry>
          <cylinder radius="0.05" height="0.25"/>
        </geometry>
      </collision>
      <visual name="thigh_l_visual">
        <geometry>
          <cylinder radius="0.05" height="0.25"/>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_l_joint" type="revolute">
      <parent>hip_l</parent>
      <child>thigh_l</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左小腿 -->
    <link name="shin_l">
      <pose>0 0 -0.25 0 0 0</pose>
      <inertial>
        <mass>1.5</mass>
        <inertia>
          <ixx>0.005</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.005</iyy><iyz>0</iyz>
          <izz>0.002</izz>
        </inertia>
      </inertial>
      <collision name="shin_l_collision">
        <geometry>
          <cylinder radius="0.04" height="0.25"/>
        </geometry>
      </collision>
      <visual name="shin_l_visual">
        <geometry>
          <cylinder radius="0.04" height="0.25"/>
        </geometry>
        <material>
          <ambient>0.35 0.35 0.35 1</ambient>
        </material>
      </visual>
      
      <!-- 足尖接触传感器 -->
      <sensor name="foot_contact_l" type="contact">
        <update_rate>100</update_rate>
        <contact>
          <collision>shin_l_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_l_joint" type="revolute">
      <parent>thigh_l</parent>
      <child>shin_l</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-0.2</lower>
          <upper>2.6</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 左脚 -->
    <link name="foot_l">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.001</ixx><ixy>0</ixy><ixz>0</ixz>
          <iyy>0.002</iyy><iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      <collision name="foot_l_collision">
        <geometry>
          <box size="0.1 0.06 0.03"/>
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
      <visual name="foot_l_visual">
        <geometry>
          <box size="0.1 0.06 0.03"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="foot_l_joint" type="revolute">
      <parent>shin_l</parent>
      <child>foot_l</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-0.5</lower>
          <upper>0.5</upper>
        </limit>
      </axis>
    </joint>
    
    <!-- 右腿 (镜像左腿) -->
    <link name="hip_r">
      <pose>0 -0.1 -0.1 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <visual name="hip_r_visual">
        <geometry>
          <sphere radius="0.04"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="hip_r_joint" type="revolute">
      <parent>pelvis</parent>
      <child>hip_r</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="thigh_r">
      <pose>0 0 -0.25 0 0 0</pose>
      <inertial>
        <mass>2.0</mass>
      </inertial>
      <collision name="thigh_r_collision">
        <geometry>
          <cylinder radius="0.05" height="0.25"/>
        </geometry>
      </collision>
      <visual name="thigh_r_visual">
        <geometry>
          <cylinder radius="0.05" height="0.25"/>
        </geometry>
        <material>
          <ambient>0.4 0.4 0.4 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="thigh_r_joint" type="revolute">
      <parent>hip_r</parent>
      <child>thigh_r</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-1.57</lower>
          <upper>1.57</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="shin_r">
      <pose>0 0 -0.25 0 0 0</pose>
      <inertial>
        <mass>1.5</mass>
      </inertial>
      <collision name="shin_r_collision">
        <geometry>
          <cylinder radius="0.04" height="0.25"/>
        </geometry>
      </collision>
      <visual name="shin_r_visual">
        <geometry>
          <cylinder radius="0.04" height="0.25"/>
        </geometry>
        <material>
          <ambient>0.35 0.35 0.35 1</ambient>
        </material>
      </visual>
      <sensor name="foot_contact_r" type="contact">
        <update_rate>100</update_rate>
        <contact>
          <collision>shin_r_collision</collision>
        </contact>
      </sensor>
    </link>
    
    <joint name="shin_r_joint" type="revolute">
      <parent>thigh_r</parent>
      <child>shin_r</child>
      <axis>
        <xyz>0 1 0</xyz>
        <limit>
          <lower>-0.2</lower>
          <upper>2.6</upper>
        </limit>
      </axis>
    </joint>
    
    <link name="foot_r">
      <pose>0 0 -0.15 0 0 0</pose>
      <inertial>
        <mass>0.5</mass>
      </inertial>
      <collision name="foot_r_collision">
        <geometry>
          <box size="0.1 0.06 0.03"/>
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
      <visual name="foot_r_visual">
        <geometry>
          <box size="0.1 0.06 0.03"/>
        </geometry>
        <material>
          <ambient>0.3 0.3 0.3 1</ambient>
        </material>
      </visual>
    </link>
    
    <joint name="foot_r_joint" type="revolute">
      <parent>shin_r</parent>
      <child>foot_r</child>
      <axis>
        <xyz>1 0 0</xyz>
        <limit>
          <lower>-0.5</lower>
          <upper>0.5</upper>
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
            <namespace>/humanoid</namespace>
          </ros>
        </plugin>
      </sensor>
    </link>
    
    <joint name="imu_joint" type="fixed">
      <parent>pelvis</parent>
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

## 步态与平衡配置

### 零力矩点 (ZMP) 控制

```xml
<!-- ZMP 控制插件 -->
<gazebo>
  <plugin filename="humanoid_balance_controller" name="humanoid::BalanceController">
    <robotNamespace>humanoid</robotNamespace>
    
    <!-- ZMP 参数 -->
    <zmp>
      <target_zmp_x>0</target_zmp_x>
      <target_zmp_y>0</target_zmp_y>
      <zmp_margin>0.03</zmp_margin>
    </zmp>
    
    <!-- 平衡参数 -->
    <balance>
      <kp>10.0</kp>
      <kd>5.0</kd>
      <ki>0.1</ki>
    </balance>
  </plugin>
</gazebo>
```

### 步态参数

```xml
<!-- 步行参数 -->
<gazebo>
  <plugin filename="humanoid_gait_controller" name="humanoid::GaitController">
    <gait>
      <step_height>0.05</step_height>
      <step_length>0.3</step_length>
      <step_period>0.6</step_period>
      <double_support_ratio>0.2</double_support_ratio>
    </gait>
    
    <!-- 足部轨迹 -->
    <foot_trajectory>
      <type>bezier</type>
      <swing_height>0.05</swing_height>
    </foot_trajectory>
  </plugin>
</gazebo>
```

---

## 传感器配置

### 足部力传感器

```xml
<!-- 足部六维力传感器 -->
<gazebo reference="foot_l">
  <sensor type="force_torque">
    <force>
      <noise type="gaussian">
        <mean>0</mean>
        <stddev>0.5</stddev>
      </noise>
    </force>
    <torque>
      <noise type="gaussian">
        <mean>0</mean>
        <stddev>0.1</stddev>
      </torque>
    </torque>
  </sensor>
</gazebo>
```

### 电子皮肤 (可选)

```xml
<!-- 接触传感器阵列 -->
<gazebo reference="hand_l">
  <sensor type="contact">
    <contact>
      <collision>hand_l_collision</collision>
    </contact>
  </sensor>
</gazebo>
```

---

## 环境交互

### 不平整地面行走

```xml
<!-- 脚部摩擦调整 -->
<gazebo reference="foot_l">
  <surface>
    <friction>
      <ode>
        <mu>1.2</mu>
        <mu2>1.0</mu2>
        <slip1>0</slip1>
        <slip2>0</slip2>
      </ode>
    </friction>
  </surface>
</gazebo>

<!-- 斜坡行走 -->
<gazebo reference="foot_r">
  <surface>
    <friction>
      <ode>
        <mu>1.5</mu>
        <mu2>1.2</mu2>
      </ode>
    </friction>
  </surface>
</gazebo>
```

---

## 常见问题

### 问题 1: 机器人跌倒

**解决方案**：
- 检查重心位置
- 调整 ZMP 目标位置
- 验证平衡控制器参数

### 问题 2: 行走不稳定

**解决方案**：
- 调整步态参数
- 增加双足支撑时间
- 检查足部摩擦

### 问题 3: 关节限位冲突

**解决方案**：
- 验证关节运动范围
- 检查自碰撞设置
- 调整关节优先级

---

## 相关资源

- [Gazebo Humanoid](https://gazebosim.org/docs/harmonic/humanoid)
- [DARPA Robotics Challenge](https://www.darpa.mil/program/darpa-robotics-challenge)
- [Atlas Robot](https://www.bostondynamics.com/atlas)

---

## 另见

- [navigation/](../navigation/) - 导航配置
- [skill-planning/](../skill-planning/) - 技能规划