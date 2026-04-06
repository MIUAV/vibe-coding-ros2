#!/bin/bash
# ros2-simulator-generator.sh — Gazebo 仿真包生成器
# 用法: bash ros2-simulator-generator.sh <pkg_name> [sim_type]
# sim_type: differential_drive | manipulator | drone | quadruped | ackermann
#
# 示例: bash ros2-simulator-generator.sh my_robot_sim differential_drive

PKG_NAME="${1:-}"
SIM_TYPE="${2:-differential_drive}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [仿真类型]"
    echo "  differential_drive — 差速驱动仿真（TurtleBot3）"
    echo "  manipulator       — 机械臂仿真（MoveIt2 + Gazebo）"
    echo "  drone            — 无人机仿真（Gazebo UAV）"
    echo "  quadruped        — 四足机器人仿真（宇树 Go1）"
    echo "  ackermann        — 阿克曼转向仿真（赛车/小车）"
    exit 1
fi

set -e

mkdir -p "$PKG_NAME/urdf" "$PKG_NAME/worlds" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>Gazebo simulation package for PKGNAME</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>gazebo_ros_pkgs</depend>
  <depend>gazebo_ros</depend>
  <depend>xacro</depend>
  <depend>robot_state_publisher</depend>
  <depend>joint_state_publisher</depend>
  <depend>rviz2</depend>
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ── CMakeLists.txt ────────────────────────────────────────
cat > "$PKG_NAME/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(PKGNAME)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)
find_package(gazebo_ros REQUIRED)

ament_environment_hooks(
  "${ament_package_share_dir}/envIRONMENT_HOOKS")
ament_package()
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/CMakeLists.txt"

# ════════════════════════════════════════════════════════════
# 差速驱动仿真（TurtleBot3 Burger）
# ════════════════════════════════════════════════════════════
if [[ "$SIM_TYPE" == "differential_drive" ]]; then

