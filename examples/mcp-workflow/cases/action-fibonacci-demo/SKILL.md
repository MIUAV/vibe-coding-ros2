# SKILL — ROS2 Action 模式

> ROS2 Action 异步任务接口。三要素：Goal（目标）/ Feedback（反馈）/ Result（结果）。

## 核心概念

| 要素 | 类型 | 说明 |
|------|------|------|
| Goal | Action.Goal | 客户端发送的任务目标 |
| Feedback | Action.Feedback | 服务端实时推送的进度 |
| Result | Action.Result | 任务完成时的最终结果 |

## Action Server 模式

```cpp
// 创建 Server
action_server_ = rclcpp_action::create_server<Action>(
  this, "action_name",
  handle_goal,    // 验证并接受/拒绝 Goal
  handle_cancel,  // 处理取消请求
  handle_accepted  // 启动后台执行
);

// Goal 验证：返回 ACCEPT_AND_EXECUTE / REJECT
rclcpp_action::GoalResponse handle_goal(goal_uuid, goal);

// Cancel 响应：返回 ACCEPT / REJECT
rclcpp_action::CancelResponse handle_cancel(goal_handle);

// 实际执行：在后台线程运行
void execute(std::shared_ptr<GoalHandle> goal_handle) {
  // 循环：检查取消 + 计算 + 发布反馈
  goal_handle->publish_feedback(feedback);
  goal_handle->succeed(result);  // 或 canceled() / aborted()
}
```

## 注意事项

1. **后台线程**：`handle_accepted` 中用 `std::thread.detach()` 执行，避免阻塞 spin
2. **取消检测**：`is_canceling()` 必须在循环中定期检查
3. **超时处理**：设置 goal 响应超时，避免客户端无限等待

## 常用命令

```bash
ros2 action list                  # 列出所有 Action
ros2 action info /fibonacci       # 查看 Action 类型
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 5}"
ros2 action send_goal /fibonacci ... --feedback  # 带反馈
ros2 action cancel /fibonacci     # 取消 Goal
```
