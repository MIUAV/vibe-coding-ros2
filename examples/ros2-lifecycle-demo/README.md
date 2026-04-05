# ros2-lifecycle-demo

> 生产级 LifecycleNode 完整示例。展示正确的状态机管理、QoS 配置、参数处理。

## 快速测试

```bash
# 进入工作区
cd ~/ros2_ws

# 编译
colcon build --packages-select ros2_lifecycle_demo
source install/setup.bash

# 启动节点
ros2 run ros2_lifecycle_demo lifecycle_demo

# 在另一个终端测试状态切换
ros2 lifecycle list /lifecycle_controller
ros2 lifecycle set /lifecycle_controller configure   # 配置
ros2 lifecycle set /lifecycle_controller activate    # 激活
ros2 lifecycle set /lifecycle_controller deactivate  # 停用
ros2 lifecycle set /lifecycle_controller cleanup     # 清理
ros2 lifecycle set /lifecycle_controller shutdown    # 关闭

# 查看输出
ros2 topic echo /controller_status
ros2 topic echo /cmd_vel
```

## 关键要点

| 阶段 | 做什么 | 不做什么 |
|------|--------|---------|
| `on_configure` | 创建 publisher/subscriber/timer | 不要开始发布 |
| `on_activate` | 调用 `pub->on_activate()` + 启动 timer | 不要重建资源 |
| `on_deactivate` | `timer->cancel()` + `pub->on_deactivate()` | 不要 `reset()` 资源 |
| `on_cleanup` | `timer/subscriber.reset()` | 不要 `reset()` publisher |
| `on_shutdown` | 清理所有资源 | - |

## QoS 规则

| 场景 | QoS |
|------|-----|
| 控制命令（cmd_vel） | `reliable()` |
| 传感器数据（camera/lidar） | `best_effort()` |
| 状态反馈 | `best_effort()` |
| 生命周期切换 | `reliable()` |

## Launch 集成

推荐使用 `lifecycle_manager` 统一管理多个 Lifecycle 节点：

```python
from launch_ros.actions import Node

Node(package='ros2_lifecycle_demo', executable='lifecycle_demo',
     name='lifecycle_controller', output='screen'),
# lifecycle_manager 会在 configure 阶段自动触发所有节点的 on_configure
```
