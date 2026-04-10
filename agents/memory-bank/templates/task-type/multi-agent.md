# Multi-Agent Coordination Context

## 协调架构
| 架构 | 说明 | 适用规模 |
|------|------|---------|
| 集中式 | 地面站统一决策 | ≤ 10 机 |
| 分布式 | 机器人间 P2P 通信 | 10-100 机 |
| 混合式 | 簇内分布 + 簇间集中 | > 100 机 |

## 协调算法对比
| 算法 | 通信需求 | 适用场景 |
|------|---------|---------|
| Leader-Follower | 低 | 编队保持 |
| 虚拟结构（VS）| 低 | 刚性编队 |
| ORCA | 无（局部感应）| 碰撞避免 |
| 行为法（Behavioral）| 中 | 多目标跟踪 |
| 拍卖算法（Auction）| 高 | 任务分配 |
| BOIDs | 无 | 仿生群体 |

## ORCA（Optimal Reciprocal Collision Avoidance）
```cpp
#include <nav2_multi_robot/ORCA2D.hpp>

ORCA2D orca;
geometry_msgs::msg::Twist optimal_vel;

// 计算无碰撞速度
orca.computeVelocity(
    own_pose,           // 本机位置
    other_agents,       // 其他智能体位置+速度
    optimal_vel          // 输出最优速度
);

// 发布到 cmd_vel
cmd_pub_->publish(optimal_vel);
```

## 编队控制
```python
# Leader-Follower 编队
leader_pose = PoseStamped()  # 从导航得到领航者轨迹
follower_target = PoseStamped()

# 保持固定偏移（形成三角形编队）
offset_x, offset_y = 2.0, 1.5
follower_target.pose.position.x = leader_pose.pose.position.x - offset_x
follower_target.pose.position.y = leader_pose.pose.position.y - offset_y
```

## 多机通信
```cpp
// ROS2 DDS 广播（无需中心节点）
rclcpp::QoS qos(10);
qos.transient_local();  // 新加入也能收到最近状态

auto pub = create_publisher<my_msgs::msg::RobotState>("/robot_state", qos);
```

## 生成器选择
- `ros2-multi-agent-generator.sh` — formation | auction | BOIDs | ORCA
- `ros2-nav2-node-generator.sh` — multi-robot 导航
- `ros2-behavior-tree-generator.sh` — swarm 行为树
