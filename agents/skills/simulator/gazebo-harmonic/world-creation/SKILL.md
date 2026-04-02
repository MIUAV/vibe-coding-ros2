---
name: world-creation
description: Gazebo 世界创建技能 - SDF 世界文件、环境光照、地形、物理引擎配置
argument-hint: "创建gazebo世界" / "仿真环境" / "地形生成"
user-invocable: true
---

# Gazebo World Creation Skill

> 用于创建 Gazebo Harmonic 仿真世界

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建 SDF 世界文件
- 配置物理引擎
- 添加地形和障碍物
- 设置光照和天气效果

---

## 快速参考

### 基本世界文件

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="my_world">
    <!-- 物理引擎 -->
    <physics name="physics" default="true">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    
    <!-- 光照 -->
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <intensity>1</intensity>
      <diffuse>0.8 0.8 0.8 1</diffuse>
    </light>
    
    <!-- 地面 -->
    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
            </plane>
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
        <visual name="visual">
          <geometry>
            <plane>
              <size>100 100</size>
            </plane>
          </geometry>
          <material>
            <script>
              <uri>file://media/materials/scripts/gazebo.material</uri>
              <name>Gazebo/Grey</name>
            </script>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

---

## 物理引擎配置

### ODE 物理引擎

```xml
<physics name="physics" default="true" type="ode">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
  
  <ode>
    <solver>
      <type>quick</type>
      <iters>50</iters>
      <sor>1.3</sor>
    </solver>
    <constraints>
      <cfm>1e-5</cfm>
      <erp>0.2</erp>
      <contact_max_correcting_vel>100</contact_max_correcting_vel>
      <contact_surface_layer>0.001</contact_surface_layer>
    </constraints>
  </ode>
</physics>
```

### Dart 物理引擎

```xml
<physics name="physics" default="true" type="dart">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
  
  <dart>
    <solver>
      <type>bullet</type>
      <iters>50</iters>
      <tolerance>1e-6</tolerance>
    </solver>
  </dart>
</physics>
```

### 反弹物理

```xml
<physics name="bouncy_physics">
  <dynamics>
    <ode>
      <bullet_friction>0.8</bullet_friction>
    </ode>
  </dynamics>
  
  <collision>
    <surface>
      <friction>
        <ode>
          <mu>1.0</mu>
          <mu2>1.0</mu2>
          <slip1>0</slip1>
          <slip2>0</slip2>
        </ode>
      </friction>
      <restitution>
        <coefficient>0.8</coefficient>
        <threshold>100</threshold>
      </restitution>
    </surface>
  </collision>
</physics>
```

---

## 光照配置

### 定向光

```xml
<light type="directional" name="sun">
  <pose>0 0 10 0 0 0</pose>
  <cast_shadows>true</cast_shadows>
  <intensity>1.0</intensity>
  <diffuse>0.8 0.8 0.8 1</diffuse>
  <specular>0.2 0.2 0.2 1</specular>
  <direction>-0.5 0.5 -0.5</direction>
  <attenuation>
    <range>100</range>
    <constant>0.5</constant>
    <linear>0.01</linear>
    <quadratic>0.001</quadratic>
  </attenuation>
</light>
```

### 点光源

```xml
<light type="point" name="lamp">
  <pose>0 0 3 0 0 0</pose>
  <diffuse>1 0.9 0.7 1</diffuse>
  <specular>1 1 1 1</specular>
  <intensity>0.8</intensity>
  <attenuation>
    <range>10</range>
    <constant>0.5</constant>
    <linear>0.2</linear>
    <quadratic>0.1</quadratic>
  </attenuation>
</light>
```

### 聚光灯

```xml
<light type="spot" name="spot_light">
  <pose>0 0 5 0 0 0</pose>
  <diffuse>1 1 1 1</diffuse>
  <specular>1 1 1 1</specular>
  <intensity>1.0</intensity>
  <spot>
    <inner_angle>0.3</inner_angle>
    <outer_angle>0.5</outer_angle>
    <falloff>1.0</falloff>
  </spot>
  <direction>0 0 -1</direction>
  <attenuation>
    <range>20</range>
    <constant>0.5</constant>
    <linear>0.1</linear>
  </attenuation>
</light>
```

### 环境光

```xml
<scene>
  <ambient>0.3 0.3 0.3 1</ambient>
  <background>0.5 0.7 1 1</background>
  <shadows>true</shadows>
  <grid>false</grid>
  <origin_visual>false</origin_visual>
</scene>
```

---

## 地形创建

### 高度图地形

```xml
<model name="heightmap_terrain">
  <static>true</static>
  <link name="terrain_link">
    <collision name="terrain_collision">
      <geometry>
        <heightmap>
          <uri>file://models/terrain.png</uri>
          <size>100 100 10</size>
          <resolutions>0.5 0.5</resolutions>
        </heightmap>
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
    <visual name="terrain_visual">
      <geometry>
        <heightmap>
          <uri>file://models/terrain.png</uri>
          <size>100 100 10</size>
          <resolutions>0.5 0.5</resolutions>
          <material>
            <script>
              <uri>file://media/materials/scripts/gazebo.material</uri>
              <name>Gazebo/Grass</name>
            </script>
          </material>
        </heightmap>
      </geometry>
    </visual>
  </link>
</model>
```

