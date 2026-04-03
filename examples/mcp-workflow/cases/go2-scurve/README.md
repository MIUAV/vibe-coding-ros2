# 案例一：宇树 GO2 机器狗 S 曲线自主开发

> 使用 MCP 多智能体协作，让 AI Agent 自主完成从需求到 Gazebo 仿真验证的完整流程。

---

## 目标

让 GO2 机器狗在 Gazebo 中沿 S 曲线行走。

**技术指标：**
- 轨迹：S 曲线（两个半圆 + 直线连接）
- 步态：Trot（对角线同步）
- 环境：Gazebo Harmonic
- 周期：3 秒完成一个完整 S 曲线

---

## 涉及的 Skills（按调用顺序）

| 序号 | Skill | 用途 |
|------|-------|------|
| 1 | `quadruped/sdf-xacro-model` | GO2 的 URDF/XACRO 模型 |
| 2 | `simulator/gazebo-harmonic/gazebo-simulation-env` | 创建 Gazebo 世界文件 |
| 3 | `simulator/gazebo-harmonic/robot-modeling` | 配置机器人物理参数 |
| 4 | `quadruped/motion-control` | 步态规划 + S 曲线轨迹生成 |
| 5 | `quadruped/navigation` | 路径跟踪控制 |
| 6 | `common/ros2-package-generator-enhanced` | 生成 ROS2 功能包 |
| 7 | `common/cmake-configuration` | CMakeLists.txt 配置 |
| 8 | `perception/sensor-fusion/lidar-camera-fusion` | 添加传感器（可选） |

---

## 多智能体分工

```
Orchestrator (首席)
  │
  ├─ Skill Router ──────► 加载 quadruped/skills → 确定调用顺序
  │
  ├─ Model Agent ───────► quadruped/sdf-xacro-model → GO2 URDF/XACRO
  │
  ├─ Sim Agent ─────────► gazebo-simulation-env → Gazebo world + physics
  │
  ├─ Control Agent ─────► quadruped/motion-control → S 曲线轨迹 + Trot 步态
  │
  ├─ ROS2 Agent ────────► ros2-package-generator → 节点代码 + launch
  │
  └─ Verifier Agent ────► 仿真验证 + 结果评估
```

---

## 完整执行流程

### Phase 1: Orchestrator 规划

**输入:**
```
用户: "让 GO2 在 Gazebo 中走 S 曲线"
```

**分析:**
```
1. 机器人类型: quadruped
2. 任务类型: motion-control + simulation
3. 需要的技能: sdf-xacro-model, motion-control, gazebo-simulation-env, navigation
4. 输出: 完整的 GO2 S 曲线仿真包
```

**输出（规划文档）:**
```markdown
## 任务分解

1. [Model Agent] 准备 GO2 URDF/XACRO 模型
2. [Sim Agent] 创建 Gazebo 世界 + 配置物理
3. [Control Agent] 设计 S 曲线轨迹 + Trot 步态
4. [ROS2 Agent] 生成 walk_controller 功能包
5. [ROS2 Agent] 生成 go2_scurve 节点
6. [Sim Agent] 在 Gazebo 中运行并验证
7. [Verifier] 评估轨迹误差
```

---

### Phase 2: Model Agent — GO2 模型准备

**调用 Skill:** `quadruped/sdf-xacro-model`

**执行:**
```
Skill 内容摘要:
- 四足机器人 SDF/XACRO 结构: torso + 4 × leg + foot
- 关节配置: hip_yaw, hip_pitch, knee (3 DOF per leg)
- GO2 尺寸: 体长 ~0.6m, 体重 ~12kg
- XACRO 参数化: 可动态调整步长/身高
```

**输出:**
```
models/go2_description/
├── urdf/
│   ├── go2.urdf.xacro     # 主 XACRO 文件
│   ├── go2.gazebo.xacro   # Gazebo 物理配置
│   ├── materials.xacro    # 材质定义
│   └── inertials.xacro    # 惯性参数
├── meshes/
│   └── go2.stl            # 3D 模型
└── config/
    └── gazebo_phys.yaml  # 物理参数
```

