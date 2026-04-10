# Robot-Type Templates — 索引

> 自动切换：检测机器人类型关键词 → 加载对应模板
> 激活方式：`cp <file> agents/memory-bank/active-context.md`

| 机器人 | 文件 | 核心 Topic | 生成器 |
|--------|------|-----------|--------|
| 轮式移动机器人 | `wheeled-vehicle.md` | `/cmd_vel`, `/odom`, `/scan` | Nav2, param-gen |
| 多旋翼无人机 | `multi-rotor-uav.md` | `/mavros/state`, `/setpoint_position` | PX4, simulator |
| 四足机器人 | `quadruped.md` | `/LowCmd`, `/LowState`, `/cmd_vel` | control-node-gen |
| 机械臂 | `manipulator.md` | `/move_group`, `/joint_trajectory` | MoveIt-gen |
| 人形机器人 | `humanoid.md` | `/whole_body_controller`, `/contacts` | WBC-gen |
| 水下机器人 | `underwater.md` | `/depth`, `/dvl`, `/camera` | slam-gen, sim |
| 多机器人系统 | `multi-robot.md` | `/robot_state`, `/formation` | multi-agent-gen |

## 关键词检测规则

| 关键词 | 激活模板 |
|--------|---------|
| 轮式、差速、Ackermann、wheeled、diff_drive | `wheeled-vehicle.md` |
| 无人机、uav、drone、px4、mavros、multirotor、Offboard | `multi-rotor-uav.md` |
| 四足、go2、spot、quadruped、anybot | `quadruped.md` |
| 机械臂、manipulator、arm、grasp、MoveIt | `manipulator.md` |
| 人形、humanoid、双足、biped、CoM | `humanoid.md` |
| 水下、AUV、ROV、underwater、auv | `underwater.md` |
| 多机、编队、swarm、multi-robot、ORCA | `multi-robot.md` |
