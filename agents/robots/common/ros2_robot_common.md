# ROS2 机器人共性特性 VibeCoding 指南

> 所有 ROS2 机器人的通用开发指南，涵盖感知、定位、导航、技能规划的共性原理

---

## 1. ROS2 机器人系统架构

### 1.1 通用层次结构

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                          │
│            (任务规划、技能编排、人机交互)                            │
├─────────────────────────────────────────────────────────────────┤
│                         Skill Layer                              │
│        (感知技能、定位技能、导航技能、操作技能、运动技能)              │
├─────────────────────────────────────────────────────────────────┤
│                       Navigation Layer                            │
│              (路径规划、轨迹生成、障碍规避)                          │
├─────────────────────────────────────────────────────────────────┤
│                      Localization Layer                          │
│                (SLAM、里程计融合、GPS/视觉定位)                     │
├─────────────────────────────────────────────────────────────────┤
│                      Perception Layer                             │
│         (视觉、激光雷达、IMU、深度传感器、触觉)                      │
├─────────────────────────────────────────────────────────────────┤
│                       Control Layer                               │
│              (电机控制、舵机控制、力矩控制、PID)                      │
├─────────────────────────────────────────────────────────────────┤
│                   Hardware Abstraction Layer                      │
│                  (驱动接口、传感器接口、执行器接口)                   │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 消息流架构

```
传感器驱动 → 感知处理 → 定位融合 → 态势理解 → 任务规划 → 行为决策 → 运动控制 → 执行器
    ↓           ↓           ↓           ↓           ↓           ↓           ↓
 [Raw Data] → [Feature] → [Pose]   → [Map/Model] → [Goal]   → [Action] → [Cmd]
```

---

## 2. 感知 (Perception) 共性特性

### 2.1 传感器分类

| 类型 | 传感器 | 话题 | 消息类型 |
|------|--------|------|----------|
| 视觉 | RGB相机 | `/camera/image_raw` | `sensor_msgs/Image` |
| 深度 | Depth相机 | `/camera/depth` | `sensor_msgs/Image` |
| 激光 | 激光雷达 | `/scan` | `sensor_msgs/LaserScan` |
| 3D激光 | 3D激光 | `/points` | `sensor_msgs/PointCloud2` |
| IMU | 惯性单元 | `/imu` | `sensor_msgs/Imu` |
| 里程 | 编码器 | `/odom` | `nav_msgs/Odometry` |
| GPS | GPS接收机 | `/gps` | `sensor_msgs/NavSatFix` |
| 接触 | 力矩传感器 | `/wrench` | `geometry_msgs/WrenchStamped` |

### 2.2 感知处理流水线

```python
# 通用感知处理流水线
Pipeline:
  1. 传感器驱动 (Sensor Driver)
     - 发布原始数据话题
     - 硬同步/软同步多传感器
     
  2. 预处理 (Preprocessing)
     - 去噪/滤波
     - 畸变校正
     - 时间戳对齐
     
  3. 特征提取 (Feature Extraction)
     - 边缘/角点
     - 深度特征
     - 语义特征
     
  4. 目标检测 (Detection)
     - 2D/3D 边界框
     - 语义分割
     - 实例分割
     
  5. 目标跟踪 (Tracking)
     - 多目标跟踪
     - ID 分配
```

### 2.3 感知共性技能

#### 2.3.1 相机驱动技能

```yaml
name: camera-driver-skill
description: 各类相机 (USB/GMSL/Ethernet) 的 ROS2 驱动配置
topics:
  - /camera/image_raw     # 原始图像
  - /camera/camera_info   # 相机内参
  - /camera/depth         # 深度图像 (如果有)
params:
  - device: "/dev/video0"
  - width: 640
  - height: 480
  - fps: 30
  - frame_id: "camera_link"
```

#### 2.3.2 激光雷达驱动技能

```yaml
name: lidar-driver-skill
description: 各类激光雷达 (Livox/Hesai/Velodyne) 的 ROS2 驱动
topics:
  - /scan              # 2D 激光扫描
  - /scan_filtered     # 滤波后扫描
  - /points           # 3D 点云 (可选)
params:
  - frame_id: "laser_link"
  - angle_min: -3.14159
  - angle_max: 3.14159
  - range_min: 0.1
  - range_max: 100.0
  - scan_rate: 10      # Hz
```

