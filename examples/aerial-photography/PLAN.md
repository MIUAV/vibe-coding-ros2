# aerial-photography — Agent 执行计划

## Phase 0: 相机 + 云台确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list | grep -E "camera|gimbal|image"
mcp__ros2__param_list /gimbal_controller
```

### 验证
- [ ] 相机话题存在（`/camera/image_raw`）
- [ ] 云台控制话题存在（`/gimbal/angle`）
- [ ] 相机内参已知（fx, fy, cx, cy）

---

## Phase 1: 航线规划器

### Agent
`MCP-BUILD`

### 目标
根据目标区域多边形生成航线条带。

### 实现检查点
- [ ] `WaypointPlanner` 类
- [ ] 区域网格化（根据重叠率计算）
- [ ] 条带方向选择（顺风方向减少偏流影响）
- [ ] 航点序列生成（x, y, z, yaw）
- [ ] 相机快门触发点标记

### 验证
- [ ] 航点覆盖完整区域
- [ ] 重叠率满足要求（> 80% 前向，> 60% 旁向）
- [ ] 航点之间距离平滑（无急转弯）

---

## Phase 2: 云台控制器

### Agent
`MCP-BUILD`

### 目标
云台角度跟踪飞行方向，保持相机始终对准地面。

### 实现检查点
- [ ] `GimbalController` 类（PID）
- [ ] 飞行方向 → 云台俯仰角映射
- [ ] 实时图传角度平滑
- [ ] 云台控制 QoS: RELIABLE（控制命令）

### 验证
- [ ] 云台俯仰角跟踪误差 < 5°
- [ ] 图传画面抖动 < 10%

---

## Phase 3: 航线执行

### Agent
`MCP-BUILD`

### 目标
按航点序列执行飞行和拍摄。

### 实现检查点
- [ ] `FlightController` 类
- [ ] 航点到达判定（距离 < 2m）
- [ ] 相机快门触发（定时或位置触发）
- [ ] 航点间速度规划（匀速通过）

### 验证
- [ ] 飞行路径与规划误差 < 5m
- [ ] 相机快门触发正确（> 90% 航点有触发）
- [ ] 电池消耗 < 80%

---

## Phase 4: 图传监控

### Agent
`MCP-SIM`

### 验证
- [ ] 实时图传延迟 < 500ms
- [ ] 图传画面质量（无明显压缩伪影）
- [ ] 图像 GPS 坐标记录正确

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] 覆盖目标区域 > 95%
- [ ] 图像数量符合预期（重叠率计算正确）
- [ ] 无禁区闯入
- [ ] 电池消耗 < 90%
