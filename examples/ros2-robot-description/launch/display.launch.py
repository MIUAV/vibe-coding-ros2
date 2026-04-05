# display.launch.py — 启动 robot_state_publisher + joint_state_publisher
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.substitutions import LifecycleNode


def generate_launch_description() -> LaunchDescription:
    # URDF 文件路径
    urdf_file = '/path/to/workspace/vibe-coding-ros2/examples/ros2-robot-description/urdf/robot.urdf'

    # 读取 URDF 内容
    with open(urdf_file, 'r') as f:
        robot_desc = f.read()

    return LaunchDescription([
        # Robot State Publisher
        Node(
            package='robot_state_publisher',
            executable='robot_state_publisher',
            name='robot_state_publisher',
            parameters=[{'robot_description': robot_desc}],
            arguments=['--ros-args', '--log-level', 'info'],
        ),

        # Joint State Publisher (GUI)
        Node(
            package='joint_state_publisher',
            executable='joint_state_publisher',
            name='joint_state_publisher',
        ),

        # RViz2
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', '/path/to/default.rviz'],
        ),
    ])
