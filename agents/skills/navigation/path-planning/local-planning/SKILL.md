---
name: local-planning
description: 局部路径规划技能 - DWA、TEB、MPC、轨迹跟踪、ROS2 局部规划器
argument-hint: "局部规划" / "DWA" / "TEB" / "MPC" / "local planning"
user-invocable: true
---

# 局部路径规划技能

> 局部路径规划与轨迹跟踪

---

## 何时使用

当需要以下帮助时使用此技能：
- DWA 动态窗口法
- TEB 时间弹性带
- MPC 模型预测控制
- 轨迹跟踪
- ROS2 局部规划器

---

## 核心实现

### DWA 算法

```python
import numpy as np

class DWAPlanner:
    def __init__(self):
        # 机器人参数
        self.max_speed = 0.5  # m/s
        self.max_yaw_rate = 1.0  # rad/s
        self.max_accel = 2.5  # m/s^2
        self.max_yaw_accel = 3.5  # rad/s^2
        self.v_resolution = 0.01
        self.yaw_resolution = 0.02
        
        # 评估参数
        self.heading_weight = 0.15
        self clearance_weight = 1.0
        self.velocity_weight = 0.25
        
    def plan(self, robot_state, goal, obstacles):
        """
        DWA 规划
        robot_state: [x, y, yaw, v, yaw_rate]
        """
        x, y, yaw, v, yaw_rate = robot_state
        
        # 速度采样
        v_samples, yaw_samples = self.sample_velocities(v, yaw_rate)
        
        best_score = -float('inf')
        best_traj = None
        
        for v in v_samples:
            for yaw_r in yaw_samples:
                # 模拟轨迹
                traj = self.simulate_traj(x, y, yaw, v, yaw_r)
                
                # 评估
                score = self.evaluate(traj, goal, obstacles)
                
                if score > best_score:
                    best_score = score
                    best_traj = traj
                    
        return best_traj
        
    def sample_velocities(self, v, yaw_rate):
        """采样速度空间"""
        v_min = max(0, v - self.max_accel)
        v_max = min(self.max_speed, v + self.max_accel)
        yaw_min = max(-self.max_yaw_rate, yaw_rate - self.max_yaw_accel)
        yaw_max = min(self.max_yaw_rate, yaw_rate + self.max_yaw_accel)
        
        v_samples = np.arange(v_min, v_max, self.v_resolution)
        yaw_samples = np.arange(yaw_min, yaw_max, self.yaw_resolution)
        
        return v_samples, yaw_samples
        
    def simulate_traj(self, x, y, yaw, v, yaw_rate):
        """模拟轨迹"""
        traj = [(x, y, yaw)]
        
        dt = 0.1
        for _ in range(15):  # 预测 1.5 秒
            yaw += yaw_rate * dt
            x += v * np.cos(yaw) * dt
            y += v * np.sin(yaw) * dt
            traj.append((x, y, yaw))
            
        return traj
        
    def evaluate(self, traj, goal, obstacles):
        """评估轨迹"""
        # 方向评分
        heading_score = self.heading_weight * self.heading(traj[-1], goal)
        
        # 障碍物评分
        clearance_score = self.clearance_weight * self.clearance(traj, obstacles)
        
        # 速度评分
        velocity_score = self.velocity_weight * abs(traj[0][2])
        
        return heading_score + clearance_score + velocity_score
```

### TEB 算法

```python
class TEBPlanner:
    def __init__(self):
        self.dt_ref = 0.1
        self.dt_hyst = 0.5
        
    def plan(self, start, goal, obstacles):
        """时间弹性带规划"""
        # 初始化轨迹
        trajectory = self.initialize_trajectory(start, goal)
        
        # 迭代优化
        for _ in range(50):
            # 构建约束
            constraints = self.build_constraints(trajectory, obstacles, goal)
            
            # 优化
            trajectory = self.optimize(trajectory, constraints)
            
        return trajectory
        
    def build_constraints(self, trajectory, obstacles, goal):
        """构建约束"""
        constraints = []
        
        # 速度约束
        for i in range(len(trajectory) - 1):
            v = self.compute_velocity(trajectory[i], trajectory[i+1])
            constraints.append(('velocity', v, self.max_velocity))
            
        # 障碍物约束
        for i, pose in enumerate(trajectory):
            for obs in obstacles:
                dist = self.distance(pose, obs)
                if dist < self.min_obstacle_dist:
                    constraints.append(('obstacle', i, obs, dist))
                    
        return constraints
```

### ROS2 局部规划器

```cpp
#include <nav2_core/local_planner.hpp>
#include <pluginlib/class_list_macros.hpp>

class DwaLocalPlanner : public nav2_core::LocalPlanner {
public:
    void configure() override {
        // 加载参数
    }
    
    nav_msgs::msg::Path computeVelocityCommands(
        const geometry_msgs::msg::PoseStamped & pose,
        const geometry_msgs::msg::Twist & velocity,
        nav2_core::GoalChecker * goal_checker) override {
        
        // DWA 规划
        geometry_msgs::msg::Twist cmd;
        cmd.linear.x = v;
        cmd.angular.z = yaw_rate;
        return cmd;
    }
};
```
