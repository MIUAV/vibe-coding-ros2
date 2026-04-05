# VERIFY — action-fibonacci-demo

## 编译验证

```bash
colcon build --packages-select fibonacci_action
# 期望：0 errors
```

## 运行验证

**Terminal 1:**
```bash
ros2 run fibonacci_action fibonacci_action_node
```

**Terminal 2 — 发送 Goal:**
```bash
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 10}" --feedback
```

**预期输出：**
```
Waiting for action server...
Sending goal:
  order: 10
Goal accepted.
[feedback]: sequence: [0, 1, 1]
[feedback]: sequence: [0, 1, 1, 2]
[feedback]: sequence: [0, 1, 1, 2, 3]
...
[result]: sequence: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
Goal succeeded with result:
  sequence: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
```

## 取消测试

**Terminal 3:**
```bash
ros2 action send_goal /fibonacci example_interfaces/action/Fibonacci "{order: 100}" --feedback &
sleep 0.5
ros2 action cancel /fibonacci
```

**预期：**
```
[INFO] [..]: Goal 被取消
```

## 错误检查

| 错误 | 原因 | 修复 |
|------|------|------|
| Goal REJECTED | order ≤ 0 或 > 93 | 传入有效 order |
| 无 feedback | `publish_feedback()` 未调用 | 检查是否在 execute 循环中调用 |
| 无 result | `succeed()` 未调用 | 确保循环正常结束 |
