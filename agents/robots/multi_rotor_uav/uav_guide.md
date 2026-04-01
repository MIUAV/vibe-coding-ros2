# 多旋翼无人机 (Multi-rotor UAV) VibeCoding 指南

> 专注于多旋翼无人机的感知、定位、导航和技能规划开发

---

## 1. 多旋翼无人机概述

### 1.1 机型分类

```
┌─────────────────────────────────────────────────────────────────┐
│                      多旋翼无人机类型                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [四旋翼]                  [六旋翼]                  [八旋翼]    │
│                                                                 │
│        ◇                        ◇                              │
│       /│\                      /││\                             │
│      / │ \                    / │ │ \                           │
│     ◇──┼──◇                  ◇──┼─┼──◇                          │
│      \ │ /                    \ │ │ /                           │
│       \│/                      \│ │/                           │
│        ◇                        ◇                              │
│                                                                 │
│   最常见构型                 更大负载               更高冗余     │
│   负载: 0.5-2kg            负载: 2-5kg           负载: 5-10kg  │
│                                                                 │
│   [VTOL 垂直起降]              [共轴双旋翼]                      │
│                                                                 │
│       ┌──────┐                   ╱╲                              │
│       │  │   │                  ╱  ╲                             │
│       │  ◇   │                 ╱ ◇  ╲                            │
│       │  │   │                ╱    ╲                           │
│       └──────┘               ╱______╲                          │
│                                                                 │
│   固定翼+旋翼               双层旋翼折叠                        │
│   适合长航程               高负载                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 系统架构

```yaml
uav_system_architecture:
  # 飞行控制器 (FCU)
  fcu:
    processor: STM32 / ARM Cortex-M
    sensors:
      - gyroscope: 6-axis IMU
      - accelerometer
      - barometer
      - magnetometer (可选)
    outputs:
      - motor PWM (4-8通道)
      - gimbal control
      - LED/buzzer
      
  # 机载计算机 ( companion computer)
  companion:
    processor: Raspberry Pi 4 / Jetson NX / Orin
    os: Ubuntu 20.04 + ROS2
    connection: Serial / CAN / Ethernet
    functions:
      - 高级感知
      - 路径规划
      - 状态监控
      
  # 通信链路
  communication:
    - type: mavlink
      protocol: ROS2 / direct
    - telemetry: 915MHz / 2.4GHz
    - video_stream: 5.8GHz / WiFi
```

### 1.3 ROS2 接口

```yaml
uav_ros2_interfaces:
  # MAVROS (MAVLink ↔ ROS2)
  mavros:
    topics:
      - /mavros/state (ConnectionState)
      - /mavros/setpoint_raw (VehicleCommand)
      - /mavros/local_position/pose (PoseStamped)
      - /mavros/global_position/global (NavSatFix)
      - /mavros/imu/data (Imu)
      - /mavros/battery/status (BatteryState)
      
  # 自主飞行接口
  offboard:
    - /setpoint_position/local (PoseStamped)
    - /setpoint_velocity/velocity (TwistStamped)
    - /setpoint_attitude/attitude (AttitudeTarget)
    - /trajectory (Trajectory)
      
  # 视觉里程计
  visual_odometry:
    - /camera/odometry/sample (Odometry)
    - /vio/pose (PoseWithCovarianceStamped)
