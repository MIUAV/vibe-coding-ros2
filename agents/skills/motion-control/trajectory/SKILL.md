---
name: trajectory
description: 轨迹规划技能 - 关节空间规划、笛卡尔空间规划、插值算法、时间最优轨迹
argument-hint: 轨迹规划 OR trajectory OR 插值 OR path planning OR 时间最优
user-invocable: true
---

# 轨迹规划技能

> 机器人轨迹规划：关节空间、笛卡尔空间、插值算法、时间最优轨迹

---

## 何时使用

- 机械臂关节空间点到点轨迹
- 末端笛卡尔空间直线/圆弧轨迹
- S 曲线加减速（速度平滑）
- 时间最优轨迹优化
- 多段连续轨迹拼接

---

## 关节空间规划（Joint Space）

### 5 次多项式（平滑加减速）

```cpp
// joint_trajectory.cpp — 5次多项式关节空间轨迹
#include <Eigen/Dense>

struct JointTrajectoryPoint {
  std::vector<double> positions;
  std::vector<double> velocities;
  std::vector<double> accelerations;
  double time_from_start;
};

class QuinticPolynomial {
public:
  // 5次多项式: q(t) = a0 + a1*t + a2*t^2 + a3*t^3 + a4*t^4 + a5*t^5
  // 边界条件: q(0)=q0, q(T)=q1, q'(0)=v0, q'(T)=v1, q''(0)=a0, q''(T)=a1
  std::vector<double> compute(double t, double T,
                               double q0, double q1,
                               double v0, double v1,
                               double a0, double a1) {
    double a3 = (20*(q1-q0) - (8*v1+12*v0)*T - (3*a1-a0)*T*T) / (2*T*T*T);
    double a4 = (30*(q0-q1) + (14*v1+16*v0)*T + (3*a1-2*a0)*T*T) / (2*T*T*T*T);
    double a5 = (12*(q1-q0) - (6*v1+6*v0)*T - (a1-a0)*T*T) / (2*T*T*T*T*T);

    double q = q0 + v0*t + 0.5*a0*t*t + a3*t*t*t + a4*t*t*t*t + a5*t*t*t*t*t;
    double v = v0 + a0*t + 3*a3*t*t + 4*a4*t*t*t + 5*a5*t*t*t*t;
    double a = a0 + 6*a3*t + 12*a4*t*t + 20*a5*t*t*t;
    return {q, v, a};
  }
};

class JointSpacePlanner : public rclcpp::Node {
public:
  JointSpacePlanner() : Node("joint_space_planner") {
    traj_pub_ = this->create_publisher<trajectory_msgs::msg::JointTrajectory>("/joint_trajectory", 10);
    timer_ = this->create_wall_timer(10ms, [this]() { this->publish_next_point(); });

    // 初始化路径点
    std::vector<std::vector<double>> via_points = {
      {0.0, 0.0, 0.0, 0.0, 0.0, 0.0},  // 起始
      {1.0, 0.5, -0.5, 0.3, 0.2, 0.1},  // 中间点
      {1.5, 1.0, -1.0, 0.5, 0.3, 0.2},  // 终点
    };
    plan_trajectory(via_points);
  }

  void plan_trajectory(const std::vector<std::vector<double>>& via_points) {
    // 计算各段时间
    for (size_t i = 0; i < via_points.size() - 1; ++i) {
      double seg_time = compute_segment_time(via_points[i], via_points[i+1]);
      segment_times_.push_back(seg_time);
    }
    total_time_ = std::accumulate(segment_times_.begin(), segment_times_.end(), 0.0);
  }

  void publish_next_point() {
    double t = (this->get_clock()->now().seconds()) - start_time_;
    if (t > total_time_) { return; }

    // 找到当前时间段
    size_t seg = 0;
    double cumsum = 0;
    for (size_t i = 0; i < segment_times_.size(); ++i) {
      cumsum += segment_times_[i];
      if (t < cumsum) { seg = i; break; }
    }

    trajectory_msgs::msg::JointTrajectoryPoint pt;
    pt.time_from_start = rclcpp::Duration::from_seconds(t);
    for (size_t j = 0; j < 6; ++j) {
      // Quintic polynomial interpolation per joint
      auto [pos, vel, acc] = quintic_.compute(
        t, segment_times_[seg],
        via_points_[seg][j], via_points_[seg+1][j],
        0, 0, 0, 0);
      pt.positions.push_back(pos);
      pt.velocities.push_back(vel);
      pt.accelerations.push_back(acc);
    }
    traj_pub_->publish(pt);
  }

private:
  double compute_segment_time(const std::vector<double>& a,
                             const std::vector<double>& b) {
    double max_delta = 0;
    for (size_t i = 0; i < a.size(); ++i) {
      max_delta = std::max(max_delta, std::abs(b[i] - a[i]));
    }
    return max_delta / max_joint_velocity_;  // 最慢关节决定时间
  }

  QuinticPolynomial quintic_;
  rclcpp::Publisher<trajectory_msgs::msg::JointTrajectory>::SharedPtr traj_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
  std::vector<std::vector<double>> via_points_;
  std::vector<double> segment_times_;
  double total_time_;
  double start_time_;
  double max_joint_velocity_ = 0.5;  // rad/s
};
```

---

## 笛卡尔空间规划（Cartesian Space）

### 直线插补

