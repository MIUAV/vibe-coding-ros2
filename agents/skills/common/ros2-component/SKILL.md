---
name: ros2-component
description: ROS2 组件技能 - Composable Nodes、组件加载器、组件容器、跨进程通讯
user-invocable: true
argument-hint: 组件 OR component OR composable node OR 组件容器 OR dlopen
---

# ROS2 Component Skill

> ROS2 可组合节点完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现可加载的组件
- 使用组件容器运行多个节点
- 跨进程通讯
- 动态加载/卸载组件
- 模块化机器人应用

---

## 快速参考

### 组件 vs 节点

| 特性 | 普通节点 | 组件 |
|------|----------|------|
| 编译 | 独立可执行文件 | 库 (.so) |
| 启动 | ros2 run | 组件容器 |
| 生命周期 | 手动管理 | 容器管理 |
| 加载 | 编译时 | 运行时 |

### 组件架构

```
                    ┌─────────────────┐
                    │ Component       │
                    │ Container       │
                    │ (rclcpp::Node)  │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────┴─────┐     ┌─────┴─────┐     ┌─────┴─────┐
    │ Component │     │ Component │     │ Component │
    │    A      │     │    B      │     │    C      │
    └─────┬─────┘     └─────┬─────┘     └─────┬─────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    [Intra-process]
```

---

## C++ 组件实现

### 基本组件

```cpp
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class MyComponent : public rclcpp::Node {
public:
    MyComponent(const rclcpp::NodeOptions& options) 
        : Node("my_component", options) {
        
        publisher_ = this->create_publisher<std_msgs::msg::String>("output", 10);
        subscription_ = this->create_subscription<std_msgs::msg::String>(
            "input", 10, [this](const std_msgs::msg::String::SharedPtr msg) {
                RCLCPP_INFO(this->get_logger(), "Received: %s", msg->data.c_str());
            });
        
        RCLCPP_INFO(this->get_logger(), "Component initialized");
    }

private:
    rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
    rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
};

// 注册组件
#include <rclcpp_components/register_node_macro.hpp>
RCLCPP_COMPONENTS_REGISTER_NODE(MyComponent)
```

### CMakeLists.txt

```cmake
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(std_msgs REQUIRED)

add_library(my_component SHARED src/my_component.cpp)
ament_target_dependencies(my_component rclcpp std_msgs)

rclcpp_components_register_nodes(my_component 
    "my_component"
)

# 安装库
install(TARGETS my_component
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
```

---

## Python 组件

### 基本组件

```python
import rclpy
from rclpy.node import Node
from rclpy.component import Component
from std_msgs.msg import String

class MyComponent(Component):
    def __init__(self, options=None):
        super().__init__('my_component', options)
        
        self.pub = self.create_publisher(String, 'output', 10)
        self.sub = self.create_subscription(String, 'input', self.callback, 10)
        
        self.get_logger().info('Component initialized')
    
    def callback(self, msg):
        self.get_logger().info(f'Received: {msg.data}')


def main(args=None):
    rclpy.init(args=args)
    component = MyComponent()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```

### 注册组件

```python
# 在 setup.py 中
entry_points={
    'rclpy.component': [
        'my_component = my_package.my_component:MyComponent',
    ],
}
```

---

## 组件容器

### Launch 启动组件

```python
# launch/component_container.launch.py
from launch_ros.actions import Node
from launch_ros.descriptions import ComposableNode

def generate_launch_description():
    # 组件 A
    comp_a = ComposableNode(
        package='pkg_a',
        plugin='pkg_a::ComponentA',
        name='component_a',
        parameters=[{'param': value}],
    )
    
    # 组件 B
    comp_b = ComposableNode(
        package='pkg_b',
        plugin='pkg_b::ComponentB',
        name='component_b',
    )
    
    # 组件容器
    container = Node(
        package='rclcpp_components',
        executable='component_container',
        name='my_container',
        composable_node=[comp_a, comp_b],
        output='screen',
    )
    
    return LaunchDescription([container])
```

### 命令行运行

```bash
# 启动组件容器
ros2 run rclcpp_components component_container

# 加载组件 (通过 ros 客户端)
ros2 component load /my_container pkg_a ComponentA

# 列出组件
ros2 component list

# 卸载组件
ros2 component unload /my_container 1
```

### 多容器分布式

```python
# 容器 A
Node(
    package='rclcpp_components',
    executable='component_container',
    name='container_a',
    remappings=[('/my_container', '/container_a')]
)

# 容器 B - 通过话题通讯
Node(
    package='rclcpp_components',
    executable='component_container',
    name='container_b',
    remappings=[('/input', '/container_a/output')]
)
```

---

## 高级模式

### 条件加载组件

```python
def generate_launch_description():
    components = []
    
    if LaunchConfiguration('enable_camera').evaluate(context):
        components.append(ComposableNode(
            package='camera_driver',
            plugin='camera_driver::CameraComponent',
            name='camera',
        ))
    
    return LaunchDescription([
        DeclareLaunchArgument('enable_camera', default_value='true'),
        Node(
            package='rclcpp_components',
            executable='component_container',
            name='container',
            composable_node=components,
        ),
    ])
```

### 组件分组

```python
# 视觉处理组
vision_group = ComposableNodeContainer(
    package='rclcpp_components',
    executable='component_container',
    name='vision_container',
    composable_node_descriptors=[
        ComposableNode(
            package='vision',
            plugin='vision::Detector',
            name='detector',
        ),
        ComposableNode(
            package='vision',
            plugin='vision::Tracker',
            name='tracker',
        ),
    ],
)
```

---

## 命令行工具

```bash
# 启动容器
ros2 run rclcpp_components component_container

# 加载组件
ros2 component load /container pkg_name PluginName

# 查看已加载组件
ros2 component list

# 卸载组件
ros2 component unload /container component_id

# 查看组件信息
ros2 component info /container 1
```

---

## 最佳实践

1. **独立编译**: 组件作为库单独编译
2. **接口清晰**: 定义明确的输入输出接口
3. **参数化**: 使用参数配置组件行为
4. **错误处理**: 处理组件加载失败情况
5. **资源清理**: 组件卸载时正确释放资源