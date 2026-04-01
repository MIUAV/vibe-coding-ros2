# 四足机器人 (Quadruped) VibeCoding 指南

> 专注于四足机器人的感知、定位、导航和技能规划开发

---

## 1. 四足机器人概述

### 1.1 结构特点

```
            ┌─────────────────────┐
            │       Body         │ ← 主控、IMU、电池
            └─────────────────────┘
            /   |       |   \
           /    |       |    \
      ┌────┐  ┌────┐ ┌────┐  ┌────┐
      │Leg │  │Leg │ │Leg │  │Leg │
      │ FL │  │ FR │ │ BL │  │ BR │
      └────┘  └────┘ └────┘  └────┘
```

### 1.2 步态类型

| 步态 | 特点 | 速度 | 适用场景 |
|------|------|------|----------|
| Walk | 对角线顺序落地 | 慢 | 复杂地形 |
| Trot | 对角线同时落地 | 中 | 普通行走 |
| Pace | 同侧同时落地 | 中 | 平滑地面 |
| Gallop | 连续跳跃 | 快 | 奔跑 |
| Bound | 前后同时落地 | 快 | 直线冲刺 |

### 1.3 关键特性

| 特性 | 说明 | 技术挑战 |
|------|------|----------|
| 足式移动 | 全向移动能力 | 步态规划 |
| 地形适应 | 复杂地形通过 | 足端感知 |
| 负载能力 | 背负额外设备 | 重心控制 |
| 自主导航 | 未知环境探索 | SLAM+导航 |
| 多模态感知 | 视觉+触觉+IMU | 传感器融合 |

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
quadruped_sensors:
  # 视觉感知
  cameras:
    - name: forward_camera
      type: RGB or RGB-D
      location: front
      topics: [/camera/front/image, /camera/front/depth]
      purpose: 导航、目标检测
      
    - name: downward_camera
      type:鱼眼相机
      location: underside
      topics: [/camera/downward/image]
      purpose: 足端视觉、降落
      
  # 深度感知
  depth_sensors:
    - name: intel_realsense
      type: D435i
      topics: [/depth/image, /depth/points, /imu]
      purpose: 3D 感知
      
  # 惯性测量
  imu:
    - name: body_imu
      topics: [/imu/data, /imu/filtered]
      purpose: 姿态估计、平衡
      
  # 足端传感器
  foot_sensors:
    - name: contact_sensor
      topics: [/foot_contactFL, /foot_contactFR, 
               /foot_contactBL, /foot_contactBR]
      type: bool (contact/release)
      
    - name: foot_force
      topics: [/foot_forceFL, /foot_forceFR,
               /foot_forceBL, /foot_forceBR]
      type: geometry_msgs/WrenchStamped
      
  # 关节传感器
  joint_states:
    - topic: /joint_states
      count: 12 (3 joints × 4 legs)
```

### 2.2 感知技能

#### 2.2.1 地形分类

```yaml
name: terrain_classification_skill
description: 实时分类地形类型
input:
  - /depth/points
  - /camera/downward/image
  - /imu
  
output:
  - /terrain/type           # terrain_type
  - /terrain/roughness      # float
  - /terrain/slope          # geometry_msgs/Vector3
  
terrain_types:
  - flat        # 平坦
  - rough       # 崎岖
  - slope_up   # 上坡
  - slope_down # 下坡
  - stairs     # 楼梯
  - gap        # 缝隙
  - obstacle   # 障碍物
  
processing:
  method: CNN (TerraByte or similar)
  inference_time: < 20ms
```

#### 2.2.2 足端落点规划

```yaml
name: foot_placement_skill
description: 计算最优足端落点
input:
  - /terrain/type
  - /terrain/roughness
  - /odom/body_velocity
  - /imu
  
output:
  - /footstep/planFL
  - /footstep/planFR
  - /footstep/planBL
  - /footstep/planBR
  
algorithm:
  method: foothold_selection_optimizer
  inputs:
    - terrain_validity
    - momentum_compensation
    - kinematic_feasibility
    
params:
  max_step_height: 0.2    # m
  max_step_length: 0.4     # m
  step_duration: 0.3       # s
