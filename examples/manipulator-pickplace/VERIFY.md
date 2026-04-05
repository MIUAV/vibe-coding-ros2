# manipulator-pickplace — 验证标准

## 成功标准（仿真）

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 抓取成功率 | ≥ 80% | 10 次连续测试 |
| 放置成功率 | ≥ 90%（抓取成功后）| 同上 |
| 周期时间 | < 15s | `ros2 topic echo /pickplace/status` |
| 规划时间 | < 3s | 日志 |
| 碰撞数 | 0 | MoveIt! 碰撞检测 |
| 物体掉落 | 0 | 仿真器状态 |

## 代码质量

| 检查项 | 标准 |
|--------|------|
| `colcon build` | 零错误 |
| `ament_lint` | 通过 |
| 依赖声明 | 所有依赖在 package.xml |
| 注释覆盖率 | 关键函数有 docstring |

## 测试命令

```bash
# 编译
colcon build --packages-select manipulator_pickplace vision_localization
source install/setup.bash

# 启动仿真
ros2 launch manipulator_pickplace sim.launch.py

# 运行测试
ros2 run manipulator_pickplace pickplace_test_node --ros-args -p test_count:=10

# 查看结果
ros2 topic echo /pickplace/result
```

## 失败条件

- [ ] 抓取成功率 < 80%
- [ ] 任何碰撞检测
- [ ] 关节超过限位
- [ ] 状态机卡在非 IDLE 状态 > 30s
