# wheeled-nav2 — 验证标准

## 成功标准

### 基础导航

| 指标 | 通过标准 | 测试方法 |
|------|---------|---------|
| 到达精度 | < 0.3m | `ros2 topic echo /amcl_pose` 距离目标 |
| 导航时间 | < 60s | 从发目标到到达的时间 |
| 路径长度 | ≤ 1.3×最短路径 | 路径长度对比 |
| 碰撞次数 | 0 | `ros2 topic echo /mobile_base/events/collision` |

### 动态避障

| 指标 | 通过标准 |
|------|---------|
| 绕行延迟 | < 5s（不停止 > 2s）|
| 恢复时间 | < 3s（障碍消失后恢复）|
| 到达率 | ≥ 90%（10 次测试）|

### 定位精度

| 指标 | 通过标准 |
|------|---------|
| AMCL 定位漂移 | < 0.2m |
| 初始定位误差 | < 0.5m |

## 失败条件

- [ ] 机器人与障碍物碰撞
- [ ] 导航超时 > 120s 未到达
- [ ] AMCL 粒子耗散（定位丢失）
- [ ] 路径规划失败

## 测试命令

```bash
# 1. 启动导航
ros2 launch wheeled_robot_nav2 bringup.launch.py
source install/setup.bash

# 2. 发送目标点
ros2 topic pub /goal_pose geometry_msgs/PoseStamped \
  '{header: {stamp: {sec: 0}}, pose: {position: {x: 5.0, y: 3.0}}}'

# 3. 运行验证
bash scripts/validators/wheeled-nav2-verify.sh
```
