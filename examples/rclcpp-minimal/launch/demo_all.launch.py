#!/usr/bin/env python3
# demo_all.launch.py - 同时启动发布者和订阅者

from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='rclcpp_minimal',
            executable='demo_publisher',
            name='publisher_demo',
            output='screen',
            parameters=[{'use_sim_time': False}]
        ),
        Node(
            package='rclcpp_minimal',
            executable='demo_subscriber',
            name='subscriber_demo',
            output='screen',
            parameters=[{'use_sim_time': False}]
        ),
        Node(
            package='rclcpp_minimal',
            executable='demo_timer',
            name='timer_demo',
            output='screen',
        ),
    ])
