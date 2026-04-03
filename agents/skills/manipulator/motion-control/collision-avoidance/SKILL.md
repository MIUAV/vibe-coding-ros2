---
name: manipulator-collision-avoidance
description: 机械臂碰撞避免技能 - 任务空间障碍规避、人工势场、动态障碍响应、ROS2避障节点
argument-hint: 碰撞避免 OR 障碍规避 OR 碰撞检测 OR 路径重规划 OR collision avoidance
user-invocable: true
---

# 机械臂碰撞避免技能

> 用于实现机械臂的任务空间碰撞避免，涵盖障碍物感知、势场法、动态重规划和 ROS2 集成

---

## 何时使用

当需要以下帮助时使用此技能：
- 动态避开工作空间中的障碍物
- 障碍物感知和轨迹重规划
- 碰撞预测和预防
- 多障碍物场景的轨迹优化
- 安全区域的定义和监控

---

## 快速参考

### 碰撞避免算法

```
任务空间碰撞避免:
├── 人工势场法 (APF) → 吸引势场 + 排斥势场
├── 动态窗口法 (DWA) → 速度空间采样
├── 可达性地图 (RRT*/BIT*) → 随机采样规划
└── 学习-based → 神经网络预测避障
```

### 核心话题

```yaml
/dynamic_obstacles: visualization_msgs/MarkerArray  # 障碍物位置
/collision_avoidance/status: String                # 避障状态
/task_space_trajectory: trajectory_msgs/JointTrajectory  # 修正后轨迹
```

---

## 人工势场法 (APF)

```python
import numpy as np
from typing import List, Tuple, Optional


class ArtificialPotentialField:
    """
    人工势场法碰撞避免

    原理:
    - 目标产生吸引势场（随距离减小）
    - 障碍物产生排斥势场（靠近时急剧增大）
    - 梯度下降求解无碰方向
    """

    def __init__(
        self,
        goal_position: np.ndarray,
        obstacle_positions: List[np.ndarray] = None,
        obstacle_radii: List[float] = None,
        attractive_gain: float = 1.0,
        repulsive_gain: float = 100.0,
        influence_distance: float = 0.3,
        max_force: float = 50.0
    ):
        self.goal = goal_position
        self.obstacles = obstacle_positions or []
        self.obstacle_radii = obstacle_radii or [0.05] * len(self.obstacles)
        self.k_att = attractive_gain
        self.k_rep = repulsive_gain
        self.d_influ = influence_distance
        self.max_force = max_force

        # 速度限制
        self.max_velocity = 0.5  # m/s
        self.max_angular_velocity = 1.0  # rad/s

    def add_obstacle(self, position: np.ndarray, radius: float = 0.05):
        """添加障碍物"""
        self.obstacles.append(position)
        self.obstacle_radii.append(radius)

    def attractive_force(self, position: np.ndarray) -> np.ndarray:
        """吸引势场梯度 → 指向目标"""
        diff = self.goal - position
        distance = np.linalg.norm(diff)
        if distance < 1e-6:
            return np.zeros(3)
        # F_att = k_att * (goal - pos)
        return self.k_att * diff

    def repulsive_force(self, position: np.ndarray) -> np.ndarray:
        """排斥势场梯度 → 远离障碍"""
        F_rep = np.zeros(3)
        d_min = float('inf')

        for obs, radius in zip(self.obstacles, self.obstacle_radii):
            diff = position - obs
            distance = np.linalg.norm(diff)
            d_min = min(d_min, distance - radius)

            if distance < self.d_influ + radius:
                # 排斥势场: F_rep = k_rep * (1/d - 1/d_influ)^2 * grad(d)
                if distance > 1e-6:
                    grad = diff / distance
                    rep_magnitude = self.k_rep * (
                        1.0 / (distance - radius) - 1.0 / self.d_influ
                    ) ** 2
                    F_rep += rep_magnitude * grad

        # 限幅
        if np.linalg.norm(F_rep) > self.max_force:
            F_rep = F_rep / np.linalg.norm(F_rep) * self.max_force

        return F_rep, d_min

    def compute_gradient(
        self,
        position: np.ndarray
    ) -> Tuple[np.ndarray, bool]:
        """
        计算势场梯度

        Returns:
            (gradient, near_obstacle)
        """
        F_att = self.attractive_force(position)
        F_rep, d_min = self.repulsive_force(position)

        F_total = F_att + F_rep
        near_obstacle = d_min < 0.05  # 5cm 内判定为危险

        # 限幅
        norm = np.linalg.norm(F_total)
        if norm > self.max_force:
            F_total = F_total / norm * self.max_force

        return F_total, near_obstacle

    def plan_velocity(
        self,
        current_position: np.ndarray,
        dt: float = 0.01
    ) -> Tuple[np.ndarray, bool]:
        """
        规划末端速度

        Returns:
            (velocity_cmd, needs_replan)
        """
        gradient, near = self.compute_gradient(current_position)

        # 速度 = 梯度方向 * min(梯度模, max_vel)
        velocity = gradient * dt
        velocity_norm = np.linalg.norm(velocity)

        if velocity_norm > self.max_velocity * dt:
            velocity = velocity / velocity_norm * self.max_velocity * dt

        return velocity, near


class CollisionAvoidanceAPF:
    """
    带轨迹跟踪的 APF 避障控制器
    """

    def __init__(self, ur5_robot_model):
        self.robot = ur5_robot_model
        self.potential_field = None

        # 配置参数
        self.Kp = 5.0  # 位置跟踪增益
        self.danger_distance = 0.05  # 危险距离 (m)

        # 状态
        self.q_current = None
        self.ee_position = None

    def set_obstacles(self, obstacle_list: List[dict]):
        """设置障碍物列表 [{position: np.ndarray, radius: float}]"""
        obs_positions = [o['position'] for o in obstacle_list]
        obs_radii = [o['radius'] for o in obstacle_list]

        # 使用当前末端位置作为目标（实际中需要外部设定）
        if self.ee_position is not None:
            self.potential_field = ArtificialPotentialField(
                goal_position=self.ee_position,
                obstacle_positions=obs_positions,
                obstacle_radii=obs_radii,
                repulsive_gain=200.0,  # 增大排斥力
                influence_distance=0.2,
            )

    def compute_safe_velocity(
        self,
        q: np.ndarray,
        target_ee: np.ndarray,
        obstacle_list: List[dict],
        dt: float = 0.01
    ) -> Tuple[np.ndarray, bool]:
        """
        计算安全的末端执行器速度

        Returns:
            (safe_velocity, obstacle_detected)
        """
        # 更新状态
        self.q_current = q
        self.ee_position = self.robot.forward_kinematics(q)

        # 更新势场
        self.set_obstacles(obstacle_list)

        # 计算位置误差
        pos_error = target_ee - self.ee_position

        # 期望末端速度（位置控制）
        desired_velocity = self.Kp * pos_error

        # 如果无障碍，直接返回
        if not self.potential_field:
            return desired_velocity, False

        # APF 排斥力
        apf_velocity, near_obstacle = self.potential_field.plan_velocity(
            self.ee_position, dt
        )

        # 融合：正常时跟踪目标，有障碍时避让
        if near_obstacle:
            # 避障模式：APF 方向主导
            safe_velocity = 0.3 * desired_velocity + 0.7 * apf_velocity
            return safe_velocity, True
        else:
            return desired_velocity, False
```

