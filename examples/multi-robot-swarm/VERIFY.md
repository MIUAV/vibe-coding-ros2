# multi-robot-swarm — 验证标准

## 成功标准

### 编队控制

| 指标 | 通过标准 |
|------|---------|
| 编队间距误差 | < 0.15m |
| 编队形状保持率 | > 90% |
| Leader 加速跟踪延迟 | < 1.0s |

### 任务分配

| 指标 | 通过标准 |
|------|---------|
| 分配时间 | < 5s（≤10台）|
| 分配一致性 | 0 冲突 |
| 分配覆盖率 | 100%（所有区域被覆盖）|

### 碰撞协调

| 指标 | 通过标准 |
|------|---------|
| 碰撞次数 | 0 |
| 安全距离触发次数 | > 0（测试有效）|
| 碰撞恢复时间 | < 2s |

## 失败条件

- [ ] 任意两台机器人碰撞
- [ ] 任务分配有冲突（同一区域分配给两台机器人）
- [ ] 超过 20% 的机器人失联

## 测试命令

```bash
# 编译
colcon build --packages-select multi_robot_swarm
source install/setup.bash

# 启动仿真（3台机器人）
ros2 launch multi_robot_swarm sim.launch.py

# 运行测试
ros2 run multi_robot_swarm swarm_test --ros-args -p robot_count:=3

# 查看编队误差
ros2 topic echo /formation_error
```
