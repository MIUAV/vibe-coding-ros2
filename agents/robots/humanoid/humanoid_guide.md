# 人形机器人 (Humanoid) VibeCoding 指南

> 专注于双足人形机器人的感知、定位、导航和技能规划开发

---

## 1. 人形机器人概述

### 1.1 结构特点

```
        ┌─────────────┐
        │   Head      │ ← 头部 (相机、麦克风)
        ├─────────────┤
        │   Torso     │ ← 躯干 (主控、IMU)
        ├──────┬──────┤
   ┌────┤ Arm  │ Arm  ├────┐
   │    │ L    │ R    │    │
   │    └──────┴──────┘    │
   │                       │
 ┌─┴─┐                   ┌─┴─┐
 │Leg │                   │Leg│
 │ L  │                   │ R │
 └────┘                   └────┘
```

### 1.2 关键特性

| 特性 | 说明 | 技术挑战 |
|------|------|----------|
| 双足平衡 | 实时平衡控制 | ZMP/重心控制 |
| 全身运动 | 多关节协调 | 逆运动学 |
| 动态行走 | 复杂地形行走 | 步态规划 |
| 手臂操作 | 抓取、操作 | 任务级控制 |
| 人机交互 | 语音、视觉 | 多模态感知 |

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
humanoid_sensors:
  # 视觉感知
  cameras:
    - name: head_camera
      type: stereo_or_rgbd
      topics: [/head_camera/left/image, /head_camera/right/image]
      fps: 30
      purpose: 导航、交互
    - name: hand_camera
      type: wrist_mounted_camera
      topics: [/hand_camera/image]
      purpose: 精细操作
      
  # 深度感知
  depth_sensors:
    - name: torso_depth
      type: Intel RealSense / Azure Kinect
      topics: [/depth/image, /depth/points]
      purpose: 3D 环境感知
      
  # 惯性测量
  imu:
    - name: body_imu
      location: torso
      topics: [/imu/data, /imu/filtered]
      purpose: 平衡、姿态估计
      
  # 力感知
  force_sensors:
    - name: foot_force
      location: [left_foot, right_foot]
      topics: [/force/left_foot, /force/right_foot]
      purpose: ZMP 计算、平衡控制
    - name: hand_force
      location: [left_hand, right_hand]
      topics: [/force/left_hand, /force/right_hand]
      purpose: 抓取力控制
      
  # 关节传感器
  joint_states:
    - topic: /joint_states
      type: sensor_msgs/JointState
      fields: [position, velocity, effort]
      count: 20+ joints
```

### 2.2 感知技能

#### 2.2.1 人体姿态估计

```yaml
name: human_pose_estimation_skill
description: 从图像中估计人体骨骼关键点
input: /head_camera/image_raw
output: /human_pose

detection_points:
  - head
  - neck
  - shoulders (L/R)
  - elbows (L/R)
  - wrists (L/R)
  - hips (L/R)
  - knees (L/R)
  - ankles (L/R)

models:
  - type: OpenPose / HRNet
    framework: TensorRT
    inference_time: < 50ms
    accuracy: > 0.9 AP

applications:
  - human_robot_interaction
  - gesture_recognition
  - activity_recognition
```

#### 2.2.2 足区域检测

```yaml
name: foot_detection_skill
description: 检测地面和足部位置，用于平衡控制
input: /depth/image or /stereo/left/image
output: 
  - /foot_detection/left_position
  - /foot_detection/right_position
  - /ground_plane

processing:
  - ground_segmentation
  - foot_candidate_extraction
  - foot_tracking
  - cop_calculation  # 压力中心

accuracy:
  position_error: < 0.02m
  orientation_error: < 5 deg
```

#### 2.2.3 楼梯/台阶检测

```yaml
name: stair_detection_skill
description: 检测楼梯和台阶，用于上下楼梯规划
input: 
  - /depth/points
  - /scan (2D lidar optional)

output:
  - /stairs/detections  # StairDetection[]
  - /stairs/step_heights
  - /stairs/step_widths

detection_params:
  min_step_height: 0.1   # m
  max_step_height: 0.25  # m
  min_step_width: 0.2    # m
  
applications:
  - stair_climbing
  - step_detection
  - terrain_classification
