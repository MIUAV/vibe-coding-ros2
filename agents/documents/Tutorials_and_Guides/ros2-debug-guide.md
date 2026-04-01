# ROS2 调试指南

> 详细的 ROS2 调试方法和工具使用指南

---

## 1. 调试工具概览

### 1.1 命令行工具

```bash
# 核心调试工具
ros2 pkg list                    # 列出所有包
ros2 node list                   # 列出运行中的节点
ros2 topic list                   # 列出所有 topic
ros2 service list                 # 列出所有 service
ros2 action list                  # 列出所有 action
ros2 param list                   # 列出所有参数

# 信息查看
ros2 node info /node_name        # 查看节点详情
ros2 topic info /topic_name       # 查看 topic 详情
ros2 service info /service_name   # 查看 service 详情
ros2 interface list               # 列出所有消息类型
```

### 1.2 GUI 工具

| 工具 | 用途 | 命令 |
|------|------|------|
| rqt_graph | 可视化计算图 | `ros2 run rqt_graph rqt_graph` |
| rqt_console | 查看日志 | `ros2 run rqt_console rqt_console` |
| rqt_logger_level | 设置日志级别 | `ros2 run rqt_logger_level rqt_logger_level` |
| rqt_plot | 绘制数据曲线 | `ros2 run rqt_plot rqt_plot` |
| rqt_image_view | 查看图像 | `ros2 run image_view image_view` |
| rviz2 | 3D 可视化 | `rviz2` |

---

## 2. Topic 调试

### 2.1 查看 Topic 数据

```bash
# 实时查看 topic (按 Ctrl+C 退出)
ros2 topic echo /topic_name

# 只查看一条消息
ros2 topic echo /topic_name --once

# 查看 topic 详细信息
ros2 topic info /topic_name

# 查看 topic 频率
ros2 topic hz /topic_name

# 查看 topic 带宽
ros2 topic bw /topic_name

# 查找 topic 类型
ros2 interface show /sensor_msgs/msg/Image
```

### 2.2 发布测试消息

```bash
# 发布字符串
ros2 topic pub /chatter std_msgs/msg/String "data: 'hello'" --once

# 发布整数
ros2 topic pub /counter std_msgs/msg/Int32 "data: 5" -r 10  # 10Hz

# 发布图像 (需要完整消息结构)
ros2 topic pub /camera/image_raw sensor_msgs/msg/Image "{header: {stamp: {sec: 0, nanosec: 0}, frame_id: 'camera'}, height: 480, width: 640, encoding: 'rgb8', step: 1920, data: [0]}"

# 发布 PointCloud2
ros2 topic pub /scan sensor_msgs/msg/LaserScan '{header: {stamp: {sec: 0, nanosec: 0}, frame_id: "laser"}, angle_min: -3.14, angle_max: 3.14, angle_increment: 0.01, time_increment: 0.0, scan_time: 0.1, range_min: 0.1, range_max: 30.0, ranges: [1.0, 2.0, 3.0]}'
```

### 2.3 延迟和性能测量

```bash
# 测量 topic 延迟 (消息头中的时间戳 vs 当前时间)
ros2 topic delay /topic_name

# 测量发布-订阅延迟
ros2 topic pub /test_topic std_msgs/msg/Header "{data: ''}" --once
# Header 中会自动填充时间戳

# 录制 bag 并分析
ros2 bag record /topic_name -o bag_name
ros2 bag info bag_name
ros2 bag play bag_name
```

---

## 3. Node 调试

### 3.1 查看节点信息

```bash
# 列出所有运行中的节点
ros2 node list

# 查看特定节点信息
ros2 node info /camera_driver_node

# 输出示例:
# /camera_driver_node
#   Subscribers:
#     /parameter_events: rcl_interfaces/msg/ParameterEvent
#   Publishers:
#     /camera/image_raw: sensor_msgs/msg/Image
#     /rosout: rcl_interfaces/msg/Log
#   Service Servers:
#     /camera_driver_node/describe_parameters: rcl_interfaces/srv/DescribeParameters
#   Service Clients:
#   Action Servers:
#   Action Clients:
```

### 3.2 节点命名空间

```bash
# 查看节点对应的完整话题名
ros2 topic list | grep camera

# 重映射节点名
ros2 run pkg node --ros-args -r __node:=new_name

# 设置命名空间
ros2 run pkg node --ros-args -r __ns:=/robot1
```

### 3.3 节点调试模式

