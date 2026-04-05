# drone-exploration — 验证标准

## 成功标准（仿真）

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 探索覆盖率 | ≥ 80% | `ros2 service call /get_map_coverage` |
| 无碰撞路程 | > 100m | `ros2 topic echo /flight_path` 里程积分 |
| 地图分辨率 | 0.1 m | `ros2 param get /octomap_server resolution` |
| 地图更新频率 | ≥ 10 Hz | `ros2 topic hz /octomap_full` |
| 规划时间 | < 2s | 日志时间戳差 |
| 飞行速度 | ≤ 1 m/s | `ros2 topic echo /mavros/local_position/velocity` |
| 飞行高度 | ≥ 1.5 m | `ros2 topic echo /mavros/local_position/pose` |

## 失败条件

满足以下任意则判定失败：

- [ ] 任何碰撞检测（`/mobile_base/events/collision`）
- [ ] 飞行高度 < 1.5m 持续 > 2s
- [ ] 飞行速度 > 2 m/s
- [ ] 地图更新频率 < 5Hz（地图过时）
- [ ] 电池 < 10%

## 测试命令

```bash
# 编译
colcon build --packages-select drone_exploration octomap_tools
source install/setup.bash

# 启动仿真
ros2 launch drone_exploration sim.launch.py

# 运行验证
ros2 run drone_exploration exploration_test --ros-args -p test_duration:=300

# 查看覆盖率
ros2 service call /get_map_coverage std_srvs/srv/Trigger
```

## 定量指标记录

每次测试记录：
- 覆盖率：__%
- 总飞行路程：__m
- 碰撞次数：__
- 电池消耗：__%
- 测试时长：__s
