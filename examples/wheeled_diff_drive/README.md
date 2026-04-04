# wheeled_diff_drive — 差速驱动控制器示例

> 演示 ROS2 差速驱动运动学转换。适合轮式机器人（Robotnik, KUKA, Clearpath Husky 等）。

## 运动学

```
v_l = v - ω × (W/2)
v_r = v + ω × (W/2)

v  = 线速度 (m/s)
ω  = 角速度 (rad/s)
W  = 轮距 (m)
```

逆运动学：给定 `cmd_vel (v, ω)` → 计算左右轮速度。

## 编译

```bash
cd /path/to/ros2_ws
colcon build --packages-select wheeled_diff_drive
source install/setup.bash
```

## 运行

```bash
# 基本运行
ros2 run wheeled_diff_drive diff_drive_node

# 带参数
ros2 run wheeled_diff_drive diff_drive_node --ros-args -p wheelbase:=0.6 -p max_linear_vel:=1.5

# Launch 启动
ros2 launch wheeled_diff_drive diff_drive.launch.py
```

## 测试

```bash
# 模拟 cmd_vel（前进 0.5m/s）
ros2 topic pub /cmd_vel geometry_msgs/Twist '{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}' -1

# 查看左右轮速输出
ros2 topic echo /left_wheel_velocity
ros2 topic echo /right_wheel_velocity

# 查看所有话题
ros2 topic list | grep wheel
```

## 话题

| 类型 | 名称 | 说明 |
|------|------|------|
| 订阅 | `/cmd_vel` | 几何速度命令 |
| 发布 | `/left_wheel_velocity` | 左轮速度 (m/s) |
| 发布 | `/right_wheel_velocity` | 右轮速度 (m/s) |

## 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `wheelbase` | 0.5 m | 机器人轮距 |
| `max_linear_vel` | 1.0 m/s | 最大线速度 |
| `max_angular_vel` | 2.0 rad/s | 最大角速度 |

## QoS 说明

- `cmd_vel` 订阅: **RELIABLE** — 控制命令不能丢
- 轮速发布: **RELIABLE** — 轮子速度命令必须完整送达

## 关键代码

```cpp
// 差速运动学（必须在 QoS RELIABLE 模式下）
double half_wheelbase = wheelbase_ / 2.0;
double v_left  = v - ω * half_wheelbase;
double v_right = v + ω * half_wheelbase;
```

## 集成到真实机器人

将 `/left_wheel_velocity` 和 `/right_wheel_velocity` 映射到你的电机驱动接口：

1. 修改 launch 文件的 `left_wheel_topic` / `right_wheel_topic`
2. 在电机控制节点中订阅这两个话题
3. 将速度值转换为电机 PWM/电流指令