```bash
# 以 GDB 调试模式启动
ros2 run pkg node --prefix 'gdb -ex run -ex bt'

# 以 Valgrind 内存分析启动
ros2 run pkg node --prefix 'valgrind --leak-check=full'

# 以 Perf 性能分析启动
ros2 run pkg node --prefix 'perf record -g'
```

---

## 4. 参数调试

### 4.1 查看和设置参数

```bash
# 列出节点参数
ros2 param list /node_name

# 获取参数值
ros2 param get /node_name param_name

# 设置参数 (运行时)
ros2 param set /node_name param_name value

# 列出所有参数 (YAML 格式)
ros2 param dump /node_name

# 从文件加载参数
ros2 param load /node_name config.yaml
```

### 4.2 动态参数

```cpp
// C++ 中声明动态参数
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_components/register_node_macro.hpp>

class MyNode : public rclcpp::Node {
public:
    MyNode() : Node("my_node") {
        // 声明参数
        this->declare_parameter<int>("queue_size", 10);
        this->declare_parameter<double>("threshold", 0.5);
        
        // 获取参数
        int queue_size;
        this->get_parameter("queue_size", queue_size);
        
        // 参数回调
        this->set_on_parameters_set_callback(
            [this](std::vector<rclcpp::Parameter> params) {
                for (auto& param : params) {
                    if (param.get_name() == "threshold") {
                        RCLCPP_INFO(this->get_logger(), 
                                   "threshold changed to %f", 
                                   param.as_double());
                    }
                }
                return rcl_interfaces::msg::SetParametersResult();
            });
    }
};
```

---

## 5. Service 调试

### 5.1 调用 Service

```bash
# 列出所有 service
ros2 service list

# 查看 service 类型
ros2 service type /service_name

# 查看 service 详情
ros2 service find <service_type>

# 调用 service (交互式)
ros2 service call /service_name srv_type "request: {data: 1}"

# 调用 service (一次性)
ros2 service call /reset std_srvs/srv/Empty "{}"
```

### 5.2 Service 测试示例

```bash
# /add_two_ints service
ros2 service call /add_two_ints example_interfaces/srv/AddTwoInts "{a: 5, b: 3}"

# 响应
# waiting for service to be available...
# making request as: example_interfaces.srv.AddTwoInts_Request(a=5, b=3)
# response:
#   sum: 8
```

---

## 6. Action 调试

### 6.1 Action 命令

```bash
# 列出所有 action
ros2 action list

# 查看 action 类型
ros2 action action_list /navigate_to_pose

# 查看 action 详情
ros2 action info /navigate_to_pose

# 发送 action goal
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose "
{
  'pose': {
    'header': {'stamp': {sec: 0}, 'frame_id': 'map'},
    'pose': {'position': {x: 1.0, y: 2.0}, 'orientation': {z: 0.0}}
  }
}
"

# 带反馈查看
ros2 action send_goal /navigate_to_pose nav2_msgs/action/NavigateToPose "
{
  'pose': {
    'header': {'stamp': {sec: 0}, 'frame_id': 'map'},
    'pose': {'position': {x: 1.0, y: 2.0}, 'orientation': {z: 0.0}}
  }
}" --feedback
```

---

## 7. 日志调试

### 7.1 日志级别

```bash
# 打开日志控制台
ros2 run rqt_console rqt_console

# 设置日志级别
ros2 run rqt_logger_level rqt_logger_level

# 命令行设置
ros2 param set /node_name log_level DEBUG  # DEBUG, INFO, WARN, ERROR, FATAL
```

### 7.2 代码中输出日志

```cpp
// 日志级别
RCLCPP_DEBUG(this->get_logger(), "Debug message: %d", value);
RCLCPP_INFO(this->get_logger(), "Info message: %s", str.c_str());
RCLCPP_WARN(this->get_logger(), "Warning: low memory");
RCLCPP_ERROR(this->get_logger(), "Error: failed to open file");
RCLCPP_FATAL(this->get_logger(), "Fatal: system shutdown");

// 条件日志
RCLCPP_INFO_ONCE(this->get_logger(), "This prints only once");
RCLCPP_INTERVAL_RATE(this->get_logger(), 1000);  // 每秒最多一次
```

### 7.3 日志保存

```bash
# 保存日志到文件
ros2 run rqt_console rqt_console  # 在 GUI 中 File -> Save

# 或者重定向输出
ros2 run pkg node > node.log 2>&1
```

---

## 8. Bag 回放

### 8.1 录制