---

## 动态障碍响应

```python
import numpy as np
from dataclasses import dataclass
from typing import List, Optional


@dataclass
class DynamicObstacle:
    """动态障碍物"""
    position: np.ndarray      # 当前位置
    velocity: np.ndarray      # 当前速度
    radius: float             # 半径
    predicted_path: List[np.ndarray] = None  # 预测轨迹


class DynamicObstaclePredictor:
    """
    动态障碍物轨迹预测

    假设障碍物做匀速运动，预测其未来位置
    """

    def __init__(self, prediction_horizon: float = 2.0, dt: float = 0.1):
        self.T = prediction_horizon  # 预测时长 (s)
        self.dt = dt
        self.num_steps = int(T / dt)

    def predict(self, obstacle: DynamicObstacle) -> List[np.ndarray]:
        """
        预测障碍物未来位置

        Returns:
            预测路径点列表
        """
        trajectory = []
        current_pos = obstacle.position.copy()

        for step in range(self.num_steps):
            # 匀速模型
            current_pos = current_pos + obstacle.velocity * self.dt
            trajectory.append(current_pos.copy())

        return trajectory


class CollisionRiskEvaluator:
    """
    碰撞风险评估

    结合障碍物预测轨迹和机械臂末端轨迹
    """

    def __init__(self, robot_model):
        self.robot = robot_model

    def compute_risk(
        self,
        robot_trajectory: List[np.ndarray],  # 末端位置序列
        obstacle: DynamicObstacle,
        risk_threshold: float = 0.03  # 碰撞判定距离
    ) -> Tuple[float, Optional[int]]:
        """
        计算碰撞风险

        Returns:
            (max_risk_score, collision_step)
            risk_score: 0-1, 1=最危险
            collision_step: 预计碰撞的步数，None=无碰撞
        """
        predictor = DynamicObstaclePredictor()
        obstacle_path = predictor.predict(obstacle)

        max_risk = 0.0
        collision_step = None

        min_steps = min(len(robot_trajectory), len(obstacle_path))

        for step in range(min_steps):
            dist = np.linalg.norm(
                robot_trajectory[step] - obstacle_path[step]
            ) - obstacle.radius

            if dist < 0:
                # 碰撞
                return 1.0, step

            # 风险 = 1 - normalized_distance
            risk = max(0.0, 1.0 - dist / risk_threshold)
            max_risk = max(max_risk, risk)

        return max_risk, collision_step

    def find_safe_velocity(
        self,
        current_ee: np.ndarray,
        desired_velocity: np.ndarray,
        obstacles: List[DynamicObstacle],
        max_iterations: int = 10
    ) -> np.ndarray:
        """
        迭代求解安全速度

        在期望速度的基础上，迭代调整直到无碰撞风险
        """
        safe_vel = desired_velocity.copy()
        step_size = 0.01  # 每次调整量

        for _ in range(max_iterations):
            # 预测下一步位置
            next_pos = current_ee + safe_vel * 0.1  # 假设 0.1s 预测

            # 检查所有动态障碍
            max_risk = 0.0
            for obs in obstacles:
                dist = np.linalg.norm(next_pos - obs.position) - obs.radius
                if dist < 0.03:  # 危险
                    # 计算避让方向
                    diff = next_pos - obs.position
                    if np.linalg.norm(diff) > 1e-6:
                        avoid_dir = diff / np.linalg.norm(diff)
                        safe_vel += step_size * avoid_dir

        return safe_vel
```

