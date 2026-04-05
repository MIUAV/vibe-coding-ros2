# industrial-integration — 验证标准

## 成功标准

| 指标 | 通过标准 |
|------|---------|
| 通信延迟 | < 50ms |
| 急停响应 | < 10ms |
| 任务完成率 | 100% |
| 连续生产 | > 100 工件无错误 |

## 失败条件

- [ ] 急停响应 > 20ms
- [ ] 通信错误率 > 1%
- [ ] 任务完成率 < 99%
- [ ] 断网时机器人进入不安全状态

## 测试命令

```bash
colcon build --packages-select industrial_integration
source install/setup.bash
ros2 launch industrial_integration line.launch.py
ros2 run industrial_integration integration_test --ros-args -p test_count:=100
```
