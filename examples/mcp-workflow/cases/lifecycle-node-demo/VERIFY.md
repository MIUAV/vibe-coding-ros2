# VERIFY — lifecycle-node-demo

## 编译验证

```bash
colcon build --packages-select lifecycle_demo
# 期望：0 errors
```

## 运行验证

```bash
ros2 run lifecycle_demo lifecycle_demo_node
```

**预期日志顺序：**

```
[lifecycle_demo] [Lifecycle] Configuring...
[lifecycle_demo] [Lifecycle] Configured
```

状态：`UNCONFIGURED` → `INACTIVE`

```bash
ros2 lifecycle set /lifecycle_demo configure
# 预期日志：
[lifecycle_demo] [Lifecycle] Configuring...
[lifecycle_demo] [Lifecycle] Configured
# 状态：INACTIVE
```

```bash
ros2 lifecycle set /lifecycle_demo activate
# 预期日志：
[lifecycle_demo] [Lifecycle] Activating...
[lifecycle_demo] [Lifecycle] Activated
# /controller_status 开始有输出
ros2 topic echo /controller_status
```

## 错误检查

| 错误 | 原因 | 修复 |
|------|------|------|
| Timer 不触发 | 在 `on_configure` 中创建了 timer | 移到 `on_activate` |
| `on_activate` 中 crash | 发布者未 `on_activate()` 就 publish | 先调用 `pub_->on_activate()` |
| 状态切换失败 | `CallbackReturn::FAILURE` | 检查是否有未初始化的成员 |