#### 2.3.3 深度学习推理技能

```yaml
name: perception-inference-skill
description: 深度学习感知模型推理 (TensorRT/ONNX)
models:
  - type: object_detection
    input: /camera/image_raw
    output: /detections
    framework: tensorrt
  - type: semantic_segmentation
    input: /camera/image_raw
    output: /semantic_mask
    framework: tensorrt
hardware:
  - platform: x86_64/NVIDIA
  - platform: ARM64/Jetson
```

---

## 3. 定位 (Localization) 共性特性

### 3.1 定位方法分类

| 方法 | 输入 | 输出 | 适用场景 |
|------|------|------|----------|
| 里程计 | 编码器/IMU | 相对位姿 | 短期定位 |
| SLAM | 激光/视觉 | 全局地图+定位 | 未知环境 |
| GPS/RTK | GNSS | 全局绝对位置 | 室外开阔地 |
| 视觉里程计 | 相机 | 相对运动 | 纹理丰富环境 |
| 激光里程计 | 激光雷达 | 相对运动 | 结构化环境 |
| UWB | UWB基站 | 室内全局位置 | 室内定位 |

### 3.2 定位流水线

```
传感器输入 → 时间同步 → 预处理 → 特征提取 → 里程计/匹配 → 融合 → 位姿输出
     ↓           ↓          ↓          ↓           ↓          ↓
 [Raw Data] → [Sync]  → [Filter] → [Features] → [Odometry] → [EKF/Pose]
```

### 3.3 定位共性技能

#### 3.3.1 SLAM 技能

```yaml
name: slam-skill
description: 2D/3D SLAM 实现
types:
  2d_slam:
    package: slam_toolbox
    input: /scan
    output: /map, /pose
  3d_slam:
    package: lio_sam / FAST_LIO
    input: /points, /imu
    output: /map, /pose, /cloud_registered
params:
  map_resolution: 0.05    # meters
  scan_range: 30.0       # meters
  update_rate: 5.0      # Hz
```

#### 3.3.2 定位融合技能

```yaml
name: localization-fusion-skill
description: 多传感器位姿融合 (EKF/UKF)
sensors:
  - source: odometry
    weight: 0.3
  - source: imu
    weight: 0.2
  - source: gps
    weight: 0.2
  - source: visual
    weight: 0.3
filter:
  type: extended_kalman_filter  # or unscented_kalman_filter
  process_noise: [0.01, 0.01, 0.01]
  measurement_noise: [0.1, 0.1, 0.1]
```

---

## 4. 导航 (Navigation) 共性特性

### 4.1 导航类型

| 类型 | 包 | 输入 | 输出 |
|------|-----|------|------|
| 2D 导航 | nav2 | /goal_pose, /map | /cmd_vel |
| 3D 导航 | navigation2 | /goal_pose, /map | /cmd_vel |
| 自主探索 | explore_lite | /map | /goal_pose |
| 跟随领航 | social_navigation | /person_pose | /cmd_vel |

### 4.2 导航流水线

```
目标点 → 全局规划 → 路径平滑 → 局部规划 → 障碍检测 → 轨迹优化 → 运动控制 → 速度输出
   ↓          ↓           ↓          ↓           ↓           ↓           ↓
[Goal]   [Global Path] [Smooth]  [Local Path] [Obstacle] [Trajectory] [Cmd]
```

### 4.3 导航共性技能

#### 4.3.1 全局规划技能

```yaml
name: global-planner-skill
description: 全局路径规划
planners:
  - type: smac_planner      # Hybrid A*
    costmap: global_costmap
    resolution: 0.05
  - type: navfn_planner     # Dijkstra
    costmap: global_costmap
  - type: theta_star_planner # Theta*
    costmap: global_costmap
params:
  tolerance: 0.5              # goal tolerance (m)
  max_iterations: 1000000
  use_final_backaround: true
```

