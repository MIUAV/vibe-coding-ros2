# ros2-action-server — Action Server 示例

> 演示 ROS2 Action 的标准用法：Goal / Feedback / Result 三层机制。

## 编译

```bash
colcon build --packages-select ros2_action_server
source install/setup.bash
```

## 运行

```bash
# 启动 Action Server
ros2 run ros2_action_server fibonacci_action_server

# 在另一个终端，发送 Goal
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}"

# 查看 Action 列表
ros2 action list

# 查看 Action 详情
ros2 action info /fibonacci

# 取消 Goal
ros2 action cancel /fibonacci
```

## Action 机制

```
Client                          Server
  │                                │
  │──── Goal(order=10) ──────────►│
  │                                │
  │◄─── Feedback(sequence=...) ───│  ← 每步返回当前序列
  │◄─── Feedback(sequence=...) ───│
  │◄─── Feedback(sequence=...) ───│
  │                                │
  │◄──────── Result ───────────────│  ← 最终完整序列
```

## 关键代码模式

```cpp
// 创建 Action Server
action_server_ = rclcpp_action::create_server<Fibonacci>(
  this, "fibonacci",
  handle_goal,    // 接收 goal
  handle_cancel,  // 接收 cancel
  handle_accepted // 开始执行
);

// 发布 Feedback
goal_handle->publish_feedback(feedback);

// 成功完成
goal_handle->succeed(result);

// 取消
goal_handle->canceled(result);
```

## Action 类型（example_interfaces）

```yaml
# Goal
order: int16

# Feedback
sequence: int32[]

# Result
sequence: int32[]
```

## 参考

- ROS2 Action 文档: https://docs.ros.org/en/humble/Tutorials/Intermediate/Actions/Action-Server-Client-Cpp.html
