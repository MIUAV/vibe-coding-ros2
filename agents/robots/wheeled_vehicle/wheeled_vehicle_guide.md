# 轮式底盘 (Wheeled Vehicle) VibeCoding 指南

> 专注于轮式车辆的感知、定位、导航和技能规划开发

---

## 1. 轮式车辆概述

### 1.1 底盘类型

```
┌─────────────────────────────────────────────────────────────────┐
│                      轮式底盘类型                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [两轮差速]              [四轮差速]              [阿克曼]        │
│    ┌───┐                   ┌───┬───┐              ┌───┬───┐     │
│    │ ◯ │                   │ ◯ │ ◯ │              │ ◯ │ ◯ │     │
│    └───┘                   └───┴───┘              └───┼───┘     │
│      │                         │                      │         │
│    ┌───┐                     ┌───┐                  ◇         │
│    │ ◯ │                     │ ◯ │              (前轮转向)      │
│    └───┘                     └───┘                              │
│                                                                 │
│   [麦克纳姆轮]              [全向轮]            [履带式]         │
│    ┌───┬───┐                ┌───┬───┐            ┌─────────┐    │
│    │ ◆ │ ◆ │                │ ◯ │ ◯ │            │ ═══╬═══│    │
│    ├───┼───┤                ├───┼───┤            │ ═══╬═══│    │
│    │ ◆ │ ◆ │                │ ◯ │ ◯ │            └─────────┘    │
│    └───┴───┘                └───┴───┘                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 底盘特性对比

| 类型 | 机动性 | 负载 | 复杂度 | 适用场景 |
|------|--------|------|--------|----------|
| 两轮差速 | ★★★★ | 中 | 低 | 室内机器人 |
| 四轮差速 | ★★★ | 高 | 低 | 轮式机器人 |
| 阿克曼 | ★★ | 高 | 中 | 室外车辆 |
| 麦克纳姆轮 | ★★★★★ | 中 | 高 | 狭窄空间 |
| 全向轮 | ★★★★★ | 中 | 高 | 精密操作 |
| 履带式 | ★★★★ | 高 | 中 | 复杂地形 |

### 1.3 ROS2 驱动接口

```yaml
wheeled_vehicle_drive:
  # 差速驱动
  differential_drive:
    topic: /diff_drive/cmd_vel
    type: geometry_msgs/Twist
    params:
      wheel_separation: 0.5  # m
      wheel_radius: 0.1       # m
      
  # 阿克曼驱动
  ackermann_drive:
    topic: /ackermann_drive/cmd
    type: ackermann_msgs/AckermannDriveStamped
    
  # 麦克纳姆轮驱动
  mecanum_drive:
    topic: /mecanum_drive/cmd_vel
    type: geometry_msgs/Twist
    
  # 全向轮驱动
  omni_drive:
    topic: /omni_drive/cmd_vel
    type: geometry_msgs/Twist
```

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
wheeled_vehicle_sensors:
  # 激光雷达
  lidars:
    - name: front_lidar
      location: front
      model: SICK LMS511 / Hokuyo UST-10
      topic: /scan_front
      range: 25m / 270°
      frequency: 25-50 Hz
      
    - name: rear_lidar
      location: rear
      model: SICK LMS511
      topic: /scan_rear
      
    - name: top_lidar
      location: top
      model: Velodyne VLP-32 / Ouster OS1
      topic: /scan_top / points_top
      range: 100m / 360°
      vertical_fov: ±15°
      
  # 相机
  cameras:
    - name: front_camera
      location: front
      topics: [/camera_front/image_raw, /camera_front/camera_info]
      config: {resolution: 1920x1080, fov: 90°}
      
    - name: surround_view
      cameras: [front, rear, left, right]
      topic: /surround_view/image
      
    - name: fisheye
      location: top
      topic: /camera/top/fisheye
      
  # 超声波雷达
  ultrasonics:
    - name: us_front
      location: front
      topics: [/ultrasonic/front_0x, ...]
      range: 0.2-2m
      fov: 60°
      
  # 红外传感器
  infrared:
    - name: cliff_sensor
      location: bottom
      purpose: 楼梯/边缘检测
      
  # IMU
  imu:
    - name: primary_imu
      topic: /imu/data
      type: sensor_msgs/Imu
      model: xsens_mti / vectornav
      
  # GPS / RTK
  gnss:
    - name: gps
      topic: /gps/fix
      type: sensor_msgs/NavSatFix
      rtk: {model: u-blox ZED-F9P, accuracy: <2cm}
```

