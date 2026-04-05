# ros2-action-demo

> ROS2 Action 完整示例。包含 Fibonacci Action Server + 客户端调用。

## 测试

```bash
colcon build --packages-select ros2_action_demo
source install/setup.bash

# 启动 Server
ros2 run ros2_action_demo fibonacci_action_server

# 客户端发送 Goal
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}"

# 客户端发送 Goal + 观察反馈
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}" --feedback

# 查看 Action 列表
ros2 action list
ros2 action info /fibonacci
```

## 关键模式

```
Client                    Server
  |────── Goal ──────────→│  handle_goal()
  │←─── Feedback ─────────│  publish_feedback() (循环)
  │←──── Result ──────────│  succeed(result)
  │     or Cancel ────────│  is_canceling() → canceled()
```

## Action 三要素

| 要素 | 内容 | 作用 |
|------|------|------|
| Goal | `order: int` | 任务目标 |
| Result | `sequence: int[]` | 最终结果 |
| Feedback | `sequence: int[]` | 实时进度 |