```

#### 2.2.3 动态障碍检测

```yaml
name: dynamic_obstacle_detection_skill
description: 检测动态障碍物 (人/动物/车辆)
input:
  - /depth/points
  - /camera/front/image
  
output:
  - /obstacles/dynamic/tracked  # TrackedObject[]
  - /obstacles/prediction       # trajectory prediction
  
detection:
  method: tracking-by-detection
  models:
    - YOLOv8 + DeepSort
    - PointPillars + PointNet++
      
tracking:
  max_objects: 20
  prediction_horizon: 2.0   # seconds
  reid_enabled: true
```

#### 2.2.4 自主探索

```yaml
name: autonomous_exploration_skill
description: 未知环境自主探索
input:
  - /map
  - /odom
  - /depth/points
  
output:
  - /exploration/goal_pose   # geometry_msgs/PoseStamped
  - /exploration/status
  
algorithm:
  method: frontier_based_exploration
  variants:
    - nearest_frontier
    - utility_function (coverage/risk/speed)
    - deepRL_based
    
params:
  exploration_rate: 0.8     # frontier selection
  replan_interval: 5.0     # seconds
```

---

## 3. 定位 (Localization) 特性

### 3.1 定位方案

```yaml
quadruped_localization:
  # 里程计
  odometry:
    - type: kinematic_odometry
      input: /joint_states
      output: /odom/kinematic
      
    - type:视觉_惯性_odometry
      input: [/camera, /imu]
      output: /odom/visual
      package: VINS / OKVIS / OpenVINS
      
  # SLAM
  slam:
    lidar_slam:
      package: lio_sam / FAST_LIO
      input: [/ouster/points, /imu]
      output: /map, /odom
      
    visual_slam:
      package: ORB_SLAM3 / RTABMAP
      input: [/camera/image, /depth]
      output: /map, /odom
      
  # GPS (室外)
  gps:
    enabled: true
    topic: /gps/fix
    fusion: EKF with wheel odometry
    
  # 融合
  fusion:
    type: EKF
    inputs: [/odom/visual, /odom/kinematic, /imu/data, /gps/fix]
    output: /pose/filtered
```

### 3.2 定位技能

#### 3.2.1 足端里程计

```yaml
name: foot_odometry_skill
description: 基于足端接触的里程计
input:
  - /joint_states
  - /foot_contactFL, /foot_contactFR, ...
  
output:
  - /odom/foot
  - /drift/correction_needed
  
drift_correction:
  method: EKF with visual loop closure
  loop_detection: when same area revisited
  
accuracy:
  position_drift: < 1% of distance
  orientation_drift: < 2 deg per 10m
```

#### 3.2.2 地形适应定位

```yaml
name: terrain_adaptive_localization_skill
description: 考虑地形起伏的定位
input:
  - /odom/foot
  - /terrain/slope
  - /imu
  
output:
  - /pose/terrain_adjusted  # 位姿在地形坐标系
  
compensation:
  - pitch_roll_compensation
  - height_variation_compensation
  - slope_velocity_compensation
```

---

## 4. 导航 (Navigation) 特性

### 4.1 导航配置

```yaml
quadruped_navigation:
  # 全局规划
  global_planner:
    type: smac_planner
    costmap:
      resolution: 0.05
      inflation_radius: 0.3
      
  # 局部规划
  local_planner:
    type:teb_local_planner / dwb
    adapt_to_terrain: true
    footstep_planning: true
    
  # 地形适应导航
  terrain_navigation:
    enabled: true
    gait_adaptation: true
    slope_limits:
      max_pitch: 30       # deg
      max_roll: 30        # deg
      max_step_height: 0.25  # m
      
  # 特殊功能
  special:
    stair_climbing: true
    rough_terrain: true
    gap_crossing: true
```

### 4.2 步态规划

```yaml
gait_planning:
  # 步态选择
  gait_selection:
    gait_library:
      - trot
      - walk
      - pace
      - gallop
      - pronk
      
    selection_criteria:
      - speed
      - terrain_type
      - energy_efficiency
      - stability
      
  # 步态参数
  gait_params:
    trot:
      step_length: 0.3
      step_height: 0.15
      step_frequency: 2.0   # Hz
      
    walk:
      step_length: 0.2
      step_height: 0.1
      step_frequency: 1.0
      
  # 姿态控制
  posture_control:
    body_orientation: terrain_adapted
    height_adaptation: terrain_height
    roll_pitch_limits: [±30°, ±30°]
