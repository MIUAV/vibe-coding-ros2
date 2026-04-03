---
name: slam
description: SLAM 算法技能 - LaserSLAM、VisualSLAM、RTAB-Map、Cartographer、GMapping
argument-hint: SLAM OR slam OR 地图构建 OR laser slam OR visual slam OR 同步定位与建图
user-invocable: true
---

# SLAM 算法技能

> 同步定位与建图（Simultaneous Localization and Mapping）

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现激光雷达 SLAM（GMapping、Cartographer）
- 实现视觉 SLAM（ORB-SLAM3、RTAB-Map）
- 配置 SLAM 实时运行
- 优化 SLAM 定位精度
- 融合多传感器 SLAM

---

## 快速参考

### SLAM 类型对比

| 类型 | 传感器 | 优点 | 缺点 | 适用场景 |
|------|--------|------|------|----------|
| GMapping | 激光雷达 | 计算量小 | 精度一般 | 室内、小场景 |
| Cartographer | 激光雷达 | 高精度、实时 | 资源消耗大 | 室内+室外 |
| RTAB-Map | 深度相机 | 闭环检测强 | 内存消耗大 | 大场景 |
| ORB-SLAM3 | 单目/立体 | 多地图 | 需要纹理 | 室内有纹理 |
| LIO-SAM | LiDAR+IMU | 高精度 | 需 IMU | 室外复杂地形 |

---

## LaserSLAM 实现（GMapping）

### 节点结构

```cpp
// laser_slam_node.cpp
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/laser_scan.hpp>
#include <nav_msgs/msg/odometry.hpp>
#include <tf2_ros/transform_broadcaster.h>

class LaserSlamNode : public rclcpp::Node
{
public:
  LaserSlamNode() : Node("laser_slam")
  {
    // ── 激光雷达订阅 ───────────────────────
    scan_sub_ = this->create_subscription<sensor_msgs::msg::LaserScan>(
      "/scan", 10,
      [this](const sensor_msgs::msg::LaserScan::SharedPtr msg) {
        this->laser_callback(msg);
      }
    );

    // ── 里程计订阅 ───────────────────────
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
      "/odom", 10,
      [this](const nav_msgs::msg::Odometry::SharedPtr msg) {
        this->odom_callback(msg);
      }
    );

    // ── TF 广播 ─────────────────────────
    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    // ── SLAM 初始化 ──────────────────────
    slam_ = std::make_unique<GridSlam>(GridSlam::Params{
      .particle_count = 30,
      .map_resolution = 0.05,  // 5cm 栅格
      .range_max = 30.0
    });

    RCLCPP_INFO(this->get_logger(), "LaserSLAM started");
  }

private:
  void laser_callback(const sensor_msgs::msg::LaserScan::SharedPtr scan)
  {
    // 1. 里程计积分 → 获取机器人位姿
    auto pose = odom_queue_.back();

    // 2. 激光_scan → 栅格地图更新
    slam_->process_scan(scan, pose);

    // 3. 发布地图
    publish_map();

    // 4. 发布 TF（odom → map）
    publish_tf(pose);
  }

  void odom_callback(const nav_msgs::msg::Odometry::SharedPtr odom)
  {
    odom_queue_.push_back(odom->pose.pose);
    if (odom_queue_.size() > 10) odom_queue_.pop_front();
  }

  // GridSlam 核心算法
  std::unique_ptr<GridSlam> slam_;
  std::deque<geometry_msgs::msg::Pose> odom_queue_;

  rclcpp::Subscription<sensor_msgs::msg::LaserScan>::SharedPtr scan_sub_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  std::unique_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster_;
};
```

### Launch 文件

```python
# laser_slam.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package="laser_slam",
            executable="laser_slam_node",
            name="laser_slam",
            parameters=[{
                "particle_count": 30,
                "map_resolution": 0.05,
                "range_max": 30.0,
                "publish_map": True,
                "publish_tf": True,
            }],
            remappings=[
                ("/scan", "/front_laser/scan"),
                ("/odom", "/robot_odom"),
            ],
        ),
    ])
```

---

## Cartographer 配置

### .lua 配置文件

```lua
-- cartographer.lua
INCLUDE "map_builder.lua"
INCLUDE "trajectory_builder.lua"

MAP_BUILDER = {
  map_builder_pub_sub_state = true,
}

TRAJECTORY_BUILDER = {
  trajectory_builder_2d = {
    scan_matcher_config = {
      occupied_space_weight = 20.0,
      resolution = 0.05,
    },
  },
}

```

### ROS2 集成 Launch

```python
# cartographer.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package="cartographer_ros",
            executable="cartographer_node",
            name="cartographer",
            parameters=[{"configuration_directory": "/path/to/config"},
                       {"configuration_basename": "cartographer.lua"}],
            remappings=[
                ("/scan", "/front_laser/scan"),
            ],
        ),
        Node(
            package="cartographer_ros",
            executable="cartographer_occupancy_grid_node",
            name="occupancy_grid_node",
        ),
    ])
```

---

## VisualSLAM（RTAB-Map）

```cpp
// visual_slam_node.cpp — RTAB-Map 视觉 SLAM
#include <rtabmap_ros/rtabmap.h>

class VisualSlamNode : public rclcpp::Node
{
public:
  VisualSlamNode() : Node("visual_slam")
  {
    // 深度相机话题
    rtabmap_.init(this, "visual_slam");

    // 订阅深度相机 + RGB
    depth_sub_ = this->create_subscription<sensor_msgs::msg::Image>(
      "/depth/image_rect_raw", 1,
      [this](const sensor_msgs::msg::Image::SharedPtr img) {
        rtabmap_.processDepth(img);
      }
    );

    rgb_sub_ = this->create_subscription<sensor_msgs::msg::Image>(
      "/rgb/image_rect_color", 1,
      [this](const sensor_msgs::msg::Image::SharedPtr img) {
        rtabmap_.processRGBD(img);
      }
    );
  }
};
```

---

## SLAM 质量自检

```
□ 激光雷达数据格式正确（/scan）
□ TF 树正确（map → odom → base_link）
□ 里程计话题已连接（/odom）
□ 地图分辨率合理（室内: 0.02-0.05m，室外: 0.05-0.1m）
□ 实时性满足（SLAM 处理 < 100ms/帧）
□ 地图更新频率合理（5-10Hz）
□ 定位精度 < 0.1m
□ 闭环检测工作正常（如使用 RTAB-Map）
□ 栅格地图覆盖率 > 80%
```

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 地图漂移 | 里程计累计误差 | 添加 IMU 融合 / 闭环检测 |
| 定位丢失 | 激光雷达数据质量差 | 清洁传感器 / 调整参数 |
| 实时性差 | 计算量过大 | 减少粒子数 / 降低分辨率 |
| 地图空洞 | 传感器视角不足 | 增加激光雷达数量 |
| 闭环失败 | 场景重复性高 | 使用视觉 SLAM 辅助闭环 |

---

## 性能指标

| 指标 | 目标 | 测量方法 |
|------|------|----------|
| 处理延迟 | < 50ms/帧 | 记录回调耗时 |
| 定位精度 | < 0.1m | 与已知地图对比 |
| 地图分辨率 | 0.02-0.1m | 检查栅格大小 |
| TF 延迟 | < 10ms | `ros2 topic delay /tf` |
| 内存占用 | < 2GB | `top` / `htop` |