### 2.2 感知技能

#### 2.2.1 障碍物检测

```yaml
name: obstacle_detection_skill
description: 激光雷达和视觉融合障碍物检测
input:
  - /scan (LaserScan)
  - /points (PointCloud2)  # if 3D lidar
  - /camera_*/image
  
output:
  - /obstacles/detected[]   # Obstacle[]
  - /obstacles/dynamic[]    # 动态障碍物
  - /obstacles/static[]     # 静态障碍物
  
detection:
  methods:
    - lidar_based: segmentation + classification
    - vision_based: yolov8 / detectron
    - fusion: late_fusion / early_fusion
    
obstacle_types:
  - pedestrian
  - vehicle
  - cyclist
  - unknown
  
tracking:
  method: kalman_filter / sort
  max_age: 0.5  # s
  min_hits: 3
```

#### 2.2.2 车道线检测

```yaml
name: lane_detection_skill
description: 道路车道线检测
input:
  - /camera/front/image
  - /camera/front/camera_info
  
output:
  - /lane/lines          # LaneLine[]
  - /lane/center_line
  - /lane/vehicle_pose   # 车道内相对位置
  
detection:
  method:
    - traditional: hough_transform + perspective
    - deep_learning: LaneNet / UltraFastLane
    
lane_types:
  - solid_white
  - solid_yellow
  - dashed_white
  - dashed_yellow
  
camera_config:
  resolution: 1920x1080
  focal_length: 1500 (等效)
  mount_height: 1.5  # m
```

#### 2.2.3 可通行区域检测

```yaml
name: traversability_skill
description: 可通行区域分析
input:
  - /scan
  - /points
  - /terrain_class
  
output:
  - /traversability/map      # GridMap
  - /traversability/frontier # 探索前沿
  
analysis:
  - slope_estimation
  - roughness_measurement
  - step_height_detection
  - surface_type_classification
    
cost_map:
  - 0.0: 高度可通行
  - 0.5: 中等可通行
  - 1.0: 不可通行
```

#### 2.2.4 交通标志识别

```yaml
name: traffic_sign_recognition_skill
description: 交通标志识别
input:
  - /camera/front/image
  
output:
  - /traffic_sign/detected[]   # SignType + Pose
  - /traffic_sign/speed_limit
  
sign_types:
  - speed_limit: [20, 30, 50, ...]
  - stop
  - yield
  - pedestrian_crossing
  - no_entry
  
detection:
  method: yolov8 / efficientdet
  accuracy: >95% @ 10m
```

---

## 3. 定位 (Localization) 特性

### 3.1 定位方案

```yaml
wheeled_vehicle_localization:
  # 轮式里程计
  wheel_odometry:
    topic: /odom
    type: nav_msgs/Odometry
    fusion:
      - wheel_encoders
      - steering_angle
    drift: 1-5% of distance
    
  # IMU 融合
  imu_fusion:
    topic: /imu/data
    algorithms:
      - madgwick_filter
      - kalman_filter
    output: /imu/filtered
    
  # 激光雷达定位
  lidar_localization:
    method:
      - ndt_matching (Autoware)
      - ICP matching
      - loam (for 3D)
    map: /map/point_cloud
    
  # 视觉定位
  visual_localization:
    method:
      - visual_odometry
      - loop_closure (RTAB-Map)
      - landmark_based
    features: 
      - apriltags
      - natural_features
      
  # GPS/RTK 定位
  gnss_localization:
    - single_point: ~2-5m accuracy
    - DGPS: ~1m accuracy
    - RTK: <2cm accuracy
    topic: /gps/rtk/fix
    
  # 多传感器融合
  sensor_fusion:
    package: robot_localization
    ekf_nodes:
      - name: robot_localization_ekf
        inputs: [odom, imu, gps]
        output: /odom/filtered
```

### 3.2 定位技能

#### 3.2.1 里程计融合

