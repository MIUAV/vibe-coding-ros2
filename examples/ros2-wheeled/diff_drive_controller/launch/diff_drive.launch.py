#!/usr/bin/env python3
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='diff_drive_controller',
            executable='diff_drive_controller',
            name='diff_drive_controller',
            output='screen',
            parameters=[{'wheel_base': 0.5}, {'max_speed': 1.0}]
        )
    ])
