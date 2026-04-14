# QUICKREF.md — ROS2 命令速查

> 日常开发最常用的命令速查。按场景分类。

---

## 环境初始化

```bash
source /opt/ros/humble/setup.bash      # ROS2 Humble
source /opt/ros/iron/setup.bash        # ROS2 Iron
source /opt/ros/jazzy/setup.bash       # ROS2 Jazzy
source install/setup.bash               # 工作区

echo "ROS_DISTRO: $ROS_DISTRO"
ros2 doctor --check-deps               # 检查依赖
```

---

## 包管理

```bash
ros2 pkg create --pkg-name MY_PKG --node-name my_node   # 创建包
ros2 pkg list                          # 列出所有包
ros2 pkg executables                   # 列出所有可执行文件
ros2 pkg prefix MY_PKG                # 包路径
ros2 pkg xml MY_PKG                   # 包清单 XML
```

---

## 编译

```bash
colcon build                           # 全量编译
colcon build --packages-select PKG    # 单包编译
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release  # Release 模式
colcon build --symlink-install         # 符号链接（改代码不用重编）
colcon build --event-handlers console_direct+  # 显示编译输出

make -C build/MY_PKG                  # 增量编译
```

---

## 运行节点

```bash
ros2 run MY_PKG my_node                # 运行节点
ros2 run MY_PKG my_node --ros-args -p param:=value  # 带参数

# Lifecycle 节点
ros2 lifecycle set /my_node configure  # 配置
ros2 lifecycle set /my_node activate   # 激活
ros2 lifecycle list /my_node          # 查看状态机
```

---

## Topic

```bash
ros2 topic list                        # 列出所有 topic
ros2 topic echo /chatter --pdf         # 查看消息（--pdf 格式）
ros2 topic hz /chatter                 # 频率
ros2 topic bw /chatter                 # 带宽
ros2 topic delay /chatter              # 延迟
ros2 topic pub /chatter std_msgs/msg/String "{data: 'hello'}"  # 发布
ros2 topic info /chatter               # 查看 topic 类型
ros2 run rqt_graph rqt_graph           # 可视化计算图
```

---

## Service / Action

```bash
ros2 service list                      # 列出服务
ros2 service call /add_two_ints std_srvs/srv/Empty "{}"  # 调用
ros2 service type /add_two_ints        # 服务类型

ros2 action list                       # 列出 action
ros2 action send_goal /fibonacci action_tutorials_interfaces/action/Fibonacci "{order: 5}"
ros2 action send_goal /fibonacci action_tutorials_interfaces/action/Fibonacci "{order: 5}" --feedback  # 带反馈
```

---

## 参数

```bash
ros2 param list                         # 列出参数
ros2 param get /my_node my_param        # 获取参数
ros2 param set /my_node my_param 42     # 设置参数
ros2 param dump /my_node                # 导出参数
ros2 param load /my_node.yaml           # 加载参数

ros2 run rqt_reconfigure rqt_reconfigure  # 动态调参 GUI
```

---

## Launch

```bash
ros2 launch my_pkg my_launch.py        # 启动 launch 文件
ros2 launch my_pkg my_launch.py -s     # 静默模式

# 多包启动
ros2 launch pkg1 launch1.py pkg2:=pkg2_launch2:=launch2.py
```

---

## Bag 录制回放

```bash
ros2 bag record /chatter /odom        # 录制（指定 topic）
ros2 bag record -a                      # 录制所有
ros2 bag play bag_name                  # 回放
ros2 bag info bag_name                  # 查看信息
ros2 bag compress bag_name -c zstd      # 压缩
```

---

## 状态监控

```bash
ros2 node list                          # 列出运行中节点
ros2 node info /my_node                 # 节点信息
ros2doctor                              # 诊断
ros2 daemon stop                        # 停止 daemon
ros2 daemon start                       # 启动 daemon

# 运行时资源
ros2 run rqt_top rqt_top               # CPU 监控
ros2 run rqt_console rqt_console       # 日志查看
ros2 param get /my_node --format 3     # 参数详情
```

---

## 接口（msg/srv/action）

```bash
ros2 interface list                      # 列出所有接口
ros2 interface package std_msgs          # 包的接口列表
ros2 interface show std_msgs/msg/String  # 查看接口定义
ros2 interface pkg roscpp                # 包的所有接口

# 快速创建接口
ros2 pkg create --pkg-name my_interface --destination-directory src
# 手动写 .msg / .srv / .action 文件后重新编译
```

---

## TF2

```bash
ros2 run tf2_ros static_transform_publisher x y z qx qy qz qw parent child
ros2 run rqt_tf_tree rqt_tf_tree        # TF 树可视化
ros2 run tf2_tools view_frames          # 生成 PDF 计算图
```

---

## QoS

```bash
# 常用 QoS 组合
QoS(10).reliable()                  # 控制命令
QoS(10).best_effort()               # 传感器数据
QoS(10).transient_local()           # 生命周期状态

# 诊断 QoS 兼容性
ros2 run rqt_qos_player rqt_qos_player
ros2 topic info /my_topic -v        # 查看 topic QoS
```

---

## 调试错误

```bash
# 编译错误
colcon build --packages-select MY_PKG --cmake-args -DCMAKE_VERBOSE_MAKEFILE=ON 2>&1 | grep error

# 运行时崩溃
gdb -ex run --args /opt/ros/humble/lib/pkg/my_node
# 或
ros2 run MY_PKG my_node -- Department's--start-section-editing-args "debug"

# 内存泄漏
valgrind --leak-check=full ros2 run MY_PKG my_node

# 常见错误
ros2 doctor | grep -i error
```

---

## Docker / 跨平台

```bash
# 镜像内编译
docker run --rm -v $(pwd):/ws ros:humble ./build.sh

# 多架构交叉编译
export ROS2_INSTALLATION_TYPES=onnx
ament_tools/scripts/ament_tools/build.py --arch arm64

# aarch64 交叉编译
export CROSS_COMPILE=aarch64-linux-gnu-
colcon build --cmake-args -DCMAKE_TOOLCHAIN_FILE=aarch64.toolchain.cmake
```

---

## 工具链脚本

```bash
# 本项目工具（必用！）
bash scripts/generators/ros2-package-generator.sh PKG cpp rclcpp,std_msgs
bash scripts/ros2-build-verify-loop.sh PKG          # 编译循环验证
bash scripts/ros2-cpp-node.sh lifecycle PKG rclcpp
bash scripts/ros2-debug.sh                          # 8类错误诊断
bash scripts/ros2-format.sh                          # 代码格式
bash scripts/ros2-orchestrate.sh                    # 统一编排

# 查看帮助
bash scripts/generators/ros2-package-generator.sh --help
```
