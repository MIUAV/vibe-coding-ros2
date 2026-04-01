---
name: ros2-launch-advanced
description: ROS2 Launch 进阶技能 - Python Launch、多 launch 嵌套、事件处理、条件启动、参数替换
user-invocable: true
argument-hint: "launch 文件" / "launch advanced" / "python launch" / "事件处理" / "条件启动"
---

# ROS2 Launch Advanced Skill

> Python Launch 文件和高级启动模式完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- Python 高级 Launch 文件
- 多个 Launch 文件嵌套
- 事件驱动的启动逻辑
- 条件启动和参数替换
- Launch 文件参数化

---

## 快速参考

### Launch 文件结构

```
launch/
├── my_launch.launch.py          # 主 Launch
├── bringup.launch.py            # 启动入口
├── params/
│   ├── robot.yaml              # 参数文件
│   └── sensors.yaml
└── nodes/
    ├── camera.launch.py         # 子 Launch
    └── navigation.launch.py
```

### Launch 文件格式

```python
#!/usr/bin/env python3
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    return LaunchDescription([
        # 启动逻辑
    ])
```

---

## 高级 Launch 特性

### Launch 参数声明

```python
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

def generate_launch_description():
    # 声明参数
    robot_model = DeclareLaunchArgument(
        'robot_model',
        default_value='robot_s',
        description='Robot model name'
    )
    
    speed = DeclareLaunchArgument(
        'speed',
        default_value='1.0',
        description='Max speed'
    )
    
    use_sim = DeclareLaunchArgument(
        'use_sim',
        default_value='true',
        description='Use simulation'
    )
    
    # 使用参数
    robot_node = Node(
        package='robot_control',
        executable='robot_node',
        name='robot_node',
        parameters=[{
            'robot_model': LaunchConfiguration('robot_model'),
            'speed': LaunchConfiguration('speed'),
            'use_sim': LaunchConfiguration('use_sim'),
        }]
    )
    
    return LaunchDescription([
        robot_model, speed, use_sim,
        robot_node
    ])
```

### 参数替换

```python
from launch.substitutions import TextSubstitution, PythonExpression

# 简单替换
speed_factor = LaunchConfiguration('speed_factor')

# 表达式计算
computed_rate = PythonExpression(
    ['10.0 / ', LaunchConfiguration('speed_factor')]
)

# 路径拼接
config_path = TextSubstitution(
    text=os.path.join(pkg_dir, 'config', LaunchConfiguration('config_file'))
)
```

---

## 条件启动

### if 条件

```python
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition

def generate_launch_description():
    use_camera = DeclareLaunchArgument(
        'use_camera',
        default_value='true',
        description='Enable camera'
    )
    
    camera_node = Node(
        package='camera_driver',
        executable='camera_node',
        condition=IfCondition(LaunchConfiguration('use_camera'))
    )
    
    return LaunchDescription([use_camera, camera_node])
```

### unless 条件

```python
from launch.conditions import UnlessCondition

# 不使用仿真时启动
real_hw_node = Node(
    package='hardware_driver',
    executable='hw_node',
    condition=UnlessCondition(LaunchConfiguration('use_sim'))
)
```

### 多条件分支

```python
from launch.actions import OpaqueFunction

def launch_mode(context, *args, 
    mode = LaunchConfiguration('mode').perform(context)
    
    if mode == 'navigation':
        return [navigation_nodes()]
    elif mode == 'mapping':
        return [mapping_nodes()]
    else:
        return [default_nodes()]
    
    return LaunchDescription([
        DeclareLaunchArgument('mode', default_value='navigation'),
        OpaqueFunction(function=launch_mode),
    ])
```

---

## 事件处理

### 事件动作

```python
from launch.events import OnProcessStart, OnProcessExit, OnShutdown
from launch.actions import RegisterEventHandler, EmitEvent

# 进程启动时
on_start = RegisterEventHandler(
    OnProcessStart(
        target_action=robot_node,
        on_start=[EmitEvent(event=some_event)]
    )
)

# 进程退出时
on_exit = RegisterEventHandler(
    OnProcessExit(
        target_action=robot_node,
        on_exit=[log_exit]
    )
)

# 关闭时
on_shutdown = RegisterEventHandler(
    OnShutdown(
        on_shutdown=[cleanup_action]
    )
)
```