```yaml
name: odometry_fusion_skill
description: 多传感器里程计融合
input:
  - /wheel/odom
  - /imu/data
  - /gps/fix (optional)
  
output:
  - /odom/filtered
  - /tf (odom → base_link)
  
ekf_config:
  frequency: 50 Hz
  sensors:
    wheel_odom:
      sensor: wheel_odometry
      differential: false
    imu:
      sensor: imu
      differential: false
      orientation: true
    gps:
      sensor: gps
      differential: false
```

#### 3.2.2 SLAM 定位

```yaml
name: slam_localization_skill
description: 同步定位与地图构建
input:
  - /scan
  - /points
  - /odom
  
output:
  - /map (nav_msgs/OccupancyGrid)
  - /map/point_cloud
  - /tf (map → odom)
  - /pose
  
slam_methods:
  - cartographer: 2D/3D SLAM, 实时
  - slam_toolbox: 激光SLAM, 在线修正
  - rtabmap: 视觉+激光, 闭环检测
    
params:
  resolution: 0.05    # m
  max_range: 25      # m
  transform_tolerance: 0.1
```

#### 3.2.3 高精地图定位

```yaml
name: hd_map_localization_skill
description: 高精地图匹配定位
input:
  - /scan
  - /gps/rtk/fix
  - /hd_map
  
output:
  - /localization/pose
  - /localization/accuracy
  
map_types:
  - vector_map: 车道级语义
  - point_cloud_map: 高精度点云
  - raster_map: 栅格地图
  
matching:
  method: ndt / ndt_matching
  accuracy: < 10cm (RTK辅助)
```

---

## 4. 导航 (Navigation) 特性

### 4.1 导航配置

```yaml
wheeled_vehicle_navigation:
  # Nav2 配置
  nav2:
    planner:
      - name: SmacPlannerHybrid
        type: state_lattice
        scenario: automotive
        
      - name: ThetaStar
        type: grid_based
        
    controller:
      - name: MPPIController
        type: model_predictive
        hardware: diff_drive / ackermann
        
      - name: PurePursuit
        type: trajectory_tracking
        
    behaviors:
      - lane_following
      - obstacle_avoidance
      - intersection_handling
      - parking
      
  # 路径规划
  path_planning:
    global_planner:
      - method: hybrid_astar
        resolution: 0.1
      - method: dijkstra
        
    local_planner:
      - method: dwa
      - method: teb
      - method: mpc
        
  # 避障
  obstacle_avoidance:
    - static_obstacle: costmap layers
    - dynamic_obstacle: tracking + prediction
    - emergency_stop: AEB (自动紧急刹车)
```

### 4.2 导航技能

#### 4.2.1 路径跟踪

```yaml
name: path_following_skill
description: 路径跟踪控制
input:
  - /plan (nav_msgs/Path)
  - /odom
  
output:
  - /cmd_vel (geometry_msgs/Twist)
  
controllers:
  - pure_pursuit:
      look_ahead_dist: 1.0-2.0  # m
      kp: 1.0
  - stanley:
      k_soft: 1.0
  - mpc:
      horizon: 20
      dt: 0.1
      
vehicle_params:
  wheelbase: 2.5     # m
  max_steering: 30°  # for ackermann
  max_speed: 10      # m/s
```

#### 4.2.2 自主泊车

```yaml
name: auto_parking_skill
description: 自动泊车技能
input:
  - /scan
  - /odom
  - /parking/goal
  
output:
  - /cmd_vel
  - /parking/status
  
parking_types:
  - parallel泊车:
      space_detection: laser_scan
      path_planning: hybrid_astar
  - 垂直泊车:
      space_detection: ultrasonic + camera
  - 角度泊车:
      slot_detection: vision
      
params:
  slot_length_tolerance: +0.5m
  parking_precision: ±0.1m
  max_speed: 0.5 m/s
```

#### 4.2.3 车道保持

```yaml
name: lane_keeping_skill
description: 车道保持辅助
input:
  - /lane/lines
  - /vehicle_speed
  - /plan
  
output:
  - /cmd_vel_steering
  - /lane_offset
  
control:
  method: stanley / pure_pursuit
  lane_offset_tolerance: ±0.2m
  heading_tolerance: ±5°
  
safety:
  driver_override: true
  hands_off_detection: true
```

#### 4.2.4 区域探索

