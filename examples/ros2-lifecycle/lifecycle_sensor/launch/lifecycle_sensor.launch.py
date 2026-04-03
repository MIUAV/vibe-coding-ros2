#!/usr/bin/env python3
"""lifecycle_sensor launch — 配合 lifecycle_manager 使用"""

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package="lifecycle_sensor",
            executable="lifecycle_sensor",
            name="lifecycle_sensor",
            output="screen",
        ),
    ])
