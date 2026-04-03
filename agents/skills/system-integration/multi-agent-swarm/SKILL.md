---
name: multi-agent-swarm
description: 多智能体协同技能 - 蜂群机器人、分布式感知、协同规划、任务分配、ROS2 多机通信
argument-hint: 多智能体 OR 蜂群 OR swarm OR 协同规划 OR multi-agent OR 多机协同
user-invocable: true
---

# 多智能体协同技能

> 用于开发 ROS2 多智能体协同系统，涵盖蜂群机器人、分布式感知、协同规划、任务分配和多机通信架构

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现多机器人协同定位与建图
- 分布式感知与数据融合
- 协同路径规划与任务分配
- 蜂群机器人编队控制
- ROS2 多机通信架构设计
- 共识算法与分布式决策

---

## 快速参考

### 多机 ROS2 通信架构

```
单机:                      多机 (同一 ROS_DOMAIN):
+--------+               +--------+ +--------+ +--------+
|Node A  |               |Robot 1 | |Robot 2 | |Robot 3 |
+--------+               +--------+ +--------+ +--------+
|Node B  |   DDS 跨机    |  DDS   | |  DDS   | |  DDS   |
+--------+ <------------>|--------|<>|--------|<>|--------|
                          +--------+ +--------+ +--------+

不同域:
+--------+               +--------+   +--------+
|Robot 1 |               |Robot 2 |   |Robot 3 |
|DOMAIN=0| <--- Bridge -->|DOMAIN=1|   |DOMAIN=2|
+--------+               +--------+   +--------+
```

### 核心包

```bash
# 多机通信
sudo apt install -y ros-humble-rmw-cyclonedds-cpp  # 跨域 DDS
sudo apt install -y ros-humble-rosbridge-suite      # WebSocket 桥接

# 协同定位
sudo apt install -y ros-humble-multi-robot-map-merge
sudo apt install -y ros-humble-robot-localization
```

### 核心话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/robot_X/odom` | nav_msgs/Odometry | 第 X 台机器人里程计 |
| `/robot_X/scan` | sensor_msgs/LaserScan | 第 X 台机器人激光 |
| `/swarm/pose` | geometry_msgs/PoseStamped | 协同定位结果 |
| `/swarm/task` | my_msgs/SwarmTask | 协同任务分配 |

---

## DDS 跨域配置

### 单一域（同一网络）

```bash
# 所有机器人设置相同 DOMAIN_ID
export ROS_DOMAIN_ID=42

# 或者在代码中配置
RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
CYCLONEDDS_URI='<General>
    <Network>
        <AllowInterface>192.168.1.*</AllowInterface>
    </Network>
</General>'
```

### 多域桥接

```python
#!/usr/bin/env python3
"""ROS2 域桥接节点"""

import rclpy
from rclpy.node import Node
from rclpy.parameter import Parameter
from std_msgs.msg import String
import json


class DomainBridge(Node):
    """跨域消息桥接"""

    def __init__(self, src_domain: int, dst_domain: int):
        super().__init__(f'domain_bridge_{src_domain}_to_{dst_domain}')
        self.src_domain = src_domain
        self.dst_domain = dst_domain

        # 订阅源域话题
        self.create_subscription(
            String,
            '/swarm/leader_pose',
            self.bridge_callback,
            10
        )

        # 发布到目标域
        self.pub = self.create_publisher(
            String,
            '/swarm/leader_pose',
            10
        )

        self.get_logger().info(
            f'Bridging domain {src_domain} -> {dst_domain}'
        )

    def bridge_callback(self, msg: String):
        # 转发消息（实际应用中需要序列化/反序列化）
        self.pub.publish(msg)


def main():
    rclpy.init()
    # 启动多个域桥接
    bridge_0_1 = DomainBridge(0, 1)
    bridge_1_2 = DomainBridge(1, 2)

    executor = rclpy.executors.MultiThreadedExecutor()
    executor.add_node(bridge_0_1)
    executor.add_node(bridge_1_2)

    try:
        executor.spin()
    finally:
        executor.shutdown()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## 协同定位 (Cooperative Localization)

### 分布式 EKF

```python
import numpy as np
from dataclasses import dataclass
from typing import List, Dict
import rclpy
from rclpy.node import Node
from nav_msgs.msg import Odometry
from geometry_msgs.msg import PoseWithCovarianceStamped


