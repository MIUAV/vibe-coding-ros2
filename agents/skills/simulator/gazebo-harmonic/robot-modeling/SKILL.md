---
name: robot-modeling
description: Gazebo 机器人建模技能 - SDF 模型结构、链接、关节、惯性配置
argument-hint: gazebo机器人模型 OR SDF建模 OR 创建机器人
user-invocable: true
---

# Gazebo Robot Modeling Skill

> 用于在 Gazebo Harmonic 中创建机器人模型

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建 SDF 机器人模型文件
- 定义机器人链接和关节
- 配置惯性和碰撞体
- 添加执行器和驱动器

---

## 快速参考

### SDF 机器人模型基本结构

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="my_robot">
    <static>false</static>
    
    <link name="base_link">
      <pose>0 0 0.1 0 0 0</pose>
      <inertial>
        <mass>1.0</mass>
        <inertia>
          <ixx>0.001</ixx>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyy>0.001</iyy>
          <iyz>0</iyz>
          <izz>0.001</izz>
        </inertia>
      </inertial>
      
      <collision name="base_collision">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
      </collision>
      
      <visual name="base_visual">
        <geometry>
          <box>
            <size>0.5 0.5 0.1</size>
          </box>
        </geometry>
        <material>
          <diffuse>0.5 0.5 0.5 1</diffuse>
        </material>
      </visual>
    </link>
    
    <joint name="wheel_joint" type="revolute">
      <parent>base_link</parent>
      <child>wheel_link</child>
      <axis>
        <xyz>0 0 1</xyz>
        <limit>-1e16 1e16</limit>
      </axis>
    </joint>
  </model>
</sdf>
```

---

## 链接配置

### 惯性参数

```xml
<inertial>
  <mass>5.0</mass>
  <frame>link_frame</frame>
  <inertia>
    <ixx>0.01</ixx>
    <ixy>0</ixy>
    <ixz>0</ixz>
    <iyy>0.01</iyy>
    <iyz>0</iyz>
    <izz>0.01</izz>
  </inertia>
</inertial>
```

### 碰撞体

```xml
<collision name="base_collision">
  <pose>0 0 0 0 0 0</pose>
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
    <restitution>
      <coefficient>0.5</coefficient>
    </restitution>
  </surface>
</collision>
```

### 视觉体

```xml
<visual name="base_visual">
  <pose>0 0 0 0 0 0</pose>
  <geometry>
    <box>
      <size>0.5 0.5 0.1</size>
    </box>
  </geometry>
  <material>
    <ambient>0.5 0.5 0.5 1</ambient>
    <diffuse>0.5 0.5 0.5 1</diffuse>
    <specular>0.1 0.1 0.1 1</specular>
  </material>
</visual>
```

---

## 关节配置

### Revolute 关节 (旋转关节)

```xml
<joint name="wheel_joint" type="revolute">
  <parent>base_link</parent>
  <child>wheel_link</child>
  
  <pose>0 0 0 0 0 0</pose>
  
  <axis>
    <xyz>0 0 1</xyz>
    <limit>
      <lower>-1.57</lower>
      <upper>1.57</upper>
      <effort>10</effort>
      <velocity>5</velocity>
    </limit>
    <dynamics>
      <damping>0.1</damping>
      <friction>0.1</friction>
    </dynamics>
  </axis>
</joint>
```

### Continuous 关节 (连续旋转)

```xml
<joint name="wheel_joint" type="continuous">
  <parent>base_link</parent>
  <child>wheel_link</child>
  
  <axis>
    <xyz>0 0 1</xyz>
    <dynamics>
      <damping>0.05</damping>
      <friction>0.0</friction>
    </dynamics>
  </axis>
</joint>
```

### Prismatic 关节 (滑动关节)

```xml
<joint name="slider_joint" type="prismatic">
  <parent>base_link</parent>
  <child>slider_link</child>
  
  <axis>
    <xyz>1 0 0</xyz>
    <limit>
      <lower>0</lower>
      <upper>1.0</upper>
      <effort>100</effort>
      <velocity>0.5</velocity>
    </limit>
  </axis>
</joint>
```

### Fixed 关节 (固定)

```xml
<joint name="fixed_joint" type="fixed">
  <parent>base_link</parent>
  <child>mounted_link</child>
</joint>
```

### Ball 关节 (球形关节)

```xml
<joint name="ball_joint" type="ball">
  <parent>base_link</parent>
  <child>ball_link</child>
  <axis>
    <xyz>1 0 0</xyz>
    <dynamics>
      <damping>0.1</damping>
    </dynamics>
  </axis>
