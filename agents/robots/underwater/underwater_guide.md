# 水下机器人 (Underwater) VibeCoding 指南

> 专注于 AUV/ROV 的感知、控制、水声通信和深海导航开发

---

## 1. 水下机器人概述

### 1.1 类型分类

```
水下机器人类型:
├── AUV (Autonomous Underwater Vehicle)
│   └── 自主潜航，无缆，自包含
│   典型: BlueROV, OpenUC2, OceanOne
├── ROV (Remotely Operated Vehicle)
│   └── 有缆操控，可悬停，大负载
│   典型: Phantom, Tiger, Insight
├── AUG (Autonomous Underwater Glider)
│   └── 滑翔运动，超长续航
│   典型: Slocum, Seaglider
└── UUV (Unmanned Underwater Vehicle)
    └── 军事/工业大型水下潜航器
```

### 1.2 结构特点

```
AUV 典型结构:
         ┌─────────────┐
         │ 压力舱      │ ← 电子舱密封
         ├─────────────┤
    ┌────┤ 传感器舱    ├────┐
    │    └─────────────┘    │
    │                       │
 推进器                   推进器
    │                       │
    └───────┬───────────────┘
            │
       ┌────┴────┐
       │ 电池舱   │
       └─────────┘
```

### 1.3 关键特性

| 特性 | 说明 | 技术挑战 |
|------|------|----------|
| 水声通信 | 唯一可靠的深海无线通信 | 低带宽、高延迟、多径效应 |
| 声学定位 | GPS 不可用，声学代替 | 长基线(LBL)/短基线(SBL)/超短基线(USBL) |
| 深度感知 | 声呐代替视觉 | 噪声抑制、目标检测 |
| 动力学 | 非线性、耦合强 | 6-DOF 建模、推进器配置 |
| 能源 | 水下无法充电 | 能源管理、路径规划 |

---

## 2. 感知 (Perception) 特性

### 2.1 传感器配置

```yaml
underwater_sensors:
  # 声学感知
  sonar:
    - name: forward_looking_sonar
      type: FLS  # Forward-Looking Sonar
      frequency: 675 kHz / 1300 kHz
      range: 50 m / 200 m
      fov: 120° x 20°
      topics: [/sonar/image, /sonar/pointcloud]

    - name: imaging_sonar
      type: sector_scan
      resolution: 0.01 m

    - name: multibeam
      type: MBES  # Multibeam EchoSounder
      beams: 512
      range: 300 m

    - name: sidescan
      type: SSS  # Side-Scan Sonar
      resolution: 1 cm
      swath: 600 m

  # 惯性导航
  imu:
    - name: depth_imu
      type: AHRS
      topics: [/imu/data, /imu/mag]

  # 深度感知
  depth:
    - name: pressure_sensor
      type: fluid_pressure
      accuracy: 0.1% FS
      topics: [/pressure/depth]

  # 视觉 (浅水)
  cameras:
    - name: front_camera
      type: narrow_baseline_stereo
      lights: 2x LED 5000lm
      topics: [/camera/left/image, /camera/right/image]

  # 高度计
  altimeter:
    - name: dvl
      type: Doppler_Velocity_Log
      accuracy: 0.1% of distance
      max_altitude: 200 m
```

### 2.2 声呐成像原理

```
前视声呐 (FLS) 工作原理:
发射器 → 声波脉冲 → 扇形扫描区域 → 障碍物反射 → 接收器
           ↓
      距离 = 声速 × 时间 / 2
      强度 = 反射率 × 距离衰减
```

### 2.3 VibeCoding 提示词模板

```
## 声呐图像目标检测

请基于前视声呐图像实现目标检测技能:
- 声呐图像预处理 (自适应阈值、形态学滤波)
- 目标提取 (连通域分析、形状特征)
- 目标跟踪 (卡尔曼滤波、匈牙利匹配)
- 输出: 目标位置(x,y) 和 置信度

## 水下 SLAM

请基于声呐数据实现 SLAM:
- 声呐点云配准 (ICP、GICP)
- 回环检测 (声学特征匹配)
- 建图 (占据栅格、八叉树)
- 定位 (粒子滤波、图优化)
```

---

## 3. 定位 (Localization) 特性

### 3.1 水下定位方案