```

#### 2.2.4 狭窄空间检测

```yaml
name: narrow_space_detection_skill
description: 检测狭窄通道和门框
input: /depth/points
output: /narrow_space/detections

params:
  min_width: 0.4      # m (机器人宽度 + margin)
  max_width: 1.0      # m
  min_height: 1.2     # m
  
applications:
  - doorway_passage
  - corridor_navigation
```

---

## 3. 定位 (Localization) 特性

### 3.1 定位方案

```yaml
humanoid_localization:
  # 多传感器融合
  sensors:
    - imu: body_imu          # 姿态
    - encoders: joint_states  # 关节角度
    - visual: head_camera     # 视觉里程计
    - depth: torso_depth      # 深度里程计
    
  # 定位方法
  methods:
    - type: visual_inertial_odometry
      package: VINS / OKVIS
      input: [/head_camera/image, /imu/data]
      output: /odom/visual
      
    - type: depth_odometry
      package: RGB-D Odometry
      input: [/depth/image]
      output: /odom/depth
      
    - type: kinematic_odometry
      input: /joint_states
      output: /odom/kinematic
      
  # 融合
  fusion:
    type: EKF
    inputs: [/odom/visual, /odom/kinematic, /imu/data]
    output: /pose/filtered
    pub_rate: 100.0  # Hz
```

### 3.2 地图表示

```yaml
map_representation:
  # 2D 俯视图 (用于导航)
  nav_map:
    type: occupancy_grid_map
    resolution: 0.05  # m
    size: 100x100     # m
    layers:
      - static: terrain_type
      - inflation: robot_radius
      - obstacle: detected_objects
      - stairs: step_locations
      
  # 3D 体素图 (用于足区域规划)
  voxel_map:
    type: OctoMap
    resolution: 0.1   # m
    max_range: 10.0   # m
    
  # 语义地图
  semantic_map:
    type: 3D landmarks
    objects:
      - doors (open/close)
      - stairs (up/down)
      - furniture
      - interaction_points
```

### 3.3 定位技能

#### 3.3.1 双足里程计

```yaml
name: biped_odometry_skill
description: 基于关节角度和足部接触的双足里程计
input:
  - /joint_states
  - /force/left_foot
  - /force/right_foot
  
output:
  - /odom/biped  # 累积行走距离
  - /pose/world  # 世界坐标系位姿

drift_correction:
  method: visual_loop_closure
  loop_detection_interval: 5.0  # seconds
  
accuracy:
  drift: < 1% of distance traveled
  pose_accuracy: < 0.1m
```

#### 3.3.2 足端滑动检测

```yaml
name: foot_slip_detection_skill
description: 检测行走过程中的足端滑动
input:
  - /force/left_foot
  - /force/right_foot
  - /odom/kinematic
  - /imu/data
  
output:
  - /slip/left_foot
  - /slip/right_foot
  - /slip/emergency_stop

detection:
  velocity_threshold: 0.05   # m/s
  force_drop_threshold: 20%  # % of expected
  
response:
  immediate: reduce_velocity
  severe: full_stop
```

---

## 4. 导航 (Navigation) 特性

### 4.1 导航配置

```yaml
humanoid_navigation:
  # 全局规划
  global_planner:
    type: smac_planner_hybrid
    costmap: global_costmap
    resolution: 0.05
    
  # 局部规划
  local_planner:
    type: humanoid_footstep_planner  # 或 dwb
    footstep_cost: true
    terrain_cost: true
    
  # 地形适应
  terrain_adaptation:
    enabled: true
    foot_height_adjust: true
    terrain_classification: true
    
  # 特殊导航
  special:
    stair_climbing: true
    door_opening: true
    narrow_passage: true
    human_avoidance: true
```

### 4.2 足端规划

```yaml
footstep_planning:
  # 步态参数
  gait_params:
    step_length: 0.3      # m (max)
    step_width: 0.15       # m (min)
    step_height: 0.15      # m (max)
    step_duration: 0.6    # s
    support_duration: 0.2 # s
    
  # 步态类型
  gait_types:
    - static_walk     # 静态平衡
    - dynamic_walk    # 动态平衡
    - quasi_dynamic   # 折中
    - run            # 跑步
    
  # 约束
  constraints:
    max_tilt: 15        # deg
    min_foot_clearance: 0.1  # m
    foot_yaw_range: 30   # deg
