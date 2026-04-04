# ROS2 常用开发提示词模板

> 适用于用户直接发起常见 ROS2 开发任务的场景
> 每个模板都包含：描述 → 生成 → 验证 三步

---

## 场景 1：创建激光扫描发布节点

**用户输入**：
```
创建一个发布激光扫描数据的 ROS2 节点
```

**AI 提示词（内部使用）**：
```
为以下需求生成完整的 ROS2 节点：
- 发布 /scan 话题，类型 sensor_msgs/msg/LaserScan
- 使用 sensor_dataQoS()
- 发布频率 10Hz
- 包含距离和角度信息模拟
- 节点名：laser_scan_publisher

生成后必须：
1. 创建 launch 文件启动节点
2. 使用 ros2 topic echo /scan 验证数据发布
3. 使用 ros2 topic hz /scan 验证频率
```

---

## 场景 2：创建导航路径订阅节点

**用户输入**：
```
订阅导航路径并可视化
```

**AI 提示词（内部使用）**：
```
为以下需求生成完整的 ROS2 节点：
- 订阅 /plan 话题，类型 nav_msgs/msg/Path
- 使用 reliable QoS
- 收到路径后打印起点和终点
- 节点名：path_subscriber

生成后必须：
1. 使用 ros2 run <pkg> path_subscriber 启动
2. 使用 ros2 topic list 确认话题存在
3. 使用 ros2 topic echo /plan 检查数据
```

---

## 场景 3：创建 Service 服务器（路径重规划）

**用户输入**：
```
创建一个 Service 服务器实现路径重规划
```

**AI 提示词（内部使用）**：
```
为以下需求生成完整的 ROS2 节点：
- Service 名：/replan_path
- Request: geometry_msgs/PoseStamped start, geometry_msgs/PoseStamped goal
- Response: nav_msgs/Path path
- 使用 rclcpp::executors::MultiThreadedExecutor
- 节点名：replan_server

生成后必须：
1. 创建 .srv 文件（srv/Replan.srv）
2. 在 CMakeLists.txt 添加 .srv 文件处理
3. 使用 ros2 service call /replan_path <pkg>/srv/Replan "{...}" 测试
```

---

## 场景 4：创建 Action 客户端（抓取任务）

**用户输入**：
```
创建一个 Action 客户端执行抓取任务
```

**AI 提示词（内部使用）**：
```
为以下需求生成完整的 ROS2 节点：
- Action 名：/grasp_action
- Goal: geometry_msgs/PoseStamped target_pose
- Feedback: float32 progress
- Result: bool success, string message
- 节点名：grasp_action_client
- 异步发送 goal 并处理 feedback/result 回调

生成后必须：
1. 创建 action 文件（action/Grasp.action）
2. 使用 ros2 action list 确认 action 存在
3. 使用 ros2 action send_goal 测试
```

---

## 场景 5：创建 Lifecycle 传感器节点

**用户输入**：
```
创建一个 Lifecycle 温度传感器节点
```

**AI 提示词（内部使用）**：
```
为以下需求生成 Lifecycle 节点：
- 节点名：temp_sensor_lifecycle
- 话题：/temperature，类型 std_msgs/msg/Float32
- 使用 sensor_dataQoS()
- on_configure: 创建 publisher
- on_activate: 开始发布
- on_deactivate: 停止发布
- on_cleanup: 清理资源
- 发布频率 1Hz 模拟数据

生成后必须：
1. 使用 ros2 lifecycle list 查看状态转换
2. 使用 ros2 lifecycle set /temp_sensor_lifecycle configure/activate/deactivate
3. 使用 ros2 topic echo /temperature 验证数据
```

---

## 场景 6：创建多传感器融合节点

**用户输入**：
```
创建一个融合激光和相机的障碍物检测节点
```

**AI 提示词（内部使用）**：
```
为以下需求生成 ROS2 节点：
- 订阅 /scan（sensor_msgs/LaserScan）和 /depth/image（sensor_msgs/Image）
- 使用 message_filters::TimeSynchronizer 同步
- 在回调中融合数据检测障碍物
- 发布 /obstacles（visualization_msgs/MarkerArray）
- 使用 MultiThreadedExecutor
- 节点名：obstacle_fusion

生成后必须：
1. 在 CMakeLists.txt 添加 message_filters 依赖
2. 使用 ros2 run <pkg> obstacle_fusion 启动
3. 使用 ros2 topic hz /scan /depth/image 确认频率匹配
```

---

## 场景 7：创建参数服务节点

**用户输入**：
```
创建一个支持动态参数调节的 PID 控制器节点
```

**AI 提示词（内部使用）**：
```
为以下需求生成 ROS2 节点：
- 节点名：pid_controller
- 参数：Kp（double, 1.0）, Ki（double, 0.1）, Kd（double, 0.01）
- 支持 rclcpp::AsyncParametersClient 动态修改
- 订阅 /error（std_msgs/Float64），发布 /control（std_msgs/Float64）
- 使用 get_parameter() 获取当前参数值

生成后必须：
1. 使用 ros2 param list 查看参数
2. 使用 ros2 param set /pid_controller Kp 2.0 动态调节
3. 在 rviz2 中可视化 /control 输出
```

---

## 通用验证命令速查

```bash
# 话题
ros2 topic list              # 列出所有话题
ros2 topic info /topic_name  # 查看话题类型/QoS
ros2 topic echo /topic_name  # 查看实时数据
ros2 topic hz /topic_name   # 查看发布频率

# 节点
ros2 node list              # 列出所有节点
ros2 node info /node_name   # 查看节点订阅/发布/服务

# 服务
ros2 service list            # 列出所有服务
ros2 service call /service_name pkg/type "{...}"

# Action
ros2 action list            # 列出所有 action
ros2 action send_goal /action_name pkg/type "{goal}"

# 参数
ros2 param list             # 列出所有参数
ros2 param set /node param value
ros2 param get /node param

# Lifecycle
ros2 lifecycle list          # 列出所有 lifecycle 节点
ros2 lifecycle set /node configure/activate/deactivate/cleanup
```
