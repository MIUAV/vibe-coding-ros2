---
name: gazebo-simulation-env
description: Gazebo 仿真环境开发技能 - 地形创建、气象条件、障碍物设置、多机器人仿真场景
argument-hint: "创建仿真环境" / "地形建模" / "风力仿真" / "障碍物场景"
user-invocable: true
---

# Gazebo Simulation Environment Skill

> 用于创建 Gazebo 仿真环境和场景配置

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建各种地形环境
- 配置气象条件（风、雨、温度）
- 添加静态和动态障碍物
- 设置多机器人仿真场景
- 配置光照和时间

---

## 快速参考

```
环境类型:
- 室内环境     - 办公室、工厂
- 室外环境     - 道路、山地
- 特殊环境     - 水下、空中
```

---

## 地形创建

### 室内环境

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="indoor_env">
    <!-- 物理引擎 -->
    <physics name="physics" default="true">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    
    <!-- 地面 -->
    <model name="floor">
      <static>true</static>
      <link name="link">
        <pose>0 0 0 0 0 0</pose>
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>20 20</size>
            </plane>
          </geometry>
          <surface>
            <friction>
              <ode>
                <mu>0.5</mu>
                <mu2>0.5</mu2>
              </ode>
            </friction>
          </surface>
        </collision>
        <visual name="visual">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>20 20</size>
            </plane>
          </geometry>
          <material>
            <ambient>0.5 0.5 0.5 1</ambient>
            <diffuse>0.5 0.5 0.5 1</diffuse>
            <specular>0.1 0.1 0.1 1</specular>
          </material>
        </visual>
      </link>
    </model>
    
    <!-- 墙壁 -->
    <model name="wall_north">
      <static>true</static>
      <link name="link">
        <pose>0 10 1.5 0 0 0</pose>
        <collision name="collision">
          <geometry>
            <box>
              <size>20 0.2 3</size>
            </box>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <box>
              <size>20 0.2 3</size>
            </box>
          </geometry>
          <material>
            <ambient>0.8 0.8 0.8 1</ambient>
          </material>
        </visual>
      </link>
    </model>
    
    <!-- 柱子 -->
    <model name="pillar_1">
      <static>true</static>
      <link name="link">
        <pose>5 5 1.5 0 0 0</pose>
        <collision name="collision">
          <geometry>
            <box>
              <size>0.3 0.3 3</size>
            </box>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <box>
              <size>0.3 0.3 3</size>
            </box>
          </geometry>
          <material>
            <ambient>0.6 0.6 0.6 1</ambient>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

### 室外道路环境

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="outdoor_env">
    <!-- 道路 -->
    <model name="road">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 10</size>
            </plane>
          </geometry>
          <surface>
            <friction>
              <ode>
                <mu>0.9</mu>
                <mu2>0.9</mu2>
              </ode>
            </friction>
          </surface>
        </collision>
        <visual name="visual">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 10</size>
            </plane>
          </geometry>
          <material>
            <ambient>0.3 0.3 0.3 1</ambient>
            <diffuse>0.3 0.3 0.3 1</diffuse>
          </material>
        </visual>
        
        <!-- 道路标记 -->
        <visual name="center_line">
          <pose>0 0 0.001 0 0 0</pose>
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 0.15</size>
            </plane>
          </geometry>
          <material>
            <ambient>1 1 0 1</ambient>
          </material>
        </visual>
        
        <visual name="edge_line">
          <pose>4.5 0 0.001 0 0 0</pose>
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 0.1</size>
            </plane>
          </geometry>
          <material>
            <ambient>1 1 1 1</ambient>
          </material>
        </visual>
      </link>
    </model>
    
    <!-- 路边建筑 -->
    <model name="building_1">
      <static>true</static>
      <link name="link">
        <pose>-8 8 3 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <box>
              <size>6 6 6</size>
            </box>
          </geometry>
          <material>
            <ambient>0.7 0.6 0.5 1</ambient>
          </material>
        </visual>
      </link>
    </model>
    
    <!-- 路灯 -->
    <model name="street_lamp">
      <static>true</static>
      <link name="pole">
        <pose>-5 5.5 0 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <cylinder radius="0.05" height="4"/>
          </geometry>
          <material>
            <ambient>0.4 0.4 0.4 1</ambient>
          </material>
        </visual>
      </link>
      <link name="light">
        <pose>-5 5 4.2 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <box size="0.3 0.3 0.1"/>
          </geometry>
          <material>
            <emissive>1 1 0.9 1</emissive>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