```
AUV 定位技术对比:

| 方案 | 精度 | 范围 | 延迟 | 成本 |
|-------|------|------|------|------|
| DVL + IMU + Depth | ±0.1% OD | 200m | 实时 | 中 |
| USBL | ±0.1m | 10km | <1s | 高 |
| LBL | ±0.01m | 10km | <1s | 很高 |
| 声学里程计 | ±1% OD | 无限制 | 实时 | 低 |
| 视觉里程计 (浅水) | ±1cm | 10m | 实时 | 中 |
| 地球物理导航 | ±10m | 全球 | 离线 | 低 |
```

### 3.2 DVL-IMU 融合

```yaml
ekf_filter:
  ros__parameters:
    frequency: 50.0
    odom0: /dvl/odom
    odom0_config: [true, true, false,
                   false, false, false,
                   true, true, false,
                   false, false, false,
                   false, false, false]
    odom1: /imu/data
    odom1_config: [false, false, false,
                   true, true, true,
                   false, false, false,
                   true, true, true,
                   false, false, false]
    odom2: /depth_sensor
    odom2_config: [false, false, true,
                   false, false, false,
                   false, false, false,
                   false, false, false,
                   false, false, false]
```

### 3.3 水声定位

```
USBL (Ultra-Short Baseline) 原理:
母船 ──── 基线阵列 ───┐
    │ < 1m 基线 │
    │            │
    │    声学应答器
    │       ↘
    │    AUV (目标)
    ↓
角度测量: θ (方位), φ (俯仰)
距离: R (声学信号时延 × 声速 / 2)
位置 = [R·cos(φ)·sin(θ), R·cos(φ)·cos(θ), R·sin(φ)]
```

### 3.4 VibeCoding 提示词模板

```
## 水下定位系统

请实现 DVL-IMU-深度计融合定位:
- 扩展卡尔曼滤波 (EKF) 状态估计
- 坐标系: NED (北东地)
- 状态向量: [x, y, z, vx, vy, vz, roll, pitch, yaw]
- 传感器: DVL (速度), IMU (姿态), 压力传感器 (深度)

## 声学定位

请实现 USBL 定位模块:
- 水声调制解调器通信
- 时延估计 → 距离计算
- 角度测量 → 方位估计
- 坐标变换: 母船坐标系 → NED 坐标系
```

---

## 4. 导航 (Navigation) 特性

### 4.1 AUV 导航系统

```yaml
auv_navigation:
  # 导航模式
  modes:
    - waypoint_following     # 航点跟踪
    - path_following         # 路径跟踪
    - terrain_following       # 地形跟踪 (DVL)
    - station_keeping        # 定点保持
    - auto_homing           # 自动归航

  # 安全限制
  limits:
    max_depth: 100.0         # m
    max_speed: 2.0           # m/s
    min_altitude: 3.0        # m (DVL 要求)
    max_gradient: 30.0      # ° (地形适应)

  # 避障
  obstacle_avoidance:
    type: potential_field    # 或 RRT*
    sonar_range: 10.0        # m
    threshold: 0.5          # 安全距离
```

### 4.2 路径规划

```
水下路径规划约束:
├── 深度约束 (最小深度、最大深度)
├── 地形约束 (DVL 高度 > 最小高度)
├── 障碍约束 (声呐检测到的物体)
├── 能耗约束 (路径最短/能耗最低)
└── 水流约束 (逆流耗能大，顺流省能)
```

### 4.3 VibeCoding 提示词模板

```
## AUV 路径规划

请实现 AUV 路径规划技能:
- A* / RRT* 全局规划
- 动态窗口法 (DWA) 局部规划
- 深度约束下的 3D 路径
- 地形跟踪模式 (保持 DVL 高度)
- 避障响应 (声呐检测到障碍时重规划)

## 定点保持 (Station Keeping)

请实现定点保持控制器:
- PID / MPC 控制
- 推力分配 (多推进器配置)
- 洋流补偿 (DVL 测速反馈)
- 能耗优化 (最小能耗推力分配)
```

---

## 5. 技能规划 (Skill Planning) 特性

### 5.1 水下机器人技能分类

