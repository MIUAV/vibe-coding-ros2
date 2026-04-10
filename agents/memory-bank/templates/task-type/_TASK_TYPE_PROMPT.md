# 🔀 Task-Type Memory — 自动切换模板

> 当 AI Agent 识别到任务类型时，自动加载对应模板。
> 将本文件复制到 `agents/memory-bank/active-context.md` 启用。

---

## 加载规则

| 任务 | 加载文件 |
|------|---------|
| 导航 / 路径规划 | `navigation.md` |
| 感知 / 目标检测 | `perception.md` |
| 运动控制 / 轨迹规划 | `motion-control.md` |
| 仿真 / 数字孪生 | `simulation.md` |
| 多机协同 / 编队 | `multi-agent.md` |
| 强化学习控制 | `reinforcement-learning.md` |
| 建图 / SLAM | `slam-mapping.md` |

---

## navigation.md

```markdown
# Navigation Task Context

## 导航范式
| 范式 | 工具 | 适用场景 |
|------|------|---------|
| 2D 导航 | Nav2 + costmap_2d | 室内轮式 |
| 3D 导航 | Nav2 + voxel_grid | 室外/无人机 |
| 视觉导航 | VSLAM (ORB-SLAM3/VINS) | 无 GPS |
| 组合导航 | GNSS + 视觉/激光融合 | 室外 |

## Nav2 核心组件
```
nav2_controller    → 轨迹跟踪（前进、回复）
nav2_planner       → 全局路径规划（Dijkstra/A*/RRT*）
nav2_behavior_tree → 决策逻辑（充电、停障、恢复）
nav2_costmap_2d    → 栅格地图（障碍物层、膨胀层）
nav2_map_server    → 地图加载（pgm/yaml 或 ros2 bag）
nav2_lifecycle_mgr  → 生命周期管理
```

## 关键 Topic
| Topic | 类型 | 说明 |
|-------|------|------|
| `/nav2_msgs/status` | `nav2_msgs/msg/Status` | Nav2 状态 |
| `/compute_path_to_pose` | `nav2_msgs/srv/ComputePathToPose` | 全局规划服务 |
| `/follow_path` | `nav2_msgs/action/FollowPath` | 轨迹跟踪动作 |

## 常用.launch.py 组合
```python
# Nav2 bringup 标准组合
Node(package='nav2_bringup', executable='bringup_launch.py',
     arguments=['--slam', 'False', '--map', 'map.yaml'])
```

## 常见故障
- 导航崩溃 → `nav2.lifecycle_manager` 未激活
- 路径正常但机器人不动 → `/cmd_vel` 无数据 → controller 未激活
- 障碍物不绕行 → costmap update_frequency 太低
```

---

## perception.md

```markdown
# Perception Task Context

## 感知流水线
```
传感器原始数据 → 预处理 → 特征提取 → 感知算法 → 输出
     ↓
camera/radar/lidar → 去噪/同步 → 分割/检测 → 目标跟踪/定位
```

## 感知算法速查
| 任务 | 算法 | ROS2 包 |
|------|------|---------|
| 2D 目标检测 | YOLO v5/v8 | `ros2_yolov8` / `yolov8_ros` |
| 3D 目标检测 | PointPillars / PointNet++ | `ros2_pointpillars` |
| 语义分割 | DeepLabV3 / UNet | `ros2_deeplab` |
| 深度估计 | Monodepth2 / MiDaS | `depthai_ros` |
| 激光雷达检测 | Euclidean Cluster / Ray Ground | `pointcloud_to_laserscan` |
| 传感器融合 | Autoware FF / Simple Sensor Fusion | `sensorfusion_msgs` |

## 点云处理
```cpp
// PCL 滤波 — 降采样
pcl::VoxelGrid<pcl::PointXYZ> vg;
vg.setInputCloud/cloud);
vg.setLeafSize(0.1f, 0.1f, 0.1f);
vg.filter(*filtered);

// 地面分割 — 激光雷达
pcl:: ransac_segment;
sac.setModelType(pcl::SACMODEL_PLANE);
sac.setDistanceThreshold(0.3);
```

## 图像处理
```cpp
// CV_Bridge — ROS2 ↔ OpenCV
#include <cv_bridge/cv_bridge.h>
auto cv_img = cv_bridge::toCvCopy(msg, sensor_msgs::image_encodings::BGR8);

// OpenCV 推理后处理
std::vector<cv::Rect> boxes;
std::vector<float> scores;
std::vector<int> class_ids;
// NMS 后处理
cv::dnn::NMSBoxes(boxes, scores, 0.5f, 0.4f, indices);
```

## 推理加速
| 平台 | 框架 | 说明 |
|------|------|------|
| NVIDIA Jetson | TensorRT | INT8 量化 |
| Intel NUC | OpenVINO | FP16/FP32 |
| RK3588 | RKNN | INT8 量化 |
| 通用 | ONNX Runtime | 跨平台 |
```