```

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
uav_sensors:
  # 视觉感知
  cameras:
    - name: forward_stereo
      type: stereo camera
      topics: [/stereo/left/image, /stereo/right/image]
      baseline: 0.12m
      purpose: 深度感知、障碍检测
      
    - name: downward_camera
      type: single / stereo
      topics: [/camera/down/image, /camera/down/camera_info]
      purpose: 视觉里程计、地标检测
      
    - name: front_fisheye
      type: fisheye 150°+
      topic: /camera/front/fisheye/image
      purpose: 全向障碍检测
      
    - name: thermal_camera
      type: FLIR / Seek Thermal
      topic: /camera/thermal/image
      purpose: 人员检测、搜救
      
  # 深度感知
  depth_sensors:
    - name: front_depth
      type: RealSense D435i / L515
      topics: [/depth/image, /depth/points]
      range: 0.3-10m
      
    - name: tracking_camera
      type: RealSense T265
      topics: [/odom/sample]
      purpose: 视觉里程计
      
  # 激光雷达
  lidars:
    - name: lightweight_lidar
      model: Livox MID-40 / Aero
      topic: /lidar/points
      range: 90m (MID-40)
      weight: ~200g
      purpose: 3D 避障
      
    - name: high_altitude_lidar
      model: Velodyne VLP-32
      topic: /lidar/top/points
      range: 100m+
      purpose: 地形测绘
      
  # 超声波
  ultrasonics:
    - name: landing_sensor
      type: HC-SR04 / US-100
      topic: /ultrasonic/distance
      range: 0.02-4m
      purpose: 降落检测、定高
      
  # GNSS
  gnss:
    - name: primary_gnss
      type: u-blox F9P (RTK)
      topics: [/gps/fix, /gps/rtk/fix]
      accuracy: <2cm (RTK)
      purpose: 全局定位
      
    - name: rtk_base
      type: u-blox F9P / Reach M+
      purpose: RTK 基准站
```

### 2.2 感知技能

#### 2.2.1 障碍物检测与避障

```yaml
name: obstacle_avoidance_skill
description: 3D 障碍物检测与避障
input:
  - /lidar/points (PointCloud2)
  - /camera/*/image
  - /mavros/local_position/pose
  
output:
  - /obstacles/detected[]    # Obstacle3D[]
  - /avoidance_vector        # Vector3
  - /flight_mode_change      # to auto mode
  
detection:
  methods:
    - lidar_based: voxel_grid + clustering
    - vision_based: depth_image + semantic
    - sensor_fusion: probabilistic
    
obstacle_types:
  - building
  - tree
  - power_line
  - other_aircraft
  - bird
  
avoidance_strategies:
  - passive: slow_down + wait
  - active: reroute
  - emergency: immediate_avoidance
  
reaction_time:
  detection: < 100ms
  decision: < 50ms
  execution: < 100ms
```

#### 2.2.2 视觉里程计

```yaml
name: visual_odometry_skill
description: 视觉里程计定位
input:
  - /stereo/left/image
  - /stereo/right/image
  - /camera/odometry/sample
  
output:
  - /vio/pose (PoseWithCovarianceStamped)
  - /vio/twist (TwistWithCovarianceStamped)
  - /tf (map → base_link)
  
algorithms:
  - stereo_matching: ELAS / SGBM
  - optical_flow: Lucas-Kanade
  - feature_tracking: ORB / AKAZE
  -vio: VINS-Mono / OKVIS / OpenVINS
    
accuracy:
  drift: < 1% of distance
  position_accuracy: < 0.5m over 100m
  
environmental_limits:
  min_texture: required
  max_speed: 15 m/s
  illumination: > 100 lux
```

#### 2.2.3 目标跟踪

```yaml
name: target_tracking_skill
description: 动态目标跟踪
input:
  - /camera/front/image
  - /depth/points
  - /mavros/local_position/pose
  
output:
  - /target/position_3d    # 目标3D位置
  - /tracking/status
  - /uav/velocity_command
  
tracking:
  method:
    - detection: yolov8 + sort
    - depth_association: euclidean_distance
    - prediction: kalman_filter
    
target_types:
  - person
  - vehicle
  - boat
  - custom
  
behavior:
  - orbit: maintain distance + orbit
  - follow: chase with offset
  - observe: stationary + track
  - surveillance: pattern + track
```

#### 2.2.4 地形跟随

```yaml
name: terrain_following_skill
description: 地形跟随飞行
input:
  - /lidar/points (downward)
  - /terrain_map (optional)
  - /gps/altitude
  
output:
  - /desired/altitude
  - /height_above_ground
  
params:
  terrain_clearance: {type: float, default: 30.0}  # m
  max_gradient: {type: float, default: 15.0}       # degrees
  lookahead_distance: {type: float, default: 20.0} # m
```

---

## 3. 定位 (Localization) 特性

### 3.1 定位方案