@dataclass
class RobotState:
    """单机器人状态"""
    x: float = 0.0
    y: float = 0.0
    theta: float = 0.0
    vx: float = 0.0
    vy: float = 0.0
    omega: float = 0.0
    covariance: np.ndarray = None

    def __post_init__(self):
        if self.covariance is None:
            self.covariance = np.eye(6) * 0.1


class CooperativeLocalization(Node):
    """协同定位 - 分布式扩展卡尔曼滤波"""

    def __init__(self, robot_name: str, num_robots: int):
        super().__init__(f'coop_localization_{robot_name}')
        self.robot_name = robot_name
        self.num_robots = num_robots
        self.robot_id = int(robot_name.split('_')[-1])

        # 状态: [x, y, theta, vx, vy, omega] x num_robots
        self.state_dim = 6 * num_robots
        self.state = np.zeros(self.state_dim)
        self.P = np.eye(self.state_dim) * 0.1  # 协方差

        # 邻居列表
        self.neighbors = []

        # 订阅本地里程计
        self.odom_sub = self.create_subscription(
            Odometry,
            f'/{robot_name}/odom',
            self.odom_callback,
            10
        )

        # 订阅相对测量（其他机器人观测到的）
        for i in range(num_robots):
            if i != self.robot_id:
                self.create_subscription(
                    PoseWithCovarianceStamped,
                    f'/robot_{i}/relative_pose_{self.robot_id}',
                    lambda msg, idx=i: self.relative_pose_callback(msg, idx),
                    10
                )

        # 发布全局估计（供其他机器人使用）
        self.pose_pub = self.create_publisher(
            PoseWithCovarianceStamped,
            f'/{robot_name}/swarm_pose',
            10
        )

        # 广播定时器
        self.timer = self.create_timer(0.1, self.broadcast_state)

    def odom_callback(self, msg: Odometry):
        """里程计更新 - 预测步骤"""
        # 提取本地状态
        idx = self.robot_id * 6
        self.state[idx] = msg.pose.pose.position.x
        self.state[idx+1] = msg.pose.pose.position.y
        # ... 更新角度等

    def relative_pose_callback(self, msg, observer_id: int):
        """相对测量更新 - 校正步骤"""
        # EKF 校正：融合相对位姿测量
        z = np.array([
            msg.pose.pose.position.x,
            msg.pose.pose.position.y,
            0.0  # 简化为 2D
        ])

        H = self.compute_measurement_jacobian(observer_id, self.robot_id)
        R = np.diag([0.05, 0.05, 0.1])  # 测量噪声

        innovation = z - H @ self.state
        S = H @ self.P @ H.T + R
        K = self.P @ H.T @ np.linalg.inv(S)

        self.state = self.state + K @ innovation
        self.P = (np.eye(self.state_dim) - K @ H) @ self.P

    def broadcast_state(self):
        """广播本地状态估计到邻居"""
        msg = PoseWithCovarianceStamped()
        idx = self.robot_id * 6
        msg.pose.pose.position.x = self.state[idx]
        msg.pose.pose.position.y = self.state[idx+1]
        self.pose_pub.publish(msg)

    def compute_measurement_jacobian(self, observer_id, target_id) -> np.ndarray:
        """计算测量雅可比矩阵"""
        H = np.zeros((3, self.state_dim))
        # ... 计算相对于目标机器人状态的偏导
        return H
```

---

## 协同建图 (Collaborative SLAM)

### 多机器人地图融合

```python
#!/usr/bin/env python3
"""多机器人地图融合节点"""