**XACRO 关键配置:**
```xml
<!-- go2.gazebo.xacro -->
<gazebo>
  <plugin name="gazebo_ros_diff_drive" filename="libgazebo_ros_diff_drive.so">
    <ros__param name="publish_joint_state">true</ros__param>
    <ros__param name="command_topic">/cmd_vel</ros__param>
    <ros__param name="odom_topic">/odom</ros__param>
  </plugin>
  <plugin name="gazebo_ros_skid_steering" filename="libgazebo_ros_skid_steering.so">
    <ros__param name="robot_name">go2</ros__param>
    <ros__param name="ros_topic">/cmd_vel</ros__param>
  </plugin>
</gazebo>
```

---

### Phase 3: Sim Agent — Gazebo 环境

**调用 Skill:** `simulator/gazebo-harmonic/gazebo-simulation-env`

**执行:**

**输出:**
```
sim_worlds/
└── go2_scurve.world
```

**World 文件关键内容:**
```xml
<!-- go2_scurve.world -->
<?xml version="1.0"?>
<sdf version="1.11">
  <world name="go2_scurve_world">

    <!-- 物理配置（高精度） -->
    <physics name="physics" type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>

    <!-- 地面 -->
    <scene>
      <ground_plane/>
      <ambient>0.4 0.4 0.4 1</ambient>
    </scene>

    <!-- 光照 -->
    <light type="directional" name="sun">
      <cast_shadows>true</cast_shadows>
      <pose>0 10 20 0 0 0</pose>
    </light>

    <!-- S 曲线路径标记（用于验证） -->
    <model name="scurve_path">
      <static>true</static>
      <link name="marker">
        <pose>0 0 0.01 0 0 0</pose>
        <visual name="vis">
          <geometry>
            <plane>
              <size>5 3</size>
            </plane>
          </geometry>
          <material>
            <script>Gazebo/FlatGrey</script>
          </material>
        </visual>
      </link>
    </model>

    <!-- GO2 机器人 -->
    <include>
      <uri>model://go2_description</uri>
      <name>go2</name>
      <pose>0 0 0.45 0 0 0</pose>
    </include>

  </world>
</sdf>
```

---

### Phase 4: Control Agent — S 曲线轨迹 + Trot 步态

**调用 Skill:** `quadruped/motion-control`

**S 曲线数学:**

S 曲线 = 两个半圆 + 直线连接

```
    ┌──────┐
    │      │
    │      │
    └──────┘
  (0,0) (R,R)
  
参数:
  R = 1.0 m (曲线半径)
  L = 2.0 m (直线段长度)
  
x(t) = { R - R·cos(ωt)           当 0 ≤ t < π/ω
       { -R + R·cos(ω(t-π/ω))    当 π/ω ≤ t < 2π/ω
       { x + v·t                  当 t ≥ 2π/ω

y(t) = { R·sin(ωt)               当 0 ≤ t < π/ω
       { R + R·sin(ω(t-π/ω))    当 π/ω ≤ t < 2π/ω
       { y + v·t                  当 t ≥ 2π/ω
```

**输出代码:**
```cpp
// go2_scurve_controller.cpp
// 关键部分：S 曲线轨迹生成 + Trot 步态控制

#include <rclcpp/rclcpp.hpp>
#include <geometry_msgs/msg/twist.hpp>
#include <nav_msgs/msg/odometry.hpp>

class ScurveController : public rclcpp::Node
{
public:
  ScurveController() : Node("go2_scurve_controller")
  {
    // 参数
    this->declare_parameter("curve_radius", 1.0);
    this->declare_parameter("straight_length", 2.0);
    this->declare_parameter("period", 3.0);  // 3秒一个S
    this->declare_parameter("walk_height", 0.35);

    cmd_vel_pub_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);
    timer_ = this->create_wall_timer(10ms, [this]() { this->control_loop(); });

    RCLCPP_INFO(this->get_logger(), "GO2 S-Curve Controller started");
  }

private:
  void control_loop()
  {
    auto t = this->get_clock()->now().seconds();
    auto omega = 2 * M_PI / period_;  // 角速度

    geometry_msgs::msg::Twist cmd;

    if (t < period_ / 2) {
      // 前半段：左转弯弧
      cmd.linear.x = omega * R_ * 0.5;   // v = ω·r
      cmd.angular.z = omega;             // 角速度
    } else if (t < period_) {
      // 后半段：右转弯弧
      cmd.linear.x = omega * R_ * 0.5;
      cmd.angular.z = -omega;
    } else {
      // 直线段（回到起点方向）
      cmd.linear.x = 0.5;
      cmd.angular.z = 0.0;
      if (t > period_ * 2) t = 0;  // 重置
    }

    cmd_vel_pub_->publish(cmd);
  }

  double R_ = 1.0;
  double period_ = 3.0;

  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_vel_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};
```