# ── URDF ─────────────────────────────────────────────────
cat > "$PKG_NAME/urdf/robot.urdf.xacro" <<'XACROEOF'
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro"
       name="PKGNAME">

  <!-- === 机器人物理参数 === -->
  <xacro:property name="PI" value="3.14159265358979"/>
  <xacro:property name="robot_namespace" value="PKGNAME"/>

  <!-- 尺寸参数 -->
  <xacro:property name="base_radius" value="0.08"/>
  <xacro:property name="base_height" value="0.05"/>
  <xacro:property name="wheel_radius" value="0.033"/>
  <xacro:property name="wheel_width" value="0.034"/>
  <xacro:property name="wheel_separation" value="0.160"/>

  <!-- 颜色定义 -->
  <material name="dark_blue"><color rgba="0.0 0.0 0.6 1.0"/></material>
  <material name="dark_grey"><color rgba="0.2 0.2 0.2 1.0"/></material>

  <!-- 质量属性 -->
  <xacro:property name="base_mass" value="3.0"/>
  <xacro:property name="wheel_mass" value="0.5"/>

  <!-- Gazebo 物理插件 -->
  <gazebo reference="base_footprint">
    <material>Gazebo/DarkBlue</material>
  </gazebo>

  <!-- === Base Link === -->
  <link name="base_footprint">
    <visual><geometry><box size="0.001 0.001 0.001"/></geometry></visual>
  </link>

  <joint name="base_to_base_footprint" type="fixed">
    <parent link="base_footprint"/>
    <child link="base_link"/>
    <origin xyz="0 0 ${base_height/2}" rpy="0 0 0"/>
  </joint>

  <link name="base_link">
    <pose>0 0 ${base_height/2} 0 0 0</pose>
    <inertial>
      <mass value="${base_mass}"/>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <inertia ixx="${base_mass/12*(2*base_radius**2)}" ixy="0" ixz="0"
               iyy="${base_mass/12*(2*base_radius**2)}" iyz="0"
               izz="${base_mass/12*(2*base_radius**2+base_height**2)}"/>
    </inertial>
    <visual>
      <geometry><cylinder radius="${base_radius}" length="${base_height}"/></geometry>
      <material name="dark_blue"/>
    </visual>
    <collision>
      <geometry><cylinder radius="${base_radius}" length="${base_height}"/></geometry>
    </collision>
  </link>

  <!-- Gazebo differential drive plugin -->
  <gazebo>
    <plugin name="gazebo_ros_diff_drive" filename="libgazebo_ros_diff_drive.so">
      <ros>
        <namespace>${robot_namespace}</namespace>
        <remapping>cmd_vel:=cmd_vel</remapping>
        <remapping>odom:=odom</remapping>
      </ros>
      <update_rate>50</update_rate>
      <!-- Wheels -->
      <left_joint>left_wheel_joint</left_joint>
      <right_joint>right_wheel_joint</right_jheel>
      <!-- Kinematics -->
      <wheel_separation>${wheel_separation}</wheel_separation>
      <wheel_radius>${wheel_radius}</wheel_radius>
      <!-- Limits -->
      <max_wheel_torque>20</max_wheel_torque>
      <max_wheel_acceleration>1.0</max_wheel_acceleration>
      <!-- Output -->
      <publish_odom>true</publish_odom>
      <publish_odom_tf>true</publish_odom_tf>
      <publish_wheel_tf>true</publish_wheel_tf>
      <odometry_frame>odom</odometry_frame>
      <robot_base_frame>base_link</robot_base_frame>
    </plugin>
  </gazebo>

  <!-- === Wheels === -->
  <xacro:macro name="wheel_macro" params="prefix">
    <link name="${prefix}_wheel">
      <inertial>
        <mass value="${wheel_mass}"/>
        <origin xyz="0 0 0" rpy="${PI/2} 0 0"/>
        <inertia ixx="${wheel_mass/12*(3*wheel_radius**2+wheel_width**2)}" ixy="0" ixz="0"
                 iyy="${wheel_mass/12*(3*wheel_radius**2+wheel_width**2)}" iyz="0"
                 izz="${wheel_mass/2*wheel_radius**2}"/>
      </inertial>
      <visual>
        <origin xyz="0 0 0" rpy="${PI/2} 0 0"/>
        <geometry><cylinder radius="${wheel_radius}" length="${wheel_width}"/></geometry>
        <material name="dark_grey"/>
      </visual>
      <collision>
        <origin xyz="0 0 0" rpy="${PI/2} 0 0"/>
        <geometry><cylinder radius="${wheel_radius}" length="${wheel_width}"/></geometry>
      </collision>
    </link>

    <joint name="${prefix}_wheel_joint" type="continuous">
      <parent link="base_link"/>
      <child link="${prefix}_wheel"/>
      <origin xyz="${-base_radius*0.3} ${if(prefix=='left',-1,1)*wheel_separation/2} ${-base_height/4}" rpy="0 0 0"/>
      <axis xyz="0 1 0"/>
      <dynamics damping="0.7" friction="1.0"/>
    </joint>
  </xacro:macro>

  <xacro:wheel_macro prefix="left"/>
  <xacro:wheel_macro prefix="right"/>

  <!-- === Laser Scanner (LDS-01) === -->
  <link name="hokuyo_link">
    <pose>0 0 ${base_height+0.02} 0 0 0</pose>
    <inertial>
      <mass value="0.05"/>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <inertia ixx="0.0001" ixy="0" ixz="0" iyy="0.0001" iyz="0" izz="0.0001"/>
    </inertial>
    <visual>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry><box size="0.04 0.05 0.04"/></geometry>
      <material name="dark_grey"/>
    </visual>
    <collision>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry><box size="0.04 0.05 0.04"/></geometry>
    </collision>
  </link>

  <joint name="hokuyo_joint" type="fixed">
    <parent link="base_link"/>
    <child link="hokuyo_link"/>
    <origin xyz="0 0 ${base_height/2+0.02}" rpy="0 0 0"/>
  </joint>

  <gazebo reference="hokuyo_link">
    <sensor type="ray" name="hokuyo">
      <pose>0 0 0 0 0 0</pose>
      <visualize>true</visualize>
      <update_rate>10</update_rate>
      <ray>
        <scan>
          <horizontal>
            <samples>360</samples>
            <resolution>1.0</resolution>
            <min_angle>-3.14159</min_angle>
            <max_angle>3.14159</max_angle>
          </horizontal>
        </scan>
        <range>
          <min>0.12</min>
          <max>3.5</max>
          <resolution>0.015</resolution>
        </range>
        <noise type="gaussian">
          <mean>0.0</mean>
          <stddev>0.01</stddev>
        </noise>
      </ray>
      <plugin name="gazebo_ros_hokuyo" filename="libgazebo_ros_ray_sensor.so">
        <ros>
          <namespace>${robot_namespace}</namespace>
          <remapping>~/out:=scan</remapping>
        </ros>
        <output_type>sensor_msgs/LaserScan</output_type>
        <frame_name>hokuyo_link</frame_name>
      </plugin>
    </sensor>
  </gazebo>