### 山地地形

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="mountain_env">
    <!-- 高度地图地形 -->
    <model name="terrain">
      <static>true</static>
      <link name="link">
        <visual name="visual">
          <geometry>
            <heightmap>
              <uri>file://media/heights/mountain.png</uri>
              <size>50 50 10</size>
              <position>0 0 0</position>
            </heightmap>
          </geometry>
          <material>
            <ambient>0.4 0.5 0.3 1</ambient>
            <diffuse>0.4 0.5 0.3 1</diffuse>
          </material>
        </visual>
        <collision name="collision">
          <geometry>
            <heightmap>
              <uri>file://media/heights/mountain.png</uri>
              <size>50 50 10</size>
              <position>0 0 0</position>
            </heightmap>
          </geometry>
          <surface>
            <friction>
              <ode>
                <mu>0.8</mu>
                <mu2>0.8</mu2>
              </ode>
            </friction>
          </surface>
        </collision>
      </link>
    </model>
    
    <!-- 树木 -->
    <model name="tree_1">
      <static>true</static>
      <link name="trunk">
        <pose>10 10 0 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <cylinder radius="0.2" height="3"/>
          </geometry>
          <material>
            <ambient>0.4 0.25 0.1 1</ambient>
          </material>
        </visual>
      </link>
      <link name="foliage">
        <pose>10 10 3.5 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <sphere radius="1.5"/>
          </geometry>
          <material>
            <ambient>0.2 0.5 0.2 1</ambient>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

---

## 气象条件

### 风力仿真

```xml
<!-- 恒定风力 -->
<plugin filename="gz-sim-wind-system" name="gz::sim::systems::Wind">
  <frame_id>world</frame_id>
  <namespace>wind</namespace>
  
  <!-- 风向 (北偏东) -->
  <direction>
    <x>0.7</x>
    <y>0.7</y>
    <z>0</z>
  </direction>
  
  <!-- 基础风速 -->
  <magnitude>
    <type>constant</type>
    <value>5.0</value>
  </magnitude>
</plugin>

<!-- 阵风系统 -->
<plugin filename="gz-sim-wind-gust-system" name="gz::sim::systems::WindGust">
  <start_time>10.0</start_time>
  <duration>5.0</duration>
  <direction>
    <x>1</x>
    <y>0</y>
    <z>0.2</z>
  </direction>
  <magnitude>
    <type>pulse</type>
    <min_value>3.0</min_value>
    <max_value>12.0</max_value>
    <period>2.0</period>
  </magnitude>
</plugin>

<!-- 随机湍流 -->
<plugin filename="gz-sim-wind-random-system" name="gz::sim::systems::Wind">
  <turbulence>
    <type>gaussian</type>
    <scale>1.5</scale>
    <cutoff_frequency>0.5</cutoff_frequency>
  </turbulence>
</plugin>
```

### 雨雪天气

```xml
<!-- 降雨系统 -->
<plugin filename="gz-sim-rain-system" name="gz::sim::systems::Rain">
  <update_period>0.01</update_period>
  <(rows>500</rows>
  <cols>500</cols>
  <particle_size>0.02</particle_size>
  <fall_speed>9.8</fall_speed>
  <intensity>0.5</intensity>
</plugin>

<!-- 降雪系统 -->
<plugin filename="gz-sim-snow-system" name="gz::sim::systems::Snow">
  <update_period>0.02</update_period>
  <particle_size>0.01</particle_size>
  <fall_speed>1.0</fall_speed>
  <intensity>0.3</intensity>
</plugin>
```