```

### 4.3 导航技能

#### 4.3.1 楼梯导航

```yaml
name: stair_navigation_skill
description: 上下楼梯导航
input:
  - /map
  - /terrain/type
  - /stairs/detections
  
output:
  - /gait/command      # 步态指令
  - /body_height/cmd  # 身体高度
  
stairs_config:
  max_step_height: 0.3   # m
  step_depth_min: 0.2    # m
  body_height_adjust: 0.3 # m (离楼梯高度)
  
control:
  speed: 0.1-0.2 m/s
  gaze_stabilization: true
```

#### 4.3.2 崎岖地形导航

```yaml
name: rough_terrain_navigation_skill
description: 崎岖不平地形的自主导航
input:
  - /terrain/roughness
  - /depth/points
  - /odom
  
output:
  - /gait/adapted_plan
  - /body_orientation/cmd
  
terrain_adaptation:
  - gait_modification: slower_speed
  - body_height: lowered
  - step_placement: careful
  
roughness_threshold:
  low: 0.05    # m - normal walk
  medium: 0.15 # m - careful walk
  high: 0.30   # m - very careful
```

#### 4.3.3 自主探索导航

```yaml
name: exploration_navigation_skill
description: 未知环境自主探索
input:
  - /map (partial)
  - /depth/points
  - /odom
  
output:
  - /exploration/next_goal
  - /coverage/map_update
  
frontier_detection:
  method: frontier_exploration
  min_frontier_size: 1.0   # m
  frontier_distance: 2.0-5.0  # m
  
path_planning:
  method: RRT* with constraints
  safety_margin: 0.5       # m
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 技能分类

```yaml
quadruped_skills:
  # 移动技能
  mobility:
    - walk_skill
    - trot_skill
    - gallop_skill
    - stair_up_skill
    - stair_down_skill
    - jump_skill
    - crawl_skill
    
  # 感知技能
    - terrain_classify_skill
    - object_detect_skill
    - human_detect_skill
    
  # 导航技能
    - navigate_to_goal_skill
    - explore_skill
    - follow_person_skill
    - patrol_skill
    
  # 特殊技能
    - stand_up_skill      # 摔倒后站起
    - lie_down_skill      # 躺下
    - shake_hand_skill    # 挥手
    - balance_skill       # 平衡恢复
```

### 5.2 技能描述

#### 5.2.1 行走技能

```yaml
name: walk_skill
description: 四足行走技能
type: motion

interface:
  inputs:
    - topic: /cmd_vel
      type: geometry_msgs/Twist
    - topic: /gait_type
      type: std_msgs/String
  outputs:
    - topic: /gait/status
      type: GaitStatus
    - topic: /foot_contacts
      type: Bool[4]

parameters:
  gait_type: {type: string, default: trot,
              options: [walk, trot, pace, gallop]}
  speed: {type: float, default: 0.3, range: [0.1, 1.0]}  # m/s
  step_height: {type: float, default: 0.1, range: [0.05, 0.2]}
  terrain_adapt: {type: bool, default: true}
  
preconditions:
  - imu_calibrated
  - joint_limits_ok
  - terrain_safe
  
postconditions:
  - goal_reached
  - obstacle_detected
  - terrain_too_harsh
```

#### 5.2.2 摔倒恢复技能

```yaml
name: stand_up_skill
description: 摔倒后自主站立
type: recovery

interface:
  inputs:
    - topic: /fall_direction
      type: geometry_msgs/Vector3
    - topic: /contact_state
      type: ContactState
      
  outputs:
    - topic: /recovery/trajectory
      type: JointTrajectory
      
recovery_phases:
  1: detect_fall_orientation
  2: tuck_legs
  3: roll_to_prone
  4: extend_legs
  5: stabilize
  
params:
  max_tilt_for_recovery: 45  # deg
  recovery_timeout: 10.0     # s
```

