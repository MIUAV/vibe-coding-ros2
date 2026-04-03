#!/usr/bin/env python3
"""py_subscriber launch 文件"""

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package="py_subscriber",
            executable="py_subscriber",
            name="py_subscriber",
            output="screen",
        ),
    ])
