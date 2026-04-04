---
name: ros2-debug
description: ROS2 调试技能 — 编译错误诊断、运行时崩溃处理、QoS 静默失败排查、Lifecycle 状态机调试
argument-hint: ROS2编译错误 OR rclcpp崩溃 OR 话题不通 OR Lifecycle卡住 OR ros2 topic echo OR colcon build失败
user-invocable: true
---

# ros2-debug — ROS2 调试技能

## 目的

ROS2 问题按频率排列：
1. **编译失败** — CMake/链接错误（最高频）
2. **运行时崩溃** — rclcpp 异常、段错误
3. **数据不通** — QoS 不匹配、话题不通
4. **Lifecycle 状态机卡住**

## 工具链

```bash
# 编译错误
colcon build --event-handlers console_direct+

# 运行时崩溃
gdb -ex run -ex bt --args <你的节点>

# 话题通信
ros2 topic list                     # 列出所有话题
ros2 topic info <topic>              # 查看话题类型/QoS
ros2 topic hz <topic>               # 频率监控
ros2 topic echo <topic>             # 实时打印数据

# 节点通信
ros2 node list                       # 列出所有节点
ros2 node info <node>                # 节点订阅/发布/服务

# 服务调用
ros2 service list                    # 列出所有服务
ros2 service call <service> <type> <data>

# 参数
ros2 param list                       # 节点参数
ros2 param get <node> <param>          # 获取参数值
ros2 param set <node> <param> <value>  # 设置参数

# 生命周期
ros2 lifecycle list <node>            # 查看节点生命周期状态
ros2 lifecycle set <node> <state>       # 切换状态

# 代价地图可视化
ros2 run nav2_map_server map_saver_cli -f my_map

# 工具箱
ros2 run rqt_graph rqt_graph          # 节点关系图（最常用！）
ros2 run rqt_topic rqt_topic          # 话题监控
ros2 run rqt_console rqt_console      # 日志查看器
ros2 run rqt_msg rqt_msg              # 消息定义查看器
```

## 编译错误分类与修复

### 错误1: `undefined reference to 'ros2_xxx'`

**原因：** 缺少 `ament_export_dependencies` 或 `ament_target_dependencies`

**修复：** 在 CMakeLists.txt 中添加：
```cmake
ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  std_msgs
)
ament_export_dependencies(rclcpp)
```

### 错误2: `fatal error: rclcpp/rclcpp.hpp: No such file or directory`

**原因：** CMakeLists.txt 缺少 `find_package(rclcpp REQUIRED)`

**修复：** 在 `find_package` 区域添加：
```cmake
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
```

### 错误3: `ament_export_include_directories: .../include is not a directory`

**原因：** include 目录不存在或路径错误

**修复：** 确认目录结构：
```bash
ls -la <package>/include/<package>/
```

### 错误4: `Could not find a package 'ament_auto'`

**修复：** 改用标准 ament_cmake：
```cmake
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
```

### 错误5: `library path` 链接错误

**原因：** install 名/库名不匹配

**修复：** 检查 CMakeLists.txt 的 install 语句：
```cmake
install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)
```

## 运行时崩溃

### 段错误 (Segmentation fault)

**定位方法：**
```bash
gdb -ex run -ex bt --args colcon test --packages-select <package> --event-handlers console_direct+
# 或
gdb ./install/<package>/lib/<package>/<node>
(gdb) run
# 等待崩溃
(gdb) bt  # 打印堆栈
```

**常见原因：**
- shared_ptr 管理不善（生命周期问题）
- 线程安全问题（跨线程访问未加锁）
- vector/map 越界访问

### rclcpp::exceptions::InvalidNodeNameError

**原因：** 节点名以 `/` 开头（绝对名），ROS2 不允许。

**修复：**
```cpp
// ❌ 错误
auto node = rclcpp::Node::make_shared("/my_node"); // 错误！

// ✅ 正确
auto node = rclcpp::Node::make_shared("my_node");  // 相对名称
```

### qos_policy_kind 错误

**原因：** QoS 不兼容。

**修复：** 见 `ros2-qos-checker` 技能。

## Lifecycle 状态机问题

### 节点卡在 UNCONFIGURED 不转换

```bash
# 查看当前状态
ros2 lifecycle list /my_lifecycle_node

# 手动触发转换
ros2 lifecycle set /my_lifecycle_node configure
ros2 lifecycle set /my_lifecycle_node activate
```

### on_activate() 里卡住

**常见原因：** 在 on_activate 里执行了阻塞操作。

```cpp
// ❌ on_activate 禁止阻塞
rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
on_activate() override {
    // 不要在这里 sleep()、等待服务、循环查询
    RCLCPP_INFO(get_logger(), "Activating...");
    // ✅ 只做状态设置，立即返回
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
}
```

## 数据不通排查

### 话题发布成功但订阅收不到

**排查步骤：**
```bash
# 1. 确认话题存在
ros2 topic list | grep <topic>

# 2. 查看 QoS 配置
ros2 topic info /<topic> --verbose

# 3. 检查发布/订阅是否在同一命名空间
ros2 node list

# 4. 尝试直接 echo
ros2 topic echo /<topic>
```

**常见原因：**
- QoS 不兼容（最常见）
- 命名空间不同（发布在 `/ns1`，订阅在 `/ns2`）
- lifecycle 节点未激活（UNCONFIGURED/INACTIVE 状态不发布数据）

### 服务调用失败

```bash
# 列出服务
ros2 service list

# 查看服务类型
ros2 service type /add_two_ints

# 同步调用
ros2 service call /add_two_ints example_interfaces/srv/AddTwoInts "{a: 2, b: 3}"
```

## AI 生成代码后的自动验证流程

```
1. colcon build --packages-select <pkg> 2>&1
2. 如有错误 → 提取错误类型 → 应用本技能修复建议
3. 重新编译 → 直到 0 错误
4. ros2 run <pkg> <node> --ros-args --log-level debug
5. ros2 topic list / echo 验证数据流通
```

## 禁止的调试方式

```bash
# ❌ 禁止：只用 printf 调试（ROS2 用 RCLCPP_INFO）
std::cout << "debug" << std::endl;  // 太原始
RCLCPP_INFO(this->get_logger(), "Current value: %d", val);  // ✅

# ❌ 禁止：kill -9 强制杀掉节点（导致状态机混乱）
kill -9 <pid>  # 可能留下僵尸资源

# ✅ 正确：优雅关闭
ros2 lifecycle set /node shutdown
```