#### 5.2.3 跟随技能

```yaml
name: follow_person_skill
description: 跟随指定人员
type: navigation

interface:
  inputs:
    - topic: /target_person_id
      type: int64
    - topic: /person_pose
      type: geometry_msgs/PoseStamped
      
  outputs:
    - topic: /cmd_vel
      type: geometry_msgs/Twist
      
params:
  follow_distance: {type: float, default: 1.5, range: [0.5, 3.0]}  # m
  follow_direction: {type: string, default: behind, 
                     options: [behind, front, side]}
  max_follow_speed: 0.5  # m/s
  
avoidance:
  obstacle_avoidance: true
  person_dodging: true
```

### 5.3 技能编排

#### 5.3.1 巡检编排

```python
class PatrolAndInspectOrchestrator:
    async def execute(self, patrol_points):
        """巡检任务"""
        for point in patrol_points:
            # 1. 导航到目标点
            await self.execute_skill("navigate_skill", goal=point)
            
            # 2. 停下进行环境感知
            await self.execute_skill("terrain_classify_skill")
            
            # 3. 检测异常
            anomalies = await self.execute_skill("object_detect_skill",
                                                classes=["person", "vehicle", "obstacle"])
            
            # 4. 如有异常，上报
            if anomalies:
                await self.report_anomaly(anomalies)
                
            # 5. 继续下一个点
        await self.finish_patrol()
```

#### 5.3.2 自主探索编排

```python
class ExploreAndMapOrchestrator:
    async def execute(self, area_limit):
        """区域探索建图"""
        # 1. 初始化探索
        await self.execute_skill("init_exploration_skill",
                               area_boundary=area_limit)
        
        # 2. 开始探索循环
        while not exploration_complete():
            # 检测前沿
            frontiers = await self.execute_skill("detect_frontiers_skill")
            
            # 选择最有价值前沿
            best_frontier = await self.select_frontier(frontiers)
            
            # 导航到前沿
            await self.execute_skill("navigate_skill", goal=best_frontier)
            
            # 更新地图
            await self.execute_skill("update_map_skill")
            
            # 检查是否完成
            if self.coverage > 0.9:
                break
                
        # 3. 完成，保存地图
        await self.save_map()
```

---

## 6. 仿真与验证

### 6.1 仿真环境

```yaml
simulation:
  gazebo:
    robot_models:
      - unitree_a1
      - spot
      - anymal
    worlds:
      - flat_ground
      - officeindoor
      - outdoor_rough
      - stairs
      
  terrain_types:
    - concrete
    - grass
    - gravel
    - rubble
```

### 6.2 验证测试

```yaml
tests:
  mobility_tests:
    - walk_100m
    - trot_100m
    - stair_up_down (10 steps)
    - rough_terrain_10m
    - slope_15deg
    - gap_crossing (0.5m)
    
  navigation_tests:
    - point_navigation (10 points)
    - exploration_1000m2
    - following_50m
    
  skill_tests:
    - stand_up_recovery
    - fall_detection
    - terrain_adaptation
```

---

## 7. 硬件配置参考

### 7.1 Unitree A1

```yaml
robot: Unitree A1
weight: ~12kg
dof: 12 (3 × 4)
speed: 3.3 m/s (trot)
actuators: torque-control motors
sensors:
  - Intel RealSense D430 (depth)
  - IMU
  - 12 joint encoders
```

### 7.2 Boston Dynamics Spot

```yaml
robot: Boston Dynamics Spot
weight: 32kg
payload: 14kg
dof: 12
speed: 1.6 m/s
sensors:
  - 5× stereo cameras (360°)
  - IMU
  - encoders
options:
  - Spot CAM (inspect)
  - Spot EAP (advanced perception)
```

### 7.3 ANYmal C

```yaml
robot: ANYbotics ANYmal C
weight: 50kg
payload: 20kg
dof: 12
speed: 1.0 m/s (walk), 2.0 m/s (trot)
sensors:
  - Ouster OS1-64 (lidar)
  - Intel RealSense (depth)
  - FLIR camera
  - IMU
```

---

*本文档定义四足机器人的专有感知、定位、导航和技能规划原则*
