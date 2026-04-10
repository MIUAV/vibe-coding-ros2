# SLAM & Mapping Context

## SLAM 方案对比
| 方案 | 类型 | 地图输出 | 适用场景 |
|------|------|---------|---------|
| Cartographer | 2D/3D 激光 | Submap + Grid | 建图 + 定位 |
| SLAM Toolbox | 2D 激光 | OccupancyGrid | 在线定位 |
| ORB-SLAM3 | 单目/立体/IMU | 稀疏特征点 | 视觉定位 |
| VINS-Mono/Fusion | 视觉+IMU | 稀疏点云 | 无人机 |
| LIO-SAM | 激光+IMU | 稠密点云 | 室外大场景 |
| FAST-LIO2 | 激光+IMU | 稠密点云 | 机载快速 |

## Cartographer 2D 建图
```bash
# 在线建图
ros2 launch cartographer_ros backpack_2d.launch.py \
    configuration_directory:=$(pwd)/config \
    configuration_basename:=backpack_2d.lua

# 离线建图（rosbag）
ros2 launch cartographer_ros offline_backpack_2d.launch.py \
    bag_filenames:=/path/to/bag

# 保存地图
ros2 run nav2_map_server map_saver -f my_map
```

## SLAM Toolbox 在线定位
```bash
ros2 launch slam_toolbox online_async_launch.py \
    slam_params_file:=config/mapper_params_online_async.yaml
```

## 点云配准（NDT）
```cpp
#include <pclomp/ndt_omp.h>

pclomp::NDTMatcherOMP matcher;
matcher.setResolution(1.0f);
matcher.setNumThreads(4);

Eigen::Matrix4f guess = Eigen::Matrix4f::Identity();
pcl::PointCloud<PointT>::Ptr output(new pcl::PointCloud<PointT>);
matcher.alignedMutualScan(target_cloud, source_cloud, output, guess);
```

## 地图类型转换
```cpp
// PointCloud2 → OctoMap (3D 占据栅格)
#include <octomap/OctoMap.h>
#include <octomap_ros/conversions.h>

octomap::OcTree tree(0.1);  // 分辨率 10cm
for (auto& p : cloud->points) {
    tree.updateNode(octomap::point3d(p.x, p.y, p.z), true);
}
tree.updateInnerOccupancy();
tree.writeBinary("map.bt");
```

## IMU 融合
```cpp
// imu_filter → EKF 融合
#include <imu_filter_madgwick/imu_filter_ros2.hpp>

// 融合输出（四元数方向）
// 输入：/imu/raw → 输出：/imu/data（融合后）
// 与激光雷达里程计融合
```

## 生成器选择
- `ros2-slam-generator.sh` — 2d | 3d | cartographer | lidar_imu_fusion | visual
