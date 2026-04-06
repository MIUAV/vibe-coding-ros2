# multi-robot-swarm SKILL — 多机器人编队控制指南

---

## 核心规则

1. **每个 robot 必须有唯一 namespace**：用 `__ns` 参数隔离话题
2. **领导者唯一**：只允许 1 个 Leader，发布编队目标
3. **防碰撞优先于队形保持**：安全 > 队形
4. **通信超时必须处理**：任何机器人失联时整个编队应安全停止

---

## 知识库

### 编队形状定义

```python
FORMATION_SHAPES = {
    "diamond": {
        # 相对于编队中心的偏移（m）
        "robot1": (0, 0),
        "robot2": (-1, 1),
        "robot3": (1, 1),
        "robot4": (-1, -1),
        "robot5": (1, -1),
    },
    "line": {
        "robot1": (0, 0),
        "robot2": (-1, 0),
        "robot3": (1, 0),
    },
    "circle": {
        # 等角度分布
        f"robot{i}": (np.cos(2*np.pi*i/n)*R, np.sin(2*np.pi*i/n)*R)
        for i in range(n)
    },
}
```

### ROS2 多机器人通信

```python
# Leader 发布目标
self.formation_pub = self.create_publisher(
    geometry_msgs.msg.PoseArray,
    '/formation/targets',
    10)

# Follower 订阅并计算偏差
self.formation_sub = self.create_subscription(
    geometry_msgs.msg.PoseArray,
    '/formation/targets',
    self.on_targets_received,
    10)
```

### ORCA 冲突避免

```python
def orca_velocity(robot_pos, robot_vel, other_robots, time_horizon=5.0):
    """
    计算 ORCA 速度约束
    """
    orca_lines = []
    for other in other_robots:
        # 速度障碍锥计算
        # 找到在锥内的最大安全速度
        pass
    return optimal_velocity
```

### Namespace 隔离

```bash
# 启动机器人 1
ros2 run swarm_control formation_node --ros-args -r __ns:=/robot1

# 启动机器人 2
ros2 run swarm_control formation_node --ros-args -r __ns:=/robot2

# 此时 /robot1/cmd_vel 和 /robot2/cmd_vel 互不干扰
```

---

## 错误处理

| 错误 | 原因 | 解决 |
|------|------|------|
| `DDS timeout` | 通信丢包或网络问题 | 增加 QoS depth，检查网络 |
| `duplicate leader` | 多个节点都设为 Leader | 确保只有一个 `is_leader=true` |
| `collision detected` | ORCA 计算失败 | 触发紧急停止，重新规划 |
| `namespace conflict` | 同一 namespace 启动多次 | 使用 `--remap __ns:=/robotN` |

---

## 快速启动

```bash
# 1. 生成包
bash scripts/generators/ros2-package-generator.sh swarm_control python

# 2. 修改 namespace 启动多个机器人
# 3. 运行编队控制
ros2 launch swarm_control formation.launch.py formation_type:=diamond num_robots:=5

# 4. 编译验证
bash scripts/ros2-build-verify-loop.sh swarm_control
```
