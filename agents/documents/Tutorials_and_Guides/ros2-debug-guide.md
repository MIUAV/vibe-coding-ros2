# ROS2 调试完整指南

> 覆盖：编译错误、运行时崩溃、QoS 静默失败、TF 问题、Lifecycle 调试

---

## 一、colcon build 错误速查

### 错误 1：non-existent dependency

```
CMake Error at CMakeLists.txt:XX (ament_target_dependencies):
  target "my_node" links to non-existent dependency "cv_bridge"
```

**原因**：`find_package(cv_bridge REQUIRED)` 缺失，或 cv_bridge 未安装。

**修复**：
```bash
# 检查是否安装
ros2 pkg list | grep cv_bridge

# 如果没有
sudo apt install ros-humble-cv-bridge

# CMakeLists.txt 添加
find_package(cv_bridge REQUIRED)
ament_target_dependencies(my_node cv_bridge)
```

### 错误 2：undefined reference

```
undefined reference to `cv_bridge::toCvShare()
```

**原因**：CMakeLists.txt 中只 `find_package` 了 cv_bridge，但没有 `ament_target_dependencies`。

**修复**：
```cmake
ament_target_dependencies(my_node
  cv_bridge
  sensor_msgs
  image_transport
)
```

### 错误 3：ament_export_dependencies 缺失

```
target "my_node" has dependency on "rclcpp" which is not ament_export_dependencies
```

**原因**：传递依赖未导出。解决：删除 `ament_export_dependencies` 或用 `ament_auto` 代替。

**修复**：使用 `ament_auto` 自动处理导出：
```cmake
ament_auto_find_build_dependencies()
ament_auto_add_library(${PROJECT_NAME} SHARED src/my_node.cpp)
ament_auto_package()
```

### 错误 4：ament_index_is_register_plugins 报错

```
ament_index_is_register_plugins: Something about pluginlist
```

**原因**：`plugin_description.xml` 中声明的插件未正确注册。

**修复**：
```cmake
ament_register_plugins(${PROJECT_NAME} "plugins/${PROJECT_NAME}/plugin_description.xml")
```

---

## 二、运行时崩溃诊断

### 崩溃 1：Segmentation Fault（段错误）

**常见原因**：
1. SharedPtr 为空
2. 访问已释放的内存
3. 线程安全问题

**诊断**：
```bash
# 使用 gdb 调试
ros2 run --debug --prefix 'gdb -ex run -ex bt' <pkg> <node>

# 或使用asan
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug \
  --cmake-args -DSANITIZE=address
```

### 崩溃 2：多次 rclcpp::init 调用

```
terminate called after throwing an exception: failed to initialize rcl
```

**原因**：代码中有多个 `rclcpp::init()` 调用。

**修复**：确保 `rclcpp::init()` 只调用一次，用 `rclcpp::ok()` 检查：
```cpp
if (!rclcpp::ok()) {
  rclcpp::init(argc, argv);
}
```

### 崩溃 3：定时器回调崩溃

**原因**：回调中访问已释放的对象。

**修复**：使用 `shared_from_this()` 或确保对象生命周期：
```cpp
auto self = shared_from_this();
timer_ = this->create_wall_timer(1s, [this, self]() {
  // self 捕获确保对象存活
});
```

---

## 三、QoS 静默失败（最难调试）

### 现象：数据明明发布，但订阅端收不到

**诊断步骤**：
```bash
# 1. 查看话题 QoS
ros2 topic info /scan --verbose

# 输出示例：
# Type: sensor_msgs/msg/LaserScan
# Publisher count: 1
#     QoS:
#       Reliability: BEST_EFFORT  ← 这里！
#       Durability: VOLATILE
# Subscription count: 1
#     QoS:
#       Reliability: RELIABLE      ← 不匹配！
#       Durability: TRANSIENT_LOCAL
```

**常见不兼容组合**：

| 发布者 QoS | 订阅者 QoS | 结果 |
|------------|-------------|------|
| BestEffort | Reliable | ❌ 收不到 |
| Reliable | BestEffort | ✅ 兼容 |
| Volatile | TransientLocal | ❌ 收不到（历史数据丢失）|

**修复**：
```cpp
// 发布者端显式设置 QoS
rclcpp::QoS qos(10);
qos.best_effort();                    // 传感器数据
qos.transient_local();                 // 迟到订阅者也要收到

