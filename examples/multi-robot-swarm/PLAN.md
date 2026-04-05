# multi-robot-swarm — Agent 执行计划

## Phase 0: 单机控制验证

### Agent
`MCP-SIM`

### 目标
在多机器人之前，确认每台机器人都能独立导航。

### MCP 调用
```bash
mcp__ros2__topic_list | grep -E "robot_1|robot_2|robot_3"
mcp__ros2__node_list | grep -E "nav|cmd_vel"
```

### 验证
- [ ] 每台机器人的 `/robot_N/cmd_vel` 有输出
- [ ] 每台机器人可以独立导航到目标点
- [ ] 激光雷达数据正常

---

## Phase 1: 通信中间件

### Agent
`MCP-BUILD`

### 目标
建立机器人间通信（P2P 或广播）。

### 实现检查点
- [ ] `robot_pair_broadcast` 节点（每对机器人通信）
- [ ] 或使用 `ros2 topic echo` / `pub` 做广播
- [ ] QoS: RELIABLE（协调命令不能丢）
- [ ] 通信延迟 < 100ms

### 验证
- [ ] `ros2 topic list` 看到 `robot_1/position`、`robot_2/position` 等
- [ ] 位置信息跨机器人可达

---

## Phase 2: 编队控制器

### Agent
`MCP-BUILD`

### 目标
实现 leader-follower 编队控制。

### 实现检查点
- [ ] `FormationController` 类
- [ ] Leader 发布路径
- [ ] Follower 计算相对位置误差
- [ ] PID 控制消除误差
- [ ] 编队形状可切换（直线/三角/菱形）

### Leader-Follower 控制律

```
u_follower = Kp × (p_formation - p_current) +Kd × (v_target - v_current)
```

### 验证
- [ ] 编队间距误差 < 0.1m
- [ ] 编队形状保持正确（三角/菱形）
- [ ] Leader 加速时 Follower 能跟踪（延迟 < 1s）

---

## Phase 3: 分布式任务分配

### Agent
`MCP-BUILD`

### 目标
实现拍卖/竞拍任务分配算法。

### 实现检查点
- [ ] `TaskAllocator` 类
- [ ] 区域网格化（N×N 格子）
- [ ] 距离成本计算
- [ ] 竞拍协议
- [ ] 分配结果广播

### 验证
- [ ] 任务分配在 < 5s 内完成（≤10 台机器人）
- [ ] 所有机器人都有任务（或无任务时正确 IDLE）
- [ ] 分配结果一致性（无冲突分配）

---

## Phase 4: 碰撞协调

### Agent
`MCP-BUILD`

### 目标
防止机器人间碰撞。

### 实现检查点
- [ ] `CollisionDetector` 类（圆形碰撞检测）
- [ ] 速度限制区（机器人接近时减速）
- [ ] 优先级机制（直线通过的机器人优先）

### 验证
- [ ] 100 次随机路径测试，0 碰撞
- [ ] 安全距离内机器人相对速度 < 0.1 m/s

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] 3 台机器人成功覆盖指定区域
- [ ] 无碰撞（100m 总路程）
- [ ] 任务分配一致性
- [ ] 编队形状保持
