---
name: ros2-debugging
description: ROS2 调试技能 - 节点调试、话题分析、bag 回放、rqt 工具使用
---

# ROS2 Debugging Skill

> ROS2 调试方法、工具使用和问题排查指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 调试 ROS2 节点通信问题
- 分析 topic 数据流
- 回放 bag 文件排查问题
- 使用 rqt 工具可视化
- 定位性能瓶颈

---

## 快速参考

### 常用命令

```bash
# 节点
ros2 node list                    # 列出节点
ros2 node info /node_name         # 节点详情

# Topic
ros2 topic list                    # 列出话题
ros2 topic echo /topic_name       # 查看数据
ros2 topic hz /topic_name         # 查看频率
ros2 topic bw /topic_name         # 查看带宽
ros2 topic pub /topic_name ...    # 发布测试

# Service
ros2 service list                  # 列出服务
ros2 service call /srv_name ...    # 调用服务

# 参数
ros2 param list                    # 列出参数
ros2 param get /node_name param    # 获取参数
ros2 param set /node_name param value  # 设置参数

# Bag
ros2 bag record /topic_name       # 录制
ros2 bag play bag_name            # 回放
```

---

## Topic 调试

### 查看数据流

```bash
# 实时查看话题数据
ros2 topic echo /camera/image_raw

# 只看一条
ros2 topic echo /scan --once

# 查看频率
ros2 topic hz /scan

# 查看带宽
ros2 topic bw /scan
```

### 发布测试消息

```bash
# 发布字符串
ros2 topic pub /chatter std_msgs/msg/String "data: 'test'" --once

# 发布激光雷达数据
ros2 topic pub /scan sensor_msgs/msg/LaserScan "{header: {stamp: {sec: 0}, frame_id: 'laser'}, angle_min: -3.14, angle_max: 3.14, angle_increment: 0.01, time_increment: 0.0, scan_time: 0.1, range_min: 0.1, range_max: 30.0, ranges: [1.0, 2.0]}"

# 以频率发布
ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}}" -r 10
```

---

## rqt 工具

### rqt_graph

```bash
ros2 run rqt_graph rqt_graph
```

功能：
- 可视化节点间通信
- 过滤节点/话题
- 查看发布-订阅关系

### rqt_console

```bash
ros2 run rqt_console rqt_console
```

功能：
- 查看日志消息
- 过滤日志级别
- 保存日志

### rqt_plot

```bash
ros2 run rqt_plot rqt_plot
```

使用：
- 输入话题路径如 `/odom/pose/pose/position/x`
- 实时绘制数据曲线

### rqt_image_view

```bash
ros2 run image_view image_view --ros-args -r image:=/camera/image_raw
```

---

## Bag 回放

### 录制

```bash
# 录制单个话题
ros2 bag record /scan -o scan_bag

# 录制多个
ros2 bag record /scan /camera/image_raw /odom -o all_bag

# 压缩
ros2 bag record /scan -o scan_bag --compression-type lz4
```

### 回放

```bash
# 基本回放
ros2 bag play scan_bag

# 指定话题
ros2 bag play scan_bag --topic /scan

# 循环
ros2 bag play scan_bag --loop

# 调整速率
ros2 bag play scan_bag --rate 0.5
```

---

## 日志调试

### 设置日志级别

```bash
# 命令行
ros2 run rqt_logger_level rqt_logger_level

# 代码中
RCLCPP_DEBUG(this->get_logger(), "Debug: %d", value);
RCLCPP_INFO(this->get_logger(), "Info: %s", str.c_str());
RCLCPP_WARN(this->get_logger(), "Warning");
RCLCPP_ERROR(this->get_logger(), "Error");
RCLCPP_FATAL(this->get_logger(), "Fatal");
```

---

## 常见问题

### Topic 无数据

```bash
# 1. 检查话题是否存在
ros2 topic list | grep topic_name

# 2. 检查发布者
ros2 node info /publisher_node

# 3. 检查订阅者 QoS
ros2 topic info /topic_name

# 4. 验证数据类型
ros2 interface show sensor_msgs/msg/Image
```

### 节点崩溃

```bash
# 1. 查看 dmesg
dmesg | tail -50 | grep -i segfault

# 2. GDB 调试
ros2 run pkg node --prefix 'gdb -ex run -ex bt'

# 3. Valgrind 内存
valgrind --leak-check=full ros2 run pkg node
```

### 延迟高

```bash
# 1. 测量延迟
ros2 topic delay /topic_name

# 2. 检查 CPU
top -H

# 3. Intra-process (减少延迟)
# 代码中启用
rclcpp::PublisherOptionsWithAllocator<std::allocator<void>> options;
options.use_intra_process_comms(true);
```

---

## 调试检查清单

```markdown
## ROS2 调试检查清单

### 节点
- [ ] ros2 node list 能看到节点
- [ ] ros2 node info 订阅/发布正确
- [ ] 日志无 ERROR

### 通信
- [ ] ros2 topic list 显示话题
- [ ] ros2 topic hz 有数据
- [ ] QoS 匹配

### 性能
- [ ] CPU 正常
- [ ] 内存正常
- [ ] 延迟可接受
```
