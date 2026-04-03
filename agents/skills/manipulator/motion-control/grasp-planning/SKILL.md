---
name: grasp-planning
description: 机械臂抓取规划技能 - 6-DOF抓取、点云感知、MoveIt GraspGenerator、深度学习抓取检测
argument-hint: 机械臂抓取 OR grasp planning OR 抓取规划 OR 6-DOF OR MoveIt Grasp
user-invocable: true
---

# 机械臂抓取规划技能

> 用于开发机械臂的抓取规划系统，涵盖 6-DOF 抓取姿态估计、点云处理、MoveIt 集成和深度学习抓取检测

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现目标物体的 6-DOF 抓取姿态规划
- 集成点云传感器进行抓取检测
- 配置 MoveIt GraspGenerator
- 开发深度学习抓取检测网络
- 评估抓取质量并选择最优抓取
- 多指灵巧手的抓取规划

---

## 快速参考

### 抓取类型

```
抓取类型:
├── 平行夹抓 (Parallel Jaw): 两指平行，适合扁平物体
├── 捏取 (Pinch): 拇指+食指，适合小物体
├── 包络抓取 (Enveloping): 全手包裹，适合球形物体
└── _power grasp (强力抓取): 配合手腕力，适合重型物体
```

### ROS2 接口

```bash
# 核心包
sudo apt install -y ros-humble-moveit-resources
sudo apt install -y ros-humble-moveit-ros-visualization

# 抓取检测（需要 Xavier NX / Orin）
sudo apt install -y ros-humble-depthimage-to-laserscan
```

### 核心话题

| 话题 | 类型 | 说明 |
|------|------|------|
| `/obj_detection/object_pose` | geometry_msgs/PoseStamped | 物体位姿 |
| `/grasp_poses` | geometry_msgs/PoseArray | 候选抓取姿态 |
| `/gripper/cmd` | std_msgs/Float64 | 夹爪开合 |

---

## 6-DOF 抓取姿态表示

### 抓取表示法

```python
import numpy as np
from dataclasses import dataclass
from typing import List, Tuple, Optional

@dataclass
class GripperConfig:
    """夹爪配置"""
    finger_width: float = 0.01      # 指宽 (m)
    max_span: float = 0.1           # 最大开距 (m)
    palm_size: Tuple[float, float, float] = (0.05, 0.03, 0.02)  # 掌心尺寸

@dataclass
class GraspPose:
    """6-DOF 抓取姿态"""
    # 位置 (x, y, z) - 夹爪掌心中心
    position: np.ndarray  # shape (3,)

    # 姿态 - 夹爪坐标系相对于物体坐标系
    # approach: 接近方向 (approach direction)
    # grasp_direction: 抓取闭合方向
    # binormal: 垂直于前两者的方向
    approach: np.ndarray   # (3,) 从物体指向夹爪
    grasp_direction: np.ndarray  # (3,) 闭合方向
    binormal: np.ndarray   # (3,)

    # 夹爪开度
    open_width: float = 0.0

    # 抓取质量评分
    quality: float = 0.0

    def to_matrix(self) -> np.ndarray:
        """转换为 4x4 齐次变换矩阵"""
        R = np.column_stack([self.grasp_direction, self.binormal, self.approach])
        T = np.eye(4)
        T[:3, :3] = R
        T[:3, 3] = self.position
        return T
```

### 逆运动学验证