import rclpy
from rclpy.node import Node
from nav_msgs.msg import OccupancyGrid
from geometry_msgs.msg import PoseWithCovarianceStamped
import numpy as np


class MapMerger(Node):
    """地图融合"""

    def __init__(self, num_robots: int):
        super().__init__('map_merger')
        self.num_robots = num_robots
        self.maps = {}
        self.poses = {}
        self.resolution = 0.05
        self.width = 2000
        self.height = 2000

        # 订阅各机器人的局部地图和位姿
        for i in range(num_robots):
            robot_name = f'robot_{i}'
            self.maps[i] = None

            self.create_subscription(
                OccupancyGrid,
                f'/{robot_name}/map',
                lambda msg, idx=i: self.map_callback(msg, idx),
                10
            )

            self.create_subscription(
                PoseWithCovarianceStamped,
                f'/{robot_name}/amcl_pose',
                lambda msg, idx=i: self.pose_callback(msg, idx),
                10
            )

        self.merged_map_pub = self.create_publisher(
            OccupancyGrid,
            '/swarm/map',
            10
        )

        self.timer = self.create_timer(1.0, self.merge_and_publish)

    def map_callback(self, msg: OccupancyGrid, robot_id: int):
        self.maps[robot_id] = msg

    def pose_callback(self, msg: PoseWithCovarianceStamped, robot_id: int):
        self.poses[robot_id] = msg.pose.pose

    def merge_and_publish(self):
        """融合所有局部地图"""
        merged = OccupancyGrid()
        merged.data = np.zeros(self.width * self.height, dtype=np.int8)
        merged.info.resolution = self.resolution
        merged.info.width = self.width
        merged.info.height = self.height

        for robot_id, local_map in self.maps.items():
            if local_map is None:
                continue

            pose = self.poses.get(robot_id)
            if pose is None:
                continue

            # 计算地图原点偏移
            offset_x = int((pose.position.x - self.width * self.resolution / 2) / self.resolution)
            offset_y = int((pose.position.y - self.height * self.resolution / 2) / self.resolution)

            # 叠加局部地图到全局地图
            for y in range(local_map.info.height):
                for x in range(local_map.info.width):
                    global_x = x + offset_x
                    global_y = y + offset_y
                    if 0 <= global_x < self.width and 0 <= global_y < self.height:
                        idx = global_y * self.width + global_x
                        if local_map.data[y * local_map.info.width + x] > 0:
                            merged.data[idx] = max(merged.data[idx], local_map.data[y * local_map.info.width + x])

        self.merged_map_pub.publish(merged)


def main(args=None):
    rclpy.init(args=args)
    node = MapMerger(num_robots=3)
    rclpy.spin(node)
    node.destroy_node()
    ricleanup()


if __name__ == '__main__':
    main()
```

---

## 协同任务分配 (Task Allocation)

### 拍卖算法 (Auction Algorithm)

```python
import numpy as np
from dataclasses import dataclass
from typing import List, Dict, Tuple
import heapq


@dataclass
class Task:
    """任务定义"""
    task_id: int
    position: Tuple[float, float]  # (x, y)
    reward: float
    estimated_cost: float
    assigned_robot: int = -1


