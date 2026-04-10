# Wheeled Vehicle Context

## 运动模型
- 差速驱动（Diff Drive）：左右轮速差转向，最常用
- 阿克曼（Ackermann）：汽车模型，前轮转向
- 全向轮（Omni）：麦轮/瑞典轮，任意方向移动

## 关键依赖
- `nav2_msgs`, `nav2_util` — 导航框架
- `geometry_msgs/Twist` — 速度命令 `/cmd_vel`
- `nav_msgs/Odometry` — 里程计 `/odom`
- `sensor_msgs/Imu` — IMU `/imu/data`
- `sensor_msgs/LaserScan` — 激光雷达 `/scan`

## 核心 Topic
| Topic | 类型 | QoS | 用途 |
|-------|------|-----|------|
| `/cmd_vel` | `Twist` | reliable | 速度控制 |
| `/odom` | `Odometry` | reliable | 里程计 |
| `/imu/data` | `Imu` | best_effort | 惯性测量 |
| `/scan` | `LaserScan` | best_effort | 激光雷达 |
| `/camera/image_raw` | `Image` | best_effort | 相机 |

## 标准 Launch
```bash
ros2 launch nav2_bringup bringup_launch.py slam:=False map:=xxx.yaml
```

## 常用参数（diff_driver）
```yaml
min_vel_x: 0.0
max_vel_x: 2.0
min_vel_theta: -3.14
max_vel_theta: 3.14
```

## 生成器选择
- 包生成：`ros2-package-generator.sh <pkg> cpp nav2_msgs,nav2_util`
- Nav2节点：`ros2-nav2-node-generator.sh lifecycle|costmap|controller`
- 参数生成：`ros2-param-generator.sh diff|ackermann`
- 仿真生成：`ros2-simulator-generator.sh wheeled`

## 常见错误
- `/cmd_vel` 无数据 → controller 未激活，查看 `ros2 lifecycle get /controller`
- 里程计漂移 → 检查轮式编码器发布频率