```cpp
// cartesian_trajectory.cpp — 笛卡尔空间直线轨迹
class CartesianLinearPlanner : public rclcpp::Node {
public:
  CartesianLinearPlanner() : Node("cartesian_linear_planner") {
    traj_pub_ = create_publisher<trajectory_msgs::msg::JointTrajectoryPoint>("/cartesian_trajectory", 10);
  }

  // 起点 → 终点 直线插补
  // N = 总步数
  std::vector<Eigen::Matrix4d> linear_interpolate(const Eigen::Matrix4d& T_start,
                                                   const Eigen::Matrix4d& T_end,
                                                   int N) {
    std::vector<Eigen::Matrix4d> traj;
    for (int i = 0; i <= N; ++i) {
      double alpha = static_cast<double>(i) / N;
      Eigen::Vector3d p = (1-alpha)*T_start.block<3,1>(0,3) + alpha*T_end.block<3,1>(0,3);
      Eigen::Quaterniond q_start(T_start.block<3,3>(0,0));
      Eigen::Quaterniond q_end(T_end.block<3,3>(0,0));
      Eigen::Quaterniond q = q_start.slerp(alpha, q_end);  // 四元数球面线性插值
      Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
      T.block<3,1>(0,3) = p;
      T.block<3,3>(0,0) = q.toRotationMatrix();
      traj.push_back(T);
    }
    return traj;
  }

  // S 曲线（平滑速度）
  std::vector<Eigen::Matrix4d> scurve_interpolate(const Eigen::Matrix4d& T_start,
                                                   const Eigen::Matrix4d& T_end,
                                                   int N,
                                                   double v_max, double a_max) {
    std::vector<Eigen::Matrix4d> traj;
    Eigen::Vector3d p_start = T_start.block<3,1>(0,3);
    Eigen::Vector3d p_end = T_end.block<3,1>(0,3);
    double dist = (p_end - p_start).norm();

    // 时间最优：加速 → 匀速 → 减速
    double t_accel = v_max / a_max;
    double d_accel = 0.5 * a_max * t_accel * t_accel;
    double t_cruise = (dist - 2*d_accel) / v_max;  // 可能 < 0

    if (t_cruise < 0) {
      // 达不到匀速段，缩短加速时间
      t_accel = std::sqrt(dist / a_max);
      t_cruise = 0;
      v_max = a_max * t_accel;
      d_accel = 0.5 * a_max * t_accel * t_accel;
    }
    double total_time = 2*t_accel + t_cruise;

    for (int i = 0; i <= N; ++i) {
      double t = total_time * i / N;
      double s, ds, dds;  // 位置，速度，加速度

      if (t < t_accel) {
        s = 0.5 * a_max * t * t;
        ds = a_max * t;
        dds = a_max;
      } else if (t < t_accel + t_cruise) {
        s = d_accel + v_max * (t - t_accel);
        ds = v_max;
        dds = 0;
      } else {
        double t_dec = t - t_accel - t_cruise;
        s = dist - 0.5 * a_max * (t_accel - t_dec) * (t_accel - t_dec);
        ds = a_max * (t_accel - t_dec);
        dds = -a_max;
      }

      double alpha = s / dist;
      Eigen::Vector3d p = (1-alpha)*p_start + alpha*p_end;
      // 旋转 SLERP
      Eigen::Matrix4d T = Eigen::Matrix4d::Identity();
      T.block<3,1>(0,3) = p;
      traj.push_back(T);
    }
    return traj;
  }
};
```

---

## 时间最优轨迹（Time-Optimal）

```cpp
// time_optimal.cpp — 时间最优轨迹规划（基于bang-bang控制）
class TimeOptimalPlanner {
public:
  // 输入: 路径点序列 + 关节限位
  // 输出: 时间最优轨迹
  trajectory_msgs::msg::JointTrajectory
  compute_time_optimal(const std::vector<std::vector<double>>& path,
                       const JointLimits& limits) {
    trajectory_msgs::msg::JointTrajectory traj;

    // 1. 计算每段路径长度
    std::vector<double> seg_lengths;
    for (size_t i = 0; i < path.size() - 1; ++i) {
      double len = 0;
      for (size_t j = 0; j < path[i].size(); ++j) {
        len += std::abs(path[i+1][j] - path[i][j]);
      }
      seg_lengths.push_back(len);
    }

    // 2. Bang-Bang 控制: 最大加速 → 最大减速
    double v_prev = 0;
    for (size_t i = 0; i < path.size() - 1; ++i) {
      double s = seg_lengths[i];
      // 最大速度由最慢关节决定
      double v_max_seg = compute_v_max_seg(path[i], path[i+1], limits);

      // 加速到 v_max_seg
      double t_accel = (v_max_seg - v_prev) / limits.max_acceleration[0];
      // 减速到下一段允许速度
      double v_next = (i+1 < path.size()-1) ? compute_v_max_seg(path[i+1], path[i+2], limits) : 0;
      double t_decel = (v_max_seg - v_next) / limits.max_acceleration[0];

      if (t_accel + t_decel > 0) {
        double t_cruise = std::max(0.0, s - 0.5*(v_max_seg+v_prev)/limits.max_acceleration[0]
                                    - 0.5*(v_max_seg+v_next)/limits.max_acceleration[0]);
        double total_t = t_accel + t_cruise + t_decel;
        // 添加轨迹点...
      }
    }
    return traj;
  }
};
```

---

## 性能指标

| 指标 | 目标 | 说明 |
|------|------|------|
| 轨迹生成时间 | < 10ms | 实时规划需要 |
| 插补周期 | 1-10ms | 控制周期 |
| 位置误差 | < 1mm | 笛卡尔规划 |
| 速度连续性 | C¹ 连续 | 避免冲击 |
| 加速度限制 | 满足关节限位 | 保护机械 |
