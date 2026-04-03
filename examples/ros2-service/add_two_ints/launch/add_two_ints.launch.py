#!/usr/bin/env python3
"""add_two_ints service + client launch"""

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package="add_two_ints",
            executable="add_two_ints_server",
            name="add_two_ints_server",
            output="screen",
        ),
        Node(
            package="add_two_ints",
            executable="add_two_ints_client",
            name="add_two_ints_client",
            output="screen",
        ),
    ])
