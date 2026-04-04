---
name: ros2-debug
description: ROS2调试技能 - 编译错误诊断/QoS静默失败/TF问题/rclcpp崩溃/Lifecycle调试/性能剖析
argument-hint: ros2调试 OR cmake错误 OR QoS不兼容 OR tf问题 OR 崩溃 OR Lifecycle调试 OR rclcpp
user-invocable: true
---

# ROS2 调试技能

> 用于诊断和解决 ROS2 开发中的各类运行时/编译时问题

---

## 一、编译错误

### 1.1 "non-existent dependency XXX"

```bash
# 诊断
colcon build --packages-select <pkg> 2>&1 | grep "non-existent"

# 修复：添加缺失的 find_package
find_package(XXX REQUIRED)
ament_target_dependencies(my_node XXX)
ament_export_dependencies(XXX)
```

### 1.2 "undefined reference to YYY"

```bash
# 原因：YYY 是某个库的符号，但未链接
# 修复：在 ament_target_dependencies 中加入该库
ament_target_dependencies(my_node rclcpp cv_bridge sensor_msgs)
```

### 1.3 "ament_index_is_register_plugins failed"

```bash
# 原因：plugin_description.xml 中的插件未注册
# 修复：添加 ament_register_plugins
ament_register_plugins(${PROJECT_NAME}
  "plugins/${PROJECT_NAME}/plugin_description.xml")
```

---

## 二、运行时崩溃

### 2.1 Segmentation Fault

```bash
# 诊断：使用 gdb
ros2 run --debug --prefix 'gdb -ex run -ex bt' <pkg> <node>

# 常见原因：
# - SharedPtr 为空
# - 访问已释放对象
# - 线程安全问题
```

### 2.2 "failed to initialize rcl"

```bash
# 原因：多次调用 rclcpp::init()
# 修复：确保只初始化一次
if (!rclcpp::ok()) {
  rclcpp::init(argc, argv);
}
```

### 2.3 定时器回调崩溃

```bash
# 原因：回调中访问已释放对象
# 修复：捕获 shared_from_this
auto self = shared_from_this();
timer_ = this->create_wall_timer(1s, [this, self]() {
  // self 确保对象存活
});
```

---

## 三、QoS 静默失败（最难调试）

### 3.1 现象：数据发布但订阅端收不到

```bash
# 第一步：查看两端 QoS
ros2 topic info /topic_name --verbose
```

### 3.2 QoS 兼容性矩阵

| 发布者 | 订阅者 | 结果 |
|--------|--------|------|
| BestEffort | Reliable | ❌ |
| Reliable | BestEffort | ✅ |
| Volatile | TransientLocal | ❌ |

### 3.3 修复

```cpp
// 发布端显式设置 QoS
rclcpp::QoS qos(10);
qos.best_effort();           // 传感器
qos.reliable();              // 控制命令
qos.transient_local();       // 迟到订阅者

publisher_ = this->create_publisher<Msg>("/topic", qos);
```

---

## 四、TF 问题

### 4.1 TF 广播频率不匹配

```bash
# 查看 TF 频率
ros2 topic hz /tf
ros2 topic hz /tf_static

# 常见问题：定位漂移 = 频率不匹配
# 解决：确保所有传感器频率一致
```

### 4.2 Frame not found

```bash
# 诊断
ros2 run tf2_ros tf2_echo world base_link

# 如果报错 "Frame not found"：
# 1. 检查 broadcaster 是否发布
# 2. 检查时间戳同步
# 3. 检查是否存在循环引用
```

---

## 五、Lifecycle 调试

### 5.1 查看 Lifecycle 状态

```bash
# 列出所有 lifecycle 节点
ros2 lifecycle list /node_name

# 触发状态转换
ros2 lifecycle set /node_name configure
ros2 lifecycle set /node_name activate
ros2 lifecycle set /node_name deactivate
```

### 5.2 节点卡在 inactive

```bash
# 查看 /rosout 日志
ros2 run rqt_console rqt_console

# on_configure 回调返回 FAILURE 通常是原因
```

---

## 六、rclpy 问题

### 6.1 节点无法退出

```python
# 错误
def main():
    rclpy.init()
    node = MyNode()
    rclpy.spin(node)
    # Ctrl+C 无响应，没有 shutdown

# 正确
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

### 6.2 回调阻塞

```python
# 错误：在回调中使用 time.sleep()
def callback(self, msg):
    time.sleep(1)  # 阻塞整个事件循环

# 正确：用 timer
self.timer = self.create_timer(1.0, self.timer_callback)
```

---

## 七、性能问题

### 7.1 高频消息丢帧

```bash
# 诊断
ros2 topic hz /topic_name

# 如果频率远低于预期：
# 1. 检查 QoS 是否为 BestEffort（传感器）
# 2. 检查是否用 SingleThreadedExecutor（改用 MultiThreaded）
```

### 7.2 CPU 占用高

```bash
# 使用 top 定位高 CPU 进程
top -p $(pgrep -f <node_name>)

# 常见原因：
# - 回调中有耗时计算
# - 日志输出过多
# - 定时器间隔太短
```

---

## 八、常用调试命令速查

```bash
# 计算图
rqt_graph

# 话题
ros2 topic list -v
ros2 topic info /name --verbose
ros2 topic echo /name
ros2 topic hz /name
ros2 topic bw /name

# 节点
ros2 node list
ros2 node info /name

# 服务
ros2 service list
ros2 service call /name type "{...}"

# 参数
ros2 param list
ros2 param set /node param value
ros2 param get /node param

# Lifecycle
ros2 lifecycle list /node
ros2 lifecycle set /node state

# TF
ros2 run tf2_ros view_frames
ros2 run tf2_ros tf2_echo frame1 frame2

# 日志
ros2 run rqt_console rqt_console
```
