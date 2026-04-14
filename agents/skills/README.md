# Skills — 可用技能索引

> 本项目的 AI Agent 技能库，共 **180+ SKILL.md**，覆盖 ROS2 开发全链路。

---

## 顶层分类速查

| 分类 | 路径 | 数量 |
|------|------|------|
| 通用技能 | `common/` | 19 |
| 边缘平台 | `edge-platforms/` | 25 |
| 感知 | `perception/` | 22 |
| 导航 | `navigation/` | 20 |
| 运动控制 | `motion-control/` | 17 |
| 多旋翼无人机 | `multi_rotor_uav/` | 27 |
| 四足机器人 | `quadruped/` | 6 |
| 人形机器人 | `humanoid/` | 6 |
| 机械臂 | `manipulator/` | 10 |
| 轮式车辆 | `wheeled_vehicle/` | 5 |
| 水下机器人 | `underwater/` | 3 |
| 机器人学习 | `robotics-learning/` | 26 |
| 仿真 | `simulation/` | 7 |
| 仿真器 | `simulator/` | 35 |
| 系统集成 | `system-integration/` | 11 |
| ROS2 专用 | `ros2-cmake-guard/` | 2 |
| ROS2 调试 | `ros2-debug/` | 1 |
| ROS2 QoS | `ros2-qos-checker/` | 1 |

---

## 快速定位

### 机器人开发核心（必读）

| 任务 | 技能路径 |
|------|---------|
| ROS2 包生成 | `common/ros2-package-generator/SKILL.md` |
| CMake 防护（三行导出） | `common/cmake-configuration/SKILL.md` |
| LifecycleNode 规范 | `common/ros2-lifecycle/SKILL.md` |
| QoS 组合正确 | `common/ros2-topic-communication/SKILL.md` |
| ROS2 调试诊断 | `ros2-debug/SKILL.md` |
| ROS2 CMake Guard | `ros2-cmake-guard/SKILL.md` |
| ROS2 QoS Checker | `ros2-qos-checker/SKILL.md` |

### 感知（perception/）

| 技能 | 路径 |
|------|------|
| 相机标定 | `perception/calibration/camera-intrinsic-calibration/SKILL.md` |
| Lidar-相机外参标定 | `perception/calibration/lidar-camera-extrinsic/SKILL.md` |
| 多传感器时间同步 | `perception/calibration/multi-sensor-timesync/SKILL.md` |
| 激光雷达 3D 检测 | `perception/lidar-perception/lidar-3d-detection/SKILL.md` |
| 点云处理 | `perception/lidar-perception/pointcloud-processing/SKILL.md` |
| 地面分割 | `perception/lidar-perception/lidar-ground-segmentation/SKILL.md` |
| 目标检测 YOLO | `perception/vision-perception/yolo-detection/SKILL.md` |
| 3D 目标检测 | `perception/vision-perception/3d-object-detection/SKILL.md` |
| 语义分割 | `perception/vision-perception/semantic-segmentation/SKILL.md` |
| 双目深度估计 | `perception/vision-perception/stereo-depth-estimation/SKILL.md` |
| 深度估计 | `perception/edge-inference/` |
| TensorRT 部署 | `perception/edge-inference/tensorrt-deployment/SKILL.md` |
| OpenVINO 部署 | `perception/edge-inference/openvino-deployment/SKILL.md` |
| RKNN 部署 | `perception/edge-inference/rknn-deployment/SKILL.md` |
| 卡尔曼滤波 | `perception/sensor-fusion/kalman-filtering/SKILL.md` |
| Lidar-相机融合 | `perception/sensor-fusion/lidar-camera-fusion/SKILL.md` |
| 多目标跟踪 | `perception/sensor-fusion/multi-object-tracking/SKILL.md` |

### 导航（navigation/）

| 技能 | 路径 |
|------|------|
| Nav2 配置 | `navigation/nav2-config/SKILL.md` |
| Nav2 集成 | `navigation/nav2-integration/nav2-configuration/SKILL.md` |
| 行为树导航 | `navigation/nav2-integration/behavior-tree-nav/SKILL.md` |
| 全局路径规划 | `navigation/path-planning/global-planning/SKILL.md` |
| 局部路径规划 | `navigation/path-planning/local-planning/SKILL.md` |
| 多机路径规划 | `navigation/path-planning/multi-robot-planning/SKILL.md` |
| 障碍物规避 | `navigation/obstacle-avoidance/costmap-configuration/SKILL.md` |
| 动态障碍物 | `navigation/obstacle-avoidance/dynamic-obstacle/SKILL.md` |
| 激光 SLAM | `navigation/slam/laser-slam/SKILL.md` |
| 视觉 SLAM | `navigation/slam/visual-slam/SKILL.md` |
| 激光-视觉融合 SLAM | `navigation/slam/lidar-visual-fusion/SKILL.md` |
| 2D 栅格地图 | `navigation/map-building/2d-grid-map/SKILL.md` |
| 3D 点云地图 | `navigation/map-building/3d-pointcloud-map/SKILL.md` |