#### 4.3.2 局部规划技能

```yaml
name: local-planner-skill
description: 局部路径规划和动态避障
planners:
  - type: dwb_controller
    critics: ["ObstacleCritic", "GoalCritic", "PathCritic", "MatchCritic"]
  - type: teb_local_planner
    batch_size: 5
  - type: rpp_local_planner
params:
  max_vel_x: 1.0            # m/s
  max_vel_theta: 1.0        # rad/s
  max_accel: 0.5           # m/s^2
  lookahead: 1.0            # m
```

#### 4.3.3 避障技能

```yaml
name: obstacle-avoidance-skill
description: 动态障碍物检测和避障
detection:
  method: costmap_2d        # or vector_field
  layers: ["inflation", "obstacles", "virtual_walls"]
inflation:
  radius: 0.5               # m
  cost_scaling_factor: 3.0
response:
  method: replan            # or slow_down, stop
  replan_time: 2.0          # s
```

---

## 5. 技能规划 (Skill Planning) 共性特性

### 5.1 技能分类

| 类别 | 技能 | 描述 |
|------|------|------|
| 感知技能 | detect_skill | 目标检测 |
| 感知技能 | segment_skill | 语义分割 |
| 感知技能 | track_skill | 目标跟踪 |
| 定位技能 | localize_skill | 定位 |
| 定位技能 | mapping_skill | 建图 |
| 导航技能 | navigate_skill | 导航 |
| 导航技能 | explore_skill | 自主探索 |
| 导航技能 | follow_skill | 跟随 |
| 操作技能 | grasp_skill | 抓取 |
| 操作技能 | place_skill | 放置 |
| 操作技能 | push_skill | 推动 |
| 运动技能 | move_skill | 运动执行 |
| 运动技能 | balance_skill | 平衡控制 |

### 5.2 技能系统架构

```
                    ┌──────────────────────────────────────┐
                    │           Skill Orchestrator          │
                    │         (技能编排器)                   │
                    └──────────────────┬───────────────────┘
                                       │
           ┌───────────────────────────┼───────────────────────────┐
           │                           │                           │
    ┌──────▼──────┐           ┌───────▼───────┐           ┌───────▼───────┐
    │  Perception  │           │  Navigation   │           │   Manipulation│
    │    Skills    │           │    Skills     │           │    Skills     │
    └──────────────┘           └───────────────┘           └───────────────┘
           │                           │                           │
    ┌──────▼──────┐           ┌───────▼───────┐           ┌───────▼───────┐
    │ - detect    │           │ - navigate    │           │ - grasp       │
    │ - segment   │           │ - explore     │           │ - place       │
    │ - track     │           │ - follow      │           │ - push        │
    │ - classify  │           │ - patrol      │           │ - align       │
    └──────────────┘           └───────────────┘           └───────────────┘
```

### 5.3 技能描述模板

```yaml
name: skill_name
description: 技能功能描述
type: perception|navigation|manipulation|motion  # 技能类型

# 输入输出接口
interface:
  inputs:
    - topic: /input/topic
      type: sensor_msgs/Image
      required: true
  outputs:
    - topic: /output/topic
      type: sensor_msgs/Image
      required: true

# 技能参数
parameters:
  param1: {default: 1.0, type: float, range: [0.0, 10.0]}
  param2: {default: "mode_a", type: string, options: [mode_a, mode_b]}

# 前置条件
preconditions:
  - condition: localization_ready
    description: 定位系统已初始化
  - condition: map_loaded
    description: 地图已加载

# 后置条件
postconditions:
  - condition: task_completed
    description: 任务成功完成
  - condition: timeout
    description: 任务超时

# 异常处理
error_handling:
  - error: sensor_timeout
    action: retry_3_times
  - error: obstacle_stuck
    action: replan_path
```

### 5.4 技能编排模板

