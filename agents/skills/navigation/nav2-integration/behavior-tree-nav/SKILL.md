---
name: behavior-tree-nav
description: 行为树导航技能 - BehaviorTree.CPP、Nav2 BT、自定义行为节点
argument-hint: 行为树 OR BehaviorTree OR BT navigator OR nav2 BT
user-invocable: true
---

# 行为树导航技能

> Navigation2 行为树配置与自定义节点

---

## 何时使用

当需要以下帮助时使用此技能：
- BehaviorTree.CPP 使用
- Nav2 行为树配置
- 自定义 BT 节点
- 条件节点开发
- 导航状态机

---

## 核心实现

### BT Navigator 配置

```yaml
# config/bt_navigator.yaml
bt_navigator:
  ros__parameters:
    bt_xml_filename: 'config/nav2_bt_nav.xml'
    plugin_lib_names:
      - nav2_compute_path_to_pose_action_bt_node
      - nav2_follow_path_action_bt_node
      - nav2_back_up_action_bt_node
      - nav2_spin_action_bt_node
      - nav2_wait_action_bt_node
      - nav2_clear_costmap_service_bt_node
```

### 行为树 XML

```xml
<?xml version="1.0"?>
<root BTCPP_format="4">
  <BehaviorTree ID="MainTree">
    <PipelineSequence name="Navigate">
      <!-- 恢复 -->
      <ReactiveFallback>
        <GoalUpdated/>
        <RecoveryNode name="Recovery">
          <RoundRobin name="RecoveryActions">
            <ClearEntireCostmap name="ClearCostmap"/>
            <Spin spin_dist="1.57"/>
            <Wait wait_duration="2"/>
          </RoundRobin>
        </RecoveryNode>
      </ReactiveFallback>
      
      <!-- 规划路径 -->
      <ComputePathToPose goal="{goal}" path="{path}" error="{error}"/>
      
      <!-- 跟随路径 -->
      <FollowPath path="{path}" error="{error}"/>
    </PipelineSequence>
  </BehaviorTree>
</root>
```

### 自定义 BT 节点

```cpp
#include <behaviortree_cpp_v3/action_node.h>
#include <nav_msgs/msg/path.hpp>

class ComputePathToPoseAction : public BT::ActionNodeBase {
public:
    ComputePathToPoseAction(const std::string& name,
                           const BT::NodeConfiguration& config)
        : BT::ActionNodeBase(name, config) {}
        
    void halt() override {}
    
    BT::NodeStatus tick() override {
        // 获取输入
        auto goal = getInput<geometry_msgs::msg::PoseStamped>("goal");
        
        // 调用规划服务
        auto result = call_planner_service(goal.value());
        
        if (result.success) {
            setOutput("path", result.path);
            return BT::NodeStatus::SUCCESS;
        }
        return BT::NodeStatus::FAILURE;
    }
};
```

### Python BT 节点

```python
from behavior_tree_class import Action

class CustomCondition(Action):
    def __init__(self, name, config):
        super().__init__(name, config)
        
    def tick(self):
        # 检查条件
        if self.check_condition():
            return NodeStatus.SUCCESS
        return NodeStatus.FAILURE
        
    def check_condition(self):
        # 自定义检查逻辑
        return True
```
