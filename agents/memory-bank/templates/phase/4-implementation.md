# Phase 4: Implementation

## Lifecycle 节点模板
```cpp
class MyNode : public rclcpp_lifecycle::LifecycleNode {
public:
  MyNode() : LifecycleNode("my_node") {}
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override { return SUCCESS; }
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override { return SUCCESS; }
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State&) override { return SUCCESS; }
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State&) override { return SUCCESS; }
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State&) override { return SUCCESS; }
};
```

## 自测命令
```bash
colcon build --packages-select <pkg>
ros2 run <pkg> <node> --ros-args --log-level DEBUG
ros2 topic echo /<topic> --once
ros2 service call /<service> <pkg>/srv/<Service> "{param: value}"
ros2 action send_goal /<action> <pkg>/action/<Action> "{goal: value}"
```

## 提交前检查
- [ ] `colcon build` 无警告无错误
- [ ] `ament_lint` 通过
- [ ] `clang-format -i src/*.cpp` 格式正确
- [ ] gtest 测试通过