class MarketBasedAllocator:
    """基于市场拍卖的多机器人任务分配"""

    def __init__(self, num_robots: int, robot_positions: List[Tuple[float, float]]):
        self.num_robots = num_robots
        self.robot_positions = robot_positions
        self.tasks: List[Task] = []

    def add_task(self, task: Task):
        self.tasks.append(task)

    def compute_cost(self, robot_id: int, task: Task) -> float:
        """计算机器人到任务的行驶成本"""
        rx, ry = self.robot_positions[robot_id]
        tx, ty = task.position
        distance = np.sqrt((rx - tx)**2 + (ry - ty)**2)
        return distance + np.random.uniform(0, 0.5)  # 加入随机成本

    def auction(self) -> Dict[int, List[Task]]:
        """
        拍卖过程
        返回: {robot_id: [assigned_tasks]}
        """
        # 重置分配
        for task in self.tasks:
            task.assigned_robot = -1

        assignments = {i: [] for i in range(self.num_robots)}
        unassigned = self.tasks.copy()

        iteration = 0
        while unassigned and iteration < 100:
            iteration += 1

            # 步骤1: 各机器人对自己未分配的任务竞价
            bids = {}  # {(robot_id, task_id): bid_value}

            for robot_id in range(self.num_robots):
                for task in unassigned:
                    cost = self.compute_cost(robot_id, task)
                    bid = task.reward - cost  # 净收益
                    bids[(robot_id, task.task_id)] = bid

            if not bids:
                break

            # 步骤2: 找出最高竞价
            max_bid_robot, max_bid_task = max(bids.keys(), key=lambda k: bids[k])
            max_bid_value = bids[(max_bid_robot, max_bid_task)]

            if max_bid_value <= 0:
                break  # 无正收益，停止

            # 步骤3: 分配任务给最高竞价者
            for task in unassigned:
                if task.task_id == max_bid_task:
                    task.assigned_robot = max_bid_robot
                    assignments[max_bid_robot].append(task)
                    unassigned.remove(task)
                    break

            # 步骤4: 更新机器人位置（简化：移动到任务点）
            self.robot_positions[max_bid_robot] = task.position

        return assignments

    def rebalance_tasks(self) -> Dict[int, List[Task]]:
        """周期性重新平衡（考虑任务执行后的位置变化）"""
        # 当有新任务加入或环境变化时调用
        return self.auction()
```

---

## 编队控制 (Formation Control)

### 虚拟结构法

```python
import numpy as np
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist, Pose
from typing import List, Tuple


class FormationController(Node):
    """编队控制器 - 虚拟结构法"""

    def __init__(self, num_robots: int, formation_type: str = "triangle"):
        super().__init__('formation_controller')
        self.num_robots = num_robots
        self.formation_type = formation_type

        # 虚拟结构中心目标
        self.center_target = np.array([0.0, 0.0])
        self.center_heading = 0.0

        # 编队形状相对偏移
        self.formation_offsets = self.get_formation_offsets()

        # 各机器人当前位置
        self.robot_poses = [None] * num_robots

        # 订阅各机器人位姿
        for i in range(num_robots):
            self.create_subscription(
                Pose,
                f'/robot_{i}/pose',
                lambda msg, idx=i: self.pose_callback(msg, idx),
                10
            )

        # 发布各机器人速度命令
        self.cmd_pubs = []
        for i in range(num_robots):
            pub = self.create_publisher(Twist, f'/robot_{i}/cmd_vel', 10)
            self.cmd_pubs.append(pub)

        self.timer = self.create_timer(0.05, self.control_loop)

    def get_formation_offsets(self) -> List[np.ndarray]:
        """获取编队形状相对偏移"""
        if self.formation_type == "triangle":
            r = 2.0  # 编队半径
            return [
                np.array([0, 0]),           # 机器人0在中心
                np.array([r, 0]),           # 机器人1
                np.array([-r/2, r*np.sqrt(3)/2]),  # 机器人2
            ]
        elif self.formation_type == "line":
            spacing = 1.5
            return [np.array([i * spacing, 0]) for i in range(self.num_robots)]
        else:  # circle
            r = 2.0
            return [
                np.array([r * np.cos(2*np.pi*i/self.num_robots),
                          r * np.sin(2*np.pi*i/self.num_robots)])
                for i in range(self.num_robots)
            ]

    def pose_callback(self, msg: Pose, robot_id: int):
        self.robot_poses[robot_id] = np.array([
            msg.position.x, msg.position.y, 0.0
        ])

    def control_loop(self):
        """控制循环"""
        if any(p is None for p in self.robot_poses):
            return

        for i in range(self.num_robots):
            # 计算期望位置
            desired_pos = self.center_target + self.formation_offsets[i]

            # 计算误差
            error = desired_pos - self.robot_poses[i][:2]

            # PID 控制
            Kp = 1.0
            v = Kp * np.linalg.norm(error)

            # 计算朝向
            if v > 0.01:
                desired_theta = np.arctan2(error[1], error[0])
            else:
                desired_theta = 0.0

            # 发布速度命令
            cmd = Twist()
            cmd.linear.x = min(v, 0.5)
            cmd.angular.z = desired_theta * 0.5
            self.cmd_pubs[i].publish(cmd)

    def set_center_target(self, x: float, y: float, heading: float = 0.0):
        """设置虚拟结构中心的新目标"""
        self.center_target = np.array([x, y])
        self.center_heading = heading