```python
# 技能编排示例
from skill_manager import SkillManager

class TaskOrchestrator:
    def __init__(self):
        self.skill_manager = SkillManager()
        
    async def execute_patrol_task(self):
        """巡检任务编排"""
        # 1. 激活定位技能
        await self.skill_manager.activate("localize_skill")
        
        # 2. 激活导航技能
        await self.skill_manager.activate("navigate_skill")
        
        # 3. 循环巡检点
        for point in patrol_points:
            # 4. 发布目标点
            await self.skill_manager.execute(
                "navigate_skill",
                goal=point,
                tolerance=0.5
            )
            
            # 5. 执行检测
            detections = await self.skill_manager.execute(
                "detect_skill",
                timeout=5.0
            )
            
            # 6. 处理检测结果
            if detections:
                await self.handle_anomaly(detections)
                
    async def handle_anomaly(self, detections):
        """异常处理"""
        # 停止导航
        await self.skill_manager.stop("navigate_skill")
        
        # 拍照记录
        await self.skill_manager.execute("capture_skill")
        
        # 上报异常
        await self.report_anomaly(detections)
        
        # 恢复导航
        await self.skill_manager.resume("navigate_skill")
```

---

## 6. 机器人类型通用技能

### 6.1 运动控制技能

```yaml
name: motion-control-skill
description: 通用运动控制接口
control_modes:
  - velocity_control
  - position_control
  - torque_control
  - hybrid_control
interfaces:
  subscriber: /cmd_vel
  publisher: /joint_states
params:
  control_frequency: 100.0    # Hz
  max_vel_linear: 1.0        # m/s
  max_vel_angular: 1.0      # rad/s
  max_accel: 0.5            # m/s^2
```

### 6.2 状态监控技能

```yaml
name: state-monitor-skill
description: 机器人状态监控和故障检测
monitoring:
  - subsystem: motors
    check: [current, temperature, error_flag]
    threshold: {current: 10.0, temp: 80.0}
  - subsystem: sensors
    check: [data_valid, timestamp_delay]
    threshold: {delay: 0.5}  # seconds
  - subsystem: computation
    check: [cpu_usage, memory_usage]
    threshold: {cpu: 80.0, memory: 80.0}
actions:
  - on_error: stop_motion
  - on_warning: reduce_load
  - on_critical: emergency_stop
```

### 6.3 通信接口技能

```yaml
name: communication-skill
description: 机器人间/机载通信
protocols:
  - ros2_topic
  - ros2_service
  - ros2_action
  - ros2_parameter
remote:
  enabled: true
  interface: ethernet
  ip: 192.168.1.100
telemetry:
  enabled: true
  topic: /telemetry
  rate: 10.0          # Hz
```

---

## 7. 调试与验证共性方法

### 7.1 仿真验证

```bash
# 启动 Gazebo 仿真
ros2 launch gazebo_ros bringup.launch.py

# 启动 Rviz 可视化
rviz2 -d config/robot.rviz

# 录制 bag 回放
ros2 bag record -a -o test_bag
```

### 7.2 单元测试

```bash
# 运行包测试
colcon test --packages-select my_robot_perception

# 运行特定测试
ros2 run rclcpp_components test_component
```

### 7.3 性能基准

| 指标 | 目标 | 测量方法 |
|------|------|----------|
| 感知延迟 | < 50ms | topic delay |
| 定位精度 | < 0.1m | ground truth 比较 |
| 导航成功率 | > 95% | 统计100次任务 |
| CPU 使用率 | < 70% | top/htop |
| 内存占用 | < 2GB | /proc/meminfo |

---

## 8. 安全共性规范

### 8.1 紧急停止

```yaml
emergency_stop:
  enabled: true
  hardware_watchdog: true
  soft_stop_timeout: 0.5    # seconds
  recovery_action: restart
```

### 8.2 权限管理

```yaml
safety:
  operation_modes:
    - mode: manual
      allowed: [all]
    - mode: semi_auto
      allowed: [navigate, detect]
    - mode: full_auto
      allowed: [navigate, detect, skill_execute]
  restrictions:
    max_velocity: 0.5       # m/s
    max_height: 2.0         # m (for UAV)
    no_go_zones: [[x, y, r], ...]
```

---

*本文档定义了所有 ROS2 机器人的共性开发原则，是各类机器人 VibeCoding 指南的基础*
