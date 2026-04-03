# 轮式机器人示例

## diff_drive_controller

差速驱动控制器：接收 `/cmd_vel`，输出左右轮速 + 里程计 + TF

### 编译运行

```bash
colcon build --packages-select diff_drive_controller --symlink-install
ros2 run diff_drive_controller diff_drive_controller
```

### 话题

| 话题 | 类型 | 方向 |
|------|------|------|
| `/cmd_vel` | geometry_msgs/msg/Twist | 订阅 |
| `/wheel_l_speed` | geometry_msgs/msg/Float32 | 发布 |
| `/wheel_r_speed` | geometry_msgs/msg/Float32 | 发布 |
| `/odom` | nav_msgs/msg/Odometry | 发布 |

### TF

```
odom → base_link
```

### 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `wheel_base` | 0.5 m | 左右轮间距 |
| `max_speed` | 1.0 m/s | 最大线速度 |

### 差速数学

```
v_l = v − ω × W/2
v_r = v + ω × W/2
```

### 规范

- SharedPtr 订阅
- rclcpp::init / rclcpp::shutdown
- std::mutex 线程安全
- MultiThreadedExecutor
- QoS reliable（控制命令不能丢）