</robot>
XACROEOF
# Fix typo in diff drive plugin
sed -i "s/right_jheel/right_wheel_joint/g" "$PKG_NAME/urdf/robot.urdf.xacro"
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/urdf/robot.urdf.xacro"

# ── Gazebo world ─────────────────────────────────────────
cat > "$PKG_NAME/worlds/empty.world" <<'WORLDEOF'
<?xml version="1.0"?>
<sdf version="1.8">
  <world name="PKGNAME_world">
    <physics type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>
    <scene>
      <ambient>0.5 0.5 0.5 1</ambient>
      <grid>true</grid>
      <shadows>true</shadows>
    </scene>
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 0 10 0 0 0</pose>
      <diffuse>0.8 0.8 0.8 1</diffuse>
      <specular>0.2 0.2 0.2 1</specular>
      <attenuation><range>1000</range><constant>0.9</constant><linear>0.01</linear><quadratic>0.001</quadratic></attenuation>
      <direction>-0.5 0.1 -0.9</direction>
    </light>
    <!-- Ground plane -->
    <model name="ground">
      <static>true</static>
      <link name="ground_link">
        <collision><plane><normal>0 0 1</normal><size>100 100</size></plane></collision>
        <visual><plane><normal>0 0 1</normal><size>100 100</size><material><ambient>0.5 0.5 0.5 1</ambient><diffuse>0.9 0.9 0.9 1</diffuse></material></plane></visual>
      </link>
    </model>
    <!-- Some obstacles for SLAM testing -->
    <model name="obstacle_1">
      <pose>2 0 0.5 0 0 0</pose>
      <static>true</static>
      <link name="link"><collision><geometry><box><size>0.5 0.5 1.0</size></box></geometry></collision>
        <visual><geometry><box><size>0.5 0.5 1.0</size></box></geometry><material><ambient>0.8 0.2 0.2 1</ambient></material></visual>
      </link>
    </model>
    <model name="obstacle_2">
      <pose>0 2 0.5 0 0 0</pose>
      <static>true</static>
      <link name="link"><collision><geometry><box><size>0.5 0.5 1.0</size></box></geometry></collision>
        <visual><geometry><box><size>0.5 0.5 1.0</size></box></geometry><material><ambient>0.2 0.2 0.8 1</ambient></material></visual>
      </link>
    </model>
  </world>
</sdf>
WORLDEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/worlds/empty.world"

# ── Launch ────────────────────────────────────────────────
cat > "$PKG_NAME/launch/sim.launch.py" <<'LAUNCHEOF'
"""Gazebo simulation launch for PKGNAME"""
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    pkg_name = 'PKGNAME'
    world_file = os.path.join(
        get_package_share_directory(pkg_name), 'worlds', 'empty.world')

    return LaunchDescription([
        # Gazebo
        ExecuteProcess(
            cmd=['gazebo', '--verbose', world_file, '-s',
                 'libgazebo_ros_factory.so', '-s',
                 'libgazebo_ros_init.so'],
            output='screen'),

        # Robot state publisher
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            parameters=[{
                'robot_description': open(
                    os.path.join(get_package_share_directory(pkg_name),
                                 'urdf', 'robot.urdf.xacro')).read()
            }],
            output='screen'),

        # Spawn robot
        Node(
            package='gazebo_ros',
            executable='spawn_entity.py',
            arguments=['-entity', 'PKGNAME', '-topic', 'robot_description'],
            output='screen'),

        # Rviz2
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', os.path.join(
                get_package_share_directory(pkg_name), 'config', 'default.rviz')],
            output='screen'),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/sim.launch.py"

