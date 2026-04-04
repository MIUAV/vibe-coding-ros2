# lifecycle_controller.launch.py
# Launch 文件 — 启动 lifecycle_controller 节点
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    """
    启动 LifecycleController 节点

    使用方法:
        ros2 launch lifecycle_controller lifecycle_controller.launch.py
    """
    node = Node(
        package='lifecycle_controller',
        executable='lifecycle_controller_node',
        name='lifecycle_controller',
        output='screen',
        parameters=[{
            'cycle_duration': 1.0,  # Hz
        }],
        arguments=['--ros-args', '--log-level', 'info'],
    )

    return LaunchDescription([
        node,
    ])
