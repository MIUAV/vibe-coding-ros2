# wheeled-nav2 — Agent 执行计划

## Phase 0: 环境检查 + 机器人确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list
mcp__ros2__node_list
mcp__ros2__pkg_list
mcp__ros2__param_list /nav2_controller
```

### 验证
- [ ] 机器人 URDF 存在且完整（base_link + wheels）
- [ ] `nav2_bringup` 包存在
- [ ] 激光雷达话题存在（`/scan`）
- [ ] 机器人可以在 RViz 中显示

---

## Phase 1: SLAM 建图（已知地图跳过）

### 目标
使用 SLAM Toolbox 构建环境地图。

### Agent
`MCP-SIM` → `MCP-BUILD`

### 实现检查点
- [ ] `slam_toolbox` 在线建图配置
- [ ] 激光雷达扫描数据输入 `/scan`
- [ ] 地图输出到 `/map`（nav_msgs/OccupancyGrid）
- [ ] 建图过程中机器人可以手动遥控

### MCP 调用
```bash
mcp__ros2__service_call /slam_toolbox/pause slam_msgs/srv/Pause "{pause: true}"  # 保存地图
mcp__ros2__topic_pub /slam_mode std_msgs/msg/Bool "{data: true}"
```

### 验证
- [ ] 地图覆盖率 > 90%
- [ ] 占用栅格清晰（障碍物/自由空间分明）
- [ ] `ros2 run nav2_map_server map_saver_cli -f my_map` 可保存地图

---

## Phase 2: AMCL 定位

### 目标
使用 AMCL 在已知地图中定位。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `amcl` 节点配置（地图文件路径）
- [ ] 初始位姿设置（`/initialpose`）
- [ ] 激光雷达扫描匹配
- [ ] 定位精度评估（< 0.1m）

### 验证
- [ ] `ros2 topic echo /amcl_pose` 返回非零粒子数
- [ ] 机器人在 RViz 中正确显示在地图上
- [ ] 移动后定位漂移 < 0.2m

---

## Phase 3: Nav2 导航配置

### 目标
配置 Nav2 全套组件（planner + controller + bt_navigator）。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `nav2_bringup` launch 文件配置
- [ ] DWB Controller 参数（`dwb_controller`）
- [ ] NavFn Planner 参数
- [ ] 行为树 XML 配置

### MCP 调用
```bash
mcp__ros2__service_call /navigate_to_pose nav2_msgs/action/NavigateToPose
mcp__ros2__param_set /dwb_controller max_vel_x 0.5
```

### 验证
- [ ] 所有 Nav2 节点启动成功（`ros2 node list`）
- [ ] `ros2 lifecycle list /bt_navigator` 状态为 Active
- [ ] `/cmd_vel` 有输出

---

## Phase 4: 目标点导航测试

### 目标
发送目标点，验证机器人自主导航到达。

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__service_call /navigate_to_pose \
  nav2_msgs/action/NavigateToPose \
  "{pose: {header: {stamp: {sec: 0}}, pose: {position: {x: 5.0, y: 3.0}}}}"
```

### 验证
- [ ] 机器人开始移动
- [ ] 路径规划成功（`/plan` 有输出）
- [ ] 控制器输出 `/cmd_vel`
- [ ] 到达目标点（距离 < 0.3m）
- [ ] 无碰撞

---

## Phase 5: 动态避障测试

### 目标
导航中遇到动态障碍物（人）能绕行。

### Agent
`MCP-SIM`

### 验证
- [ ] 模拟人在机器人前方行走
- [ ] 机器人检测到障碍（代价地图变红）
- [ ] 机器人减速/绕行（不停止）
- [ ] 障碍消失后恢复原路径
- [ ] 到达原始目标点