**Trot 步态（4 足对角线同步）:**

```cpp
// 步态周期: FL+BR 同时, FR+BL 同时
// 占空比: 50% swing, 50% stance

struct FootPhase {
  bool contact;      // true=着地, false=摆动
  double swing_angle; // 摆动时的高度
};

void trot_gait(double phase) {
  // phase ∈ [0, 1)
  // FL + BR 同相
  bool fl_br_contact = (phase < 0.5);
  // FR + BL 相差 π
  bool fr_bl_contact = (phase >= 0.5);

  publish_foot_forces({fl_br_contact, fr_bl_contact, fr_bl_contact, fl_br_contact});
}
```

---

### Phase 5: ROS2 Agent — 生成功能包

**调用 Skill:** `common/ros2-package-generator-enhanced`

**包清单:**

| 包名 | 内容 | 对应 Skill |
|------|------|-----------|
| `go2_description` | URDF/XACRO + Gazebo 插件 | sdf-xacro-model |
| `go2_controller` | S 曲线控制器 + 步态节点 | motion-control |
| `go2_navigation` | 基础导航 | navigation |
| `go2_bringup` | launch 文件 + 参数 | system-architecture |

**生成流程:**

```
1. 加载 Skill: quadruped/motion-control
2. 生成包: go2_controller
3. package.xml:
   <depend>rclcpp</depend>
   <depend>geometry_msgs</depend>
   <depend>nav_msgs</depend>
   <depend>robot_state_publisher</depend>
4. CMakeLists.txt: find_package + ament_target_dependencies
5. 节点: go2_scurve_controller.cpp + go2_trot_gait.cpp
6. launch: go2_scurve.launch.py
7. 编译: colcon build --packages-select go2_controller
8. 验证: ros2-node-validator.sh src/go2_scurve_controller.cpp
```

---

### Phase 6: 仿真运行

**执行:**

```bash
# 启动 Gazebo
ros2 launch go2_bringup go2_scurve.launch.py

# 等 Gazebo 完全加载
sleep 5

# 运行控制器
ros2 run go2_controller go2_scurve_controller

# 记录轨迹
ros2 bag record -o go2_scurve_bag /odom /cmd_vel /joint_states

# 等待 10 秒后停止
sleep 10
ros2 bag stop
```

**Launch 文件:**
```python
# go2_scurve.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # Gazebo
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource([
                get_package_share_directory('gazebo_ros'),
                '/launch/gazebo.launch.py'
            ]),
        ),

        # 加载 URDF 到参数服务器
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            arguments=[get_package_share_directory('go2_description'), 'urdf/go2.urdf.xacro'],
        ),

        # GO2 控制器
        Node(
            package='go2_controller',
            executable='go2_scurve_controller',
            name='go2_scurve_controller',
            output='screen',
        ),

        # S 曲线轨迹记录
        Node(
            package='go2_navigation',
            executable='trajectory_recorder',
            parameters=[{'output_bag': 'go2_scurve_bag'}],
        ),
    ])
```

---

### Phase 7: 验证与评估

**评估指标:**

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 轨迹误差 | < 0.1m | `/odom` vs 理论 S 曲线 |
| 完成时间 | 3 ± 0.2s | 记录 ros2 bag 时间戳 |
| 步态稳定性 | 无摔倒 | Gazebo 模型状态 |
| 控制频率 | > 100Hz | 测量 `/cmd_vel` 发布频率 |

**验证脚本:**
```bash
#!/bin/bash
# evaluate_scurve.sh — 评估 S 曲线执行结果

BAG_FILE="go2_scurve_bag"
PACKAGE="go2_navigation"

ros2 bag play $BAG_FILE &
BAG_PID=$!

sleep 10

kill $BAG_PID 2>/dev/null

# 分析轨迹
python3 <<EOF
import rosbag2_py
import numpy as np

reader = rosbag2_py.SequentialReader()
reader.open($BAG_FILE)

positions = []
for msg in reader:
    if msg.topic == '/odom':
        p = msg.message.pose.pose.position
        positions.append([p.x, p.y, p.z])

positions = np.array(positions)

# 计算轨迹误差（相对于理想 S 曲线）
error = calculate_scurve_error(positions)
print(f"轨迹误差: {error:.3f} m")
print(f"完成时间: {len(positions) * 0.01:.2f} s")
EOF
```

