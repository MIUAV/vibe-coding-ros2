---
name: cloud-robotics
description: 云机器人技能 - 边缘云协同、云端规划、远程操控、数字孪生、ROS2 云桥接
argument-hint: 云机器人 OR cloud robotics OR 边缘计算 OR digital twin OR 云边协同
user-invocable: true
---

# 云机器人技能

> 用于实现云机器人架构，涵盖边缘云协同、云端计算、远程操控、数字孪生和 ROS2 云桥接

---

## 何时使用

当需要以下帮助时使用此技能：
- 云端机器人计算卸载（Computation Offloading）
- 远程机器人操控
- 数字孪生系统构建
- 云端 SLAM/导航计算
- 低延迟云边通信架构

---

## 快速参考

### 云机器人架构

```
机器人端 (Edge)          云端 (Cloud)
    ┌──────────────┐         ┌──────────────┐
    │ 传感器采集   │ ──5G─── │ 密集计算     │
    │ 实时控制     │  WiFi   │ SLAM/导航    │
    │ 安全监控     │         │ AI 推理      │
    └──────────────┘         └──────────────┘
          │                         │
          └────── 数字孪生 ─────────┘
```

### 关键指标

| 指标 | 要求 |
|------|------|
| 控制延迟 | < 20ms（本地闭环） |
| 感知延迟 | < 100ms（云端处理可接受） |
| 带宽需求 | 压缩后 10-50 Mbps |
| 可用性 | > 99.9% |

---

## ROS2 云边通信

### ZeroMQ 桥接