---

## motion-control.md

```markdown
# Motion Control Task Context

## 控制范式
| 范式 | 说明 | 典型场景 |
|------|------|---------|
| PID 控制 | 最简单，最常用 | 位置/速度环 |
| MPC | 模型预测，最优控制 | 轨迹跟踪 |
| WBC | 全身协调控制 | 人形/冗余机械臂 |
| 阻抗控制 | 力控柔顺 | 接触任务 |
| 自适应控制 | 参数不确定系统 | |

## 常用控制周期
| 应用 | 周期 |
|------|------|
| 机械臂关节控制 | 1 kHz（1ms）|
| 机械臂末端控制 | 100 Hz（10ms）|
| 移动机器人 | 50 Hz（20ms）|
| 无人机 | 200-400 Hz（2.5-5ms）|

## 关键依赖
```cpp
// 关节轨迹跟踪
#include <control_msgs/action/joint_trajectory.hpp>
#include <trajectory_msgs/msg/joint_trajectory_point.hpp>

// 力/位置混合控制
#include <geometry_msgs/msg/wrench_stamped.hpp>

// 欧拉角/四元数转换
#include <tf2_geometry_msgs/tf2_geometry_msgs.hpp>
```

## 运动学
```cpp
// 逆运动学 — KDL
#include <kdl/chainiksolvervel_pinv.hpp>
KDL::Chain chain;
chain.addSegment(KDL::Segment(KDL::Joint(KDL::Joint::RotZ),
  KDL::Frame::DH(0.0, 1.57, 0.0, 0.0)));

// 笛卡尔路径规划 — MoveIt2
moveit::planning_interface::MoveGroupInterface::Plan plan;
moveit_interface.plan(pose_target, plan);
moveit_interface.execute(plan);
```

## 轨迹生成
```cpp
// 梯形速度曲线（TrapVelProfile）
KDL::VelocityProfile_Trap trap(1.0, 0.5); // max_vel, max_accel
trap.SetProfileDuration(start_q, end_q, duration);
trap.Duration(start_q, end_q);

// S 曲线 — 无人机平滑轨迹
trap.ChangeMaxVel(max_vel);
trap.ChangeMaxAcc(accel);
```
```

---

## simulation.md

```markdown
# Simulation Task Context

## 仿真平台对比
| 平台 | 优势 | 劣势 | 推荐场景 |
|------|------|------|---------|
| Gazebo | ROS2 原生、物理丰富 | 渲染一般 | 通用机器人首选 |
| Isaac Sim | NVIDIA 渲染、物理精准 | 资源消耗大 | 室内视觉导航 |
| Mujoco | 接触动力学好、速度快 | 传感器少 | 机械臂、RL |
| Carla | 自动驾驶仿真 | 非 ROS2 原生 | 自动驾驶 |
| Webots | 跨平台、易上手 | 物理精度一般 | 教育、快速原型 |

## Gazebo 仿真关键配置
```xml
<!-- SDF 物理引擎配置 -->
<physics name="gz_physics" type="ode">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>1000</real_time_update_rate>
</physics>

<!-- 激光雷达_plugin -->
<plugin name="gazebo_ros_ray_sensor"
        filename="libgazebo_ros_ray_sensor.so">
  <ros>
    <namespace>/</namespace>
    <remapping>~/out:=scan</remapping>
  </ros>
  <output_type>sensor_msgs/LaserScan</output_type>
</plugin>
```

## ROS2-Gazebo 桥接
```python
# launch.py 中桥接配置
Node(
    package='gazebo_ros',
    executable='spawn_entity.py',
    arguments=['-entity', 'my_robot', '-file', robot_urdf]),
Node(package='ros_gz_bridge', executable='parameter_bridge',
     arguments=['/model/vehicle_blue/odometry@nav_msgs/Odometry@gz.msgs.Odometry']),
```

## Isaac Sim 仿真
```bash
# ROS2 bridge 启动
ros2 launch ros2 Isaac_sim_bridge/launch isaac_sim_docker.launch.py
```
```

---

## multi-agent.md