```

---

## ROS2 启动配置

```python
# launch/swarm_bringup.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
import os


def generate_swarm_launch(num_robots: int = 3):
    nodes = []

    for i in range(num_robots):
        ns = f'robot_{i}'
        robot_pose = f'{i * 1.5} {i * 0.5} 0'

        # 各自的 ROS_DOMAIN
        nodes.append(
            DeclareLaunchArgument(f'robot_{i}_domain', default_value=str(i))
        )

        # SLAM 定位
        nodes.append(
            Node(
                package='slam_toolbox',
                executable='async_slam_toolbox_node',
                name='slam',
                namespace=ns,
                parameters=[{
                    'use_sim_time': False,
                    'map_frame': 'map',
                    'odom_frame': f'{ns}/odom',
                }],
                remappings=[
                    ('/scan', f'{ns}/scan'),
                ],
                domain_id=i,  # 不同域
            )
        )

        # 协同定位
        nodes.append(
            Node(
                package='coop_localization',
                executable='coop_localization_node',
                name='coop_loc',
                namespace=ns,
                parameters=[{
                    'num_robots': num_robots,
                    'robot_id': i,
                }],
            )
        )

        # 蜂群控制器
        if i == 0:
            nodes.append(
                Node(
                    package='swarm_control',
                    executable='formation_controller',
                    name='formation',
                    parameters=[{
                        'num_robots': num_robots,
                        'formation_type': 'triangle',
                    }],
                )
            )

    # 地图融合（仅 leader 节点运行）
    nodes.append(
        Node(
            package='swarm_mapping',
            executable='map_merger',
            name='map_merger',
            parameters=[{'num_robots': num_robots}],
        )
    )

    return LaunchDescription(nodes)
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 多机 DDS 无法发现 | 防火墙阻止 UDP 多播 | 配置防火墙放行 239.255.0.0/24 |
| 地图融合错位 | 各机器人坐标系原点不一致 | 统一地图原点，使用 AMCL 全局定位 |
| 编队散开 | 通信延迟导致位置同步慢 | 减小控制周期，增加预测控制 |
| 拍卖算法不收敛 | 任务冲突激烈 | 增加任务收益多样性，减少竞争 |
| 协同定位发散 | 测量噪声太大 | 增加 EKF 过程噪声，过滤异常测量 |

### 调试命令

```bash
# 查看 DDS 发现状态
ros2 daemon stop && ros2 daemon start

# 查看跨机通信话题
ROS_DOMAIN_ID=42 ros2 topic list

# 查看地图融合结果
ros2 topic echo /swarm/map --type nav_msgs/msg/OccupancyGrid

# 手动发布编队中心目标
ros2 topic pub /formation_center geometry_msgs/msg/PoseStamped \
  '{header: {frame_id: world}, pose: {position: {x: 5.0, y: 3.0}}}'

# 网络诊断
ping <robot_ip>
tcpdump -i eth0 udp port 7400 -n  # DDS 端口
```

---

## 相关技能

- `system-integration/ros2-communication` — ROS2 通信基础
- `navigation/nav2-integration` — Nav2 导航集成
- `wheeled_vehicle/navigation` — 轮式车辆导航
- `quadruped/navigation` — 四足机器人导航
- `humanoid/navigation` — 人形机器人导航
