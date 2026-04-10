# Task-Type Templates — 索引

> 自动切换：检测任务类型关键词 → 加载对应模板
> 激活方式：`cp <file> agents/memory-bank/active-context.md`

| 任务 | 文件 | 核心工具 | 关键包 |
|------|------|---------|--------|
| 导航/路径规划 | `navigation.md` | Nav2, costmap | nav2_msgs, nav2_util |
| 感知/目标检测 | `perception.md` | YOLO, PCL, OpenCV | yolov8_ros, pcl_ros |
| 运动控制 | `motion-control.md` | PID, MPC, WBC | control_msgs, trajectory_msgs |
| 仿真/数字孪生 | `simulation.md` | Gazebo, Isaac, Mujoco | ros_gz_bridge |
| 多机协同 | `multi-agent.md` | ORCA, BOIDs, Auction | formation_control |
| 强化学习 | `reinforcement-learning.md` | DDPG, PPO, SAC | stable_baselines3 |
| 建图/SLAM | `slam-mapping.md` | Cartographer, VINS, LIO-SAM | cartographer_ros |

## 关键词检测规则

| 关键词 | 激活模板 |
|--------|---------|
| 导航、nav2、path、路径、localization | `navigation.md` |
| 感知、检测、yolo、segment、perception | `perception.md` |
| 控制、trajectory、PID、mpc、impedance | `motion-control.md` |
| 仿真、gazebo、simulator、digital twin | `simulation.md` |
| 多机、编队、formation、swarm、ORCA | `multi-agent.md` |
| 强化学习、RL、DDPG、PPO、SAC、sim2real | `reinforcement-learning.md` |
| slam、建图、mapping、cartographer、VINS | `slam-mapping.md` |
