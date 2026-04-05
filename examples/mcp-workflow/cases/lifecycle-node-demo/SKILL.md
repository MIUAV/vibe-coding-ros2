# SKILL — LifecycleNode 生产规范

> LifecycleNode 状态机完整规范。生产机器人控制节点必须使用。

## 核心规则

- **生产控制**：`rclcpp_lifecycle::LifecycleNode`（不是 `rclcpp::Node`）
- **五个状态**：UNCONFIGURED → Inactive → Active → Inactive → Finalized
- **三行 export**：ament_export_dependencies + include_directories + libraries 必须同时存在
- **MultiThreadedExecutor**：多线程并发回调

## 状态切换规则

```
on_configure  →  UNCONFIGURED → INACTIVE     （创建资源）
on_activate   →  INACTIVE → ACTIVE           （开始运行）
on_deactivate →  ACTIVE → INACTIVE           （暂停运行）
on_cleanup    →  INACTIVE → UNCONFIGURED     （销毁资源）
on_shutdown   →  任意状态 → FINALIZED        （关闭）
```

## QoS 规范

| Topic 类型 | QoS | 原因 |
|-----------|-----|------|
| 控制命令（cmd_vel） | `reliable()` | 不能丢命令 |
| 传感器数据 | `best_effort()` | 允许丢帧降低延迟 |
| 状态反馈 | `best_effort()` | 实时性 > 可靠性 |
| Lifecycle 切换 | `reliable()` | 必须保证切换成功 |

## 常见错误

1. 在 `on_configure` 中创建并启动 timer → timer 在 INACTIVE 状态就会触发
2. 在 `on_activate` 中 publish 前没调用 `pub->on_activate()` → crash
3. 在 `on_cleanup` 之外 `reset()` publisher → 资源泄漏

## 调试命令

```bash
ros2 lifecycle list /node_name        # 查看当前状态
ros2 lifecycle set /node_name configure  # 触发 configure
ros2 lifecycle set /node_name activate   # 触发 activate
ros2 lifecycle set /node_name deactivate # 触发 deactivate
```
