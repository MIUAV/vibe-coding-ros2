# SKILL — uav_action

> 无人机 Action 技能

## Tools
- **action_server**: ROS2 Action Server（rclcpp_action / rclpy_action）
- **nav2_action**: Nav2 NavigateToPose / NavigateThroughPoses Action
- **waypoint_action**: 航点到达确认 Action（等待目标 reached 超时处理）

## Usage
ROS2 Action 异步任务接口，用于长时间任务：
- Action Server 状态：GOACTIVE → PROCESSING → SUCCEEDED/ABORTED/CANCELED
- 无人机任务：NavigateToPose（Nav2）→ 等待 `feedback.pose` 更新
- 任务取消：rclcpp_action::ResultCode = CANCELED

## Tips
- Action 超时处理：goal_handle → expired 时触发 ABORTED
- Nav2 Action feedback 提供实时位姿（可用于降落检测）
- Action 的 cancel 接口需在 Server 端实现 CancelCallback