```bash
# 录制所有 topic
ros2 bag record -a

# 录制特定 topic
ros2 bag record /scan /camera/image_raw /odom

# 指定文件名
ros2 bag record /scan -o scan_data

# 录制压缩
ros2 bag record /scan -o scan_data --compression-type lz4
```

### 8.2 回放

```bash
# 查看 bag 信息
ros2 bag info bag_name

# 回放 (暂停/继续: 空格)
ros2 bag play bag_name

# 回放特定 topic
ros2 bag play bag_name --topic /scan

# 调整回放速率
ros2 bag play bag_name --rate 0.5  # 0.5x 速度
ros2 bag play bag_name --rate 2.0  # 2x 速度

# 循环回放
ros2 bag play bag_name --loop
```

---

## 9. RQT 工具详解

### 9.1 rqt_graph (计算图可视化)

```bash
ros2 run rqt_graph rqt_graph
```

常用操作:
- 鼠标滚轮: 缩放
- 拖拽: 移动节点
- 右上角过滤: 过滤节点/Topic
- Options -> Debug: 显示隐藏的发布/订阅

### 9.2 rqt_plot (数据曲线)

```bash
ros2 run rqt_plot rqt_plot
```

使用:
1. 在 Topic 输入框输入: `/odom/pose/pose/position/x`
2. 点击绿+按钮添加
3. 实时显示数据曲线

### 9.3 rqt_image_view (图像查看)

```bash
ros2 run image_view image_view --ros-args -r image:=/camera/image_raw
```

### 9.4 rviz2 (3D 可视化)

```bash
rviz2
```

常用配置:
- Add -> By topic -> /scan: 激光扫描
- Add -> By topic -> /image: 相机图像
- Add -> By topic -> /odom: 里程计
- Add -> By display -> RobotModel: 机器人模型

---

## 10. 性能分析

### 10.1 延迟分析

```bash
# 使用 ros2 topic delay
ros2 topic delay /camera/image_raw

# 输出: Average delay: 12.345ms
```

### 10.2 内存分析

```bash
# Valgrind
valgrind --tool=memcheck --leak-check=full \
    --log-file=memcheck.log \
    ros2 run pkg node

# 查看泄漏
cat memcheck.log | grep "definitely lost" -A 5
```

### 10.3 CPU 分析

```bash
# Perf
sudo perf record -g -p $(ros2 pid /node_name) -o perf.data
sudo perf report -i perf.data

#火焰图 (需安装)
git clone https://github.com/brendangregg/FlameGraph.git
sudo perf script -i perf.data | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > flamegraph.svg
```

---

## 11. 常见问题调试

### 11.1 Topic 无数据

```bash
# 1. 检查 topic 是否存在
ros2 topic list | grep topic_name

# 2. 检查发布者是否运行
ros2 node info /publisher_node

# 3. 检查订阅者是否匹配 QoS
ros2 topic info /topic_name

# 4. 检查消息类型
ros2 interface show sensor_msgs/msg/Image
```

### 11.2 节点崩溃

```bash
# 1. 检查 dmesg
dmesg | tail -50 | grep -i "segfault\|killed"

# 2. 使用 gdb
gdb -ex run -ex bt ros2 run pkg node

# 3. 检查 ulimit
ulimit -a
```

### 11.3 通信延迟高

```bash
# 1. 检查网络
ping target_ip

# 2. 检查 CPU 负载
top -H

# 3. 检查消息大小
ros2 topic type /topic_name | xargs ros2 interface show

# 4. 使用 intra-process 减少延迟
# 在代码中启用
rclcpp::PublisherOptionsWithAllocator<std::allocator<void>> options;
options.use_intra_process_comms(true);
```

---

## 12. 调试检查清单

```markdown
## ROS2 调试检查清单

### 节点问题
- [ ] ros2 node list 能看到节点
- [ ] ros2 node info 显示正确的订阅/发布
- [ ] 节点日志无错误

### 通信问题
- [ ] ros2 topic list 显示 topic
- [ ] ros2 topic hz 有数据
- [ ] ros2 topic echo 能看到数据
- [ ] QoS 设置匹配

### 参数问题
- [ ] ros2 param list 显示参数
- [ ] ros2 param get 能获取值
- [ ] 参数类型正确

### 性能问题
- [ ] CPU 使用率正常
- [ ] 内存使用正常
- [ ] 延迟在可接受范围

### 日志
- [ ] rqt_console 无 ERROR/FATAL
- [ ] 日志级别设置正确
```

---

*掌握这些调试技巧，可以快速定位和解决 ROS2 项目中的问题*