```python
import numpy as np
from typing import List, Optional

class GraspIKValidator:
    """验证抓取姿态的可达性和碰撞"""

    def __init__(self, robot_model, scene):
        self.robot_model = robot_model
        self.scene = scene  # MoveIt PlanningScene

    def validate(
        self,
        grasp_pose: GraspPose,
        arm_group: str = "manipulator"
    ) -> bool:
        """
        验证抓取姿态是否可达且无碰撞
        """
        # 1. 末端执行器姿态（夹爪闭合时的姿态）
        ee_pose = grasp_pose.to_matrix()

        # 2. 逆运动学求解
        joint_limits = self.robot_model.get_joint_limits(arm_group)
        ik_solution = self.robot_model.solve_ik(
            ee_pose,
            arm_group=arm_group,
            joint_limits=joint_limits
        )

        if ik_solution is None:
            return False  # 不可达

        # 3. 碰撞检测
        self.scene.set_joint_state(arm_group, ik_solution)
        if self.scene.check_collisions(arm_group):
            return False  # 有碰撞

        return True

    def find_valid_grasp(
        self,
        grasp_poses: List[GraspPose],
        arm_group: str = "manipulator"
    ) -> Optional[GraspPose]:
        """从候选抓取中找到第一个有效的"""
        for grasp in grasp_poses:
            if self.validate(grasp, arm_group):
                return grasp
        return None
```

---

## 点云预处理

```python
import numpy as np
import open3d as o3d
from typing import Tuple

class PointCloudPreprocessor:
    """点云预处理用于抓取检测"""

    @staticmethod
    def preprocess(
        cloud: o3d.geometry.PointCloud,
        voxel_size: float = 0.003,
        outlier_nb_neighbors: int = 20,
        outlier_std_ratio: float = 0.8
    ) -> o3d.geometry.PointCloud:
        """
        点云预处理流程
        """
        # 1. 下采样（体素滤波）
        cloud_down = cloud.voxel_down_sample(voxel_size)

        # 2. 去除离群点
        cl, ind = cloud_down.remove_statistical_outlier(
            nb_neighbors=outlier_nb_neighbors,
            std_ratio=outlier_std_ratio
        )
        cloud_filtered = cloud_down.select_by_index(ind)

        # 3. 估计法向量
        cloud_filtered.estimate_normals(
            search_param=o3d.geometry.KDTreeSearchParamHybrid(radius=0.02, max_nn=30)
        )

        return cloud_filtered

    @staticmethod
    def extract_object_clusters(
        cloud: o3d.geometry.PointCloud,
        eps: float = 0.02,
        min_points: int = 100
    ) -> list:
        """
        欧几里得聚类分割物体
        """
        with o3d.utility.VerbosityContextManager(o3d.utility.VerbosityLevel.Error):
            labels = np.array(
                cloud.cluster_dbscan(eps=eps, min_points=min_points, print_progress=False)
            )

        clusters = []
        max_label = labels.max()
        for i in range(max_label + 1):
            indices = np.where(labels == i)[0]
            cluster = cloud.select_by_index(indices)
            clusters.append(cluster)

        return clusters

    @staticmethod
    def compute_grasps_from_cluster(cluster: o3d.geometry.PointCloud) -> List[GraspPose]:
        """
        从点云簇生成候选抓取
        """
        center = cluster.get_center()

        # 计算物体主轴方向
        cov = cluster.compute_mean_and_covariance()[1]
        eigenvalues, eigenvectors = np.linalg.eigh(cov)
        major_axis = eigenvectors[:, np.argmax(eigenvalues)]

        # 生成多个候选抓取（沿不同方向）
        grasps = []
        for sign in [-1, 1]:
            for angle in [0, np.pi/4, np.pi/2]:
                grasp = GraspPose(
                    position=center + sign * 0.05 * major_axis,
                    approach=np.array([0, 0, -1]),  # 从上方接近
                    grasp_direction=-sign * major_axis,
                    binormal=np.cross(major_axis, np.array([0, 0, -1])),
                    open_width=0.04,
                    quality=0.5
                )
                grasps.append(grasp)

        return grasps
```

---

## MoveIt GraspGenerator 集成

### C++ 节点