```yaml
uav_localization:
  # GNSS 定位
  gnss:
    - single_point: 2-5m accuracy
    - DGPS: 1m accuracy
    - RTK: 2cm accuracy
    topic: /gps/fix, /gps/rtk/fix
    
  # 视觉里程计
  visual_odometry:
    - methods: stereo_vio / mono_vio / imu_vio
    - packages: rtabmap_ros / okvis / VINS-Fusion
    - topic: /odom
    
  # 激光里程计
  lidar_odometry:
    - methods: LOAM / A-LOAM / LIO-SAM
    - topic: /lidar/odom
    
  # 传感器融合
  sensor_fusion:
    package: robot_localization / ethz_ekf
    inputs: [gps, vio, barometer, imu]
    output: /local_position/filtered
    
  # UWB 定位
  uwb:
    - topic: /uwb/range
    - accuracy: 0.3m
    - anchor_positions: known
    
  # 室内定位
  indoor_localization:
    - method: aruco_markers
    - method: april_tags
    - method: lighthouse (Vive trackers)
```

### 3.2 定位技能

#### 3.2.1 GNSS 定位

```yaml
name: gnss_localization_skill
description: GNSS 全球定位
input:
  - /gps/fix (NavSatFix)
  - /gps/rtk/fix (NavSatFix with covariance)
  
output:
  - /local_position/global (PoseStamped)  # ECEF → ENU
  - /local_position/pose (ENU frame)
  - /gps/status
  
params:
  datum: auto / manual (lat, lon, alt)
  use_rtk: true if available
  altitude_source: ellipsoid / geoid
```

#### 3.2.2 视觉惯性里程计

```yaml
name: vio_localization_skill
description: 视觉惯性里程计
input:
  - /camera/odometry/sample
  - /imu/data
  
output:
  - /vio/pose
  - /vio/twist
  - /map → /base_link tf
  
params:
  vio_type: {stereo, mono, rgb-d}
  loop_closure: true
  map_storage: /map_db.db
  
accuracy:
  position_drift: < 0.5% distance
  heading_drift: < 1° per 50m
```

#### 3.2.3 融合定位

```yaml
name: fused_localization_skill
description: 多传感器融合定位
input:
  - /gps/local_position
  - /vio/pose
  - /barometer/altitude
  - /mavros/imu/data
  
output:
  - /local_position/filtered
  - /tf (map → base_link)
  
fusion:
  method: extended_kalman_filter
  covariance_propagation: true
  failure_detection: true
  
mode_transition:
  outdoor_gnss: use_gps + vio_correction
  indoor_vio: use_vio + baro_correction
  degraded: use_last_known + warn
```

---

## 4. 导航 (Navigation) 特性

### 4.1 导航配置

```yaml
uav_navigation:
  # 飞行模式
  flight_modes:
    - manual: 遥控器直接控制
    - stabilized: 自稳模式
    - altitude_hold: 高度保持
    - position: 位置控制 (GPS)
    - offboard: 机载计算机控制
      
  # 路径规划
  path_planning:
    global_planner:
      - method: grid_based_astar
      - method: RRTstar (3D)
      - method: geometric planning (for simple paths)
        
    local_planner:
      - method: elastic_band
      - method: EGO-planner
      - method: fast-planner
        
  # 3D 避障
  3d_obstacle_avoidance:
    - voxel_grid_mapping
    - dynamic_obstacle_tracking
    - real-time replanning
    
  # 着陆
  landing:
    - precision_landing: aruco / april_tag
    - terrain_landing: lidar_altitude
    - ship_landing: motion_capture
```

### 4.2 导航技能

#### 4.2.1 Offboard 控制

```yaml
name: offboard_control_skill
description: 机载计算机轨迹控制
type: autonomous_flight

interface:
  inputs:
    - topic: /setpoint_position/local
      type: PoseStamped
    - topic: /mavros/state
      type: MAVState
  outputs:
    - topic: /mavros/setpoint_raw
    - topic: /trajectory
      
parameters:
  # 必须先发送 setpoint 再切换 offboard
  setpoint_rate: 10 Hz (minimum)
  timeout: 1.0  # s, 超过此时间无命令则退出 offboard
  
preconditions:
  - mavros connected
  - local_position received
  - home position set
  - EKF healthy
```

