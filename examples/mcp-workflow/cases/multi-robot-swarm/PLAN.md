# multi-robot-swarm Case — 多机器人编队协同控制

## 背景

多机器人编队（Swarm Robotics）是机器人领域的前沿方向。多台机器人在共享空间中协同作业，需要解决：防碰撞、编队保持、目标分配、分布式通信等核心问题。

**应用场景：**
- 无人机群表演（灯光秀、搜救）
- 仓库多 AGV 协同搬运
- 水面无人艇（USV）编队巡逻

---

## 用户需求

```
用户：控制 5 台 TurtleBot3 在 10m×10m 区域内，以菱形编队从 (0,0) 移动到 (5,5)，保持 1m 间距
```

---

## 约束

- ROS2 humble
- Robot 数量：3-10 台
- 通信：ROS2 Topic（DDS）+ 可选局域网 UDP
- 定位：OptiTrack 或激光雷达 SLAM

---

## 技术方案

### 编队控制算法

**Leader-Follower 模式：**
```
Leader 发布 /formation/target
Follower 订阅 /formation/target 并计算相对位置偏差
```

**虚拟结构（Virtual Structure）：**
```
整个编队视为一个刚体
每个机器人保持相对于刚体中心的固定坐标
```

### 冲突避免

```
基于 ORCA（Optimal Reciprocal Collision Avoidance）
每台机器人计算其他机器人的速度障碍锥
在锥外选择安全速度
```

---

## 执行流程

### Step 1: 包生成

```bash
bash scripts/generators/ros2-package-generator.sh swarm_control python
```

### Step 2: 启动多机器人

```bash
# 每台机器人启动一个实例（namespace 区分）
ros2 run swarm_control formation_node --ros-args -r __ns:=/robot1
```

### Step 3: 启动编队控制

```bash
ros2 launch swarm_control formation.launch.py formation_type:=diamond num_robots:=5
```

### Step 4: 验证

```bash
bash scripts/ros2-build-verify-loop.sh swarm_control
```

---

## 预期结果

- ✅ 5 台机器人形成菱形编队到达目标点
- ✅ 任意两台机器人距离始终 ≥ 0.5m（防碰撞）
- ✅ 允许临时队形调整以避障，之后恢复原队形
- ✅ `colcon build` 编译通过，无 error
