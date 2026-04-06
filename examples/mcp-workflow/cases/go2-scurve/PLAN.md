# go2-scurve Case — Unitree Go2 四足机器人 S 曲线运动规划

## 背景

Unitree Go2 是宇树科技的四足机器人，支持 ROS2 控制。本案例展示如何为 Go2 生成符合 S 曲线加减速的运动轨迹，实现平滑、稳定的步态运动。

**应用场景：**
- 复杂地形导航（楼梯、斜坡）
- 平滑轨迹跟踪（避免冲击）
- 运动模式切换（walk/trot/gallop）

---

## 用户需求

```
用户：让 Go2 从当前位置平滑移动到 (2.0, 1.0)，使用 S 曲线加减速，避开途中障碍物
```

---

## 约束

- ROS2 humble/iron/jazzy
- Go2 固件版本 ≥ 2.0（支持 ROS2 指令接口）
- Python 3.8+
- 障碍物检测依赖激光雷达数据 `/scan`

---

## 执行流程

### Step 1: 包生成

```bash
cd /home/node/.openclaw/workspace/vibe-coding-ros2
bash scripts/generators/ros2-package-generator.sh go2_scurve mixed
```

### Step 2: S 曲线轨迹生成

```bash
python3 go2_scurve/src/scurve_planner.py \
  --start 0.0,0.0,0.0 \
  --goal 2.0,1.0,0.0 \
  --vmax 0.5 \
  --amax 0.2 \
  --step_height 0.15
```

### Step 3: 障碍物检测

```bash
ros2 run go2_scurve obstacle_avoider --ros-args -p scan_topic:/scan
```

### Step 4: 编译验证

```bash
bash scripts/ros2-build-verify-loop.sh go2_scurve
```

---

## 技术要点

### S 曲线生成算法

```
S 曲线 = 5段：T_acc → T_jerk → T_const → T_decel → T_settle
```

| 参数 | 含义 | 默认值 |
|------|------|--------|
| vmax | 最大速度 | 0.5 m/s |
| amax | 最大加速度 | 0.2 m/s² |
| jmax | 最大加加速度（冲击限制） | 1.0 m/s³ |

### Go2 步态周期

```
步态周期 T = 1 / frequency
trot:   T = 0.3s, 50% 占空比
walk:   T = 0.6s, 70% 占空比
gallop: T = 0.2s, 40% 占空比
```

---

## 预期结果

- ✅ 生成的轨迹经过 S 曲线加减速，无突变
- ✅ 步态频率与轨迹速度匹配
- ✅ 障碍物检测触发局部路径重规划
- ✅ colcon build 编译通过，无 error
- ✅ 单元测试覆盖 scurve 计算核心逻辑
