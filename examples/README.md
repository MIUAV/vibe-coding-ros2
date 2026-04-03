# ROS2 Examples

> 所有示例均可 `colcon build --packages-select <pkg> --symlink-install` 编译

## 目录

```
examples/
├── mcp-workflow/           # 多智能体自主开发（重点）
│   ├── MCP_WORKFLOW.md    # 架构 + 快速启动
│   ├── MCP_ORCHESTRATOR.md # 编排器使用
│   └── cases/
│       ├── go2-scurve/     # 四足S曲线轨迹
│       └── manipulator-pickplace/  # 机械臂抓取
├── memory-bank-example/    # ROS2 Memory Bank 架构
└── ros2-wheeled/           # 轮式机器人
    └── diff_drive_controller/  # 差速驱动控制器
```

## 多智能体工作流

详见 [MCP_WORKFLOW.md](mcp-workflow/MCP_WORKFLOW.md)

```bash
./scripts/mcp/mcp-agent-orchestrator.sh go2-scurve --agent claude
```

## 轮式机器人

### diff_drive_controller

差速驱动：`/cmd_vel` → 左右轮速 + 里程计 + TF

```bash
colcon build --packages-select diff_drive_controller --symlink-install
ros2 run diff_drive_controller diff_drive_controller
```

规范：SharedPtr / MultiThreadedExecutor + Mutex / QoS reliable

差速驱动数学：v_l = v − ω·W/2，v_r = v + ω·W/2

## 基础示例

| 示例 | 规范 |
|------|------|
| cpp_publisher | SharedPtr, QoS |
| py_subscriber | rclpy shutdown |
| lifecycle_sensor | Lifecycle 状态机 |
| add_two_ints | wait_for() 超时 |

详情见各子目录 README。
