"""Lifecycle Controller 启动文件."""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='ros2_lifecycle_demo',
            executable='lifecycle_demo',
            name='lifecycle_controller',
            output='screen',
            parameters=[{
                'publish_rate_hz': 20.0,
                'max_linear_vel': 1.0,
                'max_angular_vel': 2.0,
            }],
            # Lifecycle 节点需要额外启动生命周期管理器
            # 注意：通常需要 lifecycle_manager 统一管理状态切换
        ),
    ])