```yaml
name: exploration_skill
description: 未知区域自主探索
input:
  - /scan
  - /odom
  
output:
  - /cmd_vel
  - /exploration/status
  
frontier_detection:
  method: frontier_based
  exploration_rate: 0.1  # m²/s
  
coverage:
  method: boustrophedon / spiral
  grid_resolution: 0.5m
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 技能分类

```yaml
wheeled_vehicle_skills:
  # 驾驶技能
  driving:
    - lane_following_skill
    - lane_change_skill
    - intersection_handling_skill
    - roundabout_navigation_skill
    
  # 泊车技能
  parking:
    - parallel_parking_skill
    - perpendicular_parking_skill
    - valet_parking_skill
    
  # 安全技能
  safety:
    - emergency_brake_skill
    - collision_avoidance_skill
    - pedestrian_avoidance_skill
    - narrow_passage_skill
    
  # 特殊场景
  special:
    - reverse_driving_skill
    - ramp_climbing_skill
    - garage_parking_skill
```

### 5.2 技能描述

#### 5.2.1 车道保持技能

```yaml
name: lane_following_skill
description: 车道保持与前向行驶
type: autonomous_driving

interface:
  inputs:
    - topic: /lane/lines
      type: LaneLines
    - topic: /vehicle/speed
      type: Float32
  outputs:
    - topic: /cmd_vel
      type: Twist
    - topic: /skill/status
      type: SkillStatus

parameters:
  target_speed: {type: float, default: 5.0}  # m/s
  lane_offset: {type: float, default: 0.0}   # m, offset from center
  min_clearance: {type: float, default: 0.3}  # m from lane edge
  
preconditions:
  - vehicle_calibrated
  - lane_visible
  - no_obstacle_ahead
  
postconditions:
  - lane_keeping_active
  - lane_lost
  - obstacle_detected
  
error_handling:
  - lane_lost: reduce_speed
  - obstacle: emergency_stop
  - intersection: switch_to_manual
```

#### 5.2.2 变道技能

```yaml
name: lane_change_skill
description: 自主变道
type: autonomous_driving

interface:
  inputs:
    - topic: /lane/change_request
      type: String  # "left" / "right"
    - topic: /lane/current_lines
  outputs:
    - topic: /cmd_vel
    - topic: /lane_change/status
    
parameters:
  target_lane_offset: {type: float}  # m
  change_duration: {type: float, default: 3.0}  # s
  min_gap: {type: float, default: 10.0}  # m, rear gap needed
  max_speed: {type: float, default: 5.0}
  
safety_check:
  - front_gap: > 5m
  - rear_gap: > 10m
  - adjacent_lane_clear: true
  - no_oncoming_vehicle: true
```

#### 5.2.3 紧急制动

```yaml
name: emergency_brake_skill
description: 紧急制动技能
type: safety

interface:
  inputs:
    - topic: /obstacles/detected
    - topic: /scan
  outputs:
    - topic: /cmd_vel
    - topic: /brake/command
      
parameters:
  detection_range: {type: float, default: 5.0}  # m
  ttc_threshold: {type: float, default: 2.0}     # s, time-to-collision
  
brake_profile:
  - deceleration: 8.0  # m/s² (comfortable)
  - max_deceleration: 10.0  # m/s² (emergency)
    
activation:
  - obstacle_in_path: true
  - ttc < threshold
  - driver_override: false
  
deactivation:
  - vehicle_stopped
  - obstacle_cleared
```

#### 5.2.4 自主泊车

```yaml
name: auto_parking_skill
description: 自主泊车技能
type: parking

interface:
  inputs:
    - topic: /parking/goal_pose
      type: PoseStamped
    - topic: /parking/type
      type: String  # "parallel" / "perpendicular"
  outputs:
    - topic: /cmd_vel
    - topic: /parking/status
      
parameters:
  parking_precision: {type: float, default: 0.1}  # m
  slot_length_add: {type: float, default: 1.0}     # m
  max_attempts: {type: int, default: 3}
  
parking_phases:
  - slot_detection
  - path_planning
  - trajectory_execution
  - final_adjustment
  
error_handling:
  - no_slot_found: search_adjacent
  - path_blocked: replan
  - failed_attempt: try_alternative
