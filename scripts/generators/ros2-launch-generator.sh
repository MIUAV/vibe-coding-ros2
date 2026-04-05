#!/bin/bash
# ros2-launch-generator.sh — Launch 文件生成器
# 用法: bash ros2-launch-generator.sh <node_name> [node_type]
# node_type: lifecycle | normal | nodelet | component

PKG_NAME="${1:-}"
NODE_NAME="${2:-}"
NODE_TYPE="${3:-normal}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <pkg_name> <node_name> [node_type]"
    echo "  node_type: lifecycle (default) | normal | component"
    exit 1
fi

[[ "$NODE_NAME" == "" ]] && NODE_NAME="$PKG_NAME"

mkdir -p "$PKG_NAME/launch"

if [[ "$NODE_TYPE" == "lifecycle" ]]; then
cat > "$PKG_NAME/launch/${PKG_NAME}.launch.py" <<LAUNCH
"""${PKG_NAME} launch — Lifecycle 节点启动"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='${PKG_NAME}',
            executable='${NODE_NAME}_node',
            name='${NODE_NAME}',
            output='screen',
            parameters=[{
                # Lifecycle 节点启动时处于 UNCONFIGURED 状态
                # 需要外部通过 ros2 lifecycle set 切换
            }],
        ),
    ])
LAUNCH

elif [[ "$NODE_TYPE" == "component" ]]; then
cat > "$PKG_NAME/launch/${PKG_NAME}.launch.py" <<LAUNCH
"""${PKG_NAME} launch — Component 节点"""
from launch import LaunchDescription
from launch_ros.actions import ComposableNodeContainer
from launch_ros.descriptions import ComposableNode


def generate_launch_description() -> LaunchDescription:
    container = ComposableNodeContainer(
        name='${PKG_NAME}_container',
        package='rclcpp_components',
        executable='component_container',
        composable_node_descriptions=[
            ComposableNode(
                package='${PKG_NAME}',
                plugin='${PKG_NAME}::${NODE_NAME}Component',
                name='${NODE_NAME}',
                parameters=[{}],
            ),
        ],
    )
    return LaunchDescription([container])
LAUNCH

else
cat > "$PKG_NAME/launch/${PKG_NAME}.launch.py" <<LAUNCH
"""${PKG_NAME} launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='${PKG_NAME}',
            executable='${NODE_NAME}_node',
            name='${NODE_NAME}',
            output='screen',
            parameters=[{}],
        ),
    ])
LAUNCH
fi

echo "Generated: $PKG_NAME/launch/${PKG_NAME}.launch.py"
echo ""
echo "To use:"
echo "  1. Add to package.xml:"
echo "       <exec_depend>launch_ros</exec_depend>"
echo "  2. Register in CMakeLists.txt:"
echo "       install(DIRECTORY launch DESTINATION share/\${PROJECT_NAME})"
echo "  3. Run:"
echo "       ros2 launch $PKG_NAME ${PKG_NAME}.launch.py"
