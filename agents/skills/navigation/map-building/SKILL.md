---
name: map-building
description: 地图构建技能 - SLAM实时建图、地图保存与加载、动态地图更新
argument-hint: 建图 OR SLAM OR 地图 OR map building OR slam
user-invocable: true
---

# 地图构建技能

> 使用 ROS2 + SLAM 工具链构建 2D/3D 地图，支持实时建图与动态更新

---

## 核心工具链

| 工具 | ROS2 包 | 说明 |
|------|---------|------|
| Cartographer | `cartographer_ros` | Google SLAM，2D/3D |
| SLAM Toolbox | `slam_toolbox` | 实时在线建图，Karto-SLAM |
| RTAB-Map | `rtabmap_ros` | 视觉SLAM，3D建图 |
| GMapping | `slam_gmapping` | 2D 激光SLAM（离线） |

---

## 2D 建图（slam_toolbox）

```bash
# 启动 slam_toolbox 在线建图
ros2 launch slam_toolbox online_async_launch.py \
  slam_params_file:=config/slam_params.yaml

# 保存地图
ros2 run nav2_map_server map_saver_cli -f my_map
# 生成 my_map.yaml + my_map.pgm

# 地图服务
ros2 run nav2_map_server map_server_yaml my_map.yaml
```

### slam_params.yaml 关键参数

```yaml
solver_plugin: solver_plugins::CeresSolver
ceres_linear_solver: SPARSE_NORMAL_CHOLESKY

scanmatcher:
  resolution: 0.05        # 地图分辨率 m/像素
  max_iterations: 20
  correlation_search_space:  # 搜索窗口
    transform_timeout: 0.2
    vietoris_radius: 2.0
```

---

## 3D 建图（RTAB-Map）

```bash
# 启动 RTAB-Map
ros2 launch rtabmap_ros rtabmap.launch.py \
  rgb_topic:=/camera/color/image_raw \
  depth_topic:=/camera/depth/image_raw \
  camera_info_topic:=/camera/color/camera_info \
  rtabmap_args:="--delete_db_on_start"

# 导出 3D 点云
ros2 run rtabmap_ros rtabmap_utilities \
  /rtabmap/export_point_cloud
```

---

## 动态地图更新

```cpp
// 增量地图更新（使用 OctoMap）
#include <octomap/OctoMap.h>
#include <octomap_ros/conversions.h>

void mapCallback(const sensor_msgs::msg::PointCloud2::SharedPtr msg) {
  octomap::OctoMap tree(0.05);  // 5cm 分辨率
  octomap::PointCloud pc;
  octomap::pointCloud2ToOctomap(*msg, pc);
  tree.insertPointCloud(pc, octomap::point3d(0,0,0));
  tree.updateInnerOccupancy();
}
```

---

## 规范

- 地图坐标系：`map` frame，TF: `map → odom → base_link`
- 分辨率：室内 0.05m/pixel，室外 0.10-0.20m/pixel
- 保存格式：2D 用 PGM+ YAML，3D 用 OctoMap (.bt/.ot)
- 动态地图更新需用 `nav2_costmap_2d` 的 `VoxelLayer` 或 OctoMap

---

## 错误处理

| 问题 | 原因 | 解决 |
|------|------|------|
| 地图漂移 | 激光数据质量差 | 检查 scan_matcher/max_iterations |
| 里程计跳变 | TF 配置错误 | 确认 odom frame 正确 |
| 建图不闭合 | 闭环检测失败 | 增大 correlation_search_space |