### 纹理地形

```xml
<visual name="terrain_visual">
  <geometry>
    <heightmap>
      <uri>file://models/terrain.png</uri>
      <size>100 100 5</size>
      <material>
        <diffuse>
          <uri>file://materials/textures/grass.jpg</uri>
          <size>10 10</size>
        </diffuse>
      </material>
    </heightmap>
  </geometry>
</visual>
```

### 几何地形

```xml
<!-- 使用 Mesh -->
<model name="mesh_terrain">
  <static>true</static>
  <link name="terrain_link">
    <collision name="terrain_collision">
      <geometry>
        <mesh>
          <uri>file://models/terrain.obj</uri>
          <scale>1 1 1</scale>
        </mesh>
      </geometry>
    </collision>
    <visual name="terrain_visual">
      <geometry>
        <mesh>
          <uri>file://models/terrain.obj</uri>
          <scale>1 1 1</scale>
        </mesh>
      </geometry>
    </visual>
  </link>
</model>
```

---

## 障碍物和物体

### 墙壁

```xml
<model name="wall">
  <static>true</static>
  <link name="wall_link">
    <pose>0 0 1 0 0 0</pose>
    <collision name="wall_collision">
      <geometry>
        <box>
          <size>10 0.2 2</size>
        </box>
      </geometry>
    </collision>
    <visual name="wall_visual">
      <geometry>
        <box>
          <size>10 0.2 2</size>
        </box>
      </geometry>
      <material>
        <diffuse>0.7 0.7 0.7 1</diffuse>
      </material>
    </visual>
  </link>
</model>
```

### 障碍物

```xml
<model name="obstacle_1">
  <static>true</static>
  <link name="link">
    <pose>2 2 0.5 0 0 0</pose>
    <collision>
      <geometry><cylinder><radius>0.3</radius><height>1</height></cylinder></geometry>
    </collision>
    <visual>
      <geometry><cylinder><radius>0.3</radius><height>1</height></cylinder></geometry>
      <material><diffuse>0.8 0.2 0.2 1</diffuse></material>
    </visual>
  </link>
</model>
```

### 动态物体

```xml
<model name="ball">
  <pose>0 0 1 0 0 0</pose>
  <link name="ball_link">
    <inertial>
      <mass>0.5</mass>
      <inertia>
        <ixx>0.001</ixx><iyy>0.001</iyy><izz>0.001</izz>
      </inertia>
    </inertial>
    <collision>
      <geometry><sphere><radius>0.2</radius></sphere></geometry>
    </collision>
    <visual>
      <geometry><sphere><radius>0.2</radius></sphere></geometry>
      <material><diffuse>1 0 0 1</diffuse></material>
    </visual>
  </link>
</model>
```

---

## 环境效果

### 天空盒

```xml
<scene>
  <sky>
    <clouds>
      <speed>0.1</speed>
      <scale>0.5</scale>
      <ambient>0.8 0.8 0.8 1</ambient>
    </clouds>
  </sky>
</scene>
```

### 雾效

```xml
<scene>
  <fog>
    <color>0.8 0.8 0.8 1</color>
    <density>0.01</density>
    <type>linear</type>
    <start>10</start>
    <end>50</end>
  </fog>
</scene>
```

---

## 包含其他模型

```xml
<!-- 包含模型库中的模型 -->
<include>
  <uri>model://pioneer2dx</uri>
  <pose>0 0 0 0 0 1.57</pose>
  <name>pioneer</name>
</include>

<!-- 包含本地模型 -->
<include>
  <uri>file://models/my_robot.sdf</uri>
  <pose>0 0 0 0 0 0</pose>
  <name>my_robot</name>
</include>
```

---

## GUI 配置

```xml
<gui fullscreen='0'>
  <camera name='user_camera'>
    <pose>-5 -5 2 0 0.275643 2.35619</pose>
    <view_controller>orbit</view_controller>
  </camera>
  
  <entity_visual>
    <link>1</link>
    <geometry>0 0 0 0 0 0</geometry>
  </entity_visual>
</gui>
```

---

## 常见问题

### 问题 1: 物理不稳定

**解决方案**：减小 max_step_size，增加 real_time_factor

### 问题 2: 阴影不显示

**解决方案**：确认 cast_shadows 设置为 true，光源强度足够

---

## 相关资源

- [Gazebo World File](https://gazebosim.org/docs/harmonic/sdf_worlds)
- [Heightmap](https://gazebosim.org/docs/harmonic/heightmap)

---

## 另见

- [robot-modeling](../robot-modeling/) - 机器人建模
- [sensor-integration](../sensor-integration/) - 传感器集成