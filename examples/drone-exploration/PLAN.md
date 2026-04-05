# drone-exploration — Agent 执行计划

## Phase 0: 环境检查

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__topic_list                          # 列出话题
mcp__ros2__pkg_list                            # 列出包
mcp__ros2__node_info /octomap_server           # 检查 Octomap 节点
mcp__ros2__service_list                        # 列出服务
```

### 验证
- [ ] 深度相机话题存在（`/depth_camera/points` 或类似）
- [ ] `octomap_server` 包存在
- [ ] EKF/IMU 融合节点运行中
- [ ] 无人机安全开关解除

---

## Phase 1: Octomap 建图

### Agent
`MCP-BUILD`

### 目标
点云 → Octomap 3D 占据栅格地图。

### 实现检查点
- [ ] `OctomapServer` 配置（分辨率 0.1m，最大范围 50m）
- [ ] 点云过滤（VoxelGrid 下采样）
- [ ] 地图更新频率 ≥ 10Hz
- [ ] 发布到 `/octomap_full`（octomap_msgs）

### MCP 调用
```bash
mcp__ros2__topic_pub /octomap/clear std_msgs/msg/Empty {}  # 清除地图
mcp__ros2__service_call /octomap_server/reset               # 重置服务器
```

### 验证
- [ ] `ros2 topic hz /octomap_full` ≥ 10Hz
- [ ] Octomap 可在 RViz 中显示

---

## Phase 2: 前沿检测 (Frontier Detection)

### Agent
`MCP-BUILD`

### 目标
从 Octomap 检测"前沿"——已探索与未探索区域的边界。

### 实现检查点
- [ ] `FrontierDetector` 类（Python 或 C++）
- [ ] 从 3D Octomap 降维到 2D 探索栅格
- [ ] frontier 聚类（距离阈值 1.0m）
- [ ] 信息增益计算（前沿面积 × 未知区域占比）

### 验证
- [ ] frontier 数量在合理范围（5-50 个）
- [ ] 每个 frontier 有 `position` + `information_gain`

---

## Phase 3: RRT* 路径规划

### Agent
`MCP-BUILD`

### 目标
对每个候选 frontier 做 RRT* 规划，输出无碰撞路径。

### 实现检查点
- [ ] `RRTStarPlanner` 类
- [ ] 状态空间：位置（x, y, z）+ 安全高度约束
- [ ] 碰撞检测：Octomap ray casting
- [ ] 平滑后处理（Bezier 曲线）

### 验证
- [ ] 规划时间 < 2s
- [ ] 路径无碰撞（与 Octomap 碰撞检测）
- [ ] 路径满足最大速度/加速度约束

---

## Phase 4: 探索状态机

### Agent
`MCP-BUILD`

### 状态定义
```
IDLE → FRONTIER_DETECTION → PLANNING → TRAVERSING → MAPPING → FRONTIER_DETECTION
                                                              ↓
                                                          LOW_BATTERY
                                                              ↓
                                                          RETURN_HOME
```

### 验证
- [ ] 状态转换正确
- [ ] 超时处理（规划超时 5s → 选择次优 frontier）
- [ ] 低电量保护（< 20% → 返回）

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] 在 Gazebo 室内环境中成功探索 > 80% 区域
- [ ] 无碰撞飞行 > 100m 总路程
- [ ] 地图覆盖率 > 80%（相对于环境体积）
- [ ] 电池消耗 < 50%