### 运动控制（motion-control/）

| 技能 | 路径 |
|------|------|
| 正逆运动学 | `motion-control/kinematics/forward-inverse-kinematics/SKILL.md` |
| 人形运动学 | `motion-control/kinematics/humanoid-kinematics/SKILL.md` |
| 关节空间轨迹 | `motion-control/trajectory/joint-space-trajectory/SKILL.md` |
| 笛卡尔轨迹 | `motion-control/trajectory/cartesian-trajectory/SKILL.md` |
| 时间最优轨迹 | `motion-control/trajectory/time-optimal-trajectory/SKILL.md` |
| 力位混合控制 | `motion-control/force-control/force-position-hybrid/SKILL.md` |
| 阻抗控制 | `motion-control/force-control/impedance-control/SKILL.md` |
| 双足平衡控制 | `motion-control/biped-control/balance-control/SKILL.md` |
| 双足步态 | `motion-control/biped-control/walking-pattern/SKILL.md` |
| 多臂协同 | `motion-control/collaborative-control/multi-arm-coordination/SKILL.md` |
| 人机协作 | `motion-control/collaborative-control/human-robot-collaboration/SKILL.md` |
| 碰撞检测 | `manipulator/motion-control/collision-avoidance/SKILL.md` |
| 抓取规划 | `manipulator/motion-control/grasp-planning/SKILL.md` |

### 仿真（simulator/）

| 仿真器 | 路径 |
|--------|------|
| Gazebo (Classic) | `simulation/gazebo/` |
| Gazebo Harmonic | `simulator/gazebo-harmonic/` |
| Isaac Sim | `simulator/isaac-sim/` |
| Isaac Lab | `simulator/isaaclab/` |
| Carla | `simulator/carla/` |
| Mujoco | `simulator/mujoco/` |
| PyBullet | `simulator/pybullet/` |
| Webots | `simulator/webots/` |
| CoppeliaSim | `simulator/coppeliasim/` |
| RViz2 插件 | `simulator/rviz2/` |
| Unreal Engine | `simulator/unreal-engine/` |

### 机器人学习（robotics-learning/）

| 方向 | 技能 |
|------|------|
| 强化学习 DDPG/PPO/SAC/TD3 | `robotics-learning/reinforcement-learning/` |
| 强化学习 ROS2 集成 | `robotics-learning/reinforcement-learning/rl-ros2-integration/SKILL.md` |
| sim2real 迁移 | `robotics-learning/sim2real/SKILL.md` |
| 迁移学习 | `robotics-learning/transfer-learning/` |
| 持续学习 | `robotics-learning/continual-learning/` |
| 联邦学习 | `robotics-learning/federated-learning/` |
| 增量学习 | `robotics-learning/incremental-learning/` |

### 边缘推理（edge-platforms/）

| 平台 | 路径 |
|------|------|
| NVIDIA Jetson | `edge-platforms/nvidia-jetpack/` |
| NVIDIA CUDA | `edge-platforms/nvidia-cuda/` |
| TensorRT | `edge-platforms/nvidia-jetpack/tensorrt/SKILL.md` |
| RKNN (瑞芯微) | `edge-platforms/rockchip-rknn/` |
| OpenVINO | `edge-platforms/opencv/edge-platforms/openvino/SKILL.md` |
| ARM64 交叉编译 | `edge-platforms/nvidia-jetpack/ros2-integration/SKILL.md` |

---

## SKILL.md 编写规范

参考 `CONTRIBUTING.md` — 每个 SKILL 必须包含：

1. **Frontmatter**：`name` `description` `tools` `usage`
2. **≥1 实战案例**：错误现象 + 修复方法
3. **具体代码示例**：可直接使用的片段
4. **触发词**：方便 AI 路由

---

## 更新日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v0.3.1 | 2026-04-13 | 重写索引，180+ SKILL 完整分类 |
| v0.3.0 | 2026-04-07 | 初始结构，涵盖 PX4/四足/机械臂/感知 |