publisher_ = this->create_publisher<sensor_msgs::msg::LaserScan>("/scan", qos);
```

### QoS 测试命令

```bash
# 测试不同 QoS 组合
ros2 topic pub /scan sensor_msgs/msg/LaserScan '{}' \
  --once \
  -r 1 \
  --qos-reliability best_effort

ros2 topic pub /scan sensor_msgs/msg/LaserScan '{}' \
  --once \
  -r 1 \
  --qos-reliability reliable
```

---

## 四、TF 调试

### 问题 1：TF 广播频率不匹配导致定位漂移

**诊断**：
```bash
# 查看所有 TF frame
ros2 run tf2_ros view_frames

# 查看特定变换的频率
ros2 topic hz /tf_static    # 静态变换（应为 0 或很低）
ros2 topic hz /tf           # 动态变换（应与传感器频率匹配）
```

### 问题 2：TF 树断裂

```bash
# 检查特定 frame 的父 frame
ros2 run tf2_ros tf2_echo world base_link

# 查看两个 frame 之间的时间差
ros2 run tf2_ros tf2_echo target_frame source_frame
```

### 问题 3：TF 找不到变换

```bash
# 检查 frame 是否存在
ros2 run tf2_ros tf2_echo map odom

# 如果报错 "Frame not found"，检查：
# 1. broadcaster 是否正常发布
# 2. 时间戳是否同步（检查时钟）
# 3. 是否存在循环引用
```

---

## 五、Lifecycle 状态机调试

### 查看所有 Lifecycle 节点

```bash
ros2 lifecycle list /node_name
```

输出：
```
node_name transitions are:
    configure -> [inactive]
    activate -> [active]
    deactivate -> [inactive]
    cleanup -> [unconfigured]
    shutdown -> [finalized]
```

### 手动触发状态转换

```bash
# 配置节点
ros2 lifecycle set /node_name configure

# 激活节点
ros2 lifecycle set /node_name activate

# 查看当前状态
ros2 lifecycle list /node_name
```

### Lifecycle 常见问题

**问题**：节点卡在 `inactive` 状态无法激活。

**原因**：`on_configure` 回调返回 FAILURE。

**诊断**：
```bash
# 查看 /rosout 日志
ros2 run rqt_console rqt_console

# 或
ros2 topic echo /rosout --once | grep node_name
```

---

## 六、rclpy 调试

### 问题：rclpy 节点无法退出（ctrl+c 无响应）

**原因**：`rclpy.spin(node)` 没有在 `finally` 块中调用 `rclpy.shutdown()`。

**修复**：
```python
def main():
    rclpy.init()
    node = MyNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()
```

### 问题：Python 回调阻塞事件循环

**诊断**：检查是否有 `time.sleep()` 或同步 I/O。

**修复**：使用 `rclpy.timer.Timer` 而非 `time.sleep`。

---

## 七、ros2 常用调试命令速查

```bash
# 启动节点带调试
ros2 run --debug --prefix 'gdb -ex run -ex bt' <pkg> <node>

# 查看实时计算图
rqt_graph

# 查看节点订阅/发布/服务
ros2 node info /node_name

# 查看话题带宽和频率
ros2 topic bw /topic_name
ros2 topic hz /topic_name

# 查看服务调用延迟
ros2 service call /service type '{}' --print  # 观察时间

# 查看参数
ros2 param list
ros2 param get /node_name param_name
ros2 param set /node_name param_name value

# 录制 bag 并分析
ros2 bag record /topic1 /topic2 -o output.bag
ros2 bag play output.bag

# 内存/CPU 分析
valgrind --tool=memcheck ros2 run <pkg> <node>
```

---

## 八、日志级别控制

```bash
# 设置单个节点日志级别
ros2 run rqt_logger_level rqt_logger_level

# 或命令行
ros2 param set /node_name log_level DEBUG

# 查看所有节点日志
ros2 run rqt_console rqt_console

# 日志等级：DEBUG < INFO < WARN < ERROR < FATAL
```