```

### 5.3 技能编排

#### 5.3.1 城市驾驶编排

```python
class UrbanDrivingOrchestrator:
    async def execute(self, destination):
        """城市道路驾驶任务"""
        # 1. 全局路径规划
        route = await self.execute_skill("route_planning_skill",
                                       start=self.current_pose,
                                       goal=destination)
        
        # 2. 车道保持行驶
        while not self.arrived(destination):
            # 检测车道线
            lane_state = await self.execute_skill("lane_detection_skill")
            
            # 检测障碍物
            obstacles = await self.execute_skill("obstacle_detection_skill")
            
            if obstacles.in_path:
                # 动态障碍物 - 减速或绕行
                if obstacles.can_yield:
                    await self.execute_skill("yield_skill", obstacle=obstacles[0])
                else:
                    await self.execute_skill("emergency_brake_skill")
            
            # 检测交叉口
            if self.near_intersection(route):
                await self.execute_skill("intersection_handling_skill",
                                       intersection=route.next_intersection)
            
            # 持续车道跟踪
            await self.execute_skill("lane_following_skill")
        
        # 3. 到达目的地
        await self.execute_skill("stop_skill")
```

#### 5.3.2 泊车编排

```python
class ParkingOrchestrator:
    async def execute(self, parking_spot):
        """泊车任务"""
        # 1. 减速并扫描停车位
        await self.execute_skill("reduce_speed_skill", target_speed=2.0)
        spots = await self.execute_skill("parking_slot_detection_skill")
        
        # 2. 选择最佳车位
        target_spot = self.select_best_spot(spots, parking_spot)
        
        # 3. 路径规划
        if target_spot.type == "parallel":
            path = await self.execute_skill("parallel_parking_path_skill",
                                          spot=target_spot)
        else:
            path = await self.execute_skill("perpendicular_parking_path_skill",
                                          spot=target_spot)
        
        # 4. 执行泊车
        result = await self.execute_skill("auto_parking_skill",
                                        path=path,
                                        spot=target_spot)
        
        # 5. 熄火熄灯
        await self.execute_skill("park_complete_skill")
        
        return result
```

---

## 6. 仿真与验证

### 6.1 仿真环境

```yaml
simulation:
  gazebo:
    vehicle_models:
      - racecar (差速)
      - f1tenth (赛车)
      - twister (麦克纳姆轮)
    sensor_plugins:
      - gazebo_ros_laser
      - gazebo_ros_camera
      - gazebo_ros_imu
      
  autoware:
    # Autoware 仿真
    map: sample_map
    vehicle: sample_vehicle
    
  Carla:
    # Carla 自动驾驶仿真
    town: Town01-10
    weather: dynamic
    traffic: realistic
```

### 6.2 验证测试

```yaml
tests:
  localization_tests:
    - position_accuracy: < 0.1m
    - heading_accuracy: < 1°
    - map_match_score: > 0.9
    
  navigation_tests:
    - path_following_error: < 0.5m
    - lane_keeping_offset: < 0.2m
    -停车精度: < 0.15m
    
  safety_tests:
    - AEB_trigger_time: < 0.5s
    - min_safe_distance: maintained
    - pedestrian_detection: > 95% @ 20m
```

---

## 7. 硬件配置参考

### 7.1 室内送物机器人

```yaml
robot: 室内送物机器人
chassis: 两轮差速
dimensions: 0.5 x 0.4 x 0.3m
payload: 10kg
max_speed: 1.0 m/s
sensors:
  - 2D lidar (SICK LMS111)
  - 1-2 RGB-D camera
  - ultrasonic (optional)
navigation: Nav2 + slam_toolbox
```

### 7.2 园区配送车

```yaml
robot: 园区配送车
chassis: 阿克曼
dimensions: 2.0 x 1.0 x 1.5m
payload: 200kg
max_speed: 5.0 m/s
sensors:
  - 16线激光雷达
  - 前视相机 x2
  - GPS/RTK
  - IMU
navigation: Autoware / Nav2
```

### 7.3 窄通道搬运车

```yaml
robot: 窄通道搬运车 (Kiva/Fetch类型)
chassis: 麦克纳姆轮
dimensions: 0.6 x 0.6 x 0.8m
payload: 50kg
max_speed: 2.0 m/s
sensors:
  - 2D lidar (前/后)
  - 深度相机 (前)
navigation: 轨道跟随 + 激光定位
```

---

*本文档定义轮式车辆的专有感知、定位、导航和技能规划原则*
