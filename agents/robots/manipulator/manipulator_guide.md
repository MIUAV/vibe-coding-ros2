# 机械臂 (Manipulator) VibeCoding 指南

> 专注于机械臂的感知、定位(末端位姿)、导航(工作空间规划)和技能规划开发

---

## 1. 机械臂概述

### 1.1 结构特点

```
        ┌─────────┐
        │  Base   │ ← 基座 (固定/移动)
        ├─────────┤
        │ Joint 1 │ ← 大臂
        ├─────────┤
        │ Joint 2 │ ← 小臂
        ├─────────┤
        │ Joint 3 │ ← 腕部
        ├─────────┤
        │Joint 4-6│ ← 末端
        ├─────────┤
        │EndEffector│ ← 夹爪/工具
        └─────────┘
```

### 1.2 关键特性

| 特性 | 说明 | 技术挑战 |
|------|------|----------|
| 逆运动学 | 末端位姿→关节角度 | 多解、非线性 |
| 轨迹规划 | 平滑无碰撞轨迹 | 优化、避障 |
| 力控 | 装配、抛光等任务 | 柔顺控制 |
| 视觉引导 | 视觉定位目标 | 手眼标定 |
| 协作安全 | 人机协作 | 安全监控 |

### 1.3 自由度配置

| 类型 | DOF | 典型用途 |
|------|-----|----------|
| 3-DOF | 基本定位 | 点对点搬运 |
| 4-DOF | 增加姿态 | 门把手操作 |
| 5-DOF | 完整操作 | 抓取+放置 |
| 6-DOF | 完整姿态 | 复杂装配 |
| 7-DOF | 冗余关节 | 避障+灵巧 |

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
manipulator_sensors:
  # 关节传感器
  joint_states:
    - topic: /joint_states
      fields: [position, velocity, effort]
      frequency: 100-500 Hz
      
  # 视觉感知
  cameras:
    - name: eye_in_hand
      type: wrist-mounted camera
      topics: [/camera/hand/image, /camera/hand/depth]
      purpose: 目标定位、视觉伺服
      
    - name: eye_to_hand
      type: fixed external camera
      topics: [/camera/workspace/image, /camera/workspace/depth]
      purpose: 工作空间监控
      
    - name: 3d_sensor
      type: structured light / stereo
      topics: [/scene/points, /scene/grasps]
      purpose: 3D 物体定位
      
  # 力感知
  force_sensors:
    - name: wrist_ft_sensor
      location: wrist
      topics: [/wrench', /wrench_filtered]
      type: geometry_msgs/WrenchStamped
      purpose: 力控、碰撞检测
      
    - name: finger_sensors
      location: gripper
      topics: [/gripper/force_left, /gripper/force_right]
      purpose: 抓取力感知
      
  # 接近感知
  proximity:
    - name: proximity_sensor
      topics: [/proximity/distance]
      type: LaserScanner / TOF
      
  # 安全感知
  safety:
    - name: safety_scanner
      type: SICK safety laser
      topics: [/scan_safety]
      purpose: 人机协作区域检测
```

### 2.2 感知技能

#### 2.2.1 物体检测与定位

```yaml
name: object_detection_localization_skill
description: 3D 物体检测和定位
input:
  - /scene/points (PointCloud2)
  - /camera/workspace/image
  
output:
  - /objects/detected[]     # DetectedObject[]
  - /objects/grasps[]       # GraspConfig[]
  - /objects/pose           # PoseStamped[]
  
detection:
  method: detectron / yolov8 + depth
  6dof_pose: true
  textureless: true
  symmetry_handling: true
  
grasp_planning:
  method: grasp_detector (GraspNet, ContactGraspNet)
  output: grasp_candidates[]
  ranking: by success probability
  
accuracy:
  position: < 5mm
  orientation: < 5 deg
```

#### 2.2.2 手眼标定

```yaml
name: hand_eye_calibration_skill
description: 手眼标定 (eye-in-hand / eye-to-hand)
input:
  - /camera/hand/image
  - /aruco/poses
  - /joint_states
  
output:
  - /calibration/hand_eye_transform
  - /camera/hand/extrinsics
  
calibration_motion:
  method: robot_moves_calibration_object
  min_poses: 20
  optimization: hand_eye_calibration
  
accuracy:
  reprojection_error: < 1 pixel
  transform_accuracy: < 1mm
```

#### 2.2.3 碰撞检测

```yaml
name: collision_detection_skill
description: 实时碰撞检测
input:
  - /joint_states
  - /scene/points (filtered)
  - /wrist_ft_sensor
  
output:
  - /collision/status
  - /collision/distance_field
  - /collision/stop_command
  
detection:
  method: 
    - distance_field (moveit)
    - point cloud (depth)
  threshold:
    distance: 0.05   # m
    force: 20        # N
    
response:
  immediate_stop: true
  jerk_limited: true
```

#### 2.2.4 目标跟踪

```yaml
name: visual_servo_tracking_skill
description: 视觉伺服目标跟踪
input:
  - /camera/hand/image
  - /desired_object_pose
  - /joint_states
  
output:
  - /joint_velocity_command
  - /servo/status
  
control:
  method: image_based_vs / pose_based_vs
  ibvs_lambda: 0.05-0.1
  feature_tracking: optical_flow / descriptor
  
stability:
  convergence_check: true
  singularity_avoidance: true
```

---

## 3. 定位 (Localization) - 末端位姿

### 3.1 定位方案

```yaml
manipulator_localization:
  # 正运动学 (关节角度 → 末端位姿)
  forward_kinematics:
    package: tf2_ros
    output: /tf (base → ee_link)
    
  # 逆运动学
  inverse_kinematics:
    packages:
      - trac_ik
      - bio_ik
      - moveit_kinematics
    solver: KDL / analytical (if available)
    
  # 工具中心点 (TCP)
  tcp:
    definition: pose_offset from ee_link
    calibration: touch_taught / marker_based
    
  # 末端定位
  end_effector_localization:
    - source: forward_kinematics
      accuracy: joint_encoder resolution
      
    - source: visual_feedback
      accuracy: camera resolution / depth accuracy
      
    - source: force_closure
      accuracy: force sensor resolution
```

### 3.2 工作空间表示

```yaml
workspace_representation:
  # 3D 工作空间
  bounding_volume:
    type: box / cylinder
    dimensions: [x, y, z]
    
  # 可达性地图
  reachability_map:
    resolution: 0.02  # m
    orientation_resolution: 15  # deg
    valid_configurations: StoredIK[]
    
  # 奇异位姿
  singularities:
    detection: kdl / analytical
    avoidance: optional
    
  # 关节限位
  joint_limits:
    position: [min, max] per joint
    velocity: [max] per joint
    acceleration: [max] per joint
    effort: [max] per joint
```

### 3.3 定位技能

#### 3.3.1 正运动学技能

```yaml
name: forward_kinematics_skill
description: 计算末端执行器位姿
input:
  - /joint_states
  
output:
  - /ee_pose           # PoseStamped
  - /tf (base → ee)
  
transforms:
  base_frame: base_link
  ee_frame: ee_link / tool0
```

#### 3.3.2 逆运动学技能

```yaml
name: inverse_kinematics_skill
description: 计算到达目标位姿的关节角度
input:
  - /target/pose (world frame)
  - /current/joint_states
  
output:
  - /ik/solution      # sensor_msgs/JointState
  - /ik/cost
  - /ik/valid
  
params:
  timeout: 0.1        # seconds
  attempts: 3
  search_timeout: 1.0
  
solutions:
  - nearest_to_current
  - joint_limit_center
  - singularity_avoidance
```

---

## 4. 导航 (Navigation) - 工作空间规划

### 4.1 导航配置

```yaml
manipulator_navigation:
  # 运动规划
  motion_planners:
    - type: ompl
      algorithms:
        - RRTstar
        - PRMstar
        - BITstar
    - type: pilz_industrial_motion_planner
      algorithms:
        - LIN
        - PTP
        - CIRC
    - type: trajopt
      optimization: smooth + collision-free
      
  # 避障
  collision_avoidance:
    - method: MoveIt! collision_checking
    - method: distance_field
    - via_points: for narrow passages
    
  # 轨迹执行
  trajectory_execution:
    - type: joint_trajectory_controller
    - following_error_tolerance: 0.05
    - execution_duration_mismatch: 10%
```

### 4.2 轨迹规划

```yaml
trajectory_planning:
  # 轨迹类型
  trajectory_types:
    - joint_space: joint_interpolation
    - cartesian_space: straight line in task space
    - blended: combination
    
  # 时间参数化
  time_parameterization:
    - method: trapz_vel / S-curve
    - max_velocity: per joint
    - max_acceleration: per joint
    - max_jerk: per joint
    
  # 约束
  constraints:
    - collision_free
    - joint_limits
    - velocity_limits
    - acceleration_limits
    - orientationTolerance
    - positionTolerance
```

### 4.3 导航技能

#### 4.3.1 关节空间规划

```yaml
name: joint_space_planning_skill
description: 关节空间轨迹规划
input:
  - /target/joint_positions
  - /current/joint_states
  
output:
  - /joint_trajectory
  - /planned/result
  
params:
  planner: RRTstar
  planning_time: 1.0    # s
  max_velocity_scaling: 0.5
  max_acceleration_scaling: 0.5
```

#### 4.3.2 笛卡尔空间规划

```yaml
name: cartesian_space_planning_skill
description: 笛卡尔空间直线规划
input:
  - /target/pose
  - /current/pose
  
output:
  - /joint_trajectory
  
params:
  planner: LIN (Pilz)
  max_velocity: 0.2   # m/s
  blend_radius: 0.01  # for blending
  
waypoints:
  method: straight_line / via_points
  via_points: for complex paths
```

#### 4.3.3 抓取规划

```yaml
name: grasp_planning_skill
description: 自主抓取规划
input:
  - /scene/points
  - /target/object_type
  - /workspace/bounds
  
output:
  - /grasp/poses[]     # 多个候选抓取
  - /grasp/selected    # 最佳抓取
  - /grasp/trajectory  # 抓取轨迹
  
grasp_quality:
  - approach_direction
  - grasp_width
  - grasp_depth
  - friction_coverage
  
preprocess:
  - object_segmentation
  - pose_estimation
  - model_retrieval
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 技能分类

```yaml
manipulator_skills:
  # 基本操作技能
  basic:
    - move_to_joint_skill
    - move_to_pose_skill
    - stop_skill
    
  # 抓取技能
  grasping:
    - detect_grasp_skill
    - plan_grasp_skill
    - execute_grasp_skill
    - release_object_skill
    
  # 操作技能
    - pick_place_skill
    - push_skill
    - pull_skill
    - screw_skill
    - wipe_skill
    
  # 力控技能
  force_control:
    - impedance_control_skill
    - force_feedback_skill
    - assemble_skill
    
  # 视觉伺服技能
  visual_servo:
    - image_based_vs_skill
    - pose_based_vs_skill
    - target_tracking_skill
    
  # 移动操作 (移动机械臂)
  mobile_manipulation:
    - base_navigate_skill
    - coordinated_reach_skill
    - reactive_manipulation_skill
```

### 5.2 技能描述

#### 5.2.1 抓取技能

```yaml
name: grasp_skill
description: 抓取物体技能
type: manipulation

interface:
  inputs:
    - topic: /target/object
      type: Detection3D
    - topic: /grasp/constraints
      type: GraspConstraints
  outputs:
    - topic: /grasp/result
      type: GraspResult
    - topic: /joint_trajectory
      type: trajectory_msgs/JointTrajectory

parameters:
  grasp_type: {type: string, default: parallel,
               options: [parallel, pinch, envelop]}
  approach_distance: {type: float, default: 0.1}  # m
  lift_height: {type: float, default: 0.05}      # m
  grasp_force: {type: float, default: 10.0}       # N
  
preconditions:
  - arm_calibrated
  - camera_calibrated
  - object_in_workspace
  - collision_free_path_exists
  
postconditions:
  - object_grasped
  - grasp_failed
  - collision_abort
  
error_handling:
  - object_moved: replan_grasp
  - collision: abort_and_retract
  - force_exceeded: increase_force
```

#### 5.2.2 装配技能

```yaml
name: assemble_skill
description: 零件装配技能 (插销、螺钉等)
type: manipulation

interface:
  inputs:
    - topic: /assembly/goal_pose
      type: PoseStamped
    - topic: /assembly/type
      type: std_msgs/String  # peg_in_hole, screw, press_fit
  outputs:
    - topic: /assembly/status
      type: AssemblyStatus
      
control:
  method: impedance_control
  parameters:
    stiffness: [500, 500, 100]   # N/m
    damping: [10, 10, 5]
    
search_strategy:
  - force_feedback_search
  - visual_feedback_search
  - spiral_search
  
insertion_params:
  max_lateral_error: 0.002   # m
  max_angular_error: 2       # deg
  max_insertion_force: 50    # N
```

#### 5.2.3 视觉伺服技能

```yaml
name: visual_servo_skill
description: 视觉伺服控制技能
type: manipulation

interface:
  inputs:
    - topic: /camera/image
    - topic: /desired/feature_pose
  outputs:
    - topic: /joint_velocity_command
    - topic: /servo/status

control_params:
  lambda: 0.05-0.1      # servo gain
  cam_info: /camera/camera_info
  
feature_tracking:
  - corners
  - edges
  - aruco_markers
  - custom
  
stop_conditions:
  - error_below_threshold
  - max_iterations_reached
  - singularity_detected
  - collision_detected
```

### 5.3 技能编排

#### 5.3.1 抓取-放置编排

```python
class PickPlaceOrchestrator:
    async def execute(self, target_object, place_location):
        """抓取-放置任务"""
        # 1. 检测物体
        object_pose = await self.execute_skill("detect_object_skill",
                                            object=target_object)
        
        # 2. 规划抓取
        grasp_config = await self.execute_skill("plan_grasp_skill",
                                              object_pose=object_pose)
        
        # 3. 移动到预抓取位置
        await self.execute_skill("move_to_pregrasp_skill",
                               grasp_config=grasp_config)
        
        # 4. 接近并抓取
        result = await self.execute_skill("execute_grasp_skill",
                                        grasp_config=grasp_config)
        
        if not result.success:
            return result
            
        # 5. 抬起
        await self.execute_skill("lift_skill", height=0.1)
        
        # 6. 移动到放置位置上方
        await self.execute_skill("move_to_place_approach_skill",
                               place_location=place_location)
        
        # 7. 放置
        await self.execute_skill("place_skill",
                               location=place_location)
        
        return result
```

#### 5.3.2 移动操作编排

```python
class MobileManipulationOrchestrator:
    async def execute(self, object_location):
        """移动操作任务"""
        # 1. 移动基座到物体附近
        base_goal = calculate_base_position(object_location)
        await self.execute_skill("base_navigate_skill",
                                goal=base_goal)
        
        # 2. 调整机械臂到达物体
        await self.execute_skill("coordinated_reach_skill",
                               target=object_location)
        
        # 3. 抓取
        await self.execute_skill("grasp_skill",
                               object_pose=object_location)
        
        # 4. 搬运
        await self.execute_skill("base_navigate_skill",
                                goal=self.home_position)
        
        # 5. 放置
        await self.execute_skill("place_skill",
                               location=self.home_position)
```

---

## 6. 仿真与验证

### 6.1 仿真环境

```yaml
simulation:
  gazebo:
    models:
      - panda (Franka)
      - ur5 / ur10
      - iiwa
      - sawyer
    grippers:
      - robotiq_2f
      - robotiq_3f
      - shadow_hand
      
  moveit_simulation:
    kinematics_plugin: kinematics_plugins
    planning_scene: collision_objects
    
  contact_models:
    - surface_contact
    - friction
    - deformable_objects (optional)
```

### 6.2 验证测试

```yaml
tests:
  kinematics_tests:
    - fk_accuracy < 1mm
    - ik_success_rate > 95%
    
  motion_tests:
    - planning_time < 1s
    - trajectory_smoothness
    - path_collision_free
    
  manipulation_tests:
    - grasp_success > 90%
    - pick_place_cycle < 10s
    - force_control_accuracy < 2N
    
  safety_tests:
    - collision_detection < 10ms
    - emergency_stop < 50ms
    - human_detection < 100ms
```

---

## 7. 硬件配置参考

### 7.1 Franka Emika Panda

```yaml
robot: Franka Emika Panda
dof: 7
payload: 3kg
reach: 855mm
repeatability: ±0.1mm
actuation: torque-controlled
sensors:
  - 7x joint torque sensors
  - 14x contact sensors (fingers)
  - external torque sensor (optional)
interface: ROS / franka_ros2
```

### 7.2 Universal Robot UR5e

```yaml
robot: Universal Robot UR5e
dof: 6
payload: 5kg
reach: 850mm
repeatability: ±0.03mm
sensors:
  - 6x joint position encoders
  - force_torque_sensor (optional)
interface: ROS2 / ur_robot_driver
```

### 7.3 Kinova Gen3

```yaml
robot: Kinova Gen3
dof: 6 or 7
payload: 3kg (6-DOF), 2kg (7-DOF)
reach: 900mm / 985mm
repeatability: ±0.1mm
sensors:
  - integrated camera (optional)
  - force jointtorque sensors
interface: ROS2 / kinova_robot
```

---

*本文档定义机械臂的专有感知、定位、导航和技能规划原则*