# ── RViz config ───────────────────────────────────────────
cat > "$PKG_NAME/config/default.rviz" <<'RVIZEOF'
Panels:
  - Class: rviz_common/Displays
    Help visible: false
    Views:
      Current:
        Class: rviz_default_viewpoints/Orbit
        Distance: 2.0
        Target Frame: base_link
        Value: Orbit (rviz)
    Value: true
RobotModel:
  Alpha: 1.0
  Description Source: Topic
  Description Topic:
    Value: /robot_description
  Value: true
TF:
  Value: true
LaserScan:
  Color: 255; 0; 0
  Topic:
    Value: /scan
  Value: true
RViz Default Tools:
  - Class: rviz_default_interactions/Teleop
    Topic:
      Value: /cmd_vel
RVIZEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/config/default.rviz"

# ════════════════════════════════════════════════════════════
# 机械臂仿真（Gazebo + MoveIt2）
# ════════════════════════════════════════════════════════════
elif [[ "$SIM_TYPE" == "manipulator" ]]; then

cat > "$PKG_NAME/urdf/robot.urdf.xacro" <<'XACROEOF'
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro"
       name="PKGNAME">

  <!-- 6轴机械臂 URDF（含 Gazebo 插件） -->
  <xacro:property name="PI" value="3.14159265358979"/>

  <!-- Joint 限位 -->
  <xacro:property name="j1_limit" value="${PI*170/180}"/>
  <xacro:property name="j2_limit" value="${PI*90/180}"/>
  <xacro:property name="j3_limit" value="${PI*120/180}"/>

  <gazebo>
    <plugin name="gazebo_ros_control" filename="libgazebo_ros_control.so">
      <robotNamespace>/PKGNAME</robotNamespace>
    </plugin>
  </gazebo>

  <!-- Base -->
  <link name="base_link">
    <inertial><mass value="5.0"/><origin xyz="0 0 0" rpy="0 0 0"/></inertial>
    <visual><geometry><box size="0.2 0.2 0.1"/></geometry><material name="grey"/></visual>
    <collision><geometry><box size="0.2 0.2 0.1"/></collision>
  </link>

  <link name="link1">
    <inertial><mass value="2.0"/><origin xyz="0 0 0.05" rpy="0 0 0"/></inertial>
    <visual><geometry><cylinder radius="0.05" length="0.1"/></geometry><material name="grey"/></visual>
    <collision><geometry><cylinder radius="0.05" length="0.1"/></collision>
  </link>
  <joint name="joint1" type="revolute">
    <parent link="base_link"/><child link="link1"/>
    <origin xyz="0 0 0.05" rpy="0 0 0"/>
    <axis xyz="0 0 1"/>
    <limit lower="-${j1_limit}" upper="${j1_limit}" effort="100" velocity="1.0"/>
  </joint>

  <link name="link2">
    <inertial><mass value="1.5"/><origin xyz="0 0 0.1" rpy="0 0 0"/></inertial>
    <visual><geometry><cylinder radius="0.04" length="0.2"/></geometry><material name="grey"/></visual>
    <collision><geometry><cylinder radius="0.04" length="0.2"/></collision>
  </link>
  <joint name="joint2" type="revolute">
    <parent link="link1"/><child link="link2"/>
    <origin xyz="0 0 0.1" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="-${j2_limit}" upper="${j2_limit}" effort="100" velocity="1.0"/>
  </joint>

  <link name="link3">
    <inertial><mass value="1.0"/><origin xyz="0 0 0.1" rpy="0 0 0"/></inertial>
    <visual><geometry><cylinder radius="0.035" length="0.2"/></geometry><material name="grey"/></visual>
    <collision><geometry><cylinder radius="0.035" length="0.2"/></collision>
  </link>
  <joint name="joint3" type="revolute">
    <parent link="link2"/><child link="link3"/>
    <origin xyz="0 0 0.2" rpy="0 0 0"/>
    <axis xyz="0 1 0"/>
    <limit lower="-${j3_limit}" upper="${j3_limit}" effort="100" velocity="1.0"/>
  </joint>

  <link name="tool0">
    <inertial><mass value="0.1"/><origin xyz="0 0 0" rpy="0 0 0"/></inertial>
    <visual><geometry><box size="0.02 0.02 0.1"/></geometry><material name="black"/></visual>
    <collision><geometry><box size="0.02 0.02 0.1"/></collision>
  </link>
  <joint name="tool_joint" type="fixed">
    <parent link="link3"/><child link="tool0"/>
    <origin xyz="0 0 0.2" rpy="0 0 0"/>
  </joint>

  <gazebo reference="base_link"><material>Gazebo/Grey</material></gazebo>
  <gazebo reference="link1"><material>Gazebo/Orange</material></gazebo>
  <gazebo reference="link2"><material>Gazebo/Orange</material></gazebo>
  <gazebo reference="link3"><material>Gazebo/Orange</material></gazebo>