### 状态转换事件

```python
from launch_ros.events.lifecycle import ChangeState, StateTransition

# Lifecycle 状态转换
lifecycle_change = RegisterEventHandler(
    ChangeState(
        lifecycle_node_matcher=lambda node: node.name == 'managed_node',
        transition=TransitionTransition(
            start_state='inactive',
            goal_state='active'
        )
    )
)
```

---

## 嵌套 Launch

### 包含子 Launch

```python
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource

# 包含另一个 launch 文件
robot_bringup = IncludeLaunchDescription(
    PythonLaunchDescriptionSource(
        os.path.join(pkg_dir, 'launch', 'bringup.launch.py')
    ),
    launch_arguments={
        'robot_name': 'robot1',
        'use_sim': 'true',
    }.items()
)
```

### 参数化嵌套

```python
def generate_launch_description():
    robot_name = DeclareLaunchArgument('robot_name', default_value='robot1')
    
    # 不同机器人的 launch
    robot_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(pkg_dir + '/launch/robot.launch.py'),
        launch_arguments=[('robot_name', LaunchConfiguration('robot_name'))]
    )
    
    return LaunchDescription([robot_name, robot_launch])
```

### 条件嵌套

```python
from launch.actions import GroupAction

# 启动组
group_launch = GroupAction(
    condition=IfCondition(LaunchConfiguration('enable_robot')),
    actions=[
        Node(package='robot', executable='robot_node'),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(pkg_dir + '/launch/robot_params.launch')
        ),
    ]
)
```

---

## 复杂 Launch 示例

### 机器人启动 Launch

```python
# launch/robot.launch.py
import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.substitutions import LaunchConfiguration
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch_ros.actions import Node

def generate_launch_description():
    # 参数声明
    robot_name = DeclareLaunchArgument('robot_name', default_value='robot1')
    use_sim = DeclareLaunchArgument('use_sim', default_value='true')
    namespace = DeclareLaunchArgument('namespace', default_value='')
    
    # 参数使用
    ns = LaunchConfiguration('namespace')
    
    # 硬件驱动 (仿真时跳过)
    hardware = Node(
        package='hardware_driver',
        executable='hw_node',
        condition=IfCondition(
            PythonExpression(['not ', LaunchConfiguration('use_sim')])
        ),
        namespace=ns,
    )
    
    # 仿真驱动 (仿真时使用)
    sim_driver = Node(
        package='gazebo_ros',
        executable='gz_sim',
        condition=IfCondition(LaunchConfiguration('use_sim')),
        namespace=ns,
    )
    
    # 控制器
    controller = Node(
        package='robot_controller',
        executable='controller_node',
        parameters=[{
            'robot_name': LaunchConfiguration('robot_name'),
        }],
        namespace=ns,
    )
    
    # 导航 (可选)
    nav_nodes = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(pkg_dir + '/launch/nav.launch.py'),
        condition=IfCondition(LaunchConfiguration('enable_navigation')),
        launch_arguments=[('namespace', ns)],
    )
    
    return LaunchDescription([
        robot_name, use_sim, namespace,
        hardware, sim_driver, controller, nav_nodes,
    ])
```

---

## 命令行工具

```bash
# 启动 launch
ros2 launch pkg_name launch_file.launch.py

# 带参数
ros2 launch pkg_name launch_file.launch.py robot_name:=robot1

# 列出 launch 文件
ros2 launch pkg_name -s

# 查看 launch 内容
ros2 launch pkg_name launch_file.launch.py --show-args
```

---

## 最佳实践

1. **模块化**: 将不同功能模块分到不同 launch 文件
2. **参数化**: 使用参数使 launch 文件可配置
3. **条件启动**: 根据环境启用/禁用功能
4. **命名空间**: 合理使用 namespace 避免冲突
5. **错误处理**: 添加事件处理应对异常退出