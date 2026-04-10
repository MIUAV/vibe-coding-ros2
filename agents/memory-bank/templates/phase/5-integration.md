# Phase 5: Integration & Testing

## Gazebo 仿真验证
```bash
# 启动仿真
ros2 launch gazebo_ros house_of_worlds.launch.py

# 加载机器人
ros2 run gazebo_ros spawn_entity.py -file robot.urdf -entity my_robot

# 键盘控制（临时）
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

## Nav2 集成验证
```bash
# SLAM 建图
ros2 launch nav2_bringup bringup_launch.py slam:=True

# 保存地图
ros2 run nav2_map_server map_saver_cli -f my_map

# 定位导航
ros2 launch nav2_bringup bringup_launch.py map:=my_map.yaml params_file:=nav2_params.yaml
```

## 集成检查表
- [ ] 传感器数据流正常（topic 有数据）
- [ ] 控制命令到达执行器
- [ ] 安全机制有效（障碍物检测停障）
- [ ] lifecycle 状态切换正常
- [ ] 多机通信正常（如有多机）

## 性能基准
| 指标 | 目标 | 测量方法 |
|------|------|---------|
| 感知→控制延迟 | < 100ms | topic hz + echo 时间差 |
| CPU 占用 | < 70%/core | `top` |
| 内存占用 | < 2GB | `free -h` |
| 图像帧率 | ≥ 15fps | `ros2 topic hz /camera/image_raw` |
