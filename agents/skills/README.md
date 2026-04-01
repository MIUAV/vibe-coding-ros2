# Skills

> 可直接在 AI 开发中使用的模块化技能

---

## 目录结构

```
skills/
├── common/                    # 通用 ROS2 开发技能
│   ├── ros2-package-generator/
│   ├── ros2-debugging/
│   ├── arm64-cross-compile/
│   ├── ros2-action-communication/
│   ├── ros2-component/
│   ├── ros2-distributed-communication/
│   ├── ros2-interface-definition/
│   ├── ros2-launch-advanced/
│   ├── ros2-lifecycle/
│   ├── ros2-parameter-management/
│   ├── ros2-service-communication/
│   ├── ros2-time-management/
│   └── ros2-topic-communication/
│
├── edge-platforms/            # 边缘计算平台
│   ├── rockchip-rknn/              # 瑞芯微 RKNN
│   │   ├── rknn-model-conversion/ # 模型转换
│   │   ├── rknn-inference-runtime/# 推理运行时
│   │   ├── rknn-camera-driver/    # 相机驱动
│   │   └── rknn-npu-profiling/    # NPU性能分析
│   ├── nvidia-cuda/                # CUDA编程
│   │   ├── cuda-programming/       # 编程基础
│   │   ├── cuda-optimization/      # 性能优化
│   │   ├── cuda-libraries/         # 加速库
│   │   └── cuda-profiling/         # 性能分析
│   ├── nvidia-jetpack/             # Jetson开发
│   │   ├── jetpack-setup/          # 环境配置
│   │   ├── deepstream/             # 视频分析
│   │   ├── tensorrt/               # 推理优化
│   │   └── ros2-integration/       # ROS2集成
│   └── digiwheel-sunrise/         # 地瓜旭日
│       ├── sunrise-sdk/           # SDK开发
│       ├── sunrise-toolchain/     # 交叉编译
│       ├── sunrise-perception/    # 视觉感知
│       └── sunrise-robotics/      # 机器人应用
│
├── multi_rotor_uav/           # 多旋翼无人机 (PX4)
│   ├── perception/            # 感知类
│   │   ├── px4-sensor-config/
│   │   └── px4-vision-nav/
│   ├── localization/          # 定位类
│   │   └── px4-multicopter-dev/
│   ├── navigation/            # 导航类
│   │   ├── px4-debug-logging/
│   │   ├── px4-flight-mode/
│   │   └── px4-mc-tuning/
│   ├── skill-planning/        # 技能规划类
│   │   └── px4-ros2/
│   └── action/                # 执行类
│       ├── px4-firmware-build/
│       ├── px4-airframe/
│       ├── px4-dev-env/
│       ├── px4-module-dev/
│       └── px4-mavlink/
│
├── quadruped/                 # 四足机器人
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── navigation/            # 导航类
│   ├── motion-control/        # 运动控制类
│   └── skill-planning/        # 技能规划类
│
├── humanoid/                  # 人形机器人
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── navigation/            # 导航类
│   └── skill-planning/        # 技能规划类
│
├── manipulator/               # 机械臂
│   ├── perception/            # 感知类
│   ├── localization/          # 定位类
│   ├── motion-control/        # 运动控制类
│   └── skill-planning/        # 技能规划类
│
└── wheeled_vehicle/           # 轮式车辆
    ├── perception/            # 感知类
    ├── localization/          # 定位类
    ├── navigation/            # 导航类
    └── action/                # 执行类
```

---

## 可用技能

### 通用技能 (common/)

#### ROS2 包生成器

**路径**: `./common/ros2-package-generator/SKILL.md`

**功能**: 生成完整的 ROS2 功能包结构

**触发词**: "创建一个 ROS2 包" / "generate ros2 package"

---

#### ROS2 调试

**路径**: `./common/ros2-debugging/SKILL.md`

**功能**: ROS2 节点调试、话题分析、bag 回放

**触发词**: "调试 ROS2" / "ros2 debug"

---

#### ARM64 交叉编译

**路径**: `./common/arm64-cross-compile/SKILL.md`

**功能**: 配置 x86 到 ARM64 交叉编译环境

**触发词**: "交叉编译 ARM" / "cross compile ARM"

---

### 多旋翼无人机 (multi_rotor_uav/)

#### 感知类 (perception)

##### PX4 传感器配置