#### 4.2.2 3D 路径规划

```yaml
name: path_planning_3d_skill
description: 3D 空间路径规划
input:
  - /map/voxel_grid
  - /start_pose
  - /goal_pose
  
output:
  - /path (nav_msgs/Path)    # 3D waypoints
  - /trajectory (trajectory_msgs/JointTrajectory)
  
params:
  resolution: 0.5     # m
  vehicle_radius: 0.3 # m (safety margin)
  max_velocity: 10   # m/s
  max_acceleration: 5 # m/s²
    
planners:
  - global: RRTstar_3D / BITstar
  - local: EGO-planner / Fast-Planner
    
optimization:
  - smoothing: spline / polynomial
  - feasibility: dynamics constraints
```

#### 4.2.3 自主降落

```yaml
name: precision_landing_skill
description: 精确着陆 (视觉引导)
input:
  - /camera/down/image
  - /aruco/detections
  - /landing_target/pose
  
output:
  - /setpoint_position/local
  - /landing/status
  
params:
  search_altitude: {type: float, default: 10.0}  # m
  final_descent_speed: {type: float, default: 0.3} # m/s
  max_offset: {type: float, default: 1.0}         # m
  
phases:
  - 搜索: spiral descent until marker found
  - 对齐: hover + adjust position
  - 下降: controlled descent
  - 触地: detect contact → disarm
  
marker_types:
  - aruco: standard ARTag
  - april: AprilTag
  - motion_capture: Vicon / OptiTrack
```

#### 4.2.4 区域覆盖

```yaml
name: area_coverage_skill
description: 区域覆盖飞行
input:
  - /area/polygon (PolygonStamped)
  - /survey/parameters
  
output:
  - /path (nav_msgs/Path)
  - /setpoint_position/local
  
coverage_patterns:
  - lawn_mower: parallel lines
  - spiral: inward/outward spiral
  - adaptive: based on terrain
  
params:
  altitude: {type: float, default: 50.0}   # m
  overlap: {type: float, default: 0.2}     # 20%
  speed: {type: float, default: 5.0}        # m/s
  turn_type: {type: string, default: splined}
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 技能分类

```yaml
uav_skills:
  # 飞行技能
  flight:
    - takeoff_skill
    - landing_skill
    - hover_skill
    - return_to_home_skill
    
  # 导航技能
  navigation:
    - waypoint_navigation_skill
    - path_following_skill
    - terrain_following_skill
    - exploration_skill
    
  # 操作技能
  manipulation:
    - payload_delivery_skill
    - winch_operation_skill
    - camera_pointing_skill
    
  # 检测技能
    - surveillance_skill
    - inspection_skill
    - search_and_rescue_skill
    - target_tracking_skill
    
  # 编队技能
  formation:
    - leader_follower_skill
    - formation_keeping_skill
    - collision_avoidance_skill
```

### 5.2 技能描述

#### 5.2.1 自主起降

```yaml
name: takeoff_landing_skill
description: 自主起飞/降落技能
type: flight

interface:
  inputs:
    - topic: /mission/command
      type: std_msgs/String  # "takeoff" / "land"
    - topic: /gps/fix
  outputs:
    - topic: /mavros/cmd/command
    - topic: /flight/status
      
parameters:
  takeoff_altitude: {type: float, default: 3.0}  # m
  takeoff_speed: {type: float, default: 1.0}     # m/s
  landing_speed: {type: float, default: 0.5}      # m/s
  
preconditions:
  - gps_locked (>6 satellites)
  - home_position_set
  - imu_ calibrated
  - safe_to_arm: true
  
postconditions:
  - airborne: at_designated_altitude
  - landed: on_ground + motors_disarmed
  - aborted: returned_to_home
```

#### 5.2.2 航点飞行

```yaml
name: waypoint_navigation_skill
description: 航点自主导航
type: navigation

interface:
  inputs:
    - topic: /waypoints (Waypoint[])
      type: mission_msgs/WaypointList
    - topic: /cancel (optional)
  outputs:
    - topic: /current_waypoint
    - topic: /mission/status
      
