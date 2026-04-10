# 🔀 Development Phase Memory — 自动切换模板

> 当 AI Agent 识别到开发阶段时，自动加载对应模板。
> 将本文件复制到 `agents/memory-bank/active-context.md` 启用。

---

## 加载规则

根据当前开发阶段，启用对应的记忆：

| 阶段 | 特征关键词 | 加载文件 |
|------|-----------|---------|
| 需求分析 | "需求"、"功能定义"、"要做什么" | `1-requirements.md` |
| 架构设计 | "架构"、"接口定义"、"模块划分" | `2-architecture.md` |
| 包骨架生成 | "生成包"、"骨架"、"从零开始" | `3-prototyping.md` |
| 功能开发 | "实现"、"写代码"、"节点逻辑" | `4-implementation.md` |
| 集成测试 | "联调"、"集成"、"仿真验证" | `5-integration.md` |
| 交付运维 | "部署"、"上线"、"持续运行" | `6-deployment.md` |

---

## 1-requirements.md

```markdown
# Phase 1: Requirements Analysis

## 需求分析检查清单

### 机器人平台
- [ ] 机器人类型：轮式/履带/足式/无人机/水面/水下
- [ ] 运动自由度（DOF）数量
- [ ] 传感器配置：激光雷达/相机/IMU/深度相机/GNSS
- [ ] 计算平台：机载（Jetson/NUC）/ 边缘 / 云端

### 感知需求
- [ ] 需要检测/跟踪什么目标？
- [ ] 传感器数据类型：2D/3D 点云 / 图像 / 雷达
- [ ] 感知频率要求（Hz）
- [ ] 是否需要多传感器融合？

### 控制需求
- [ ] 控制模式：手动 / 半自主 / 全自主
- [ ] 控制频率要求（Hz）
- [ ] 是否需要安全急停机制？
- [ ] 是否需要多机协调？

### 通信需求
- [ ] 机器人内部通信：DDS Topic / Service / Action
- [ ] 机器人间通信：WiFi / 5G / 水声 / MAVLink
- [ ] 与地面站通信：ROS2 bridge / MAVROS
- [ ] 延迟要求（ms）

### 环境约束
- [ ] 工作环境：室内/室外/水下/太空
- [ ] GPS 可用性
- [ ] 电磁干扰等级
- [ ] 功耗/算力限制

## 输出格式
1. 机器人平台选型
2. 功能清单（带优先级 P0/P1/P2）
3. 传感器配置方案
4. 软件架构总图（Mermaid）
5. 关键技术风险
```

---

## 2-architecture.md

```markdown
# Phase 2: Architecture Design

## 包结构设计

### 包划分原则
- **功能内聚**：每个包完成一个功能域（感知/规划/控制）
- **接口稳定**：包间通过 msg/srv/action 接口通信，不直接依赖
- **最小依赖**：避免循环依赖，优先树状结构

### 推荐包划分（移动机器人）
```
my_robot/
├── my_robot_bringup/         # launch + config（启动入口）
├── my_robot_description/     # URDF/XACRO + rviz config
├── my_robot_perception/      # 感知节点（雷达/视觉处理）
├── my_robot_nav/            # 导航节点（Nav2）
├── my_robot_control/        # 控制节点（运动控制）
├── my_robot_msgs/           # 专用消息类型（跨包共用）
└── my_robot_hardware/       # 硬件抽象层（driver）
```

### 接口设计

#### Topic 设计（数据流）
| Topic | 发布者 | 订阅者 | 类型 | 频率 |
|-------|--------|--------|------|------|
| `/scan_filtered` | perception | nav | `LaserScan` | 10Hz |
| `/cmd_vel` | nav | control | `Twist` | 50Hz |
| `/odom` | control | nav | `Odometry` | 50Hz |

#### Service 设计（同步调用）
| Service | 服务器 | 客户端 | 用途 |
|---------|--------|--------|------|
| `/reset_odom` | control | nav | 重置里程计 |
| `/save_map` | nav | operator | 保存地图 |

#### Action 设计（长时任务）
| Action | Server | Client | 用途 |
|--------|--------|--------|------|
| `/explore` | nav | operator | 自主探索 |
| `/goto` | nav | operator | 目标导航 |

## 生命周期设计
```
UNCONFIGURED
    ↓ on_configure（加载参数、创建 pubs/subs）
