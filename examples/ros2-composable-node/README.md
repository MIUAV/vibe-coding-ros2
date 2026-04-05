# ros2-composable-node — Composable Node 示例

> 演示 rclcpp_components 动态加载的组件式节点。

## 概念

Composable Node（可组合节点）= 编译为 `.so` 共享库的 ROS2 节点，可在运行时通过 `ComponentManager` 动态加载。

优势：
- **零拷贝**：同进程内节点通信无需序列化
- **动态组合**：运行时决定加载哪些节点
- **资源高效**：单进程多节点，减少内存开销

## 编译

```bash
colcon build --packages-select ros2_composable_node
source install/setup.bash
```

## 运行

### 方式1: 手动加载

```bash
# 启动 Component Container（节点管理器）
ros2 run rclcpp_components component_container

# 在另一个终端，加载组件
ros2 component load /ComponentManager ros2_composable_node::PublisherComponent

# 查看已加载组件
ros2 component list

# 卸载组件
ros2 component unload /ComponentManager PublisherComponent_1
```

### 方式2: launch 文件自动加载

```bash
ros2 launch ros2_composable_node demo.launch.py
```

## CMakeLists.txt 关键点

```cmake
# Composable node 必须编译为 SHARED library
add_library(${PROJECT_NAME} SHARED src/publisher_component.cpp)

# 注册节点（生成 .so.desc 文件）
rclcpp_components_register_node(
  ${PROJECT_NAME}
  PLUGINLIB_EXPORT_NODE ros2_composable_node::PublisherComponent
  NODE_NAMESPACE ""
  PACKAGE_NAME ${PROJECT_NAME}
)

# 导出
ament_export_dependencies(rclcpp)
ament_export_libraries(${PROJECT_NAME})
```

## 组件注册宏

```cpp
#include <rclcpp_components/register_node_macro.hpp>

RCLCPP_COMPONENTS_REGISTER_NODE(ros2_composable_node::PublisherComponent)
```

## 应用场景

| 场景 | 为什么用 Composable |
|------|---------------------|
| 机器人控制栈 | 控制器/传感器/规划器可独立加载 |
| 多机器人协作 | 同进程通信，零拷贝 |
| 嵌入式 | 按需加载，节省内存 |
| 仿真 | 快速替换组件，无需重启进程 |
