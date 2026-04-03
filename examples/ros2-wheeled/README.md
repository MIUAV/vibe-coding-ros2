# Wheeled Robot Examples

## diff_drive_controller

差速驱动轮式机器人控制器。

### 功能

- 接收 `/cmd_vel` (Twist) → 发布左右轮速
- 发布里程计 `/odom`
- 广播 TF (odom → base_link)

### 编译

```bash
colcon build --packages-select diff_drive_controller --symlink-install
```

### 运行

```bash
ros2 run diff_drive_controller diff_drive_controller
```

### 差速驱动数学

```
v_l = v - ω × W / 2
v_r = v + ω × W / 2
```

其中 v=线速度, ω=角速度, W=轮距
