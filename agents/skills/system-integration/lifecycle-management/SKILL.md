---
name: lifecycle-management
description: Lifecycle 节点管理 — 状态机转换、状态回调、生命周期管理器，适用于生产机器人控制
argument-hint: Lifecycle OR 状态机 OR lifecycle node OR 生命周期管理 OR state machine
user-invocable: true
---

# lifecycle-management — Lifecycle 状态机 SKILL

## 状态转换

```
UNCONFIGURED
     ↓ on_configure()
  INACTIVE
     ↓ on_activate()
   ACTIVE ←——— timer_callback()
     ↓ on_deactivate()
  INACTIVE
     ↓ on_cleanup()
 FINALIZED
     ↓ on_shutdown()
  FINALIZED
```

## 关键规则

- `on_configure()` 里只做资源分配（不阻塞）
- `on_activate()` 里启动定时器/发布者
- `on_deactivate()` 里停止定时器（防止发布）
- 订阅者在 INACTIVE 状态不接收数据

## 禁止

- ❌ `on_configure()` 里执行阻塞操作
- ❌ 生产环境用 `rclcpp::Node` 而非 `LifecycleNode`
