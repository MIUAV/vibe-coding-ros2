# demo.launch.py
# Launch 参数传递示例 — 演示 launch 文件中节点参数和 remapping
#
# 功能:
# 1. launch arguments (可从命令行覆盖的参数)
# 2. node remapping (话题重映射)
# 3. parameters YAML 文件加载
# 4. 环境变量设置
# 5. 条件包含 (Composable Node)

from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument, ExecuteProcess, SetEnvironmentVariable,
    RegisterEventHandler, TimerEvent
)
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch.event_handlers import OnProcessStart


def generate_launch_description() -> LaunchDescription:
    """生成 launch 描述"""

    # ── Launch Arguments ─────────────────────────────────────────
    # 可从命令行覆盖: ros2 launch pkg demo.launch.py robot_name:=my_robot rate:=20.0
    robot_name_arg = DeclareLaunchArgument(
        'robot_name',
        default_value='robot',
        description='机器人名称（用于节点命名空间）'
    )

    rate_arg = DeclareLaunchArgument(
        'rate',
        default_value='10.0',
        description='发布频率 (Hz)'
    )

    use_sim_time_arg = DeclareLaunchArgument(
        'use_sim_time',
        default_value='false',
        description='使用仿真时间'
    )

    # ── 配置 ─────────────────────────────────────────────────
    robot_name = LaunchConfiguration('robot_name')
    rate = LaunchConfiguration('rate')
    use_sim_time = LaunchConfiguration('use_sim_time')

    # ── 环境变量 ──────────────────────────────────────────────
    set_env = SetEnvironmentVariable('RCUTILS_CONSOLE_OUTPUT_FORMAT', '[{name}]: {message}')

    # ── Nodes ─────────────────────────────────────────────────
    # 示例1: publisher 节点（带参数和 remapping）
    publisher_node = Node(
        package='rclcpp_minimal_publisher',
        executable='publisher_member_function',
        name='my_publisher',                    # 覆盖节点名
        namespace=robot_name,                  # 命名空间: /<robot_name>/my_publisher
        parameters=[{
            'rate': rate,                      # 运行时参数
        }],
        remappings=[
            ('/topic', f'/{robot_name}/pubsub_topic'),  # 话题重映射
        ],
        arguments=['--ros-args', '--log-level', 'info'],
        condition=TimerEvent(0, 0),  # 立即启动（简化示例）
    )

    # 示例2: subscriber 节点（接收重映射后的话题）
    subscriber_node = Node(
        package='rclcpp_minimal_subscriber',
        executable='subscriber_member_function',
        name='my_subscriber',
        namespace=robot_name,
        remappings=[
            ('/topic', f'/{robot_name}/pubsub_topic'),  # 匹配 publisher
        ],
    )

    # 示例3: lifecycle controller（带 config 文件）
    lifecycle_node = Node(
        package='lifecycle_controller',
        executable='lifecycle_controller_node',
        name='lifecycle_ctrl',
        namespace=robot_name,
        parameters=[{
            'use_sim_time': use_sim_time,
            'cycle_duration': 1.0,
        }],
    )

    # 示例4: 条件节点（只在非仿真模式下启动）
    # diagnostic_node = Node(
    #     package='robot_diagnostics',
    #     executable='diag_node',
    #     condition=IfCondition(PythonExpression(['not ', use_sim_time])),
    # )

    # ── 事件处理：lifecycle 节点启动后自动激活 ─────────────────
    # activate_after_configure = RegisterEventHandler(
    #     OnProcessStart(
    #         target_action=lifecycle_node,
    #         on_start=[
    #             TimerEvent(0, 0),  # 延迟后执行
    #             # lifecycle set /<robot_name>/lifecycle_ctrl configure
    #             # lifecycle set /<robot_name>/lifecycle_ctrl activate
    #         ]
    #     )
    # )

    return LaunchDescription([
        # ── 前置 ──────────────────────────────────────────
        set_env,
        robot_name_arg,
        rate_arg,
        use_sim_time_arg,

        # ── 节点 ──────────────────────────────────────────
        publisher_node,
        subscriber_node,
        # lifecycle_node,
    ])