```python
#!/usr/bin/env python3
"""ROS2-云端 ZeroMQ 桥接节点"""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, PointCloud2, LaserScan
from geometry_msgs.msg import Twist, PoseArray
import zmq
import pickle
import numpy as np
import threading
import asyncio


class ZMQBridge(Node):
    """
    ROS2 ↔ 云端 ZeroMQ 桥接

    功能:
    - 机器人端：将 ROS2 消息压缩后发送到云端
    - 云端：将控制命令发送回机器人端
    """

    def __init__(self, mode: str = "robot"):
        """
        Args:
            mode: "robot" 或 "cloud"
        """
        super().__init__(f'zmq_bridge_{mode}')
        self.mode = mode

        # ZeroMQ 配置
        self.cloud_address = "tcp://cloud.example.com:5555"
        self.robot_address = "tcp://*:5556"

        # 消息压缩器
        self.compressor = MessageCompressor()

        # 带宽限制
        self.max_bandwidth_mbps = 50
        self.current_bandwidth = 0

        if mode == "robot":
            self._init_robot_mode()
        else:
            self._init_cloud_mode()

        # 统计
        self.msg_sent = 0
        self.msg_received = 0
        self.bytes_sent = 0

    def _init_robot_mode(self):
        """机器人端：发布 ROS2 消息到云端"""
        self.ctx = zmq.Context()
        self.socket = self.ctx.socket(zmq.PUB)
        self.socket.connect(self.cloud_address)

        # 订阅的 ROS2 话题（需要发送到云端）
        self.subscribers = {}
        self._create_subscriber(Image, '/camera/image_compressed', self._send_image)
        self._create_subscriber(PointCloud2, '/velodyne_points', self._send_pointcloud)
        self._create_subscriber(LaserScan, '/scan', self._send_laserscan)

        # 接收云端命令
        self.cmd_sub = self.create_subscription(
            Twist, '/cloud_cmd_vel', self._cmd_callback, 10
        )

        self.get_logger().info(f'Robot ZMQ bridge → {self.cloud_address}')

    def _init_cloud_mode(self):
        """云端：接收机器人数据，发送命令"""
        self.ctx = zmq.Context()
        self.socket = self.ctx.socket(zmq.SUB)
        self.socket.bind(self.robot_address)
        self.socket.setsockopt(zmq.SUBSCRIBE, b'')  # 接收所有

        # 启动接收线程
        self.recv_thread = threading.Thread(target=self._recv_loop)
        self.recv_thread.start()

        # 云端控制发布
        self.cloud_cmd_pub = self.create_publisher(Twist, '/cloud_cmd_vel', 10)

        self.get_logger().info(f'Cloud ZMQ bridge ← {self.robot_address}')

    def _create_subscriber(self, msg_type, topic: str, callback):
        sub = self.create_subscription(msg_type, topic, callback, 10)
        self.subscribers[topic] = sub

    def _send_image(self, msg: Image):
        """压缩并发送图像"""
        # 简化：直接 pickle（实际应使用 JPEG/PNG 压缩）
        data = self.compressor.compress_image(msg)
        self._send('image', topic, data, msg.header.stamp)

    def _send_laserscan(self, msg: LaserScan):
        """发送激光扫描"""
        data = self.compressor.compress_laserscan(msg)
        self._send('laserscan', topic, data, msg.header.stamp)

    def _send(self, msg_type: str, topic: str, data: bytes, stamp):
        """发送数据到云端"""
        envelope = {
            'type': msg_type,
            'topic': topic,
            'data': data,
            'stamp': stamp.sec + stamp.nanosec * 1e-9,
            'robot_id': 'robot_001',
        }
        try:
            self.socket.send(pickle.dumps(envelope), flags=zmq.NOBLOCK)
            self.msg_sent += 1
            self.bytes_sent += len(data)
        except zmq.Again:
            pass  # 带宽已满，丢弃

    def _recv_loop(self):
        """云端接收循环"""
        while True:
            try:
                msg = self.socket.recv()
                envelope = pickle.loads(msg)
                self._handle_cloud_message(envelope)
            except Exception as e:
                self.get_logger().error(f'Recv error: {e}')

    def _handle_cloud_message(self, envelope: dict):
        """处理来自机器人的消息"""
        self.msg_received += 1

        if envelope['type'] == 'laserscan':
            # 云端 SLAM 处理
            cloud_result = self.process_slam(envelope['data'])
            # 发布云端处理结果
            # ...

    def _cmd_callback(self, msg: Twist):
        """接收云端命令并转发到 /cmd_vel"""
        # 实际应用中转发到本地控制器
        pass


class MessageCompressor:
    """消息压缩器"""

    @staticmethod
    def compress_image(msg: Image, quality: int = 85) -> bytes:
        """JPEG 压缩图像"""
        import cv2
        from cv_bridge import CvBridge
        bridge = CvBridge()
        img = bridge.imgmsg_to_cv2(msg, desired_encoding='bgr8')
        encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), quality]
        _, buffer = cv2.imencode('.jpg', img, encode_param)
        return buffer.tobytes()

    @staticmethod
    def compress_laserscan(msg: LaserScan) -> bytes:
        """压缩激光扫描"""
        import struct
        data = struct.pack(f'{len(msg.ranges)}f', *msg.ranges)
        return data


class AdaptiveBandwidthController:
    """自适应带宽控制器"""

    def __init__(self, target_mbps: float = 30.0):
        self.target_mbps = target_mbps
        self.current_compression_quality = 85

    def adjust(self, actual_mbps: float):
        """根据实际带宽调整压缩质量"""
        if actual_mbps > self.target_mbps * 1.1:
            self.current_compression_quality = max(50, self.current_compression_quality - 5)
        elif actual_mbps < self.target_mbps * 0.9:
            self.current_compression_quality = min(95, self.current_compression_quality + 5)
        return self.current_compression_quality
```

---

## 数字孪生

### ROS2 数字孪生节点

