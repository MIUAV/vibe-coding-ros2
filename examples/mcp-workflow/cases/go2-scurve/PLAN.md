# go2-scurve — Agent 执行计划

## Phase 0: 环境检查 + 需求确认

### 目标
确认 ROS2 Humble 环境正常，获取 Go2 机器人当前状态。

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list                    # 列出所有话题
mcp__ros2__pkg_list                      # 列出所有包
mcp__ros2__node_info /go2_state_estimation  # 查看状态估计节点
```

### 验证
- [ ] `ros2 topic list` 返回非空
- [ ] `go2_scurve` 包存在（或需要创建）
- [ ] Go2 的 UDP 通信端口正常

---

## Phase 1: 接口定义

### 目标
定义 S-curve 轨迹的话题和服务接口。

### Agent
`MCP-BUILD`

### 输出

```yaml
# 轨迹目标话题
/scurve/target:
  type: geometry_msgs/msg/Pose2D
  说明: S曲线目标点 (x, y, theta)

# 足端位置话题
/leg/feet_positions:
  type: geometry_msgs/msg/Vector3Stamped[4]
  说明: 4条腿的足端位置（世界坐标系）

# S曲线参数服务
/scurve/set_params:
  type: example_interfaces/srv/SetBool
  说明: 设置 A_max, V_max, J_max 参数

# 轨迹状态话题
/scurve/status:
  type: std_msgs/msg/String
  说明: "planning" | "executing" | "completed" | "error"
```

### 验证
- [ ] msg/srv/action 文件已创建在 `go2_scurve_msgs/` 包
- [ ] `colcon build --packages-select go2_scurve_msgs` 编译通过
- [ ] `ros2 interface show` 能查到新接口

---

## Phase 2: 轨迹生成器实现

### 目标
实现 S-curve 数学生成器（位置/速度/加速度/jerk）。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `ScurveGenerator` 类实现（位置 `get_position(t)`、速度 `get_velocity(t)`、加速度 `get_acceleration(t)`、jerk）
- [ ] 参数可动态调整（A_max, V_max, J_max）
- [ ] `colcon build --packages-select go2_scurve` 零错误
- [ ] 单元测试：输入 T=1.0, A_max=1.0, V_max=1.0, J_max=10.0，输出轨迹点序列

### MCP 调用
```bash
mcp__ros2__pkg_create go2_scurve cpp "rclcpp,geometry_msgs,std_msgs"
mcp__colcon_build --package go2_scurve
```

### 验证
- [ ] 轨迹生成器输出jerk连续（无突变）
- [ ] 速度不超过 V_max
- [ ] 加速度不超过 A_max

---

## Phase 3: 逆运动学（IK）

### 目标
将笛卡尔空间 S-curve 轨迹转换为关节角度序列。

### Agent
`MCP-BUILD`

### 实现检查点
- [ ] `Go2IK` 类实现（12个关节角度输出）
- [ ] 腿长参数化（从 URDF 或参数服务器读取）
- [ ] 奇异点处理（膝盖向后时）
- [ ] 限位检查（每个关节的角度限制）

### 验证
- [ ] IK 输出在物理限位内
- [ ] 足端位置误差 < 1mm（相对于目标）

---

## Phase 4: 仿真验证

### 目标
在 Gazebo/Ignition 中验证 S-curve 轨迹执行。

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__service_call /controller_manager/list_controllers  # 确认控制器运行
mcp__ros2__topic_pub /scurve/start std_msgs/msg/Bool "{data: true}"  # 触发轨迹执行
```

### 验证
- [ ] 机器人实际行走轨迹与规划 S-curve 误差 < 5cm
- [ ] 无关节超限位告警
- [ ] 轨迹完成时间与理论值误差 < 10%

---

## Phase 5: 真实机器人验证（可选）

### 目标
在真实 Go2 机器人上执行 S-curve 轨迹。

### 验证
- [ ] UDP 通信正常
- [ ] 轨迹执行中关节温度正常（< 80°C）
- [ ] 机器人无异常抖动
