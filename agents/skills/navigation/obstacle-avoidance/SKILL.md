---
name: obstacle-avoidance
description: 动态避障技能 - DWA/Teb/ORCA算法、局部路径规划、障碍物预测
argument-hint: "避障" / "obstacle" / "avoidance" / "局部规划" / "DWA" / "TEB"
user-invocable: true
---

# 动态避障技能

> 使用 DWA、TEB、ORCA 等算法实现机器人动态避障

---

## 算法对比

| 算法 | ROS2 包 | 适用场景 | 特点 |
|------|---------|----------|------|
| DWA | `dwb_controller` | 低速室内 | 稳定，计算量小 |
| TEB | `teb_local_planner` | 复杂地形 | 支持动态障碍 |
| ORCA | `orca_local_planner` | 多机协同 | 多机器人避碰 |
| RPP | `regional_planning` | 足式机器人 | 跳跃/楼梯 |

---

## DWA（动态窗口法）

```bash
ros2 launch nav2_bringup collision_detection_launch.py
```

### 关键参数

```yaml
dwb_controller:
  plugin: dwb_local_planner/DwbLocalPlanner
  prm:
    # 速度限制
    max_vel_x: 0.5
    max_vel_theta: 1.0
    # 轨迹评估权重
    vx_scale: 1.0
    vtheta_scale: 1.0
    # 障碍物代价权重
    obstacle_scale: 1.0
    path_distance_bias: 1.0
    goal_distance_bias: 1.0
```

```cpp
// DWA 速度采样
geometry_msgs::msg::Twist cmd;
double vx = std::clamp(target_vx, min_vx, max_vx);
double vtheta = std::clamp(target_vtheta, min_vtheta, max_vtheta);
cmd.linear.x = vx;
cmd.angular.z = vtheta;
```

---

## TEB（时间弹性带）

```bash
ros2 launch teb_local_planner_test test_obstacle.launch.py
```

### 关键参数

```yaml
TebLocalPlannerROS:
  odom_topic: /odom
  map_frame: map
  
  # 机器人参数
  max_vel_x: 0.5
  max_vel_x_backwards: 0.2
  max_vel_theta: 1.0
  acceleration_limits: [0.5, 0.5, 1.5]
  
  # 避障
  obstacles:
    min_obstacle_dist: 0.5
    inflation_dist: 0.6
    dynamic_obstacles_inflation_dist: 0.8
  
  # 轨迹优化
  dt_ref: 0.3
  dt_hysteresis: 0.1
  max_samples: 500
```

---

## 动态障碍物预测

```cpp
// 基于卡尔曼滤波的障碍物轨迹预测
#include <Eigen/Dense>

void predictObstacle(const geometry_msgs::msg::Point& pos,
                     const Eigen::Vector2d& vel,
                     double dt,
                     geometry_msgs::msg::Point& predicted) {
  predicted.x = pos.x + vel(0) * dt;
  predicted.y = pos.y + vel(1) * dt;
}

// 速度估计（常用于视觉检测）
Eigen::Vector2d estimateVelocity(const std::vector<geometry_msgs::msg::Point>& history) {
  if (history.size() < 2) return Eigen::Vector2d::Zero();
  double dt = (history.back().header.stamp - history.front().header.stamp).seconds();
  if (dt < 1e-6) return Eigen::Vector2d::Zero();
  return Eigen::Vector2d(
    (history.back().x - history.front().x) / dt,
    (history.back().y - history.front().y) / dt
  );
}
```

---

## 规范

- 避障距离：高速 > 1.0m，低速 > 0.3m
- Costmap 更新频率 ≥ 10Hz
- 动态障碍物预测 horizon ≥ 2s
- 多机器人场景用 ORCA 或制度化区域分配

---

## 错误处理

| 问题 | 原因 | 解决 |
|------|------|------|
| 机器人抖动 | 代价权重过高 | 降低 obstacle_scale |
| 避障失效 | inflation_dist 过小 | 增大 inflation_dist |
| 无法通过窄门 | 膨胀过大 | 减小 inflation_dist |
| 原地旋转 | 全局路径不合理 | 检查 global planner |