parameters:
  acceptance_radius: {type: float, default: 3.0}  # m
  waypoint_timeout: {type: float, default: 120.0} # s
  yaw_mode: {type: string, default: "next"}       # next / forward / route
  
mission_types:
  - survey: lawn_mower pattern
  - inspection: waypoints +停留
  - delivery: waypoints +动作
  - tour: sequential visit
      
error_handling:
  - waypoint_timeout: skip_to_next / abort
  - gps_loss: hold_position / return_home
  - low_battery: abort_mission
```

#### 5.2.3 编队飞行

```yaml
name: formation_flight_skill
description: 多机编队飞行
type: formation

interface:
  inputs:
    - topic: /leader/pose
    - topic: /formation/target_offsets
  outputs:
    - topic: /setpoint_position/local
    - topic: /formation/status
      
params:
  formation_type: {type: string, default: "grid"}  # grid / line / v-shape
  spacing: {type: float, default: 3.0}              # m between vehicles
  tolerance: {type: float, default: 0.5}             # m position tolerance
    
control:
  leader_follower: true
  collision_avoidance: active (within 5m)
  communication: mavlink / dedicated
```

#### 5.2.4 目标跟踪

```yaml
name: uav_target_tracking_skill
description: 无人机目标跟踪
type: tracking

interface:
  inputs:
    - topic: /target/position_3d
    - topic: /cancel
  outputs:
    - topic: /setpoint_position/local
    - topic: /tracking/status
      
params:
  track_distance: {type: float, default: 10.0}   # m from target
  track_altitude: {type: float, default: 30.0}   # m AGL
  max_speed: {type: float, default: 15.0}         # m/s
    
behaviors:
  orbit: circle around target at fixed radius
  stare: keep camera pointed at target
  handoff: switch tracking between targets
    
error_handling:
  - target_lost: orbit_last_known_position
  - target_hidden: altitude_adjust
  - collision_risk: break_away
```

### 5.3 技能编排

#### 5.3.1 巡检编排

```python
class InspectionMissionOrchestrator:
    async def execute(self, inspection_area, target_points):
        """基础设施巡检任务"""
        # 1. 起飞到巡检高度
        await self.execute_skill("takeoff_skill", altitude=50.0)
        
        # 2. 飞到第一个检查点
        await self.execute_skill("waypoint_navigation_skill",
                               waypoints=[target_points[0]])
        
        # 3. 执行检查动作
        for target in target_points:
            # 靠近目标
            await self.execute_skill("approach_skill",
                                   target=target,
                                   distance=10.0)
            
            # 环绕目标检查
            await self.execute_skill("orbit_inspection_skill",
                                   target=target,
                                   radius=5.0)
            
            # 采集数据
            await self.execute_skill("record_data_skill",
                                   sensor="camera",
                                   duration=30)
            
            # 移动到下一目标
            await self.execute_skill("waypoint_navigation_skill",
                                   waypoints=[target])
        
        # 4. 返回起飞点
        await self.execute_skill("return_to_home_skill")
        
        # 5. 降落
        await self.execute_skill("precision_landing_skill")
```

#### 5.3.2 搜索救援编排

```python
class SearchAndRescueOrchestrator:
    async def execute(self, search_area):
        """搜索救援任务"""
        # 1. 起飞并进入搜索模式
        await self.execute_skill("takeoff_skill", altitude=100.0)
        
        # 2. 区域覆盖搜索
        while not self.target_found:
            # 扫描区域
            coverage_path = self.plan_coverage(search_area)
            await self.execute_skill("area_coverage_skill",
                                   path=coverage_path)
            
            # 检测目标 (人、热源、颜色)
            detections = await self.execute_skill("object_detection_skill")
            
            if detections.person_found:
                # 锁定目标
                await self.execute_skill("target_tracking_skill",
                                       target=detections[0])
                
                # 盘旋等待救援队
                await self.execute_skill("orbit_skill",
                                       target=detections[0].position,
                                       duration=300)  # 5分钟
                
                # 报告位置
                await self.execute_skill("report_position_skill",
                                       position=detections[0].position)
        
        # 3. 搜索完成，返回基地
        await self.execute_skill("return_to_home_skill")
        await self.execute_skill("landing_skill")
