#!/usr/bin/env python3
"""
cpp_publisher launch 文件

Launch 描述符规范 (ANTI_PATTERNS.md):
  ✅ 必须返回 LaunchDescription 对象
  ✅ Node 参数必须完整: package, executable, name, output
  ✅ 参数用 parameters 传递
  ✅ 话题重映射用 remappings
"""

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package="cpp_publisher",
            executable="minimal_publisher",
            name="minimal_publisher",
            output="screen",
            # parameters=[{"param_name": "param_value"}],
            # remappings=[("/src_topic", "/dst_topic")],
        ),
    ])
