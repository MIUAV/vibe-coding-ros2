# Skill Index — 机器人技能总索引

> 由 init-agent.sh 自动生成。每次添加新 skill 后重新运行 `./init-agent.sh --agent`。

## 统计

| 机器人类型 | 技能数 |
|-----------|--------|
| common | 17 |
| edge-platforms | 5 |
| humanoid | 7 |
| manipulator | 6 |
| motion-control | 6 |
| multi_rotor_uav | 1 |
| navigation | 6 |
| perception | 6 |
| quadruped | 6 |
| robotics-learning | 7 |
| simulation | 6 |
| simulator | 10 |
| system-integration | 8 |
| underwater | 2 |
| wheeled_vehicle | 6 |

---

## 完整技能列表


### common

- **agent-skill-bootstrap**: "智能体技能导入引导技能 - 用于重建 skill-inde
- **arm64-cross-compile**: ARM64 交叉编译技能 - 配置 x86 到 ARM64 (Jetson Orin
- **cmake-configuration**: CMakeLists.txt 和 package.xml 配置技能 - ROS2 CMake 复
- **opencv**: OpenCV4 技能库 - 图像处理、特征检测、深度学�
- **ros2-action-communication**: ROS2 Action 通讯技能 - ActionServer/ActionClient 实现�
- **ros2-component**: ROS2 组件技能 - Composable Nodes、组件加载器、组
- **ros2-debugging**: ROS2 调试技能 - 节点调试、话题分析、bag 回放
- **ros2-distributed-communication**: ROS2 分布式通讯技能 - DDS/RMW 配置、多机器通�
- **ros2-interface-definition**: ROS2 接口定义技能 - MSG/SRV/Action 自定义类型、�
- **ros2-launch-advanced**: ROS2 Launch 进阶技能 - Python Launch、多 launch 嵌套
- **ros2-lifecycle**: ROS2 生命周期管理技能 - Managed Nodes、状态转换
- **ros2-package-generator**: ROS2 功能包生成器 - 生成完整的 ROS2 包结构，�
- **ros2-package-generator-enhanced**: ROS2包生成增强技能 - workspace管理、overlay开发�
- **ros2-parameter-management**: ROS2 参数管理技能 - 参数声明、获取、设置、�
- **ros2-service-communication**: ROS2 Service 通讯技能 - 服务端/客户端实现、同�
- **ros2-time-management**: ROS2 时间管理技能 - 时钟源、Time/Duration、时间
- **ros2-topic-communication**: ROS2 Topic 通讯技能 - 发布者/订阅者实现、QoS �

### edge-platforms

- **digiwheel-sunrise**: 地瓜机器人旭日系列 - X3M X5 BPU 机器人开发
- **nvidia-cuda**: 英伟达CUDA开发 - GPU编程 性能优化 CUDA库
- **nvidia-jetpack**: 英伟达JetPack开发 - Jetson环境配置 DeepStream Tenso
- **rockchip-rknn**: 瑞芯微RKNN开发 - 模型转换 NPU推理 相机驱动

### humanoid

- **localization**: 人形机器人定位系统 - SLAM、IMU融合、EKF、GPS/R
- **motion-control**: 人形机器人运动控制技能 - 步态规划、逆运动
- **navigation**: 人形机器人导航系统 - 路径规划、双足行走导
- **perception**: 人形机器人感知系统 - 双目视觉、深度感知、
- **sdf-xacro-model**: 人形机器人 SDF/XACRO 模型开发技能 - 双足机器�
- **skill-planning**: 人形机器人技能规划 - 行为树、状态机、强化

### manipulator

- **localization**: 机械臂定位系统 - 末端执行器定位、工作空间
- **motion-control**: 机械臂运动控制 - 逆运动学、轨迹规划、力控
- **perception**: 机械臂感知系统 - 视觉引导、深度感知、力矩
- **sdf-xacro-model**: 机械臂 SDF/XACRO 模型开发技能 - 关节臂模型、�
- **skill-planning**: 机械臂技能规划 - 任务规划、抓取规划、行为

### motion-control

- **biped-control**: 双足控制技能集合 - 行走模式生成、平衡控制
- **collaborative-control**: 协作控制技能集合 - 多臂协调、人机协作
- **force-control**: 力控制技能集合 - 阻抗控制、力-位置混合控�
- **kinematics**: 运动学技能 - 正逆运动学、雅可比矩阵、轨迹
- **trajectory**: 轨迹规划技能 - 关节空间规划、笛卡尔空间规

### multi_rotor_uav

- **action** _(空)_
- **localization** _(空)_
- **navigation** _(空)_
- **perception** _(空)_
- **sdf-xacro-model**: 多旋翼无人机 SDF/XACRO 模型开发技能 - 四旋翼�
- **skill-planning** _(空)_

### navigation

- **map-building**: 地图构建技能 - SLAM实时建图、地图保存与加�
- **nav2-integration**: 导航2 (Nav2) 集成技能 - Nav2 配置、行为树、路�
- **obstacle-avoidance**: 动态避障技能 - DWA/Teb/ORCA算法、局部路径规划
- **path-planning**: 全局路径规划技能 - A*/RRT*/Dijkstra/Hybrid A*、代�
- **slam**: SLAM 算法技能 - LaserSLAM、VisualSLAM、RTAB-Map、Cart

### perception

- **calibration**: 传感器标定技能集合 - 相机标定、外参标定、
- **edge-inference**: 边缘推理部署技能集合 - TensorRT、RKNN、OpenVINO 
- **lidar-perception**: 激光雷达感知技能集合 - 点云处理、3D检测、�
- **sensor-fusion**: 传感器融合技能集合 - 时空同步、激光-相机�
- **vision-perception**: 视觉感知技能集合 - 目标检测、语义分割、立

### quadruped

- **localization**: 四足机器人定位 - SLAM建图、IMU融合、EKF定位�
- **motion-control**: 四足机器人运动控制 - 步态规划、平衡控制、
- **navigation**: 四足机器人导航 - 路径规划、动态避障、导航
- **perception**: 四足机器人感知系统 - 视觉识别、深度相机、
- **sdf-xacro-model**: 足式机器人 SDF/XACRO 模型开发技能 - 四足机器�
- **skill-planning**: 四足机器人技能规划 - 任务规划、行为树、强

### robotics-learning

- **continual-learning**: 持续学习技能集合 - 灾难性遗忘、弹性权重巩
- **federated-learning**: 联邦学习技能集合 - FedAvg、差分隐私、水平联
- **incremental-learning**: 增量学习技能集合 - 类别增量、任务增量、表
- **reinforcement-learning**: 强化学习技能集合 - 策略梯度、值函数、模型
- **sim2real**: Sim2Real 迁移技能 - 域随机化、域适应、系统识
- **transfer-learning**: 迁移学习技能集合 - 域适应、微调、课程学习

### simulation

- **gazebo**: Gazebo 仿真技能集合 - SDF建模、物理配置、传�
- **isaac-sim**: Isaac Sim 仿真技能集合 - Omniverse 配置、Isaac ROS 
- **mujoco**: Mujoco 仿真技能集合 - Mujoco 建模
- **physics-simulation**: 物理仿真技能集合 - 接触动力学、软体仿真
- **robot-modeling**: 机器人建模技能集合 - URDF/Xacro、 SDF/Gazebo

### simulator

- **carla**: CARLA 自动驾驶仿真开发技能 - 车辆动力学、传
- **coppeliasim**: CoppeliaSim 机器人仿真开发技能 - 远程 API、视�
- **gazebo-harmonic**: Gazebo Harmonic 仿真器开发技能 - 机器人建模、�
- **isaaclab**: NVIDIA Isaac Lab 仿真开发技能 - 强化学习训练、G
- **maniskill3**: ManiSkill3 机器人操作技能开发 - 高保真操作任�
- **mujoco**: MuJoCo 物理仿真开发技能 - 高性能物理引擎、�
- **pybullet**: PyBullet 物理仿真开发技能 - Python 机器人仿真�
- **rviz2**: RViz2 可视化开发技能 - 3D可视化、插件开发、�
- **unreal-engine**: Unreal Engine 机器人仿真开发技能 - 高保真仿真�
- **webots**: Webots 机器人仿真开发技能 - 机器人建模、控�

### system-integration

- **cloud-robotics**: 云机器人技能 - 边缘云协同、云端规划、远程
- **debugging-optimization**: 调试优化技能集合 - ROS2 调试工具、性能分析
- **edge-deployment**: 边缘部署技能集合 - ARM64 交叉编译、Docker ROS2 
- **lifecycle-management**: 生命周期管理技能集合 - 托管节点设计、状态
- **multi-agent-swarm**: 多智能体协同技能 - 蜂群机器人、分布式感知
- **ros2-communication**: ROS2 通信技能集合 - 话题服务设计、DDS QoS、跨
- **system-architecture**: 系统架构技能集合 - 分布式设计、模块化架构

### underwater

- **auv-control**: AUV 控制技能 - 水下潜航器动力学、螺旋桨控�
- **sonar-perception**: 声呐感知技能 - 前视声呐、侧扫声呐、多波束

### wheeled_vehicle

- **action**: 轮式车辆执行控制技能 - 底盘运动控制、差速
- **localization**: 轮式车辆定位系统 - GNSS/RTK、SLAM、IMU融合、里
- **navigation**: 轮式车辆导航系统 - 全局路径规划、局部路径
- **perception**: 轮式车辆感知系统 - 视觉感知、激光雷达、深
- **sdf-xacro-model**: 轮式车辆 SDF/XACRO 模型开发技能 - 差速驱动车�

---

*运行 `./init-agent.sh --agent` 重新生成*
