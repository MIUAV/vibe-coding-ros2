# sensor-fusion-locate — 验证标准

## 成功标准

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 静态定位精度 | < 0.05m | 静止 60s，平均误差 |
| 移动定位精度 | < 0.1m | 路径跟踪测试 |
| EKF 输出频率 | ≥ 50Hz | `ros2 topic hz /odometry/filtered` |
| Scan matching 成功率 | > 95% | 仿真日志 |
| IMU 漂移 | < 0.5m/min | 模拟 DVL/GPS 丢失 |

## 失败条件

- [ ] EKF 输出频率 < 30Hz
- [ ] 定位误差 > 0.3m
- [ ] Scan matching 成功率 < 80%
