---
name: ros2-debugging-tools
description: ROS2 调试工具技能 - CLI 调试、GDB、Valgrind、ros2cli、rqt 工具
argument-hint: ROS2调试 OR debugging OR gdb OR valgrind OR CLI
user-invocable: true
---

# ROS2 调试工具技能

> ROS2 调试工具使用

---

## 何时使用

当需要以下帮助时使用此技能：
- ros2cli 工具
- GDB 调试
- Valgrind 内存分析
- rqt 工具
- 日志管理

---

## 核心工具

### ros2cli 工具

```bash
# 话题操作
ros2 topic list                    # 列出所有话题
ros2 topic echo /scan             # 查看话题数据
ros2 topic hz /scan                # 查看发布频率
ros2 topic delay /scan             # 查看延迟
ros2 topic info /scan              # 查看话题信息

# 服务操作
ros2 service list                  # 列出所有服务
ros2 service call /get_map GetMap  # 调用服务

# 参数操作
ros2 param list                    # 列出参数
ros2 param get /node_name param    # 获取参数
ros2 param set /node_name param value  # 设置参数
ros2 param dump /node_name          # 导出参数

# 节点操作
ros2 node list                     # 列出节点
ros2 node info /node_name          # 节点信息

# 消息类型
ros2 interface list                # 列出所有消息类型
ros2 interface show sensor_msgs/LaserScan  # 查看消息结构
```

### GDB 调试

```bash
# 编译带调试信息
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug

# 使用 GDB 运行
gdb -ex run --args /path/to/executable

# 或在 CMakeLists.txt 中
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0")

# 调试 ROS2 节点
ros2 run -d --prefix 'gdb -ex run --args' package_name executable
```

### Valgrind 内存分析

```bash
# 安装
sudo apt install valgrind

# 内存检查
valgrind --leak-check=full --show-leak-kinds=all \
  --track-origins=yes --error-limit=no \
  /path/to/executable

# 使用 ros2 run
ros2 run -d --prefix 'valgrind --tool=memcheck' package executable
```

### rqt 工具

```bash
# 启动 rqt
rqt

# 常用插件
rqt_graph           # 节点图
rqt_console          # 日志控制台
rqt_plot            # 数据绘图
rqt_topic           # 话题监控
rqt_bag             # 数据录制回放
rqt_reconfigure     # 动态参数配置
```

### 日志管理

```python
# 日志配置
import rclpy
from rclpy.node import Node

class LoggingNode(Node):
    def __init__(self):
        super().__init__('logging_node')
        
        # 设置日志级别
        self.get_logger().set_level(rclpy.logging.LoggingSeverity.INFO)
        
        # 不同级别日志
        self.get_logger().debug('Debug message')
        self.get_logger().info('Info message')
        self.get_logger().warn('Warning message')
        self.get_logger().error('Error message')
        
    def configure_logging(self):
        """配置日志"""
        # 设置日志文件
        # self.get_logger().publish_durable(...)
        pass
```

### 常见问题诊断

```bash
# 1. 检查 DDS 发现
ros2 daemon stop
ros2 daemon start
ros2 run rqt_graph rqt_graph

# 2. 检查话题同步
ros2 topic echo /scan --full-length

# 3. 网络诊断
ros2 doctor

# 4. 资源监控
ros2 run rqt_topic rqt_topic

# 5. 内存泄漏检测
valgrind --tool=memcheck --leak-check=full --log-file=memcheck.log ./executable
```
