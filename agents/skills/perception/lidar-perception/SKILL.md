---
name: lidar-perception
description: 激光雷达感知 — 点云处理、地面分割、障碍物检测、聚类，支持速腾/禾赛/velodyne/Ouster 等常见激光雷达
argument-hint: 激光雷达 OR lidar OR 点云 OR pointcloud OR PCL OR 障碍物检测 OR 地面分割 OR segmentation
user-invocable: true
---

# lidar-perception — 激光雷达感知 SKILL

## 引用技能

- `agents/skills/perception/sensor-fusion/`
- `agents/skills/ros2-debug/`

## 点云处理流程

```
原始点云 (PointCloud2)
    │
    ├── 降采样 (VoxelGrid) — 减少计算量
    ├── 地面分割 (RANSAC/GND) — 分离地面和非地面
    ├── 聚类 (Euclidean/DBSCAN) — 障碍物分组
    └── 分类 (ML/规则) — 行人/车/障碍
```

## ROS2 点云处理

```cpp
// 订阅点云
auto sub = this->create_subscription<sensor_msgs::msg::PointCloud2>(
  "/scan", QoS(10).best_effort(),  // sensor 数据用 BEST_EFFORT
  std::bind(&LidarNode::callback, this, std::placeholders::_1));

// PCL 处理
pcl::VoxelGrid<pcl::PointXYZ> vg;
vg.setInputCloud(pcl_cloud);
vg.setLeafSize(0.1f, 0.1f, 0.1f);
vg.filter(*filtered_cloud);
```

## 地面分割

```cpp
// RANSAC 地面检测
pcl::SACSegmentation<pcl::PointXYZ> seg;
seg.setModelType(pcl::SACMODEL_PLANE);
seg.setMethodType(pcl::SAC_RANSAC);
seg.setDistanceThreshold(0.03);  // 3cm
seg.setInputCloud(cloud);
seg.segment(inliers, coefficients);
```

## QoS 规则

激光雷达 **必须用 BEST_EFFORT**（高频数据，丢帧可接受）。

## 禁止

- ❌ 点云用 RELIABLE（延迟累积，实时性差）
- ❌ 不做降采样直接处理（计算量爆炸）
- ❌ 不设置最大距离过滤（远处噪声影响大）
