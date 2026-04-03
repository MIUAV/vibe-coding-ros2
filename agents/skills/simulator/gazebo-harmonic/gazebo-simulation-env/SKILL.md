---
name: gazebo-simulation-env
description: Gazebo 仿真环境创建技能 - 世界文件、地形、障碍物、气象条件、多机器人场景配置
argument-hint: "Gazebo仿真环境" / "创建仿真世界" / "地形建模" / "gazebo环境配置"
user-invocable: true
---

# Gazebo 仿真环境创建技能

> 用于在 Gazebo Harmonic 中创建高质量仿真环境，包括地形、障碍物、多机器人场景和气象条件

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建 Gazebo 世界文件（.world）
- 构建地形和障碍物
- 配置多机器人仿真场景
- 设置气象条件（光照、雨雪）
- 导入真实环境扫描地图

---

## 世界文件结构

### 最小 Gazebo Harmonic 世界

```xml
<?xml version="1.0"?>
<sdf version="1.9">
  <world name="empty_world">
    <!-- 物理插件 -->
    <physics name="physics" type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>

    <!-- 场景 -->
    <scene>
      <ambient>0.5 0.5 0.5 1</ambient>
      <shadows>true</shadows>
      <grid>false</grid>
    </scene>

    <!-- 光照 -->
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <specular>0.1 0.1 0.1 1</specular>
      <attenuation><range>1000</range><constant>0.9</constant><linear>0.01</linear><quadratic>0.001</quadratic></attenuation>
      <direction>-0.5 0.1 -0.9</direction>
    </light>

    <!-- 地面 -->
    <平面>
      <geometry>
        <plane>
          <size>100 100</size>
          <normal>0 0 1</normal>
        </plane>
      </geometry>
      <material>
        <ambient>0.5 0.5 0.5 1</ambient>
        <diffuse>0.7 0.7 0.7 1</diffuse>
        <specular>0.01 0.01 0.01 1</specular>
      </material>
    </平面>

    <!-- 包含机器人 -->
    <include>
      <uri>model://my_robot</uri>
      <name>robot1</name>
      <pose>0 0 0 0 0 0</pose>
    </include>
  </world>
</sdf>
```

---

## 地形创建

### 高度图地形

```xml
<!-- 高度图地形 -->
<model name="heightmap_terrain">
  <static>true</static>
  <link name="terrain_link">
    <collision name="collision">
      <geometry>
        <heightmap>
          <use_terrain_paging>false</use_terrain_paging>
          <sdf_filename>terrain.dem</sdf_filename>
          <texture>
            <size>10</size>
            <diffuse>file://media/materials/textures/terrain/dirt_diffuse.png</diffuse>
            <normal>file://media/materials/textures/terrain/dirt_normal.png</normal>
          </texture>
          <blur>1.5</blur>
          <primitives>3</primitives>
          <view_primitives>false</view_primitives>
          <cell_height>0.5</cell_height>
        </heightmap>
      </geometry>
    </collision>
    <visual name="visual">
      <geometry>
        <heightmap>
          <sdf_filename>terrain.dem</sdf_filename>
          <texture>
            <diffuse>file://media/materials/textures/terrain/dirt_diffuse.png</diffuse>
            <normal>file://media/materials/textures/terrain/dirt_normal.png</normal>
          </texture>
        </heightmap>
      </geometry>
    </visual>
  </link>
</model>
```

### 程序化不平整地面

```python
import numpy as np

def generate_rough_terrain(size=20, amplitude=0.1):
    """生成粗糙地面高度数据"""
    x = np.linspace(-size/2, size/2, 100)
    y = np.linspace(-size/2, size/2, 100)
    X, Y = np.meshgrid(x, y)

    # 基础地形 + 噪声
    Z = amplitude * np.sin(X * 0.5) * np.cos(Y * 0.5)
    Z += 0.05 * np.random.randn(100, 100)
    return Z
```

---

## 障碍物配置

### 静态障碍物

```xml
<!-- 墙壁 -->
<model name="wall_1">
  <static>true</static>
  <link name="wall_link">
    <pose>5 0 1.25 0 0 0</pose>
    <collision name="wall_collision">
      <geometry>
        <box><size>0.2 5 2.5</size></box>
      </geometry>
    </collision>
    <visual name="wall_visual">
      <geometry>
        <box><size>0.2 5 2.5</size></box>
      </geometry>
      <material>
        <diffuse>0.6 0.6 0.6 1</diffuse>
      </material>
    </visual>
  </link>
</model>

<!-- 圆柱障碍物 -->
<model name="cylinder_obstacle">
  <static>true</static>
  <link name="cylinder_link">
    <pose>3 3 0.5 0 0 0</pose>
    <collision name="collision">
      <geometry>
        <cylinder>
          <radius>0.3</radius>
          <length>1.0</length>
        </cylinder>
      </geometry>
    </collision>
    <visual name="visual">
      <geometry>
        <cylinder>
          <radius>0.3</radius>
          <length>1.0</length>
        </cylinder>
      </geometry>
      <material>
        <diffuse>0.8 0.2 0.2 1</diffuse>
      </material>
    </visual>
  </link>
</model>
```

### 动态障碍物

```xml
<!-- 移动的人 -->
<model name="walking_person">
  <static>false</static>
  <link name="body">
    <pose>0 0 0.9 0 0 0</pose>
    <collision name="collision">
      <geometry>
        <cylinder><radius>0.3</radius><length>1.8</length></cylinder>
      </geometry>
    </collision>
    <!-- 使用.actor 实现动画移动 -->
    <plugin name="actor_plugin" filename="libActorPlugin.so">
      <model>
        <walking>
          <pose>-5 0 0 0 0 0</pose>
          <keyframe>
            <time>0</time>
            <pose>-5 0 0 0 0 0</pose>
          </keyframe>
          <keyframe>
            <time>2</time>
            <pose>5 0 0 0 0 0</pose>
          </keyframe>
          <keyframe>
            <time>4</time>
            <pose>-5 0 0 0 0 0</pose>
          </keyframe>
        </walking>
      </model>
    </plugin>
  </link>
</model>
```

