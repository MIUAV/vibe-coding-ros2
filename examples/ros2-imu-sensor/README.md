# ros2-imu-sensor — IMU 传感器节点示例

> 演示 sensor_msgs/Imu + QoS BEST_EFFORT + TF2 广播。

## 编译

```bash
colcon build --packages-select ros2_imu_sensor
source install/setup.bash
```

## 运行

```bash
ros2 run ros2_imu_sensor imu_sensor_node
```

## 查看数据

```bash
# 查看 IMU 数据
ros2 topic echo /imu/data

# 查看 IMU 频率
ros2 topic hz /imu/data

# 可视化（需 IMU 过滤器）
ros2 run rqt_imu_filter rqt_imu_filter
```

## QoS 重要

IMU 必须用 **BEST_EFFORT**：
- IMU 频率 100-1000Hz
- 丢一帧不影响整体运动估计
- RELIABLE 会导致延迟累积

```cpp
rclcpp::QoS imu_qos(100);
imu_qos.best_effort();  // IMU 专用
```

## 真实 IMU 驱动

| IMU | ROS2 驱动 |
|-----|-----------|
| Bosch BMI085 | `bmi088` |
| MPU6050 | `mpu6050_driver` |
| XSens MTi | `xsensmt_ros2` |
| Ouster IMU | `ouuster_driver` |
