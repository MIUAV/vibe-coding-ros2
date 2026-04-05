# ROS2 Quick Reference Card

> 常用命令速查表。完整文档见项目 SKILL.md 文件。

---

## 编译

```bash
colcon build                              # 编译所有包
colcon build --packages-select <pkg>       # 编译指定包
colcon build --symlink-install            # 符号链接（改代码不用重编译）
colcon build --event-handlers console_direct+  # 显示详细输出
rm -rf build/ install/ log/ && colcon build  # 清理后重新编译
```

## 包管理

```bash
ros2 pkg list                     # 列出所有已安装包
ros2 pkg executables <pkg>         # 列出包中的可执行文件
ros2 pkg prefix <pkg>              # 包的安装路径
ros2 pkg create <pkg_name>         # 创建新包
```

## 节点

```bash
ros2 node list                     # 列出运行中的节点
ros2 node info <node>              # 节点详情（发布/订阅/服务）
ros2 run <pkg> <node>              # 运行节点
ros2 run <pkg> <node> --ros-args -p param:=value  # 带参数运行
```

## 话题

```bash
ros2 topic list                    # 列出所有话题
ros2 topic info <topic>            # 话题信息（类型/QoS）
ros2 topic info <topic> --verbose  # 详细 QoS
ros2 topic echo <topic>            # 实时打印话题数据
ros2 topic pub <topic> <type> '{data: 0}'  # 发布话题
ros2 topic hz <topic>              # 话题发布频率
ros2 topic bw <topic>             # 话题带宽
ros2 topic delay <topic>          # 话题延迟
```

## 服务

```bash
ros2 service list                  # 列出所有服务
ros2 service type <service>        # 服务类型
ros2 service call <service> <type> '{a: 1, b: 2}'  # 调用服务
```

## 参数

```bash
ros2 param list                     # 列出节点参数
ros2 param get <node> <param>      # 获取参数值
ros2 param set <node> <param> <value>  # 设置参数
ros2 param dump <node>             # 导出参数到 YAML
ros2 param load <node> <yaml_file> # 从 YAML 加载参数
```

## Lifecycle

```bash
ros2 lifecycle list <node>          # 列出节点生命周期状态
ros2 lifecycle set <node> configure  # 切换状态
ros2 lifecycle set <node> activate
ros2 lifecycle set <node> deactivate
ros2 lifecycle set <node> cleanup
ros2 lifecycle set <node> shutdown
```

## 消息

```bash
ros2 interface list                 # 列出所有消息类型
ros2 interface show <msg>          # 查看消息结构
ros2 msg list                       # 列出所有 msg
ros2 srv list                       # 列出所有 srv
ros2 action list                    # 列出所有 action
```

## Launch

```bash
ros2 launch <pkg> <launch.py>     # 启动 launch 文件
ros2 launch <pkg> <launch.py> pkg:=value  # 传参数
```

## 调试

```bash
ros2 run rqt_graph rqt_graph       # 节点关系图（GUI）
ros2 run rqt_console rqt_console    # 日志查看器
ros2 run rqt_topic rqt_topic        # 话题监控
ros2 doctor                         # ROS2 环境检查
ros2 doctor -v                      # 详细检查

# 编译错误分析
colcon build 2>&1 | grep "error:"   # 只显示错误
```

## QoS 速查

| 场景 | Reliability | Durability |
|------|-------------|------------|
| 控制命令 | RELIABLE | VOLATILE |
| Sensor 数据 | BEST_EFFORT | VOLATILE |
| Lifecycle 状态 | RELIABLE | TRANSIENT_LOCAL |
| 相机/雷达 | BEST_EFFORT | VOLATILE |

```bash
# 查看 QoS
ros2 topic info /scan --verbose

# 代码中设置 QoS
QoS(10).reliable()                   // 控制命令
QoS(10).best_effort()              // Sensor 数据
QoS(10).transient_local()          // Lifecycle 状态
```

## 环境变量

```bash
echo $ROS_DISTRO                    # ROS2 发行版
echo $ROS_ROOT                      # ROS 包路径
source /opt/ros/$ROS_DISTRO/setup.bash  # 初始化 ROS2
source install/setup.bash           # 初始化工作区
unset ROS_PACKAGE_PATH              # 清除 ROS1 冲突
```

## Docker

```bash
# 运行 ROS2 Humble 容器
docker run -it ros:humble

# 带 GPU 支持
docker run -it --gpus all ros:humble

# 带网络和 GUI
docker run -it --net=host -e DISPLAY ros:humble
```

## 常用 CMakeLists.txt 模板

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

add_library(${PROJECT_NAME} SHARED src/my_node.cpp)

ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)          # 必须
ament_export_include_directories(include)  # 必须
ament_export_libraries(${PROJECT_NAME})   # 必须

ament_package()
```

## 常见错误修复

| 错误 | 修复 |
|------|------|
| `undefined reference` | 添加 `ament_export_dependencies` |
| `No such file rclcpp.hpp` | 添加 `find_package(rclcpp REQUIRED)` |
| `not a directory` | 确认 `include/` 目录存在 |
| `QoS incompatible` | 统一发布/订阅 QoS |
| `LifecycleNode not configured` | 调用 `on_configure()` |

---

*Source: vibe-coding-ros2 — https://github.com/MIUAV/vibe-coding-ros2*