```

### 4.3 导航技能

#### 4.3.1 楼梯导航

```yaml
name: stair_navigation_skill
description: 上下楼梯的完整导航技能
input:
  - /map
  - /scan
  - /depth/points
  - /stairs/detections
output:
  - /footstep/plan      # 步态序列
  - /balance/commands   # 平衡控制指令
  
stairs_params:
  step_height_max: 0.22  # m
  step_depth_min: 0.2    # m
  railing_detection: true
  
control:
  velocity: slow (0.1 m/s)
  handrail_use: optional
  gaze_stabilization: enabled
```

#### 4.3.2 动态环境导航

```yaml
name: dynamic_navigation_skill
description: 动态障碍物环境中的导航
input:
  - /detections  # 动态目标检测
  - /pedestrian_tracker/tracked
  - /scan
  
output:
  - /local_plan
  - /velocity_cmd
  
avoidance:
  strategy: predictive_replan
  prediction_horizon: 2.0  # s
  time_buffer: 0.5         # s
  social_space: 1.5        # m (for humans)
  
human_models:
  - walking_speed: 1.4  # m/s
  - trajectory_prediction: linear
  - intention_estimation: optional
```

#### 4.3.3 狭窄空间导航

```yaml
name: narrow_space_navigation_skill
description: 通过狭窄通道和门框
input:
  - /map
  - /depth/points
  - /narrow_space/detections
  
output:
  - /trajectory/side_steps  # 侧身通过规划
  - /velocity_cmd
  
params:
  passage_width_threshold: 0.7    # m
  turn_in_place: true
  wall_following: optional
  
control:
  lateral_velocity: 0.1   # m/s
  turn_rate: 0.3          # rad/s
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 技能分类

```yaml
humanoid_skills:
  # 移动技能
  mobility:
    - walk_skill
    - run_skill
    - climb_stairs_skill
    - open_door_skill
    - navigate_narrow_skill
    - balance_recovery_skill
    
  # 操作技能
  manipulation:
    - grasp_skill
    - place_skill
    - push_skill
    - pull_skill
    - hand_over_skill
    - turn_handle_skill
    
  # 全身协调技能
  whole_body:
    - reach_pose_skill
    - lift_object_skill
    - crouch_skill
    - kneel_skill
    - stand_up_skill
    
  # 交互技能
  interaction:
    - wave_skill
    - point_skill
    - gesture_skill
    - handover_skill
```

### 5.2 技能描述

#### 5.2.1 行走技能

```yaml
name: walk_skill
description: 双足行走技能
type: motion

interface:
  inputs:
    - topic: /goal_pose
      type: geometry_msgs/PoseStamped
    - topic: /walk_command
      type: std_msgs/String  # start/stop/pause
  outputs:
    - topic: /current_gait
      type: HumanoidGait
    - topic: /balance_state
      type: BalanceState

parameters:
  walk_mode: {type: string, default: quasi_dynamic, 
               options: [static, dynamic, quasi_dynamic]}
  step_length: {type: float, default: 0.25, range: [0.1, 0.4]}
  step_height: {type: float, default: 0.15, range: [0.05, 0.25]}
  speed: {type: float, default: 0.5, range: [0.1, 1.0]}  # m/s
  
preconditions:
  - localization_ready
  - balance_system_calibrated
  - terrain_assessed
  
postconditions:
  - goal_reached
  - obstacle_unreachable
  - balance_lost
  
error_handling:
  - slip_detected: balance_recovery
  - obstacle_ahead: replan
  - terrain_change: adapt_gait
```

#### 5.2.2 抓取技能

```yaml
name: grasp_skill
description: 手臂抓取物体技能
type: manipulation

interface:
  inputs:
    - topic: /target_object
      type: Detection3D
    - topic: /grasp_config
      type: GraspConfig
  outputs:
    - topic: /grasp_result
      type: GraspResult
    - topic: /arm_traj
      type: trajectory_msgs/JointTrajectory

parameters:
  approach_strategy: {type: string, default: top_down,
                      options: [top_down, side, front]}
  force_control: {type: bool, default: true}
  grasp_width: {type: float, default: 0.1}  # m
  
preconditions:
  - hand_camera_calibrated
  - arm_kinematics_calibrated
  - object_in_reach
  
postconditions:
  - object_grasped
  - grasp_failed
  - object_dropped
  
error_handling:
  - slip_detected: re_grasp
  - collision: abort_motion
```

