# Phase 2: Architecture Design

## 包结构设计

### 包划分原则
- **功能内聚**：每个包完成一个功能域（感知/规划/控制）
- **接口稳定**：包间通过 msg/srv/action 通信，不直接依赖
- **最小依赖**：树状结构，避免循环依赖

### 推荐包结构（移动机器人）
```
my_robot/
├── my_robot_bringup/       # launch + config（启动入口）
├── my_robot_description/   # URDF/XACRO + rviz
├── my_robot_perception/    # 感知节点
├── my_robot_nav/          # 导航节点
├── my_robot_control/      # 控制节点
├── my_robot_msgs/         # 专用消息（跨包共用）
└── my_robot_hardware/     # 硬件抽象层
```

## Topic 设计（数据流）
| Topic | 发布者 | 订阅者 | 类型 | 频率 |
|-------|--------|--------|------|------|
| `/scan_filtered` | perception | nav | `LaserScan` | 10Hz |
| `/cmd_vel` | nav | control | `Twist` | 50Hz |
| `/odom` | control | nav | `Odometry` | 50Hz |

## Service 设计
| Service | 服务器 | 用途 |
|---------|--------|------|
| `/reset_odom` | control | 重置里程计 |
| `/save_map` | nav | 保存地图 |

## Action 设计
| Action | Server | 用途 |
|--------|--------|------|
| `/explore` | nav | 自主探索 |
| `/goto` | nav | 目标导航 |

## Lifecycle 状态机
```
UNCONFIGURED → on_configure → INACTIVE → on_activate → ACTIVE
                ↓
           on_cleanup → UNCONFIGURED
                ↓
           on_shutdown → FINALIZED
```
