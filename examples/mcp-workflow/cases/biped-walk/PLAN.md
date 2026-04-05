# biped-walk — Agent 执行计划

## Phase 0: URDF + 关节配置确认

### Agent
`MCP-SIM`

### MCP 调用
```bash
mcp__ros2__node_list | grep -E "joint|controller"
mcp__ros2__param_list /biped_controller
```

### 验证
- [ ] 18+ DOF URDF（髋×3 + 膝×1 + 踝×2 = 每条腿 6DOF × 2 = 12DOF + 上肢）
- [ ] 关节限位在 URDF 中正确声明
- [ ] 机器人可以在 RViz 中显示
- [ ] IMU 话题存在（`/imu/data`）

---

## Phase 1: ZMP 规划器

### Agent
`MCP-BUILD`

### 目标
实现 ZMP 轨迹生成器。

### 实现检查点
- [ ] `ZMPPlanner` 类
- [ ] 步行周期生成（SSP + DSP）
- [ ] ZMP 轨迹计算（基于重心位置）
- [ ] 支撑多边形计算（脚底接触面）
- [ ] ZMP 稳定性判定（ZMP 在支撑多边形内）

### 验证
- [ ] 静态步行：ZMP 始终在支撑多边形内
- [ ] 动态步行：ZMP 安全余量 > 0.02m

---

## Phase 2: 步态生成器

### Agent
`MCP-BUILD`

### 目标
生成周期性步态轨迹。

### 实现检查点
- [ ] `GaitGenerator` 类
- [ ] 摆动腿踝关节轨迹（摆线/抛物线）
- [ ] 支撑腿位置保持
- [ ] 髋关节侧向移动（重心转移）
- [ ] 步频/步长参数可调

### 验证
- [ ] 步态周期连续无突变
- [ ] 步高满足 > 0.03m（脚离地间隙）
- [ ] 脚跟着地冲击 < 10N（可调）

---

## Phase 3: 逆运动学 (IK)

### Agent
`MCP-BUILD`

### 目标
笛卡尔空间足端位置 → 关节角度。

### 实现检查点
- [ ] `BipedIK` 类（数值解法）
- [ ] 12+ DOF 逆解
- [ ] 膝关节奇异处理
- [ ] 关节限位保护

### 验证
- [ ] IK 解算时间 < 1ms
- [ ] IK 输出在关节限位内
- [ ] 足端位置误差 < 1mm

---

## Phase 4: 平衡控制器

### Agent
`MCP-BUILD`

### 目标
实时平衡控制（基于 IMU 反馈）。

### 实现检查点
- [ ] `BalanceController` 类（PID）
- [ ] IMU 倾斜角反馈（Roll/Pitch）
- [ ] 髋关节高度调整（平衡响应）
- [ ] 脚踝力矩控制

### 验证
- [ ] 站立时倾斜角 < 5°
- [ ] 外力干扰后恢复时间 < 1s

---

## Phase 5: 仿真验证

### Agent
`MCP-SIM`

### 验证
- [ ] 连续行走 > 10 步（无摔倒）
- [ ] 步行速度达到 0.3-0.6 m/s
- [ ] ZMP 始终在支撑多边形内
- [ ] 无关节超限位告警