---

## 传感器仿真

### 激光雷达

```xml
<plugin name="gazebo::ros::Rayscan" name="gazebo_ros_laser">
  <ros>
    <namespace>/robot1</namespace>
    <remapping>~/out:=scan</remapping>
  </ros>
  <frame_name>laser_link</frame_name>
  <publish_intensities>false</publish_intensities>
  <publish_channels>true</publish_channels>
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
      <min>0.08</min>
      <max>30.0</max>
      <resolution>0.01</resolution>
    </range>
    <noise>
      <type>gaussian</type>
      <mean>0.0</mean>
      <stddev>0.01</stddev>
    </noise>
  </ray>
</plugin>
```

### RGB-D 相机

```xml
<sensor name="depth_camera" type="depth">
  <camera name="depth">
    <horizontal_fov>1.047</horizontal_fov>
    <image>
      <width>640</width>
      <height>480</height>
      <format>R8G8B8</format>
    </image>
    <clip>
      <near>0.1</near>
      <far>10</far>
    </clip>
  </camera>
  <plugin name="gazebo_ros_camera" filename="libgazebo_ros_camera.so">
    <ros>
      <namespace>/robot1</namespace>
      <remapping>image_raw:=camera/image_raw</remapping>
      <remapping>camera_info:=camera/camera_info</remapping>
    </ros>
    <camera_name>depth</camera_name>
    <frame_name>camera_link</frame_name>
  </plugin>
</sensor>
```

---

## 气象条件

```xml
<!-- 天气效果 -->
<scene>
  <fog>
    <type>exponential</type>
    <color>0.9 0.9 0.9 1</color>
    <density>0.01</density>
  </fog>
  <sky>
    <clouds>
      <speed>10</speed>
      <direction>1 0 -1</direction>
      <humidity>30</humidity>
    </clouds>
  </sky>
</scene>

<!-- 雨效果（通过粒子系统） -->
<model name="rain">
  <static>true</static>
  <link name="rain_link">
    <plugin name="ParticleEffect" name="rain">
      <filename>particle/rain.dae</filename>
      <start_time>0</start_time>
      <end_time>-1</end_time>
      <update_rate>30</update_rate>
      <particle_scatter_ratio>-1</particle_scatter_ratio>
    </plugin>
  </link>
</model>
```

---

## 多机器人场景

```python
# launch/multi_robot_gazebo.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
import math

def generate_robot_pose(i, total):
    angle = 2 * math.pi * i / total
    r = 2.0
    x = r * math.cos(angle)
    y = r * math.sin(angle)
    return f"{x} {y} 0 0 0 {angle}"

def generate_multi_robot_launch(num_robots=3):
    robots = []
    for i in range(num_robots):
        ns = f"robot{i+1}"
        robots.append(
            DeclareLaunchArgument(f'{ns}_pose', default_value=generate_robot_pose(i, num_robots)),
            Node(
                package='gazebo_ros',
                executable='spawn_entity.py',
                arguments=[
                    '-entity', f'robot_{i+1}',
                    '-topic', f'robot_description_{i+1}',
                    '-namespace', ns,
                    '-x', str(2 * math.cos(2 * math.pi * i / num_robots)),
                    '-y', str(2 * math.sin(2 * math.pi * i / num_robots)),
                ],
                output='screen',
            ),
        )
    return LaunchDescription(robots)
```

---

## ROS2 launch 整合

```python
# launch/robot_gazebo.launch.py
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource

def generate_launch_description():
    pkg_share = get_package_share_directory('my_robot_description')
    world_file = os.path.join(pkg_share, 'worlds', 'warehouse.world')

    return LaunchDescription([
        # Gazebo
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                os.path.join(get_package_share_directory('gazebo_ros'), 'launch', 'gazebo.launch.py')
            ),
            launch_arguments={'world': world_file}.items(),
        ),
        # 机器人描述
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            parameters=[{'robot_description': open(os.path.join(pkg_share, 'urdf', 'robot.urdf')).read()}],
        ),
    ])
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| Gazebo 启动黑屏 | GPU 驱动问题 | `export LIBGL_ALWAYS_SOFTWARE=1` |
| 模型加载失败 | URI 路径错误 | 确认 `GAZEBO_MODEL_PATH` 包含模型目录 |
| 激光雷达无数据 | 插件未加载 | 检查 `gz topic -l` 确认插件已启动 |
| 物理不稳定 | dt 太大 | 减小 `max_step_size` |
| 纹理缺失 | 材质路径错误 | 设置 `GAZEBO_RESOURCE_PATH` |

### 调试命令

```bash
# 查看可用话题
gz topic -l

# 查看模型列表
gz model -l

# 移动模型
gz model -m robot1 -x 1 -y 2 -z 0

# 查看传感器数据
gz topic -e /robot1/lidar/scan

# 重置世界
gz world -w empty_world -r
```

---

## 相关技能

- `simulator/gazebo-harmonic/robot-modeling` — Gazebo 机器人建模
- `simulator/gazebo-harmonic/sensor-integration` — Gazebo 传感器集成
- `simulator/gazebo-harmonic/plugin-development` — Gazebo 插件开发
- `navigation/nav2-integration` — Nav2 导航集成