```python
#!/usr/bin/env python3
"""数字孪生节点"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import TransformStamped, Pose
from sensor_msgs.msg import JointState
from nav_msgs.msg import Odometry
import numpy as np
from dataclasses import dataclass, field
from typing import Dict, List
import json


@dataclass
class TwinState:
    """数字孪生状态"""
    timestamp: float
    robot_id: str
    position: np.ndarray = field(default_factory=lambda: np.zeros(3))
    orientation: np.ndarray = field(default_factory=lambda: np.zeros(4))  # quaternion
    joint_positions: np.ndarray = None
    velocities: np.ndarray = None
    battery_level: float = 1.0
    task_state: str = "idle"


class DigitalTwin(Node):
    """数字孪生系统"""

    def __init__(self):
        super().__init__('digital_twin')

        self.twins: Dict[str, TwinState] = {}
        self.sync_period = 0.1  # 同步周期 100ms

        # 订阅各机器人状态
        self.create_subscription(
            Odometry,
            '/robot_001/odom',
            lambda msg: self._update_twin('robot_001', msg),
            10
        )
        self.create_subscription(
            JointState,
            '/robot_001/joint_states',
            lambda msg: self._update_joints('robot_001', msg),
            10
        )

        # 发布数字孪生状态（供云端可视化）
        self.twin_state_pub = self.create_publisher(
            Pose,
            '/digital_twin/robot_001/pose',
            10
        )

        # 定时同步到云端
        self.create_timer(self.sync_period, self._sync_to_cloud)

        # 云端连接
        self.cloud_client = CloudSyncClient()

        self.get_logger().info('Digital Twin Node initialized')

    def _update_twin(self, robot_id: str, odom: Odometry):
        """更新孪生状态"""
        if robot_id not in self.twins:
            self.twins[robot_id] = TwinState(
                timestamp=self.get_clock().now().seconds_nanoseconds()[0] * 1e-9,
                robot_id=robot_id
            )

        twin = self.twins[robot_id]
        twin.position = np.array([
            odom.pose.pose.position.x,
            odom.pose.pose.position.y,
            odom.pose.pose.position.z,
        ])
        twin.orientation = np.array([
            odom.pose.pose.orientation.x,
            odom.pose.pose.orientation.y,
            odom.pose.pose.orientation.z,
            odom.pose.pose.orientation.w,
        ])
        twin.timestamp = odom.header.stamp.sec + odom.header.stamp.nanosec * 1e-9

    def _update_joints(self, robot_id: str, joint_state: JointState):
        if robot_id in self.twins:
            self.twins[robot_id].joint_positions = np.array(joint_state.position)

    def _sync_to_cloud(self):
        """同步孪生状态到云端"""
        for robot_id, twin in self.twins.items():
            state_json = {
                'robot_id': twin.robot_id,
                'timestamp': twin.timestamp,
                'position': twin.position.tolist(),
                'orientation': twin.orientation.tolist(),
                'task_state': twin.task_state,
            }
            self.cloud_client.publish('/twin/state', json.dumps(state_json))

    def get_twin_state(self, robot_id: str) -> TwinState:
        """查询孪生状态"""
        return self.twins.get(robot_id)
```

---

## 云端计算卸载

### 卸载决策器