---

## BIT* 路径规划

```python
import numpy as np
from typing import List, Tuple, Optional
import heapq


class BITStar:
    """
    Batch Informed Trees (BIT*) 路径规划器

    用于高维空间的快速重规划
    适用于障碍物变化时的轨迹重规划
    """

    def __init__(
        self,
        workspace_bounds: List[Tuple[float, float]],
        collision_check_fn,
        max_iterations: int = 500
    ):
        self.bounds = workspace_bounds  # [(x_min, x_max), ...]
        self.collision_check = collision_check_fn
        self.max_iter = max_iterations

        # 树节点
        self.nodes = []  # [(f_score, node_id, node_state)]
        self.edges = {}  # parent_id -> [child_ids]

        # PRM 样本
        self.samples = []

        # 起始点和目标
        self.start = None
        self.goal = None

    def add_samples(self, num_samples: int):
        """在自由空间采样"""
        for _ in range(num_samples):
            sample = np.random.uniform(
                [b[0] for b in self.bounds],
                [b[1] for b in self.bounds]
            )
            if not self.collision_check(sample):
                self.samples.append(sample)

    def path(self, start: np.ndarray, goal: np.ndarray) -> Optional[List[np.ndarray]]:
        """
        求解路径

        Returns:
            路径点列表，或 None 表示无解
        """
        self.start = start
        self.goal = goal

        # 初始化
        self.add_samples(500)

        # 简化的 RRT* 求解
        tree = [start]
        parents = {0: None}
        costs = {0: 0.0}

        for iteration in range(self.max_iter):
            # 随机采样
            if np.random.rand() < 0.1:
                # 以一定概率直接朝向目标
                rnd = goal
            else:
                rnd = self.samples[np.random.randint(len(self.samples))]

            # 找最近节点
            nearest_id = self._nearest(tree, rnd)

            # 尝试连接
            new_node = self._steer(tree[nearest_id], rnd, step_size=0.05)

            if not self.collision_check_line(tree[nearest_id], new_node):
                # 重连优化（类似 RRT*）
                near_ids = self._near neighborhood(new_node, radius=0.2)

                min_cost_id = nearest_id
                min_cost = costs[nearest_id] + self._distance(tree[nearest_id], new_node)

                for nid in near_ids:
                    cost = costs[nid] + self._distance(tree[nid], new_node)
                    if cost < min_cost and not self.collision_check_line(tree[nid], new_node):
                        min_cost = cost
                        min_cost_id = nid

                new_id = len(tree)
                tree.append(new_node)
                parents[new_id] = min_cost_id
                costs[new_id] = min_cost

                # 检查是否到达目标
                if self._distance(new_node, goal) < 0.02:
                    return self._extract_path(parents, new_id, tree)

        return None

    def _nearest(self, tree, point):
        """找最近节点"""
        dists = [self._distance(n, point) for n in tree]
        return np.argmin(dists)

    def _steer(self, from_node, to_node, step_size=0.05):
        diff = to_node - from_node
        dist = np.linalg.norm(diff)
        if dist < step_size:
            return to_node
        return from_node + diff / dist * step_size

    def _distance(self, a, b):
        return np.linalg.norm(np.array(a) - np.array(b))

    def _collision_check(self, point):
        # 占位，应由外部注入
        return False

    def _collision_check_line(self, a, b):
        # 简化为只检查端点
        return self._collision_check(b)

    def _near neighborhood(self, point, radius):
        return [i for i, n in enumerate(tree) if self._distance(n, point) < radius]

    def _extract_path(self, parents, goal_id, tree):
        path = []
        current = goal_id
        while current is not None:
            path.append(tree[current])
            current = parents[current]
        return path[::-1]
```