```

---

## 6. 仿真与验证

### 6.1 仿真环境

```yaml
simulation:
  gazebo:
    drone_models:
      - iris (默认四旋翼)
      - typhoon_h480 (六旋翼)
      - plane (VTOL)
    sensor_plugins:
      - gazebo_ros_laser
      - gazebo_ros_camera
      - gazebo_ros_imu
      - gazebo_ros_gps
    physics:
      - wind: enabled
      - contact: enabled
      
  flightgoggles:
    # 第一人称视角仿真
    tracksuit_marker tracking
    photo-realistic rendering
    
 airsim:
    # Microsoft AirSim
    vehicles: drone + car
    sensors: camera + lidar + imu
    weather: dynamic
```

### 6.2 验证测试

```yaml
tests:
  flight_tests:
    - hover_stability: < 0.5m drift over 10min
    - waypoint_accuracy: < 3m CEP
    - altitude_hold: < 1m variation
    
  safety_tests:
    - failsafe_rtl: triggers_correctly
    - geofence: respects_boundaries
    - low_battery_rtl: < 20% triggers
    - connection_loss: returns_home
    
  perception_tests:
    - obstacle_detection: >95% @ 10m
    - tracking_stability: <0.5m RMS error
    - vio_drift: <1% distance
    
  endurance_tests:
    - flight_time: meets_spec
    - battery_management: correct estimation
```

---

## 7. 硬件配置参考

### 7.1 消费级四旋翼

```yaml
platform: DJI Mavic 3 / Autel EVO II
weight: < 1kg
payload: camera only
flight_time: 30-40 min
max_speed: 15-20 m/s
sensors:
  - 4K camera (gimbal)
  - obstacle sensors (forward/back/down)
  - GPS + GLONASS
  - IMU + barometer
interface: OSDK / MAVLink (via DJI OSDK)
```

### 7.2 工业巡检四旋翼

```yaml
platform: DJI M300 RTK / Freefly Astro
weight: 4-6kg
payload: 1-2kg
flight_time: 30-55 min
max_speed: 20 m/s
sensors:
  - 4K zoom camera
  - thermal camera
  - LIDAR (optional)
  - RTK GPS
  - ADS-B receiver
interface: MAVLink / ROS2 via OSDK
```

### 7.3 定制开发平台

```yaml
platform: Custom 650mm quadrotor
frame: carbon fiber
weight: 3-4kg (空机)
payload: 2-3kg
flight_time: 20-30 min
sensors:
  - RealSense D435i (VIO + depth)
  - Livox MID-70 (360° lidar)
  - Here3 RTK GPS
  - Holybro Pixhawk 6
interface: ROS2 + PX4 + MAVROS
```

---

## 8. 安全与法规

### 8.1 安全机制

```yaml
safety_systems:
  # 硬件安全
  hardware:
    - propeller guards
    - motor failure detection
    - battery monitoring (voltage, current, temp)
    
  # 软件安全
  software:
    - geofencing: no-fly zones
    - altitude_limit: max operating height
    - failsafe_modes: RTL / Land / Hover
    - obstacle_avoidance: active when enabled
    
  # 应急程序
  emergency:
    - loss_of_gps: switch to_attitude_mode
    - loss_of_connection: timeout → RTL
    - low_battery: <20% → RTL
    - critical_failure: immediate_land
```

### 8.2 法规遵循

```yaml
regulations:
  # 适航
  airworthiness:
    - registration: required
    - type_certification: for commercial ops
    - maintenance: logbook
    
  # 运行限制
  operational:
    - max_altitude: 120m (most countries)
    - visual_line_of_sight: VLOS / BVLOS
    - night_flying: permit required
    - over_people: restrictions
    
  # 隐私
  privacy:
    - camera_usage_notification
    - data_storage_compliance
    - no_surveillance_without_permit
```

---

*本文档定义多旋翼无人机的专有感知、定位、导航和技能规划原则*