CONFIGURING → INACTIVE
    ↓ on_activate（启用发布/订阅）
ACTIVE ←→ INACTIVE（暂停/恢复）
    ↓ on_cleanup（释放资源）
UNCONFIGURED
    ↓ on_shutdown
FINALIZED
```

## 故障检测设计
- **看门狗**：每个关键 topic 是否有数据（超时报警）
- **心跳**：节点间 heartbeat 机制（检测掉线）
- **降级策略**：GPS 丢失 → 切换视觉定位；激光故障 → 安全停止
```

---

## 3-prototyping.md

```markdown
# Phase 3: Package Prototyping

## 标准包生成命令

### 基础功能包
```bash
# C++ 包（推荐）
bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp rclcpp,rclcpp_lifecycle,std_msgs,geometry_msgs --verify

# Python 包
bash scripts/generators/ros2-package-generator.sh <pkg_name> python rclpy --verify

# 带 Nav2 的包
bash scripts/generators/ros2-package-generator.sh <pkg_name> cpp rclcpp,nav2_msgs,nav2_util,nav2_core --verify
```

### 骨架验证流程
```bash
# 1. colcon build 验证骨架
colcon build --packages-select <pkg_name>

# 2. 启动节点验证基本运行
ros2 run <pkg_name> <node_name>

# 3. 查看 topic
ros2 topic list
ros2 topic echo /<topic_name> --qos-durability rclcpp.SensorDataQoS
```

## CMake 模板（生成后必须验证这三行）
```cmake
# 必须的 3 行导出
ament_export_dependencies(rclcpp std_msgs)              # ← 必加
ament_export_include_directories(include)                 # ← 有include时必加
ament_export_libraries(${PROJECT_NAME})                  # ← 必加
```

## 验证检查表
- [ ] `colcon build --packages-select <pkg>` 无错误
- [ ] `ros2 pkg list | grep <pkg>` 能找到包
- [ ] `ros2 pkg executables <pkg>` 能列出可执行文件
- [ ] launch 文件存在且语法正确
```

---

## 4-implementation.md

```markdown
# Phase 4: Feature Implementation

## 节点开发规范

### Lifecycle 节点实现模板
```cpp
class MyNode : public rclcpp_lifecycle::LifecycleNode {
public:
  MyNode() : LifecycleNode("my_node") {}

  // 5 个必须回调
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "on_configure");
    // 创建 pub/sub/service/action
    return SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "on_activate");
    return SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State&) override {
    return SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State&) override {
    return SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State&) override {
    return SUCCESS;
  }
};
```

## 错误处理规范
```cpp
// 参数校验
if (!this->has_parameter("Kp")) {
  RCLCPP_ERROR(get_logger(), "Parameter 'Kp' not declared");
  return;
}

// 超时处理
rclcpp::Rate rate(10);
while (rclcpp::ok() && !data_received_) {
  rate.sleep();
  rclcpp::spin_some(shared_from_this());
}
if (!data_received_) {
  RCLCPP_ERROR(get_logger(), "Timeout waiting for data");
}
```

## 自测命令
```bash
# 单包编译
colcon build --packages-select <pkg>

# 运行节点
ros2 run <pkg> <node> --ros-args --log-level DEBUG

# 查看 topic 数据
ros2 topic echo /<topic> --once

# 测试 service
ros2 service call /<service> <package>/srv/<Service> "{param: value}"

