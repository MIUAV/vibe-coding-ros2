---
name: global-planning
description: 全局路径规划技能 - A*、Dijkstra、RRT*、混合A*、ROS2 全局规划器
argument-hint: "全局规划" / "A*" / "Dijkstra" / "RRT*" / "global planning"
user-invocable: true
---

# 全局路径规划技能

> 全局路径规划算法

---

## 何时使用

当需要以下帮助时使用此技能：
- A* / Dijkstra 算法
- RRT* 渐进最优
- 混合 A* (Hybrid A*)
- 动态障碍物重规划
- ROS2 全局规划器

---

## 核心实现

### A* 算法

```python
import heapq
import numpy as np

class AStarPlanner:
    def __init__(self, resolution=0.1):
        self.resolution = resolution
        self.motion = [
            [1, 0, 1], [0, 1, 1], [-1, 0, 1], [0, -1, 1],
            [1, 1, np.sqrt(2)], [1, -1, np.sqrt(2)],
            [-1, 1, np.sqrt(2)], [-1, -1, np.sqrt(2)]
        ]
        
    def plan(self, start, goal, obstacles):
        """A* 路径规划"""
        start = (int(start[0]/self.resolution), int(start[1]/self.resolution))
        goal = (int(goal[0]/self.resolution), int(goal[1]/self.resolution))
        
        open_set = [(0, start)]
        came_from = {}
        g_score = {start: 0}
        f_score = {start: self.heuristic(start, goal)}
        
        while open_set:
            _, current = heapq.heappop(open_set)
            
            if current == goal:
                return self.reconstruct_path(came_from, current)
                
            for dx, dy, cost in self.motion:
                neighbor = (current[0] + dx, current[1] + dy)
                
                if self.is_collision(neighbor, obstacles):
                    continue
                    
                tentative_g = g_score[current] + cost
                
                if neighbor not in g_score or tentative_g < g_score[neighbor]:
                    came_from[neighbor] = current
                    g_score[neighbor] = tentative_g
                    f_score[neighbor] = tentative_g + self.heuristic(neighbor, goal)
                    heapq.heappush(open_set, (f_score[neighbor], neighbor))
                    
        return None
        
    def heuristic(self, a, b):
        """启发式函数"""
        return np.sqrt((a[0] - b[0])**2 + (a[1] - b[1])**2)
        
    def is_collision(self, point, obstacles):
        """碰撞检测"""
        return False  # 简化
        
    def reconstruct_path(self, came_from, current):
        """重建路径"""
        path = [current]
        while current in came_from:
            current = came_from[current]
            path.append(current)
        return path[::-1]
```

### RRT* 算法

```python
import numpy as np
import random

class RRTStar:
    def __init__(self, bounds, max_iter=1000, step_size=0.1):
        self.bounds = bounds
        self.max_iter = max_iter
        self.step_size = step_size
        self.tree = []
        self.parent = {}
        
    def plan(self, start, goal):
        """RRT* 路径规划"""
        self.tree = [start]
        self.parent = {start: None}
        
        for _ in range(self.max_iter):
            # 随机采样
            rand_point = self.sample()
            
            # 找最近节点
            nearest = self.nearest(rand_point)
            
            # 扩展
            new_point = self.steer(nearest, rand_point)
            
            if self.is_free(new_point):
                # 重连优化
                self.tree.append(new_point)
                near_nodes = self.near(new_point, self.step_size * 5)
                
                # 选择最优父节点
                min_cost = self.cost(nearest) + self.distance(nearest, new_point)
                self.parent[new_point] = nearest
                
                for near in near_nodes:
                    if near == nearest:
                        continue
                    new_cost = self.cost(near) + self.distance(near, new_point)
                    if new_cost < min_cost:
                        min_cost = new_cost
                        self.parent[new_point] = near
                        
                # 重布线
                self.rewire(new_point, near_nodes)
                
        # 返回最优路径
        return self.get_path(start, goal)
        
    def sample(self):
        return (random.uniform(self.bounds[0], self.bounds[1]),
                random.uniform(self.bounds[2], self.bounds[3]))
                
    def nearest(self, point):
        return min(self.tree, key=lambda p: self.distance(p, point))
        
    def steer(self, from_point, to_point):
        dx = to_point[0] - from_point[0]
        dy = to_point[1] - from_point[1]
        dist = np.sqrt(dx**2 + dy**2)
        
        if dist < self.step_size:
            return to_point
            
        ratio = self.step_size / dist
        return (from_point[0] + dx * ratio,
                from_point[1] + dy * ratio)
```

### ROS2 全局规划器插件

```cpp
#include <nav2_core/global_planner.hpp>
#include <pluginlib/class_list_macros.hpp>

class AStarGlobalPlanner : public nav2_core::GlobalPlanner {
public:
    void configure() override {}
    
    void cleanup() override {}
    
    void activate() override {}
    
    nav_msgs::msg::Path createPlan(
        const geometry_msgs::msg::PoseStamped & start,
        const geometry_msgs::msg::PoseStamped & goal,
        std::vector<geometry_msgs::msg::PoseStamped> & plan) override {
        
        // A* 规划
        auto path = astar_planner_.plan(start, goal);
        
        // 转换为 nav_msgs::Path
        for (auto& point : path) {
            geometry_msgs::msg::PoseStamped pose;
            pose.pose.position.x = point.x;
            pose.pose.position.y = point.y;
            plan.push_back(pose);
        }
        
        return plan;
    }
};
```
