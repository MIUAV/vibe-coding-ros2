# lifecycle_controller — Lifecycle 节点示例

> 演示 ROS2 LifecycleNode 的标准用法。适合作为生产机器人控制节点的模板。

## 文件结构

```
lifecycle_controller/
├── package.xml
├── CMakeLists.txt
├── src/
│   └── lifecycle_controller_node.cpp   # 主节点（含完整状态机）
├── launch/
│   └── lifecycle_controller.launch.py  # 启动文件
└── config/
    └── params.yaml                      # 默认参数
```

## 编译

```bash
cd /path/to/your_ros2_ws
colcon build --packages-select lifecycle_controller
source install/setup.bash
```

## 运行

```bash
# 基本运行（默认参数）
ros2 run lifecycle_controller lifecycle_controller_node

# 带参数运行
ros2 run lifecycle_controller lifecycle_controller_node --ros-args -p cycle_duration:=0.5

# 带参数文件运行
ros2 run lifecycle_controller lifecycle_controller_node --ros-args --params_file install/lifecycle_controller/share/lifecycle_controller/config/params.yaml

# Launch 文件启动
ros2 launch lifecycle_controller lifecycle_controller.launch.py
```

## 状态机

```
UNCONFIGURED
     ↓ (on_configure)
  INACTIVE
     ↓ (on_activate)
   ACTIVE ←——— timer_callback() 每秒 publish 一次
     ↓ (on_deactivate)
  INACTIVE
     ↓ (on_cleanup)
 FINALIZED (结束)
```

## 生命周期管理

```bash
# 查看节点生命周期状态
ros2 lifecycle list /lifecycle_controller

# 手动切换状态
ros2 lifecycle set /lifecycle_controller configure
ros2 lifecycle set /lifecycle_controller activate
ros2 lifecycle set /lifecycle_controller deactivate
ros2 lifecycle set /lifecycle_controller cleanup
ros2 lifecycle set /lifecycle_controller shutdown

# 验证 publisher
ros2 topic info /controller_state --verbose
ros2 topic echo /controller_state
```

## 关键代码模式

### LifecycleNode 结构
```cpp
class LifecycleController : public rclcpp_lifecycle::LifecycleNode {
  // on_configure()  → 初始化资源（timer/publisher/params）
  // on_activate()   → 开始发布（publisher->on_activate()）
  // on_deactivate() → 停止发布（timer.reset()）
  // on_cleanup()    → 释放资源
  // on_shutdown()   → 关闭
};
```

### QoS: TRANSIENT_LOCAL（Lifecycle 状态）
```cpp
publisher_ = this->create_publisher<std_msgs::msg::String>(
  "controller_state", QoS(10).transient_local());
// 新订阅者能收到最近一次发布的数据
```

## 参考

- ROS2 Lifecycle 文档: https://docs.ros.org/en/humble/Tutorials/Intermediate/Creating-a-Lifecycle-Node.html
- 完整状态机: `agents/skills/ros2-debug/SKILL.md`
- CMake 规则: `agents/skills/ros2-cmake-guard/SKILL.md`
