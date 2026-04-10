# Architecture Decisions — 技术架构决策记录

## 已确认的技术选型

### ROS2 包生成器
- **生成目标**：Humble / Iron / Jazzy 兼容的包骨架
- **包类型**：C++ (`rclcpp`) 优先，Python (`rclpy`) 可选
- **构建工具**：colcon，CMake + ament_cmake
- **节点基类**：优先使用 `rclcpp_lifecycle::LifecycleNode`（生产级）
- **指针风格**：`Node::SharedPtr` 智能指针，禁止裸指针

### CMake 导出规则（强制）
每次 `ament_target_dependencies` 后必须同时有：
```cmake
ament_export_dependencies(<pkg>)      # 必须
ament_export_include_directories(include)  # 必须（仅有 include 时）
ament_export_libraries(${PROJECT_NAME})    # 必须
```

### QoS 策略（已验证）
| 场景 | QoS 组合 | 说明 |
|------|---------|------|
| 控制命令（cmd_vel） | `QoS(10).reliable()` | 必须可靠 |
| 传感器数据（camera/lidar） | `QoS(10).best_effort()` | 允许丢帧降低延迟 |
| 生命周期状态广播 | `QoS(10).transient_local()` | 新订阅者收到最近状态 |
| 建图/定位数据 | `QoS(10).reliable()` | 必须可靠 |

### 生命周期节点（LifecycleNode）
生产机器人控制**必须**使用 LifecycleNode，实现全部5个回调：
- `on_configure` — 资源申请
- `on_activate` — 激活
- `on_deactivate` — 停用
- `on_cleanup` — 清理
- `on_shutdown` — 关闭

### 接口定义
- 优先使用 `.msg` / `.srv` / `.action`
- 接口包单独创建，不与代码包混合
- 接口命名：`<pkg_name>/msg/<MsgName>.msg`

### Nav2 集成
- 使用 `nav2_utilLifecycleNode` 代替普通 LifecycleNode
- 配置通过 YAML 文件加载，不硬编码参数
- BT.xml 行为树单独管理

### MoveIt2 集成
- 使用 `moveit_cpp` API（而非老旧 `planning_pipeline`）
- 碰撞检测默认开启（`ompl` + `fcl`）
- 末端执行器 URDF 命名约定：`<group_name>_ee`

### 仿真平台优先级
1. **Gazebo** — 通用机器人首选，ROS2 原生支持
2. **Isaac Sim / IsaacLab** — NVIDIA GPU 推理联合仿真
3. **Mujoco** — 接触动力学（manipulator 优先）
4. **Carla** — 自动驾驶仿真
5. **PyBullet** — 轻量快速 RL 训练

### 边缘推理平台
- **NVIDIA Jetson** — JetPack + TensorRT
- **Intel NUC** — OpenVINO
- **RK3588** — RKNN

---

## 决策记录（ADR）

| ID | 日期 | 决策 | 原因 |
|----|------|------|------|
| ADR-001 | 2026-04 | LifecycleNode 优先于普通 Node | 生产级需要优雅关闭/重启 |
| ADR-002 | 2026-04 | C++ 优先于 Python | 性能关键路径（C++ 生成器为主） |
| ADR-003 | 2026-04 | 包骨架生成强制验证 | 避免 AI 生成的 CMake 错误扩散 |
| ADR-004 | 2026-04 | 接口包与代码包分离 | 可复用性和版本管理 |