#### 5.2.3 全身协调技能

```yaml
name: whole_body_reach_skill
description: 全身协调到达目标姿态
type: whole_body_coordination

interface:
  inputs:
    - topic: /target_pose
      type: PoseStamped  # 目标位置
    - topic: /constraint_pose
      type: PoseStamped[]  # 约束位置
  outputs:
    - topic: /whole_body_traj
      type: WholeBodyTrajectory
      
constraints:
  center_of_mass: within_support_polygon
  joint_limits: enforced
  self_collision: avoided
  external_collision: avoided
  
optimization:
  objective: minimize_energy
  priority: [balance, reachability, smoothness]
```

### 5.3 技能编排

#### 5.3.1 移动-操作编排

```python
# 移动到操作位置
class NavigateAndGraspOrchestrator:
    async def execute(self, target_object):
        """导航到物体位置并抓取"""
        # 1. 定位物体
        object_pose = await self.execute_skill("detect_object_skill", 
                                               object=target_object)
        
        # 2. 计算操作位置 (物体前方一定距离)
        approach_pose = calculate_approach_pose(object_pose, distance=0.5)
        
        # 3. 导航到位置
        await self.execute_skill("navigate_skill", goal=approach_pose)
        
        # 4. 调整姿态
        await self.execute_skill("whole_body_align_skill", 
                                target=object_pose)
        
        # 5. 伸出手臂
        await self.execute_skill("arm_reach_skill", 
                                target=object_pose)
        
        # 6. 抓取
        result = await self.execute_skill("grasp_skill", 
                                         object=object_pose)
        
        # 7. 收回手臂
        await self.execute_skill("arm_retract_skill")
        
        return result
```

#### 5.3.2 上下楼梯编排

```python
class StairClimbingOrchestrator:
    async def execute(self, direction="up"):
        """上下楼梯"""
        # 1. 检测楼梯
        stair_info = await self.execute_skill("stair_detection_skill")
        
        # 2. 定位楼梯起点
        stair_start = await self.execute_skill("localize_stair_start_skill",
                                              stair=stair_info)
        
        # 3. 导航到楼梯起点
        await self.execute_skill("navigate_skill", goal=stair_start)
        
        # 4. 执行楼梯攀爬
        if direction == "up":
            await self.execute_skill("climb_up_stairs_skill", 
                                    stair=stair_info)
        else:
            await self.execute_skill("climb_down_stairs_skill",
                                    stair=stair_info)
            
        # 5. 到达顶部后恢复行走
        await self.execute_skill("walk_skill", mode="resume")
```

---

## 6. 仿真与验证

### 6.1 仿真环境

```yaml
simulation:
  # Gazebo 配置
  gazebo:
    world: humanoid_apartment
    robot_model: atlas / unitree / digit
    physics: ode / bullet
    
  # 传感器仿真
  sensors:
    camera_sim: true
    imu_sim: true
    force_sim: true
    
  # 地形
  terrain:
    - flat_ground
    - stairs
    - rough_terrain
    - slopes
```

### 6.2 验证测试

```yaml
tests:
  # 平衡测试
  balance_tests:
    - push_recovery
    - slope_walking
    - perturbed_walking
    
  # 移动测试
  mobility_tests:
    - walk_10m
    - stair_up_down
    - narrow_passage
    - door_open_passage
    
  # 操作测试
  manipulation_tests:
    - grasp_object
    - place_object
    - open_door
```

---

## 7. 硬件配置参考

### 7.1 Boston Dynamics Atlas

```yaml
robot: Boston Dynamics Atlas
dof: 28
actuators: hydraulic
sensors:
  - Velodyne VLP-16 (head)
  - stereo cameras
  - IMU
  - joint encoders
```

### 7.2 Unitree H1

```yaml
robot: Unitree H1
dof: 20 (configurable)
actuators:电机
sensors:
  - depth camera (D435i)
  - IMU (BMI088)
  - joint encoders
```

### 7.3 宇树 H1

```yaml
robot: 宇树 H1
height: 1.7m
weight: 55kg
dof: 20+
actuators: M107 motors
```

---

*本文档定义人形机器人的专有感知、定位、导航和技能规划原则*