```cpp
#include <moveit/moveit_cpp/moveit_cpp.h>
#include <moveit_grasps/grasp_generator.h>
#include <moveit_visual_tools/moveit_visual_tools.h>

class GraspPlanningNode {
private:
    rclcpp::Node::SharedPtr node_;
    moveit_cpp::MoveItCppPtr moveit_cpp_;
    moveit_visual_tools::MoveItVisualToolsPtr visual_tools_;
    moveit_grasps::GraspGeneratorPtr grasp_generator_;

    robot_model::RobotModelPtr robot_model_;
    planning_scene::PlanningScenePtr planning_scene_;

public:
    GraspPlanningNode() {
        node_ = rclcpp::Node::make_shared("grasp_planning_node");

        // 初始化 MoveIt
        moveit_cpp_ = std::make_shared<moveit_cpp::MoveItCpp>(node_);
        robot_model_ = moveit_cpp_->getRobotModel();

        // 初始化视觉工具
        visual_tools_ = std::make_shared<moveit_visual_tools::MoveItVisualTools>(
            node_, "world", rviz_visual_tools::RVIZ_MARKER_TOPIC,
            robot_model_
        );

        // 初始化抓取生成器
        grasp_generator_ = std::make_shared<moveit_grasps::GraspGenerator>(node_);

        // 创建抓取过滤器
        auto grasp_filter = std::make_shared<moveit_grasps::GraspFilters>();
    }

    std::vector<moveit_grasps::GraspD> generateGrasps(
        const geometry_msgs::msg::Pose& object_pose,
        const std::string& ee_group
    ) {
        // 物体位姿
        Eigen::Isometry3d object_pose_eigen;
        tf2::fromMsg(object_pose, object_pose_eigen);

        // 抓取数据对象
        moveit_grasps::GraspData grasp_data(ee_group, robot_model_, node_);

        // 生成大量候选抓取
        std::vector<moveit_grasps::GraspD> grasps;
        grasp_generator_->generateGrasps(
            object_pose_eigen,
            grasp_data,
            grasps
        );

        // 过滤不可行的抓取
        grasp_filter_->filterGrasps(grasps, planning_scene_, ee_group);

        RCLCPP_INFO(node_->get_logger(),
            "Generated %zu grasps, %zu valid after filtering",
            grasps.size(), filtered_grasps.size());

        return filtered_grasps;
    }
};
```

### Python 节点

```python
#!/usr/bin/env python3
"""MoveIt Grasp Planning Python 节点"""

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Pose, PoseArray
from moveit_ros2_python.planning_scene import PlanningScene
from moveit_ros2_python.grasp_generator import GraspGenerator
import numpy as np


class GraspPlanningNode(Node):
    def __init__(self):
        super().__init__('grasp_planning_node')

        # 参数
        self.declare_parameter('ee_group', 'hand')
        self.declare_parameter('planning_group', 'manipulator')
        self.ee_group = self.get_parameter('ee_group').value

        # 初始化抓取生成器
        self.grasp_gen = GraspGenerator(self.ee_group)

        # 发布器/订阅器
        self.grasp_pub = self.create_publisher(
            PoseArray, '/grasp_poses', 10
        )
        self.obj_sub = self.create_subscription(
            Pose, '/obj_detection/object_pose',
            self.obj_callback, 10
        )

        self.get_logger().info('Grasp Planning Node ready')

    def obj_callback(self, msg: Pose):
        # 从点云分割获取物体位姿
        obj_pose = np.array([msg.position.x, msg.position.y, msg.position.z])

        # 生成候选抓取
        grasps = self.grasp_gen.generate_candidate_grasps(
            object_position=obj_pose,
            object_size=(0.05, 0.03, 0.02),
            angle_sampling_num=8
        )

        # 发布候选抓取
        pose_array = PoseArray()
        pose_array.header.stamp = self.get_clock().now().to_msg()
        for g in grasps:
            p = Pose()
            p.position.x = g.position[0]
            p.position.y = g.position[1]
            p.position.z = g.position[2]
            pose_array.poses.append(p)

        self.grasp_pub.publish(pose_array)
        self.get_logger().info(f'Published {len(grasps)} grasp candidates')


def main(args=None):
    rclpy.init(args=args)
    node = GraspPlanningNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

---

## 深度学习抓取检测

### GraspNet (6-DOF)

```python
import torch
import numpy as np
from typing import List, Tuple