---

## ROS2 避障节点

```python
#!/usr/bin/env python3
"""任务空间碰撞避免节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState
from geometry_msgs.msg import WrenchStamped, PoseArray, Pose
from visualization_msgs.msg import MarkerArray
import numpy as np


class CollisionAvoidanceNode(Node):
    def __init__(self):
        super().__init__('collision_avoidance')

        # 参数
        self.declare_parameter('danger_distance', 0.05)
        self.declare_parameter('planner_type', 'apf')  # apf / bitstar
        self.danger_dist = self.get_parameter('danger_distance').value

        # 障碍物列表
        self.obstacles = []  # [{position, radius, velocity}]

        # APF 规划器
        self.apf = None

        # 状态
        self.ee_position = np.zeros(3)
        self.target_position = np.zeros(3)

        # 订阅
        self.obstacle_sub = self.create_subscription(
            MarkerArray,
            '/dynamic_obstacles',
            self.obstacle_callback,
            10
        )
        self.target_sub = self.create_subscription(
            PoseArray,
            '/target_trajectory',
            self.target_callback,
            10
        )

        # 发布
        self.safe_cmd_pub = self.create_publisher(
            PoseArray,
            '/safe_trajectory',
            10
        )
        self.status_pub = self.create_publisher(
            String,
            '/collision_avoidance/status',
            10
        )

        self.get_logger().info('Collision Avoidance Node ready')

    def obstacle_callback(self, msg: MarkerArray):
        """接收障碍物位置"""
        self.obstacles = []
        for marker in msg.markers:
            obs = {
                'position': np.array([
                    marker.pose.position.x,
                    marker.pose.position.y,
                    marker.pose.position.z
                ]),
                'radius': marker.scale.x / 2,  # scale 是直径
                'velocity': np.zeros(3),  # 简化：假设静态
            }
            self.obstacles.append(obs)

    def target_callback(self, msg: PoseArray):
        """接收目标轨迹"""
        if len(msg.poses) > 0:
            p = msg.poses[0]
            self.target_position = np.array([
                p.position.x, p.position.y, p.position.z
            ])

    def compute_safe_velocity(self) -> np.ndarray:
        """计算安全速度"""
        if not self.obstacles:
            return self.target_position - self.ee_position

        # 构建 APF
        self.apf = ArtificialPotentialField(
            goal_position=self.target_position,
            obstacle_positions=[o['position'] for o in self.obstacles],
            obstacle_radii=[o['radius'] for o in self.obstacles],
            repulsive_gain=200.0,
        )

        gradient, near = self.apf.compute_gradient(self.ee_position)
        return gradient * 0.5  # 缩放

    def timer_callback(self):
        # 计算安全速度
        safe_vel = self.compute_safe_velocity()

        # 发布修正后的目标
        safe_pose_array = PoseArray()
        safe_pose_array.header.stamp = self.get_clock().now().to_msg()

        # 目标 = 当前 + 安全速度
        target = self.ee_position + safe_vel
        pose = Pose()
        pose.position.x, pose.position.y, pose.position.z = target
        safe_pose_array.poses.append(pose)

        self.safe_cmd_pub.publish(safe_pose_array)


def main(args=None):
    rclpy.init(args=args)
    node = CollisionAvoidanceNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 障碍物附近振荡 | 排斥势场太陡 | 增大 d_influ，减小 k_rep |
| 无法逃离陷阱 | 局部最小点 | 添加随机扰动或切换 DWA |
| 速度跳变 | 障碍突然出现 | 添加速度平滑滤波器 |
| 规划时间过长 | BIT* 迭代不足 | 增加 max_iterations 或减少采样 |
| 频繁重规划 | 障碍跟踪不稳定 | 过滤障碍物信号，添加迟滞 |

### 调试命令

```bash
# 查看障碍物
ros2 topic echo /dynamic_obstacles

# 手动发布障碍物
ros2 topic pub /dynamic_obstacles visualization_msgs/MarkerArray '{markers: [{header: {frame_id: base_link}, scale: {x: 0.1, y: 0.1, z: 0.1}, pose: {position: {x: 0.3, y: 0.2, z: 0.0}}}]}' --once

# 查看避障状态
ros2 topic echo /collision_avoidance/status

# RViz 可视化
# Add > MarkerArray > /dynamic_obstacles
# Add > PoseArray > /safe_trajectory
```

---

## 相关技能

- `manipulator/motion-control` — 机械臂运动控制基础
- `manipulator/motion-control/trajectory` — 轨迹规划
- `navigation/obstacle-avoidance` — 导航避障
- `navigation/path-planning` — 路径规划