**路径**: `./multi_rotor_uav/perception/px4-sensor-config/SKILL.md`

**功能**: PX4 传感器校准与配置

**触发词**: "传感器校准" / "px4 sensor" / "配置传感器"

---

##### PX4 视觉导航

**路径**: `./multi_rotor_uav/perception/px4-vision-nav/SKILL.md`

**功能**: PX4 视觉导航与避障

**触发词**: "视觉导航" / "px4 vision" / "视觉避障"

---

#### 定位类 (localization)

##### PX4 多旋翼开发

**路径**: `./multi_rotor_uav/localization/px4-multicopter-dev/SKILL.md`

**功能**: PX4 SITL 仿真环境设置与运行

**触发词**: "PX4仿真" / "px4 sitl" / "启动仿真"

---

#### 导航类 (navigation)

##### PX4 调试与日志

**路径**: `./multi_rotor_uav/navigation/px4-debug-logging/SKILL.md`

**功能**: PX4 调试与日志分析

**触发词**: "PX4调试" / "px4 debug" / "日志分析"

---

##### PX4 飞行模式

**路径**: `./multi_rotor_uav/navigation/px4-flight-mode/SKILL.md`

**功能**: PX4 飞行模式与任务规划

**触发词**: "飞行模式" / "px4 mode" / "任务规划"

---

##### PX4 多旋翼调参

**路径**: `./multi_rotor_uav/navigation/px4-mc-tuning/SKILL.md`

**功能**: PX4 多旋翼 PID 参数调节与自动调参

**触发词**: "多旋翼调参" / "px4 tuning" / "PID调节"

---

#### 技能规划类 (skill-planning)

##### PX4 ROS2 集成

**路径**: `./multi_rotor_uav/skill-planning/px4-ros2/SKILL.md`

**功能**: PX4 ROS2 集成与控制

**触发词**: "PX4 ROS2" / "MAVROS" / "Offboard控制"

---

#### 执行类 (action)

##### PX4 固件构建

**路径**: `./multi_rotor_uav/action/px4-firmware-build/SKILL.md`

**功能**: PX4 固件编译与烧录

**触发词**: "编译PX4" / "px4 build" / "烧录固件"

---

##### PX4 机架配置

**路径**: `./multi_rotor_uav/action/px4-airframe/SKILL.md`

**功能**: PX4 机架配置与电机映射

**触发词**: "机架配置" / "px4 airframe" / "电机配置"

---

##### PX4 开发环境

**路径**: `./multi_rotor_uav/action/px4-dev-env/SKILL.md`

**功能**: PX4 开发环境配置

**触发词**: "配置PX4开发环境" / "安装工具链" / "Docker开发"

---

##### PX4 模块开发

**路径**: `./multi_rotor_uav/action/px4-module-dev/SKILL.md`

**功能**: PX4 模块/应用程序开发

**触发词**: "开发PX4模块" / "px4 module" / "创建应用"

---

##### PX4 MAVLink 通信

**路径**: `./multi_rotor_uav/action/px4-mavlink/SKILL.md`

**功能**: PX4 MAVLink 通信配置

**触发词**: "MAVLink配置" / "px4 mavlink" / "数传配置"

---

##### QGC/MP 地面站故障排查

**路径**: `./multi_rotor_uav/action/qgc-ground-station/SKILL.md`

**功能**: QGC/MP 地面站连接问题、串口配置、视频流、参数同步

**触发词**: "QGC故障" / "QGC连接" / "地面站排查" / "MP连接问题"

---

##### PX4 AirSim 联合开发

**路径**: `./multi_rotor_uav/action/px4-airsim-integration/SKILL.md`

**功能**: AirSim 仿真器配置、视觉/激光雷达仿真、多无人机协同、HITL

**触发词**: "AirSim仿真" / "PX4 AirSim" / "联合仿真" / "AirSim开发"

---

### 四足机器人 (quadruped/)

四足机器人技能按功能分为以下类别：

#### 感知类 (perception)

**路径**: `./quadruped/perception/SKILL.md`

**功能**: 视觉感知、激光雷达、传感器融合

**触发词**: "四足视觉" / " quadruped perception" / "目标检测"

---

#### 定位类 (localization)

**路径**: `./quadruped/localization/SKILL.md`

**功能**: SLAM、IMU融合、EKF、GPS/RTK定位

