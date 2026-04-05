# underwater-nav — 验证标准

## 成功标准

### 导航精度

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 水平位置误差 | < 5m / 路程的 1% | USBL 修正后对比 |
| 深度误差 | < 0.5m | 压力传感器 vs 真实深度 |
| 路径跟踪误差 | < 2m | 离线轨迹分析 |
| DVL 丢失漂移 | < 5m / 10s | 仿真中模拟 DVL 丢失 |

### 传感器融合

| 指标 | 通过标准 |
|------|---------|
| EKF 输出频率 | ≥ 10 Hz |
| 深度收敛时间 | < 10s |
| USBL 延迟补偿误差 | < 1m |

## 失败条件

- [ ] 水平位置误差 > 10m
- [ ] 深度超调 > 1m
- [ ] EKF 输出频率 < 5Hz
- [ ] 水声通信完全失败（USBL 长时间无响应）

## 测试命令

```bash
colcon build --packages-select underwater_nav
source install/setup.bash
ros2 launch underwater_nav sim.launch.py

# 路径跟踪测试
ros2 run underwater_nav nav_test --ros-args -p area:=100

# DVL 丢失测试
ros2 service call /dvl_sim/stop std_srvs/srv/Empty
```