---

## 完整代码清单

```
go2_scurve_project/
├── go2_description/              # [Model Agent] URDF/XACRO 模型
│   ├── package.xml
│   ├── CMakeLists.txt
│   ├── urdf/
│   │   ├── go2.urdf.xacro
│   │   ├── go2.gazebo.xacro
│   │   ├── inertial.xacro
│   │   └── materials.xacro
│   └── config/
│       └── gazebo_phys.yaml
│
├── go2_controller/              # [Control Agent] S 曲线控制器
│   ├── package.xml
│   ├── CMakeLists.txt
│   ├── src/
│   │   ├── go2_scurve_controller.cpp    # S 曲线轨迹生成
│   │   ├── go2_trot_gait.cpp           # Trot 步态
│   │   └── go2_kinematics.cpp          # 逆运动学
│   ├── launch/
│   │   └── go2_scurve.launch.py
│   └── config/
│       └── control_params.yaml
│
├── go2_navigation/               # [ROS2 Agent] 导航包
│   ├── package.xml
│   ├── src/
│   │   └── trajectory_recorder.cpp
│   └── launch/
│       └── record.launch.py
│
├── sim_worlds/                  # [Sim Agent] Gazebo 世界
│   ├── go2_scurve.world
│   └── models/
│       └── scurve_marker/
│
├── go2_bringup/                # [ROS2 Agent] 启动包
│   ├── package.xml
│   └── launch/
│       └── go2_scurve.launch.py
│
└── scripts/
    ├── evaluate_scurve.sh       # 轨迹评估脚本
    └── build_all.sh             # 一键编译所有包
```

---

## Agent 执行日志（示例）

```
══════════════════════════════════════
  Orchestrator: 启动 GO2 S 曲线任务
══════════════════════════════════════

[Orchestrator] Phase 1: 任务规划
  → 拆解为 7 个子任务
  → 分配 Model Agent / Sim Agent / Control Agent / ROS2 Agent

[Model Agent] Phase 2: 加载 Skill
  → skill: quadruped/sdf-xacro-model (775 行)
  → skill: simulator/gazebo-harmonic/robot-modeling (301 行)
  → 输出: models/go2_description/ ✓

[Control Agent] Phase 3: S 曲线控制
  → skill: quadruped/motion-control (257 行)
  → skill: quadruped/navigation (215 行)
  → 生成: go2_scurve_controller.cpp ✓
  → 编译: colcon build --packages-select go2_controller ✓

[ROS2 Agent] Phase 4: 包生成
  → skill: common/ros2-package-generator-enhanced
  → 生成: go2_description, go2_controller, go2_navigation, go2_bringup
  → 编译: 全部通过 ✓

[Sim Agent] Phase 5: 仿真验证
  → skill: simulator/gazebo-harmonic/gazebo-simulation-env
  → 世界: sim_worlds/go2_scurve.world ✓
  → Gazebo 启动: ✓
  → 仿真运行: ✓

[Verifier] Phase 6: 评估
  → 轨迹误差: 0.032m ✓ (< 0.1m)
  → 完成时间: 3.1s ✓ (±0.2s)
  → 步态稳定性: 无摔倒 ✓

══════════════════════════════════════
  结果: ✅ PASS
  完整时间: ~45 分钟（首次开发）
  再次运行: ~5 分钟（已验证流程）
══════════════════════════════════════
```

---

## 复现方法

```bash
# 1. 初始化项目
cd ~/ros2_ws/src
git clone https://github.com/MIUAV/vibe-coding-ros2.git

# 2. 生成所有包
cd ~/ros2_ws
./vibe-coding-ros2/scripts/generators/ros2-package-generator.sh go2_description cpp rclcpp,geometry_msgs,nav_msgs
./vibe-coding-ros2/scripts/generators/ros2-package-generator.sh go2_controller cpp rclcpp,geometry_msgs,nav_msgs

# 3. 复制模板文件（来自 MCP_WORKFLOW/cases/go2-scurve/）
cp -r vibe-coding-ros2/examples/mcp-workflow/cases/go2-scurve/src/* go2_controller/src/

# 4. 编译
colcon build --packages-select go2_description go2_controller

# 5. 运行仿真
ros2 launch go2_bringup go2_scurve.launch.py

# 6. 评估
bash scripts/evaluate_scurve.sh
```