```markdown
# Multi-Agent Coordination Context

## 协调算法
| 算法 | 说明 | 通信需求 |
|------|------|---------|
| Leader-Follower | 领航者指挥 | 低 |
| 虚拟结构（Virtual Structure）| 保持刚性编队 | 低 |
| 行为法（Behavioral）| 权重叠加 | 中 |
| ORCA | 速度障碍法 | 低（局部）|
| 拍卖算法（Auction）| 任务投标分配 | 高 |
| BOIDs | 仿生群体算法 | 无（感应式）|

## 通信架构
```
集中式：所有机器人 ↔ 地面站 ↔ 协调决策
分布式：机器人 ↔ 机器人（点对点 MAVLink / DDS）
混合式：簇内分布式 + 簇间集中式
```

## 核心消息
```cpp
// 编队保持
geometry_msgs::msg::PoseStamped leader_pose;  // 领航者轨迹
geometry_msgs::msg::PoseStamped target_pose; // 本机目标

// 多机距离感测
sensor_msgs::msg::Range range_msg;  // 超声波/激光测距

// 任务分配
my_msgs::msg::AuctionBid bid;      // 投标
my_msgs::msg::AuctionResult result; // 竞拍结果
```

## 碰撞避免
```cpp
// ORCA (Optimal Reciprocal Collision Avoidance)
// 速度障碍锥 + 线性规划求解
geometry_msgs::msg::Twist optimal_vel;
orca_solver.compute_velocity(own_pose, other_agents, optimal_vel);
```
```

---

## reinforcement-learning.md

```markdown
# Reinforcement Learning Control Context

## RL 算法速查
| 算法 | 类型 | 适用场景 | 库 |
|------|------|---------|----|
| DDPG | Off-policy, 连续动作 | 连续控制（机械臂）| Stable-Baselines3 |
| PPO | On-policy, 连续动作 | 通用，稳定性好 | Stable-Baselines3 / Tianshou |
| SAC | Off-policy, 最大熵 | 机器人控制 | Stable-Baselines3 |
| TD3 | Off-policy, 连续动作 | 性能优化版 DDPG | Stable-Baselines3 |
| QMIX | 值分解 | 多智能体协作 | PyMARL |

## Sim2Real 流水线
```
仿真训练 → 检查点 → 策略导出(ONNX)
  ↓
量化校准（TensorRT/RKNN）→ 边缘部署
  ↓
域随机化（物理参数、光照、纹理）
```

## ROS2 集成
```python
# RL Agent 节点（Python）
class RLAgentNode(rclcpp.Node):
    def __init__(self):
        super().__init__('rl_agent')
        self.model = SAC.load('/path/to/model.zip')
        self.subscription = self.create_subscription(
            sensor_msgs.msg.JointState, '/joint_states', self.callback)
        self.action_pub = self.create_publisher(
            trajectory_msgs.msg.JointTrajectory, '/follow_joint_trajectory/goal', 1)

    def callback(self, msg):
        state = self.normalize(msg.position)  # 状态归一化
        action, _ = self.model.predict(state)  # 推理
        self.publish_action(action)
```

## 域随机化（Domain Randomization）
```python
# 仿真中随机化参数
random_params = {
    'robot_mass': np.random.uniform(0.8, 1.2) * base_mass,
    'friction': np.random.uniform(0.5, 1.5),
    'camera_noise': np.random.uniform(0.0, 0.05),
}
```
```

---

## slam-mapping.md

```markdown
# SLAM & Mapping Context

## SLAM 范式对比
| 方案 | 类型 | 地图 | 适用场景 |
|------|------|------|---------|
| Cartographer | 2D/3D 激光 | Submap + Grid | 建图 + 定位 |
| SLAM Toolbox | 2D 激光 | OccupancyGrid | 在线定位 |
| ORB-SLAM3 | 单目/立体/IMU | 稀疏特征点 | 视觉定位 |
| VINS-Mono/Fusion | 视觉+IMU | 稀疏点云 | 无人机 |
| LIO-SAM | 激光+IMU | 稠密点云 | 室外大场景 |
| FAST-LIO | 激光+IMU | 稠密点云 | 快速机载 |

## 建图流程
```bash
# Cartographer 2D 建图
ros2 launch cartographer_ros offline_backpack_2d.launch.py \
    bag_filenames:=/path/to/bag

# SLAM Toolbox 在线
ros2 launch slam_toolbox online_async_launch.py \
    slam_params_file:=config/mapper_params_online_async.yaml
```

## 地图类型与转换
```
OccupancyGrid (2D) ←栅格地图→ costmap_2d
PointCloud2 (3D) ←滤波降采样→ OctoMap (3D 占据栅格)
Mesh (3D) ←重建→ 导航网格
```

## 定位匹配
```cpp
// NDT (Normal Distributions Transform) 配准
#include <pclomp/ndt_omp.h>
pclomp::NDTMatcherOMP matcher;
matcher.setResolution(1.0f);
Eigen::Matrix4f guess = Eigen::Matrix4f::Identity();
pcl::PointCloud<PointT>::Ptr output(new pcl::PointCloud<PointT>);
matcher.alignedMutualScan(target, source, output, guess);
```
```