# 测试 action
ros2 action send_goal /<action> <package>/action/<Action> "{goal: value}"
```

## 提交前检查
- [ ] `colcon build` 无警告无错误
- [ ] `ament_lint` 通过（静态分析）
- [ ] 代码格式：`clang-format -i src/*.cpp`
- [ ] 单元测试通过：gtest / pytest
```

---

## 5-integration.md

```markdown
# Phase 5: Integration & Testing

## 仿真验证流程

### 1. Gazebo 仿真
```bash
# 启动仿真
ros2 launch gazebo_ros house_of_worlds.launch.py

# 加载机器人
ros2 run gazebo_ros spawn_entity.py -file robot.urdf -entity my_robot

# 键盘控制（临时）
ros2 run teleop_twist_keyboard teleop_twist_keyboard

# 查看所有 topic
ros2 topic list -v
```

### 2. Nav2 集成验证
```bash
# 启动 Nav2 bringup
ros2 launch nav2_bringup bringup_launch.py \
    slam:=True \

# 保存地图（SLAM 完成后）
ros2 run nav2_map_server map_saver_cli -f my_map

# 定位导航（非 SLAM）
ros2 launch nav2_bringup bringup_launch.py \
    map:=my_map.yaml \
    params_file:=nav2_params.yaml
```

### 3. 集成测试检查表
- [ ] 传感器数据流正常（topic 有数据）
- [ ] 控制命令能到达执行器
- [ ] 安全机制有效（障碍物检测停障）
- [ ] 状态机切换正常（lifecycle 状态正确）
- [ ] 多机通信正常（如果有多机）

## 性能基准
| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 延迟（感知→控制）| < 100ms | `ros2 topic hz /scan` + `ros2 topic echo /cmd_vel` 时间差 |
| CPU 占用 | < 70% per core | `top` / `htop` |
| 内存占用 | < 2GB | `free -h` |
| 帧率（图像）| ≥ 15fps | `ros2 topic hz /camera/image_raw` |
```

---

## 6-deployment.md

```markdown
# Phase 6: Deployment & Operation

## 部署检查清单

### 启动配置
```bash
# 正确启动顺序
# 1. 启动传感器 driver
ros2 launch <pkg> sensor_driver.launch.py

# 2. 启动感知节点
ros2 launch <pkg> perception.launch.py

# 3. 启动导航/规划
ros2 launch nav2_bringup bringup_launch.py

# 4. 启动控制节点
ros2 launch <pkg> control.launch.py

# 或用统一入口
ros2 launch <pkg> robot_bringup.launch.py
```

### Docker 部署
```dockerfile
FROM ros:${ROS_DISTRO}-ros-base
RUN apt-get update && apt-get install -y \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    && rm -rf /var/lib/apt/lists/*

COPY ./install /home/robot/install
RUN /bin/bash -c 'source /home/robot/install/setup.bash'

ENTRYPOINT ["/bin/bash", "-c", "source /home/robot/install/setup.bash && exec $@"]
```

### systemd 服务（边缘设备常驻）
```ini
[Unit]
Description=My Robot ROS2 Bringup
After=network.target

[Service]
Type=simple
User=robot
ExecStart=/usr/bin/bash -c 'source /opt/ros/humble/setup.bash && \
    source /home/robot/install/setup.bash && \
    ros2 launch my_robot robot_bringup.launch.py'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 监控与日志
```bash
# 启动后自动记录所有 topic 到 bag
ros2 bag record -a -o robot_run_$(date +%Y%m%d_%H%M%S)

# 关键日志
ls -la ~/.ros/log/

# 运行时监控
ros2 run rqt_graph rqt_graph          # 节点关系图
ros2 run rqt_plot rqt_plot            # 实时数据曲线
ros2 topic echo /nav2_runtime_stats   # Nav2 运行时统计
```

### 远程调试
```bash
# SSH 端口转发（查看远程 rviz）
ssh -L 11311:localhost:11311 robot@<robot-ip>

# 远程代码同步
rsync -avz --exclude='build/' --exclude='install/' \
    ./ robot@<robot-ip>:/home/robot/workspace/
```
```
