---
name: path-planning
description: 全局路径规划技能 - A*/RRT*/Dijkstra/Hybrid A*、代价地图配置、nav2 planner插件开发
argument-hint: "路径规划" / "path planning" / "全局规划" / "planner" / "A*" / "RRT"
user-invocable: true
---

# 全局路径规划技能

> 实现 A*、RRT*、Dijkstra、Hybrid A* 等全局路径规划算法及 nav2 插件开发

---

## 常用算法对比

| 算法 | 复杂度 | 适用场景 | 特性 |
|------|--------|----------|------|
| Dijkstra | O(V²) | 小规模网格地图 | 最优解，保证性最强 |
| A* | O(E log V) | 通用栅格地图 | 启发式搜索，最常用 |
| RRT* | O(E log V) | 高维连续空间 | 概率完备，逐渐最优 |
| Hybrid A* | O(E log V) | 车辆模型 | 支持车俩运动约束 |
| Theta* | O(E log V) | 任意角度路径 | 路径更平滑 |

---

## nav2 插件开发

```bash
# 创建 planner 插件包
ros2 pkg create my_planner --cmake-args -DBUILD_SHARED_LIBS=ON
```

### plugin.xml 注册

```xml
<library path="my_planner_lib">
  <class name="my_planner/MyPlanner"
         type="my_planner::MyPlanner"
         base_class_type="nav2_core::GlobalPlanner"/>
</library>
```

### C++ 插件实现

```cpp
#include <nav2_core/global_planner.hpp>
#include <nav_msgs/msg/path.hpp>
#include <geometry_msgs/msg/pose_stamped.hpp>

namespace my_planner {

class MyPlanner : public nav2_core::GlobalPlanner {
public:
  void configure(
    rclcpp::Node* node,
    const std::string& name,
    std::shared_ptr<tf2_ros::Buffer> tf,
    std::shared_ptr<nav2_costmap_2d::Costmap2DROS> costmap_ros
  ) override {
    node_ = node;
    costmap_ = costmap_ros->getCostmap();
    // 读取参数
    resolution_ = costmap_->getResolution();
    origin_ = costmap_->getOrigin();
  }

  nav_msgs::msg::Path createPlan(
    const geometry_msgs::msg::PoseStamped& start,
    const geometry_msgs::msg::PoseStamped& goal
  ) override {
    nav_msgs::msg::Path path;
    path.header.stamp = node_->now();
    path.header.frame_id = costmap_->getGlobalFrameID();
    
    // A* 实现
    // 1. 将 start/goal 从 map frame 转换到 grid 坐标
    // 2. A* 搜索
    // 3. 将结果转换为 PoseStamped 序列
    
    return path;
  }

private:
  rclcpp::Node* node_;
  nav2_costmap_2d::Costmap2D* costmap_;
  double resolution_;
  geometry_msgs::msg::Point origin_;
};

}  // namespace my_planner

#include <pluginlib/class_list_macros.hpp>
PLUGINLIB_EXPORT_CLASS(my_planner::MyPlanner, nav2_core::GlobalPlanner)
```

### CMakeLists.txt

```cmake
ament_auto_add_library(my_planner_lib SHARED src/my_planner.cpp)
pluginlib_export_class_description_code(my_planner_lib my_planner)
```

---

## A* 算法实现

```cpp
struct Node {
  int x, y, g, h;
  Node* parent;
  bool operator<(const Node& other) const { return (g + h) < (other.g + other.h); }
};

std::vector<Node*> aStarSearch(
    nav2_costmap_2d::Costmap2D* costmap,
    int start_x, int start_y,
    int goal_x, int goal_y
) {
  std::priority_queue<Node*> open;
  std::unordered_set<int> closed;
  open.push(new Node{start_x, start_y, 0,
      std::abs(start_x-goal_x)+std::abs(start_y-goal_y), nullptr});
  
  const int dx[8] = {0,1,1,1,0,-1,-1,-1};
  const int dy[8] = {1,1,0,-1,-1,-1,0,1};
  const int cost[8] = {1,1,1,1,1,1,1,1};
  
  while (!open.empty()) {
    auto* cur = open.top(); open.pop();
    if (cur->x == goal_x && cur->y == goal_y) {
      std::vector<Node*> result;
      while (cur) { result.push_back(cur); cur = cur->parent; }
      return result;
    }
    int key = cur->x * 10000 + cur->y;
    if (closed.count(key)) continue;
    closed.insert(key);
    
    for (int i = 0; i < 8; ++i) {
      int nx = cur->x + dx[i], ny = cur->y + dy[i];
      if (nx < 0 || ny < 0) continue;
      unsigned char c = costmap->getCost(nx, ny);
      if (c == nav2_costmap_2d::LETHAL_OBSTACLE) continue;
      int ng = cur->g + cost[i] + (c > nav2_costmap_2d::FREE ? 50 : 0);
      open.push(new Node{nx, ny, ng,
          std::abs(nx-goal_x)+std::abs(ny-goy_y), cur});
    }
  }
  return {};
}
```

---

## 代价地图配置

```yaml
global_costmap:
  global_costmap:
    ros__parameters:
      costmap:
        global_frame: map
        robot_base_frame: base_link
        update_frequency: 5.0
        publish_frequency: 1.0
        width: 20.0   # meters
        height: 20.0
        resolution: 0.05
        inflation:
          inflation_radius: 0.5
          cost_scaling_factor: 1.0
```

---

## 规范

- 路径分辨率：全局 0.05m/pixel，局部 0.025m/pixel
- 最大路径长度：100m（室内），500m（室外）
- 路径重规划触发：机器人偏离路径 > 0.5m 或障碍物阻塞
- Hybrid A* 最小转弯半径：车辆轴距 × 2

---

## 错误处理

| 问题 | 原因 | 解决 |
|------|------|------|
| 路径规划失败 | 目标点被障碍物占用 | 膨胀目标点周围 |
| 路径不平滑 | 算法本身 | 后处理（Dubins/曲线拟合） |
| 全局路径卡死 | costmap 更新不及时 | 提高 update_frequency |
| RRT* 探索慢 | 随机采样效率低 | 引导性采样（目标偏置） |