class GraspNetDetector:
    """基于 PointNet++ 的 6-DOF 抓取检测"""

    def __init__(self, model_path: str, device='cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model = self._load_model(model_path)
        self.model.to(self.device)
        self.model.eval()

    def _load_model(self, path: str):
        # 加载 GraspNet 模型
        model = torch.load(path, map_location=self.device)
        return model

    def predict(
        self,
        point_cloud: np.ndarray,  # N x 3
        num_grasps: int = 10
    ) -> List[GraspPose]:
        """
        从点云预测最优抓取

        Args:
            point_cloud: N x 3 点云
            num_grasps: 输出的抓取数量

        Returns:
            抓取姿态列表
        """
        # 预处理
        pc = torch.from_numpy(point_cloud).float().unsqueeze(0).to(self.device)

        with torch.no_grad():
            # 前向传播
            outputs = self.model(pc)

        # 解析输出
        # outputs: {grasps: Nx7, scores: N}
        grasps_data = outputs['grasps'][0].cpu().numpy()
        scores = outputs['scores'][0].cpu().numpy()

        # 选择分数最高的 num_grasps 个
        top_indices = np.argsort(scores)[-num_grasps:][::-1]

        grasps = []
        for idx in top_indices:
            grasp_data = grasps_data[idx]
            grasp = GraspPose(
                position=grasp_data[:3],
                approach=grasp_data[3:6],
                grasp_direction=grasp_data[6:9],
                binormal=np.cross(grasp_data[3:6], grasp_data[6:9]),
                quality=float(scores[idx])
            )
            grasps.append(grasp)

        return grasps

    def detect_and_rank(
        self,
        point_cloud: np.ndarray,
        arm_group: str = "manipulator",
        ik_validator=None
    ) -> List[GraspPose]:
        """
        检测 + IK 验证排序
        """
        # 1. 深度学习检测
        candidate_grasps = self.predict(point_cloud, num_grasps=50)

        # 2. IK 验证
        valid_grasps = []
        for grasp in candidate_grasps:
            if ik_validator and ik_validator.validate(grasp, arm_group):
                valid_grasps.append(grasp)

        # 3. 按质量排序
        valid_grasps.sort(key=lambda g: g.quality, reverse=True)

        return valid_grasps
```

### Real-Time Grasp Detection (GPD / 6-DOF)

```python
class GPDAcquirePointCloud:
    """GPD 风格的几何抓取检测"""

    def __init__(self):
        self.hand_config = {
            'finger_width': 0.01,
            'hand_depth': 0.06,
            'hand_height': 0.03,
            'hand_width': 0.08,
        }

    def generate_grasps_from_pc(
        self,
        cloud: np.ndarray,
        viewpoint: np.ndarray = np.array([0, 0, 1.5])
    ) -> List[GraspPose]:
        """
        从点云生成几何候选抓取
        基于点云局部几何特征选择抓取
        """
        from scipy.spatial import KDTree

        tree = KDTree(cloud)
        grasps = []

        # 对每个采样点生成抓取
        num_samples = min(500, len(cloud))
        indices = np.random.choice(len(cloud), num_samples, replace=False)

        for idx in indices:
            point = cloud[idx]

            # 找邻近点估计局部曲面
            _, nn_indices = tree.query(point, k=30)
            nn_points = cloud[nn_indices]

            # 计算局部坐标系
            cov = np.cov((nn_points - point).T)
            eigenvalues, eigenvectors = np.linalg.eigh(cov)

            # 法向量（最小特征值对应方向）
            normal = eigenvectors[:, 0]

            # 确保法向量指向相机
            if np.dot(normal, viewpoint - point) < 0:
                normal = -normal

            # 从法向量生成三个正交方向
            approach = normal
            binormal = np.array([-normal[1], normal[0], 0])
            if np.linalg.norm(binormal) < 1e-6:
                binormal = np.array([0, -normal[2], normal[1]])
            binormal = binormal / np.linalg.norm(binormal)
            grasp_dir = np.cross(approach, binormal)

            # 生成两个方向（± grasp_dir）
            for sign in [1, -1]:
                grasp = GraspPose(
                    position=point + 0.03 * normal,
                    approach=approach,
                    grasp_direction=sign * grasp_dir,
                    binormal=binormal,
                    open_width=0.04,
                    quality=0.5
                )
                grasps.append(grasp)

        return grasps
```

---

## ROS2 Launch 集成

```python
# launch/grasp_planning.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
import os

def generate_launch_description():
    pkg_path = '/home/robot/ros2_ws/src/grasp_planner'

    return LaunchDescription([
        # 点云处理
        Node(
            package='depth_image_proc',
            executable='point_cloud_xyz_node',
            name='cloud_xyz',
            remappings=[
                ('/depth/image_rect', '/camera/depth/image_rect_raw'),
                ('/camera/camera_info', '/camera/color/camera_info'),
                ('/points', '/cloud_in'),
            ],
        ),

        # 点云分割
        Node(
            package='grasp_planner',
            executable='cloud_segmentation_node',
            name='cloud_segmentation',
            parameters=[{
                'cluster_tolerance': 0.02,
                'min_cluster_size': 100,
            }],
            remappings=[('cloud_in', 'cloud_in')],
        ),

        # 抓取规划
        Node(
            package='grasp_planner',
            executable='grasp_planning_node',
            name='grasp_planning',
            parameters=[{
                'ee_group': 'hand',
                'planning_group': 'arm',
            }],
            remappings=[
                ('/object_pose', '/obj_detection/object_pose'),
                ('/grasp_poses', '/grasp_poses'),
            ],
        ),

        # MoveIt
        Node(
            package='moveit_ros2_move_group',
            executable='move_group',
            name='move_group',
            parameters=[
                os.path.join(pkg_path, 'config', 'moveit_params.yaml'),
            ],
        ),
    ])
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| IK 无解 | 抓取距离超出臂展 | 检查物体位置，确保在可达范围内 |
| 抓取偏移大 | 点云噪声导致位姿估计错误 | 增大点云滤波参数，提高分割阈值 |
| 夹爪碰撞 | 接近方向有障碍 | 切换 approach 方向，使用反向抓取 |
| 抓取掉落 | 质量评分过低 | 过滤 quality < 0.6 的抓取 |
| MoveIt 抓取失败 | grasp 数据配置错误 | 检查 end_effector_link 和 group 参数 |

### 调试命令

```bash
# 查看点云
ros2 topic echo /cloud_in --type sensor_msgs/msg/PointCloud2

# 查看抓取姿态
ros2 topic echo /grasp_poses --type geometry_msgs/msg/PoseArray

# 手动发布测试物体位姿
ros2 topic pub /obj_detection/object_pose geometry_msgs/msg/PoseStamped \
  '{header: {stamp: {sec: 0}, frame_id: world}, pose: {position: {x: 0.4, y: 0.0, z: 0.1}, orientation: {x: 0.0, y: 0.0, z: 0.0, w: 1.0}}}'

# Rviz 可视化
ros2 run rviz2 rviz2 -d $(colcon prefix)/share/grasp_planner/rviz/grasp_test.rviz
```

---

## 相关技能

- `manipulator/motion-control` — 机械臂运动控制基础
- `manipulator/perception` — 机械臂感知系统
- `perception/lidar-perception` — 激光雷达感知
- `perception/vision-perception/stereo-depth-estimation` — 立体深度估计
- `manipulator/sdf-xacro-model` — 机械臂 SDF/XACRO 模型
