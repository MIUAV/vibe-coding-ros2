# sensor-fusion-locate — Agent 执行计划

## Phase 0: 传感器话题确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list | grep -E "scan|imu|gps|camera"
mcp__ros2__node_list | grep -E "laser|ekf|localization"
```

### 验证
- [ ] 激光雷达 `/scan` 话题存在
- [ ] IMU `/imu/data` 话题存在
- [ ] GPS `/gps/fix` 话题存在（如适用）
- [ ] 各传感器数据频率正常（激光 > 10Hz, IMU > 100Hz）

---

## Phase 1: 时间同步

### Agent
`MCP-BUILD`

### 目标
硬件时间同步（传感器数据时间戳对齐）。

### 实现检查点
- [ ] `MessageSynchronizer`（或 `approximate_time`）
- [ ] IMU 频率与激光雷达同步
- [ ] GPS 时间同步（如使用）

### 验证
- [ ] 同步后消息对数量 > 90%
- [ ] 时间戳差 < 50ms

---

## Phase 2: EKF 定位节点

### Agent
`MCP-BUILD`

### 目标
实现 robot_localization EKF 节点。

### 实现检查点
- [ ] `ekf_filter_node` 配置
- [ ] sensor_inputs: laser scan + IMU + GPS
- [ ] 状态向量：[x, y, z, roll, pitch, yaw, vx, vy, vz]
- [ ] Process noise covariance
- [ ] Sensor noise covariance

### 验证
- [ ] EKF 输出频率 ≥ 50Hz
- [ ] 定位精度 < 0.1m（激光+IMU）

---

## Phase 3: Scan Matching

### Agent
`MCP-BUILD`

### 目标
激光扫描匹配提高定位精度。

### 实现检查点
- [ ] ICP 或 NDT 算法
- [ ] 从点云估计机器人位姿
- [ ] 输出到 EKF 作为观测

### 验证
- [ ] 匹配成功率 > 95%
- [ ] 定位误差 < 0.05m

---

## Phase 4: 精度评估

### Agent
`MCP-SIM`

### 验证
- [ ] 静态定位精度 < 0.05m
- [ ] 移动定位精度 < 0.1m
- [ ] GPS 可用时精度 < 0.5m（室外）
- [ ] IMU 单独运行时漂移 < 0.5m/min
