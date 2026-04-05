# underwater-nav — Agent 执行计划

## Phase 0: 传感器话题确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list | grep -E "dvl|imu|pressure|usbl"
mcp__ros2__node_list | grep -E "auv|underwater"
```

### 验证
- [ ] DVL 话题存在（`/dvl/velocity` 或类似）
- [ ] IMU 话题存在（`/imu/data`）
- [ ] 压力传感器话题存在（`/depth`）
- [ ] USBL 定位话题存在（`/usbl/position`）

---

## Phase 1: EKF 传感器融合

### Agent
`MCP-BUILD`

### 目标
实现 EKF 融合 DVL + IMU + 压力传感器 + USBL。

### 实现检查点
- [ ] `UnderwaterEKF` 类（robot_localization 或自定义）
- [ ] 状态向量：[x, y, z, roll, pitch, yaw, vx, vy, vz]
- [ ] 预测模型：DVL 速度积分
- [ ] 观测模型：USBL 位置、压力深度
- [ ] DVL 丢失检测和降级处理

### 验证
- [ ] 定位误差 < 1m（USBL 修正下）
- [ ] DVL 丢失 10s 内位置漂移 < 5m
- [ ] EKF 输出频率 ≥ 10Hz

---

## Phase 2: 深度控制 (Heave)

### Agent
`MCP-BUILD`

### 目标
实现定深控制（垂直方向）。

### 实现检查点
- [ ] `DepthController` 类（PID）
- [ ] 压力传感器深度反馈
- [ ] 推进器推力分配（垂直推进器）
- [ ] 深度超调 < 0.2m

### 验证
- [ ] 深度误差 < 0.1m
- [ ] 超调 < 0.2m
- [ ] 调整时间 < 10s

---

## Phase 3: 水平面导航

### Agent
`MCP-BUILD`

### 目标
实现 DVL + EKF 水平面导航。

### 实现检查点
- [ ] `HorizontalNavigator` 类
- [ ] 路径点跟踪（line-of-sight）
- [ ] 偏流补偿（DVL 相对于海底的速度 ≠ 对水速度）
- [ ] 3D 轨迹执行（x, y, z 同时）

### 验证
- [ ] 路径跟踪误差 < 2m
- [ ] 到达目标点距离 < 1m

---

## Phase 4: USBL 位置修正

### Agent
`MCP-BUILD`

### 目标
水面母船 USBL 提供绝对位置修正。

### 实现检查点
- [ ] `USBLCorrector` 类
- [ ] 水声延迟补偿（根据距离计算）
- [ ] USBL 位置异常值过滤（Kalman filter）
- [ ] 丢包处理（USBL 刷新率低）

### 验证
- [ ] USBL 修正后位置跳变 < 0.5m
- [ ] 水声延迟补偿误差 < 1m

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] AUV 在 100×100m 区域内导航
- [ ] 总路程 > 500m，位置误差 < 5m
- [ ] 深度误差 < 0.5m
- [ ] 无碰撞（仿真环境边界）
