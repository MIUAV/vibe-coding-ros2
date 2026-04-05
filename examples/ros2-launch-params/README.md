# ros2-launch-params — Launch 参数传递示例

## Launch 参数核心概念

| 概念 | 说明 |
|------|------|
| `DeclareLaunchArgument` | 声明 launch 文件参数（可从命令行覆盖） |
| `LaunchConfiguration` | 引用声明的参数 |
| `remappings` | 话题/服务重命名 |
| `namespace` | 节点命名空间前缀 |
| `parameters` | 传给节点的参数 |

## 使用方法

```bash
# 默认参数
ros2 launch ros2_launch_params demo.launch.py

# 覆盖参数
ros2 launch ros2_launch_params demo.launch.py \
  robot_name:=my_robot \
  rate:=20.0 \
  use_sim_time:=true
```

## 关键代码

```python
from launch.substitutions import LaunchConfiguration

robot_name = LaunchConfiguration('robot_name')

Node(
    package='my_package',
    executable='my_node',
    namespace=robot_name,           # 命名空间
    parameters=[{'rate': rate}],   # 参数
    remappings=[
        ('/old_topic', '/new_topic'),  # 话题重映射
    ],
)
```

## 常见模式

### 1. 批量节点启动
```python
from launch_ros.actions import Node

nodes = [
    Node(package='pkg', executable='node1'),
    Node(package='pkg', executable='node2'),
]
return LaunchDescription(nodes)
```

### 2. Composable Node 动态加载
```python
from launch_ros.actions import ComposableNodeContainer, Node

container = ComposableNodeContainer(
    name='container',
    package='rclcpp_components',
    executable='component_container',
    composable_node_descriptions=[
        ComposableNode(package='pkg', plugin='pkg::NodeClass'),
    ],
)
```