---

## 障碍物设置

### 静态障碍物

```xml
<!-- 箱子障碍物 -->
<model name="obstacle_box">
  <static>true</static>
  <link name="link">
    <pose>2 1 0.25 0 0 0.2</pose>
    <collision name="collision">
      <geometry>
        <box>
          <size>0.5 0.5 0.5</size>
        </box>
      </geometry>
    </collision>
    <visual name="visual">
      <geometry>
        <box>
          <size>0.5 0.5 0.5</size>
        </box>
      </geometry>
      <material>
        <ambient>0.8 0.3 0.2 1</ambient>
      </material>
    </visual>
  </link>
</model>

<!-- 圆柱障碍物 -->
<model name="obstacle_cylinder">
  <static>true</static>
  <link name="link">
    <pose>3 -1 0.5 0 0 0</pose>
    <collision name="collision">
      <geometry>
        <cylinder radius="0.3" height="1"/>
      </geometry>
    </collision>
    <visual name="visual">
      <geometry>
        <cylinder radius="0.3" height="1"/>
      </geometry>
      <material>
        <ambient>0.3 0.3 0.8 1</ambient>
      </material>
    </visual>
  </link>
</model>
```

### 动态障碍物

```xml
<!-- 移动障碍物 - 行人 -->
<model name="pedestrian">
  <static>false</static>
  <link name="body">
    <pose>0 0 0.9 0 0 0</pose>
    <inertial>
      <mass>70</mass>
    </inertial>
    <visual name="visual">
      <geometry>
        <cylinder radius="0.2" height="1.8"/>
      </geometry>
    </visual>
  </link>
  
  <!-- 移动插件 -->
  <plugin filename="gz-sim-random-walk-system" name="gz::sim::systems::RandomWalk">
    <update_period>0.1</update_period>
    <velocity>
      <mean>1.2</mean>
      <min>0.5</min>
      <max>2.0</max>
    </velocity>
    <direction_change>
      <mean>5.0</mean>
      <min>2.0</min>
      <max>10.0</max>
    </direction_change>
  </plugin>
</model>

<!-- 车辆障碍物 -->
<model name="moving_car">
  <static>false</static>
  <link name="body">
    <pose>0 0 0.5 0 0 0</pose>
    <inertial>
      <mass>1500</mass>
    </inertial>
    <visual name="visual">
      <geometry>
        <box size="4 2 1.5"/>
      </geometry>
    </visual>
  </link>
  
  <plugin filename="gz-sim-waypoint-system" name="gz::sim::systems::WaypointFollower">
    <velocity>5.0</velocity>
    <waypoints>
      <point>0 0</point>
      <point>50 0</point>
      <point>50 20</point>
      <point>0 20</point>
    </waypoints>
    <loop>true</loop>
  </plugin>
</model>
```

### 交通锥

```xml
<model name="traffic_cone">
  <static>true</static>
  <link name="link">
    <pose>1 0 0 0 0 0</pose>
    <collision name="collision">
      <geometry>
        <cone radius_bottom="0.15" radius_top="0.03" height="0.3"/>
      </geometry>
    </collision>
    <visual name="visual">
      <geometry>
        <cone radius_bottom="0.15" radius_top="0.03" height="0.3"/>
      </geometry>
      <material>
        <ambient>1 0.3 0 1</ambient>
      </material>
    </visual>
  </link>
</model>
```

---

## 光照配置

### 太阳光

```xml
<!-- 定向光 - 太阳 -->
<light type="directional" name="sun">
  <pose>0 0 10 0 0 0</pose>
  <diffuse>1 0.98 0.9 1</diffuse>
  <specular>0.8 0.8 0.8 1</specuse>
  <cast_shadows>true</cast_shadows>
  <intensity>1.0</intensity>
  <direction>-0.5 -0.5 -1</direction>
  <shadow>
    <map_size>2048</map_size>
    <bias>0.00005</bias>
  </shadow>
</light>
```

