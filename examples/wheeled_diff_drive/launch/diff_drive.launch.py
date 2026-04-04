# diff_drive.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    """
    启动差速驱动控制器

    默认配置（轮式机器人）:
      - 轮距: 0.5m
      - 最大线速度: 1.0 m/s
      - 最大角速度: 2.0 rad/s
      - cmd_vel topic: /cmd_vel
      - 左右轮速 topic: /left_wheel_velocity, /right_wheel_velocity
    """
    node = Node(
        package='wheeled_diff_drive',
        executable='diff_drive_node',
        name='diff_drive_controller',
        output='screen',
        parameters=[{
            'wheelbase': 0.5,        # m — 轮距
            'max_linear_vel': 1.0,   # m/s — 最大线速度
            'max_angular_vel': 2.0,  # rad/s — 最大角速度
        }],
    )

    return LaunchDescription([node])