```python
import numpy as np
from typing import Tuple, Optional


class ComputationOffloader:
    """
    计算卸载决策器

    决定哪些计算在本地执行，哪些卸载到云端
    """

    def __init__(self):
        # 本地计算能力 (MIPS)
        self.local_mips = 10000

        # 云端计算能力 (相对值)
        self.cloud_mips_ratio = 10.0  # 云端是本地的 10 倍

        # 网络状况
        self.bandwidth_mbps = 50.0
        self.latency_ms = 20.0

        # 任务阈值
        self.compute_threshold = 1000.0  # MIPS
        self.latency_threshold = 50.0  # ms

    def should_offload(
        self,
        task_compute_mips: float,
        data_size_mb: float,
        latency_budget_ms: float
    ) -> Tuple[bool, str]:
        """
        决策是否卸载

        Args:
            task_compute_mips: 任务计算量 (MIPS)
            data_size_mb: 数据大小 (MB)
            latency_budget_ms: 延迟预算 (ms)

        Returns:
            (should_offload, reason)
        """
        # 估计本地执行时间
        local_time = task_compute_mips / self.local_mips  # ms

        # 估计传输时间
        transfer_time = (data_size_mb * 8) / self.bandwidth_mbps  # ms

        # 估计云端执行时间
        cloud_time = task_compute_mips / (self.local_mips * self.cloud_mips_ratio)

        # 总卸载延迟
        total_offload_time = transfer_time + cloud_time + self.latency_ms

        # 检查延迟预算
        if total_offload_time > latency_budget_ms:
            # 延迟不满足，本地执行
            return False, f"Latency budget exceeded: {total_offload_time:.1f}ms > {latency_budget_ms}ms"

        # 检查计算量
        if task_compute_mips < self.compute_threshold:
            return False, f"Task too small: {task_compute_mips} MIPS < {self.compute_threshold}"

        # 卸载
        speedup = local_time / total_offload_time
        if speedup > 1.2:
            return True, f"Offload beneficial: {speedup:.1f}x speedup"
        else:
            return False, f"No benefit: {speedup:.1f}x speedup"


class CloudSLAMOffloader:
    """
    云端 SLAM 卸载控制器

    将部分 SLAM 计算卸载到云端以节省本地算力
    """

    def __init__(self):
        self.offloader = ComputationOffloader()

        # SLAM 任务参数
        self.scan_compute_mips = 500.0    # 扫描处理 MIPS
        self.scan_data_mb = 0.1          # 扫描数据大小 MB
        self.loop_close_compute_mips = 2000.0  # 回环检测 MIPS
        self.loop_close_data_mb = 5.0    # 回环数据 MB

    def process_slam_offload(self, scan_data: np.ndarray, is_loop_closure: bool):
        """
        处理 SLAM 卸载决策

        Returns:
            (result, method): 结果和计算方式
        """
        if is_loop_closure:
            should_offload, reason = self.offloader.should_offload(
                self.loop_close_compute_mips,
                self.loop_close_data_mb,
                latency_budget_ms=100.0
            )
            if should_offload:
                return self._cloud_loop_closure(scan_data), "cloud"
            else:
                return self._local_loop_closure(scan_data), "local"
        else:
            should_offload, reason = self.offloader.should_offload(
                self.scan_compute_mips,
                self.scan_data_mb,
                latency_budget_ms=20.0
            )
            if should_offload:
                return self._cloud_scan_process(scan_data), "cloud"
            else:
                return self._local_scan_process(scan_data), "local"

    def _cloud_scan_process(self, scan_data):
        # 发送到云端处理
        cloud_result = self._send_to_cloud('/slam/process_scan', scan_data)
        return cloud_result

    def _local_scan_process(self, scan_data):
        # 本地处理
        return scan_data  # 占位

    def _cloud_loop_closure(self, scan_data):
        cloud_result = self._send_to_cloud('/slam/loop_closure', scan_data)
        return cloud_result

    def _local_loop_closure(self, scan_data):
        return scan_data

    def _send_to_cloud(self, endpoint: str, data):
        """发送到云端（简化）"""
        # 实际通过 ZMQ/WebSocket
        return data
```

---

## 云端导航规划

```python
class CloudNavigationPlanner:
    """
    云端导航规划器

    机器人在本地做感知和局部控制，
    云端做全局规划和长期路径优化
    """

    def __init__(self):
        self.planner_type = "hybrid_astar"  # 混合 A*

    def plan_cloud_path(
        self,
        start: Tuple[float, float],
        goal: Tuple[float, float],
        costmap: np.ndarray,
        environment_model: dict = None
    ) -> List[Tuple[float, float]]:
        """
        云端全局路径规划

        优势:
        - 可使用更大的地图
        - 可用更多计算资源做优化
        - 可整合多机器人信息
        """
        if self.planner_type == "hybrid_astar":
            return self._hybrid_astar(start, goal, costmap)
        elif self.planner_type == "topomap":
            return self._topological_planning(start, goal, environment_model)
        else:
            return self._astar(start, goal, costmap)

    def _hybrid_astar(self, start, goal, costmap):
        """
        混合 A* 算法（适合车辆动力学约束）

        Returns:
            路径点列表 [(x, y), ...]
        """
        # 简化实现
        import heapq

        class State:
            def __init__(self, x, y, g=0, h=0, parent=None):
                self.x, self.y = x, y
                self.g, self.h = g, h
                self.f = g + h
                self.parent = parent

            def __lt__(self, other):
                return self.f < other.f

        open_set = [State(start[0], start[1], h=self._heuristic(start, goal))]
        came_from = {}
        visited = set()

        while open_set:
            current = heapq.heappop(open_set)

            if self._is_goal(current, goal):
                return self._reconstruct_path(came_from, current)

            visited.add((current.x, current.y))

            for dx, dy in [(0,1), (1,0), (0,-1), (-1,0), (0.5,0.5)]:
                nx, ny = current.x + dx, current.y + dy
                if (nx, ny) not in visited and self._in_bounds(nx, ny, costmap):
                    g = current.g + np.sqrt(dx**2 + dy**2)
                    h = self._heuristic((nx, ny), goal)
                    neighbor = State(nx, ny, g, h, current)
                    if costmap[ny, nx] < 0.5:  # 自由空间
                        heapq.heappush(open_set, neighbor)

        return [start, goal]  # fallback

    def _heuristic(self, a, b):
        return np.sqrt((a[0]-b[0])**2 + (a[1]-b[1])**2)

    def _is_goal(self, state, goal):
        return abs(state.x - goal[0]) < 0.5 and abs(state.y - goal[1]) < 0.5

    def _in_bounds(self, x, y, costmap):
        return 0 <= x < costmap.shape[1] and 0 <= y < costmap.shape[0]

    def _reconstruct_path(self, came_from, current):
        path = []
        while current:
            path.append((current.x, current.y))
            current = came_from.get((current.x, current.y))
        return path[::-1]
```