```
水下机器人技能体系:
├── 感知技能
│   ├── sonar-perception        ✅ 已开发
│   ├── sonar-image-processing
│   ├── dvl-processing
│   └── underwater-vision
├── 控制技能
│   ├── auv-control             ✅ 已开发
│   ├── depth-control
│   ├── heading-control
│   └── station-keeping
├── 导航技能
│   ├── underwater-slam
│   ├── acoustic-localization
│   └── path-planning
├── 通信技能
│   ├── underwater-modem
│   └── acoustic-telemetry
└── 任务技能
    ├── pipeline-inspection      # 管道巡检
    ├── cable-tracking          # 光缆跟踪
    └── seabed-mapping         # 海底测绘
```

### 5.2 技能描述模板

```yaml
skill_name: underwater-pipeline-inspection
description: >
  水下管道巡检技能 - 基于侧扫声呐的管道检测、
  跟踪控制、缺陷识别、ROS2 部署

argument-hint:
  - 水下管道巡检
  - pipeline inspection
  - 声呐管道检测

entry_point: >
  当需要以下任务时使用此技能:
  1. 沿管道飞行并保持恒定高度
  2. 检测管道缺陷 (弯曲、泄漏、悬空)
  3. 生成管道巡检报告

required_skills:
  - sonar-perception
  - auv-control
  - path-planning
```

### 5.3 VibeCoding 提示词模板

```
## 水下机器人技能开发

请按照以下模板为水下机器人开发技能:
1. 分析任务需求，确定感知→决策→执行链路
2. 定义技能接口 (ROS2 topic/service/action)
3. 实现核心算法 (参考仿真环境和实机部署)
4. 编写故障排查章节

技能应具备:
- 可运行的 ROS2 代码示例
- Gazebo / UUV Simulator 仿真配置
- 仿真到实机的迁移指南 (Sim2Real)
```

---

## 6. 仿真环境

### 6.1 UUV Simulator

```bash
# 安装 UUV 仿真器
sudo apt install -y ros-humble-uuv-simulator

# 启动 AUV 仿真
ros2 launch uuv_simulator empty_auv.launch.py
```

### 6.2 声呐仿真

```xml
<!-- Gazebo 声呐插件配置 -->
<plugin name="gazebo_ros_sonar"
        filename="libgazebo_ros_range_sensor.so">
  <ros>
    <namespace>/sonar</namespace>
    <remapping>~/out:=scan</remapping>
  </ros>
  <ray>
    <scan>
      <horizontal>
        <samples>512</samples>
        <resolution>1</resolution>
        <min_angle>-1.047</min_angle>
        <max_angle>1.047</max_angle>
      </horizontal>
    </scan>
    <range>
      <min>0.1</min>
      <max>50.0</max>
      <resolution>0.01</resolution>
    </range>
  </ray>
</plugin>
```

---

## 7. 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| DVL 丢锁 | 高度太大/水体浑浊 | 降低高度，检查窗口清洁 |
| USBL 定位跳变 | 多径传播 | 增加卡尔曼滤波平滑 |
| 深度控制振荡 | PID 参数不当 | 调整深度 PID，增大约分时间 |
| 推进器推力不足 | 水下压力/螺旋桨缠绕 | 检查螺旋桨清洁度 |
| 声呐图像噪声大 | 增益设置过高 | 调整自动增益控制 (AGC) |
| 里程计漂移大 | DVL 底部丢失 | 启动 GPS 信标修正 (水面时) |

### 调试命令

```bash
# 监听深度
ros2 topic echo /pressure/depth

# 监听 DVL
ros2 topic echo /dvl/odom

# 监听声呐
ros2 topic echo /sonar/scan

# 校准压力传感器
ros2 service call /calibrate_depth std_srvs/srv/Trigger

# 查看 AUV 状态
ros2 topic echo /auv/state
```

---

## 相关资源

- **声呐感知技能**: `agents/skills/underwater/sonar-perception/SKILL.md`
- **AUV 控制技能**: `agents/skills/underwater/auv-control/SKILL.md`
- **仿真环境**: `agents/skills/simulator/gazebo-harmonic/gazebo-simulation-env/SKILL.md`
- **传感器融合**: `agents/skills/perception/sensor-fusion/kalman-filtering/SKILL.md`
- **多智能体**: `agents/skills/system-integration/multi-agent-swarm/SKILL.md`

---

*最后更新: 2026-04-03*
