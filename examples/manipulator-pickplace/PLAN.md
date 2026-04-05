# manipulator-pickplace — Agent 执行计划

## Phase 0: 机械臂 URDF + MoveIt! 配置检查

### 目标
确认机械臂 URDF、SRDF、MoveIt! 配置完整。

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__pkg_list                              # 列出所有包
mcp__ros2__launch_list robot_moveit_bringup      # 查看 MoveIt! launch
mcp__ros2__service_call /get_planning_scene      # 获取当前场景
```

### 验证
- [ ] 机械臂 URDF 包含所有关节（6+ 自由度）
- [ ] MoveIt! 配置包含 SRDF 和 OMPL 规划器
- [ ] 夹爪 URDF + 插件存在
- [ ] `ros2 launch moveit2_scripts demo.launch.py` 能启动 RViz

---

## Phase 1: 视觉定位服务

### 目标
实现目标检测服务，输出物体 6D 位姿。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `VisionLocalization` 节点实现
- [ ] 输入：`/camera/depth_registered/image_raw`
- [ ] 输出：`/object_detection/pose` (geometry_msgs/PoseStamped)
- [ ] 物体识别使用 YOLO / PointPillars
- [ ] 位姿估计误差 < 1cm / 5°

### MCP 调用
```bash
mcp__ros2__topic_info /camera/depth_registered/image_raw  # 检查相机话题
mcp__ros2__pkg_create vision_localization cpp "rclcpp,sensor_msgs,geometry_msgs,cv_bridge"
```

### 验证
- [ ] 目标检测率 > 90%（已知物体）
- [ ] 位姿延迟 < 500ms
- [ ] `colcon build --packages-select vision_localization` 零错误

---

## Phase 2: MoveIt! 运动规划

### 目标
实现基于 MoveIt! 的无碰撞运动规划。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `MoveItPlanner` 类（Python 或 C++）
- [ ] `compute_cartesian_path()` 实现抓取路径
- [ ] 碰撞检测：夹爪 + 机械臂 + 货架
- [ ] OMPL 规划器配置（RRTConnect）

### 验证
- [ ] 规划时间 < 3s
- [ ] 路径成功率 > 95%
- [ ] 无碰撞路径输出

### MCP 调用
```bash
mcp__ros2__service_call /plan_pipeline/plan /moveit_msgs/srv/MotionPlanRequest  # 测试规划服务
```

---

## Phase 3: 抓取策略

### 目标
实现基于物体位姿的抓取姿态计算。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `GraspPlanner` 类
- [ ] 输入：物体 PoseStamped
- [ ] 输出：`moveit_msgs/Grasp` 列表
- [ ] grasp pose = 物体位置 + 抓取方向（偏置 0.03m）

### 验证
- [ ] 抓取成功率 > 85%（测试 20 次）
- [ ] grasp pose 在夹爪可达空间内

---

## Phase 4: 状态机

### 目标
实现抓取放置的完整状态机。

### Agent
`MCP-BUILD`

### 状态定义

```
IDLE → DETECTING → PLANNING → APPROACHING → DESCENDING → GRASPING
  → LIFTING → MOVING → DESCENDING_PLACE → RELEASING → WITHDRAWING → IDLE
```

### 验证
- [ ] 状态转换正确
- [ ] 每个状态有超时处理
- [ ] 错误状态可恢复

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] 在 Gazebo 中成功抓取 10 个物体
- [ ] 成功率 > 80%
- [ ] 平均周期时间 < 10s
- [ ] 无碰撞告警