**触发词**: "四足定位" / "quadruped slam" / "机器人定位"

---

#### 导航类 (navigation)

**路径**: `./quadruped/navigation/SKILL.md`

**功能**: 路径规划、障碍物检测、地形适应

**触发词**: "四足导航" / "quadruped navigation" / "路径规划"

---

#### 运动控制类 (motion-control)

**路径**: `./quadruped/motion-control/SKILL.md`

**功能**: 步态规划、平衡控制、力控制

**触发词**: "四足步态" / "quadruped gait" / "平衡控制"

---

#### 技能规划类 (skill-planning)

**路径**: `./quadruped/skill-planning/SKILL.md`

**功能**: 行为树、状态机、强化学习、模仿学习

**触发词**: "四足技能" / "quadruped RL" / "行为树"

---

### 其他机器人类型

#### 人形机器人 (humanoid/)

##### 感知类 (perception)

**路径**: `./humanoid/perception/SKILL.md`

**功能**: 双目视觉、深度感知、触觉反馈、平衡感知

**触发词**: "人形感知" / "人形视觉" / "平衡感知"

---

##### 定位类 (localization)

**路径**: `./humanoid/localization/SKILL.md`

**功能**: SLAM、IMU融合、姿态估计、GPS/RTK定位

**触发词**: "人形定位" / "人形SLAM" / "位置估计"

---

##### 导航类 (navigation)

**路径**: `./humanoid/navigation/SKILL.md`

**功能**: 双足路径规划、动态避障、CoM轨迹规划

**触发词**: "人形导航" / "双足路径规划" / "动态避障"

---

##### 技能规划类 (skill-planning)

**路径**: `./humanoid/skill-planning/SKILL.md`

**功能**: 行为树、状态机、双手协调、强化学习

**触发词**: "人形技能" / "行为树" / "双手协调"

---

#### 机械臂 (manipulator/)

##### 感知类 (perception)

**路径**: `./manipulator/perception/SKILL.md`

**功能**: 视觉引导、深度感知、力矩感知、触觉反馈

**触发词**: "机械臂感知" / "视觉引导" / "力矩感知"

---

##### 定位类 (localization)

**路径**: `./manipulator/localization/SKILL.md`

**功能**: 末端执行器标定、手眼标定、TCP标定

**触发词**: "机械臂定位" / "手眼标定" / "末端定位"

---

##### 运动控制类 (motion-control)

**路径**: `./manipulator/motion-control/SKILL.md`

**功能**: 逆运动学、轨迹规划、阻抗控制、协作控制

**触发词**: "机械臂控制" / "轨迹规划" / "力控"

---

##### 技能规划类 (skill-planning)

**路径**: `./manipulator/skill-planning/SKILL.md`

**功能**: 抓取规划、任务规划、行为树、模仿学习

**触发词**: "机械臂任务" / "抓取规划" / "模仿学习"

---

#### 轮式车辆 (wheeled_vehicle/)

##### 感知类 (perception)

**路径**: `./wheeled_vehicle/perception/SKILL.md`

**功能**: 视觉感知、激光雷达、障碍物检测、车道线识别

**触发词**: "轮式感知" / "车辆视觉" / "障碍物检测"

---

##### 定位类 (localization)

**路径**: `./wheeled_vehicle/localization/SKILL.md`

**功能**: GNSS/RTK、SLAM、IMU融合、里程计

**触发词**: "车辆定位" / "GPS定位" / "RTK"

---

##### 导航类 (navigation)

**路径**: `./wheeled_vehicle/navigation/SKILL.md`

**功能**: 全局路径规划、轨迹跟踪、MPC避障

**触发词**: "车辆导航" / "路径规划" / "轨迹跟踪"

---

##### 执行类 (action)

**路径**: `./wheeled_vehicle/action/SKILL.md`

**功能**: 底盘控制、差速驱动、阿克曼转向、稳定性控制

**触发词**: "车辆控制" / "底盘驱动" / "转向控制"

---

## 使用方法

### VS Code Copilot

```
# 在对话中使用
@skills/common/ros2-package-generator 创建新的感知包
@skills/multi_rotor_uav/px4-sitl 启动仿真
```

### Cursor

```
# 使用快捷命令
/ros2-create-pkg
/px4-sitl
```

---

## 创建新技能

参考 `./common/ros2-package-generator/SKILL.md` 格式创建新技能。