---

## 远程操控

```python
class TeleoperationBridge(Node):
    """远程操控桥接"""

    def __init__(self):
        super().__init__('teleop_bridge')

        self.declare_parameter('cloud_url', 'wss://cloud.example.com/teleop')
        self.declare_parameter('video_quality', 70)
        self.declare_parameter('command_rate', 50)  # Hz

        # 视频压缩
        self.video_compressor = VideoCompressor(
            quality=self.get_parameter('video_quality').value
        )

        # 云端 WebSocket
        self.ws_client = WebSocketClient(
            self.get_parameter('cloud_url').value
        )
        self.ws_client.on_message = self._on_command_received

        # 视频发布（机器人端）
        self.video_pub = self.create_publisher(
            Image,
            '/teleop/video',
            10
        )

        # 命令订阅（云端）
        self.cmd_pub = self.create_publisher(
            Twist,
            '/teleop/cmd_vel',
            10
        )

        # 命令速率限制
        self.last_cmd_time = 0
        self.cmd_interval = 1.0 / self.get_parameter('command_rate').value

        self.get_logger().info('Teleoperation Bridge initialized')

    def _on_command_received(self, message: dict):
        """收到云端命令"""
        now = self.get_clock().now().seconds_nanoseconds()[0] * 1e-9
        if now - self.last_cmd_time < self.cmd_interval:
            return

        cmd = Twist()
        cmd.linear.x = message.get('vx', 0)
        cmd.linear.y = message.get('vy', 0)
        cmd.angular.z = message.get('omega', 0)
        self.cmd_pub.publish(cmd)
        self.last_cmd_time = now

    def publish_video(self, frame):
        """发布视频流"""
        compressed = self.video_compressor.compress(frame)
        self.ws_client.send({'type': 'video', 'data': compressed})
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 控制延迟过高 | 网络带宽不足 | 降低视频质量，增加本地预测 |
| 数字孪生不同步 | 网络中断 | 添加离线缓冲，重连后补发 |
| 云端 SLAM 失败 | 数据包丢失 | 添加 FEC 前向纠错 |
| 卸载决策不准 | 模型过时 | 实时测量网络状况更新模型 |
| 远程操控卡顿 | 视频延迟 > 控制延迟 | 视频降帧率，优先保证控制 |

### 调试命令

```bash
# 测量网络延迟
ping cloud.example.com

# 测量可用带宽
iperf3 -c cloud.example.com

# 查看 ZMQ 桥接状态
ros2 topic list | grep zmq

# 录制云边通信数据
ros2 bag record /twin/state /cloud_cmd_vel -o cloud_robotics_data
```

---

## 相关技能

- `system-integration/ros2-communication` — ROS2 通信基础
- `navigation/nav2-integration` — Nav2 导航集成
- `perception/edge-inference` — 边缘推理
- `edge-platforms/edge-deployment` — 边缘部署