</joint>
```

---

## 执行器配置

### 电机驱动

```xml
<joint name="wheel_joint" type="revolute">
  <parent>base_link</parent>
  <child>wheel_link</child>
  
  <axis>
    <xyz>0 0 1</xyz>
    <limit>
      <lower>-10</lower>
      <upper>10</upper>
      <effort>5</effort>
      <velocity>10</velocity>
    </limit>
  </axis>
  
  <!-- 关节驱动器配置 -->
  <dynamics>
    <damping>0.1</damping>
    <friction>0.2</friction>
  </dynamics>
</joint>
```

### 位置控制

```xml
<!-- 使用 position 控制器 -->
<plugin filename="gz-sim-joint-position-controller-system" name="gz::sim::systems::JointPositionController">
  <joint_name>arm_joint_1</joint_name>
  <initial_position>0.0</initial_position>
</plugin>
```

### 速度控制

```xml
<plugin filename="gz-sim-joint-velocity-controller-system" name="gz::sim::systems::JointVelocityController">
  <joint_name>wheel_joint</joint_name>
  <velocity>0.0</velocity>
</plugin>
```

---

## 机器人类型模板

### 差速驱动机器人

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <model name="differential_robot">
    <static>false</static>
    
    <!-- 主体 -->
    <link name="base_link">
      <pose>0 0 0.15 0 0 0</pose>
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.01</ixx><iyy>0.01</iyy><izz>0.01</izz>
        </inertia>
      </inertial>
      <collision name="base_collision">
        <geometry><box><size>0.4 0.3 0.1</size></box></geometry>
      </collision>
      <visual name="base_visual">
        <geometry><box><size>0.4 0.3 0.1</size></box></geometry>
        <material><diffuse>0.8 0.2 0.2 1</diffuse></material>
      </visual>
    </link>
    
    <!-- 左轮 -->
    <link name="left_wheel">
      <pose>0 0.2 0.05 -1.57 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia><ixx>0.001</ixx><iyy>0.001</iyy><izz>0.001</izz></inertia>
      </inertial>
      <collision name="left_wheel_collision">
        <geometry><cylinder><radius>0.05</radius><length>0.04</length></cylinder></geometry>
      </collision>
      <visual name="left_wheel_visual">
        <geometry><cylinder><radius>0.05</radius><length>0.04</length></cylinder></geometry>
        <material><diffuse>0.2 0.2 0.2 1</diffuse></material>
      </visual>
    </link>
    
    <!-- 右轮 -->
    <link name="right_wheel">
      <pose>0 -0.2 0.05 -1.57 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia><ixx>0.001</ixx><iyy>0.001</iyy><izz>0.001</izz></inertia>
      </inertial>
      <collision name="right_wheel_collision">
        <geometry><cylinder><radius>0.05</radius><length>0.04</length></cylinder></geometry>
      </collision>
      <visual name="right_wheel_visual">
        <geometry><cylinder><radius>0.05</radius><length>0.04</length></cylinder></geometry>
        <material><diffuse>0.2 0.2 0.2 1</diffuse></material>
      </visual>
    </link>
    
    <!-- 左轮关节 -->
    <joint name="left_wheel_joint" type="continuous">
      <parent>base_link</parent>
      <child>left_wheel</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
    
    <!-- 右轮关节 -->
    <joint name="right_wheel_joint" type="continuous">
      <parent>base_link</parent>
      <child>right_wheel</child>
      <axis><xyz>0 0 1</xyz></axis>
    </joint>
  </model>
</sdf>
```

### 四轮麦轮/阿克曼转向

```xml
<!-- 参考 differentials 示例扩展 -->
```

---

## 嵌套模型

```xml
<model name="compound_robot">
  <!-- 主车体 -->
  <link name="chassis">...</link>
  
  <!-- 嵌套模型 - 机械臂 -->
  <model name="arm">
    <static>false</static>
    <link name="arm_base">...</link>
  </model>
</model>
```

---

## 常见问题

### 问题 1: 机器人掉落

**解决方案**：检查惯性质量和重力设置

### 问题 2: 关节抖动

**解决方案**：调整 damping 和 friction 参数

---

## 相关资源

- [Gazebo SDF 文档](http://sdformat.org/spec)
- [Gazebo Tutorials](https://gazebosim.org/docs)

---

## 另见

- [sensor-integration](../sensor-integration/) - 传感器集成
- [world-creation](../world-creation/) - 世界创建