### 环境光

```xml
<!-- 环境光 -->
<scene>
  <ambient>0.3 0.3 0.3 1</ambient>
  <background>0.5 0.7 1.0 1</background>
  <shadows>true</shadows>
  <grid>false</grid>
  <origin_visual>false</origin_visual>
</scene>
```

---

## 多机器人仿真

### 多机器人场景

```xml
<?xml version="1.0" ?>
<sdf version="1.11">
  <world name="multi_robot_env">
    <!-- 机器人1 -->
    <model name="robot_1">
      <include>
        <uri>model://diff_drive_robot</uri>
      </include>
      <pose>0 0 0 0 0 0</pose>
    </model>
    
    <!-- 机器人2 -->
    <model name="robot_2">
      <include>
        <uri>model://diff_drive_robot</uri>
      </include>
      <pose>2 2 0 0 0 1.57</pose>
    </model>
    
    <!-- 机器人3 -->
    <model name="robot_3">
      <include>
        <uri>model://quadrotor</uri>
      </include>
      <pose>4 0 1 0 0 0</pose>
    </model>
    
    <!-- 交通规则区域 -->
    <model name="speed_limit_zone">
      <static>true</static>
      <link name="link">
        <pose>5 0 0.1 0 0 0</pose>
        <visual name="visual">
          <geometry>
            <box size="2 10 0.01"/>
          </geometry>
          <material>
            <ambient>1 1 0 0.3</ambient>
            <transparency>0.7</transparency>
          </material>
        </visual>
      </link>
    </model>
  </world>
</sdf>
```

### 机器人间距控制

```xml
<gazebo>
  <plugin filename="gz-sim-collision-detector" name="gz::sim::systems::CollisionDetector">
    <robotNamespace>multi_robot</robotNamespace>
    <check_interval>0.05</check_interval>
    <min_separation_distance>0.5</min_separation_distance>
    <warn_distance>1.0</warn_distance>
  </plugin>
</gazebo>
```

---

## 时间与天气

### 动态时间

```xml
<!-- 太阳轨迹 -->
<plugin filename="gz-sim-sun-system" name="gz::sim::systems::Sun">
  <update_period>60</update_period>
  <sunrise_time>6:00</sunrise_time>
  <sunset_time>18:00</sunset_time>
  <day_night_cycle>true</day_night_cycle>
</plugin>
```

### 雾效

```xml
<!-- 雾 -->
<scene>
  <fog>
    <type>linear</type>
    <color>0.8 0.8 0.8 1</color>
    <density>0.05</density>
    <start>10</start>
    <end>50</end>
  </fog>
</scene>
```

---

## 传感器环境干扰

### 灰尘/烟雾

```xml
<gazebo reference="laser_sensor">
  <sensor>
    <noise>
      <type>gaussian</type>
      <mean>0.0</mean>
      <stddev>0.02</stddev>
    </noise>
  </sensor>
</gazebo>

<gazebo reference="camera_sensor">
  <sensor>
    <distortion>
      <k1>0.001</k1>
      <k2>0.001</k2>
      <p1>0.0</p1>
      <p2>0.0</p2>
    </distortion>
  </sensor>
</gazebo>
```

---

## 常见问题

### 问题 1: 地形加载失败

**解决方案**：
- 检查高度图格式 (PNG/JPG)
- 验证文件路径
- 确认大小参数

### 问题 2: 风力影响异常

**解决方案**：
- 调整风力系数
- 检查机器人质量
- 验证阻力参数

### 问题 3: 多机器人碰撞

**解决方案**：
- 增加安全距离
- 启用碰撞检测
- 设置避障行为

---

## 相关资源

- [Gazebo Worlds](https://gazebosim.org/models)
- [Heightmap Demo](https://gazebosim.org/docs/harmonic/heightmap)
- [Weather Systems](https://gazebosim.org/docs/harmonic/weather)

---

## 另见

- [sdf-xacro-model/../wheeled_vehicle/) - 轮式车辆模型