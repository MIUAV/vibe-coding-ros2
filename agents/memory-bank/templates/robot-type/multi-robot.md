# Multi-Robot System Context

## 协调架构
| 架构 | 说明 | 适用规模 |
|------|------|---------|
| 集中式 | 地面站统一决策 | ≤ 10 机 |
| 分布式 | 机器人间 P2P 通信 | 10-100 机 |
| 混合式 | 簇内分布 + 簇间集中 | > 100 机 |

## 协调算法
| 算法 | 通信需求 | 适用场景 |
|------|---------|---------|
| Leader-Follower | 低 | 编队保持 |
| 虚拟结构（VS）| 低 | 刚性编队 |
| ORCA | 无（局部感应）| 碰撞避免 |
| 行为法（Behavioral）| 中 | 多目标跟踪 |
| 拍卖算法（Auction）| 高 | 任务分配 |
| BOIDs | 无 | 仿生群体 |

## 核心 Topic
```cpp
// 编队控制
geometry_msgs::msg::PoseStamped leader_pose;    // 领航者轨迹
geometry_msgs::msg::PoseStamped target_pose;    // 本机编队目标

// 局部距离感测
sensor_msgs::msg::Range range;  // 超声波/激光测距

// 任务分配
my_msgs::msg::AuctionBid bid;       // 投标
my_msgs::msg::AuctionResult result; // 竞拍结果
```

## 生成器选择
- `ros2-multi-agent-generator.sh` — formation|auction|BOIDs|ORCA
- `ros2-nav2-node-generator.sh` — multi-robot 导航
- `ros2-behavior-tree-generator.sh` — swarm 行为树