</robot>
XACROEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/urdf/robot.urdf.xacro"

cat > "$PKG_NAME/launch/sim.launch.py" <<'LAUNCHEOF'
"""Gazebo + MoveIt2 manipulation launch"""
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import ExecuteProcess
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    pkg_name = 'PKGNAME'
    return LaunchDescription([
        ExecuteProcess(
            cmd=['gazebo', '--verbose', '-s',
                 'libgazebo_ros_factory.so', '-s',
                 'libgazebo_ros_init.so'],
            output='screen'),
        Node(package='robot_state_publisher',
             executable='robot_state_publisher',
             parameters=[{'robot_description': open(
                 os.path.join(get_package_share_directory(pkg_name),
                              'urdf', 'robot.urdf.xacro')).read()}]),
        Node(package='gazebo_ros', executable='spawn_entity.py',
             arguments=['-entity', 'PKGNAME', '-topic', 'robot_description']),
        # MoveIt2 would be launched separately via moveit_configs
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/sim.launch.py"

# ════════════════════════════════════════════════════════════
# Ackermann 仿真（赛车/小车）
# ════════════════════════════════════════════════════════════
elif [[ "$SIM_TYPE" == "ackermann" ]]; then

cat > "$PKG_NAME/urdf/robot.urdf.xacro" <<'XACROEOF'
<?xml version="1.0"?>
<robot xmlns:xacro="http://www.ros.org/wiki/xacro" name="PKGNAME">

  <xacro:property name="wheel_radius" value="0.1"/>
  <xacro:property name="wheelbase" value="1.2"/>
  <xacro:property name="front_track" value="0.8"/>

  <gazebo reference="base_link">
    <material>Gazebo/Red</material>
  </gazebo>

  <!-- Ackermann plugin (Gazebo ackermann plugin via ROS2) -->
  <gazebo>
    <plugin name="gazebo_ros_ackermann_drive" filename="libgazebo_ros_ackermann_drive.so">
      <ros>
        <namespace>/PKGNAME</namespace>
        <remapping>cmd_vel:=cmd_vel</remapping>
        <remapping>odom:=odom</remapping>
      </ros>
      <update_rate>50</update_rate>
      <wheelbase>${wheelbase}</wheelbase>
      <front_track>${front_track}</front_track>
      <wheel_radius>${wheel_radius}</wheel_radius>
      <max_steer>0.5</max_steer>
      <max_speed>5.0</max_speed>
      <publish_odom>true</publish_odom>
      <publish_odom_tf>true</publish_odom_tf>
      <publish_wheel_tf>true</publish_wheel_tf>
    </plugin>
  </gazebo>

  <link name="base_link">
    <inertial><mass value="50.0"/><origin xyz="0 0 0.3" rpy="0 0 0"/></inertial>
    <visual><geometry><box size="1.5 0.8 0.5"/></geometry><material name="red"/></visual>
    <collision><geometry><box size="1.5 0.8 0.5"/></collision>
  </link>

  <!-- 4 wheels: front-left, front-right, rear-left, rear-right -->
  <xacro:macro name="ackermann_wheel" params="prefix x y">
    <link name="${prefix}_wheel">
      <inertial><mass value="5.0"/><origin xyz="0 0 0" rpy="${PI/2} 0 0"/></inertial>
      <visual><origin xyz="0 0 0" rpy="${PI/2} 0 0"/><geometry><cylinder radius="${wheel_radius}" length="0.05"/></geometry><material name="black"/></visual>
      <collision><origin xyz="0 0 0" rpy="${PI/2} 0 0"/><geometry><cylinder radius="${wheel_radius}" length="0.05"/></collision>
    </link>
    <joint name="${prefix}_wheel_joint" type="continuous">
      <parent link="base_link"/><child link="${prefix}_wheel"/>
      <origin xyz="${x} ${y} ${-wheel_radius/2}" rpy="0 0 0"/>
      <axis xyz="0 1 0"/>
    </joint>
  </xacro:macro>

  <xacro:ackermann_wheel prefix="fl" x="${wheelbase/2}"  y="${front_track/2}"/>
  <xacro:ackermann_wheel prefix="fr" x="${wheelbase/2}"  y="${-front_track/2}"/>
  <xacro:ackermann_wheel prefix="rl" x="${-wheelbase/2}" y="${front_track/2}"/>
  <xacro:ackermann_wheel prefix="rr" x="${-wheelbase/2}" y="${-front_track/2}"/>

</robot>
XACROEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/urdf/robot.urdf.xacro"

cat > "$PKG_NAME/launch/sim.launch.py" <<'LAUNCHEOF'
"""Gazebo Ackermann vehicle launch"""
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import ExecuteProcess
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    pkg_name = 'PKGNAME'
    return LaunchDescription([
        ExecuteProcess(cmd=['gazebo', '--verbose', '-s',
                            'libgazebo_ros_factory.so', '-s',
                            'libgazebo_ros_init.so'],
                       output='screen'),
        Node(package='robot_state_publisher',
             executable='robot_state_publisher',
             parameters=[{'robot_description': open(
                 os.path.join(get_package_share_directory(pkg_name),
                              'urdf', 'robot.urdf.xacro')).read()}]),
        Node(package='gazebo_ros', executable='spawn_entity.py',
             arguments=['-entity', 'PKGNAME', '-topic', 'robot_description']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/sim.launch.py"

fi

# ── Install setup ─────────────────────────────────────────
cat > "$PKG_NAME/setup.py" <<'SETUPEOF'
from setuptools import setup
setup(
    name='PKGNAME',
    version='0.1.0',
    packages=[],
    data_files=[
        ('share/PKGNAME', ['urdf/robot.urdf.xacro']),
        ('share/PKGNAME/worlds', ['worlds/empty.world']),
        ('share/PKGNAME/launch', ['launch/sim.launch.py']),
        ('share/PKGNAME/config', ['config/default.rviz']),
    ],
)
SETUPEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/setup.py"

# ── Install hooks ─────────────────────────────────────────
mkdir -p "$PKG_NAME/ament_package"
cat > "$PKG_NAME/ament_package/${PKG_NAME}.sh" <<'HOOKEOF'
# environment hook for PKGNAME
ament_package_at_prefix_prepend_nonhierarchical "PKGNAME"
HOOKEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/ament_package/${PKG_NAME}.sh"

echo ""
echo "Generated: $PKG_NAME/"
echo "  urdf/robot.urdf.xacro"
echo "  worlds/empty.world"
echo "  launch/sim.launch.py"
echo "  config/default.rviz"
echo "  setup.py"
echo ""
echo "Simulation type: $SIM_TYPE"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME && rosdep install --from-paths . --ignore-src -r -y"
echo "  2. colcon build --packages-select $PKG_NAME"
echo "  3. source install/setup.bash"
echo "  4. ros2 launch $PKG_NAME sim.launch.py"
echo ""
echo "Note: Gazebo must be installed separately:"
echo "  sudo apt install gazebo"
