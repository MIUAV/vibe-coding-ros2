# biped-walk — 验证标准

## 成功标准

### 步态质量

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 连续步行步数 | > 10 步 | 仿真器状态 |
| 步行速度 | 0.3-0.6 m/s | 位置差/时间 |
| ZMP 安全余量 | > 0.02m | ZMP 轨迹分析 |
| 脚跟着地冲击 | < 10N | 力学传感器 |

### 平衡控制

| 指标 | 通过标准 |
|------|---------|
| 站立倾斜角 | < 5° |
| 外力干扰恢复 | < 1.0s |
| 关节力矩 | < 额定 80% |

## 失败条件

- [ ] ZMP 超出支撑多边形
- [ ] 摔倒（任意关节接触地面）
- [ ] 关节超限位
- [ ] 步态周期不连续

## 测试命令

```bash
colcon build --packages-select biped_walk
source install/setup.bash
ros2 launch biped_walk walk.launch.py
ros2 run biped_walk walk_test --ros-args -p step_count:=10
```
