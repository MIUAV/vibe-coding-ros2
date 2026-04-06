#!/bin/bash
# ros2-slam-generator.sh — SLAM 配置生成器
# 用法: bash ros2-slam-generator.sh <pkg_name> [slam_type]
# slam_type: 2d | 3d | lidar_imu_fusion | visual | cartographer
#
# 示例: bash ros2-slam-generator.sh my_slam_config 2d

PKG_NAME="${1:-}"
SLAM_TYPE="${2:-2d}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [SLAM类型]"
    echo "  2d               — 2D激光SLAM（slam_toolbox，实时建图）"
    echo "  3d               — 3D激光SLAM（FAST-LIO2/LOAM系）"
    echo "  lidar_imu_fusion — 激光+IMU紧耦合定位"
    echo "  visual           — 视觉SLAM（VINS-Fusion/ORB-SLAM3）"
    echo "  cartographer     — Google Cartographer（2D/3D）"
    exit 1
fi

mkdir -p "$PKG_NAME/config" "$PKG_NAME/launch" "$PKG_NAME/urdf"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAME</name>
  <version>0.1.0</version>
  <description>SLAM configuration package</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>sensor_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>tf2_ros</depend>
  <depend>robot_state_publisher</depend>
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <export><build_type>ament_cmake</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ════════════════════════════════════════════════════════════
# 2D SLAM — slam_toolbox
# ════════════════════════════════════════════════════════════
if [[ "$SLAM_TYPE" == "2d" ]]; then

cat > "$PKG_NAME/config/slam_params.yaml" <<'YAMLEOF'
slam_toolbox:
  ros__parameters:
    # ── 地图参数 ──────────────────────────────────────
    map_frame: map
    odom_frame: odom
    base_frame: base_link
    scan_topic: /scan

    # ── 地图分辨率和范围 ──────────────────────────────
    resolution: 0.05              # m/cell
    map_size: 2048               # cells
    map_start_x: 0.5
    map_start_y: 0.5

    # ── 扫描匹配参数 ────────────────────────────────
    min_score: 0.5               # 最小匹配分数
    max_description_score: 200.0
    min_loop_check_distance: 0.5 # m

    # ── 运动模型 ────────────────────────────────────
    motion_model: differential   # odometry model: differential/omnidirectional/laser

    # ── ICP / 扫描匹配 ──────────────────────────────
    scan_matcher: 1              # default:1 (primary scanmatcher)
    scan_buffer_size: 10         # 扫描缓冲区大小
    scan_buffer_max_scan_count: 50

    # ── 实时性 ────────────────────────────────────
    enable_interactive_mode: true
    publish_topic: /map
    publish_tf: true

    # ── 优化 ──────────────────────────────────────
    solver: g2o                  # g2o / ceres
    g2o_solver:
      type: solver_var_seqslam
      max_iterations: 20
      steps_max: 1000
YAMLEOF

cat > "$PKG_NAME/launch/slam.launch.py" <<'LAUNCHEOF'
"""2D SLAM launch using slam_toolbox"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        # static transform: base → laser
        Node(package='tf2_ros',
             executable='static_transform_publisher',
             args=['0 0 0 0 0 0 base_link laser'],
             name='static_tf_base_laser'),
        # Robot state publisher
        Node(package='robot_state_publisher',
             executable='robot_state_publisher',
             name='robot_state_publisher',
             parameters=[{'robot_description': ''}]),
        # SLAM toolbox
        Node(package='slam_toolbox',
             executable='async_slam_toolbox_node',
             name='slam_toolbox',
             output='screen',
             parameters=['config/slam_params.yaml']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/slam.launch.py"

# ════════════════════════════════════════════════════════════
# 3D SLAM — FAST-LIO2
# ════════════════════════════════════════════════════════════
elif [[ "$SLAM_TYPE" == "3d" ]]; then

cat > "$PKG_NAME/config/slam_params.yaml" <<'YAMLEOF'
fast_lio:
  ros__parameters:
    # ── 话题 ─────────────────────────────────────────
    point_cloud_topic: /livox/lidar
    imu_topic: /livox/imu

    # ── 帧 ─────────────────────────────────────────
    frame: map
    odometry_frame: odom
    base_frame: base_link
    lidar_frame: livox_frame

    # ── 建图参数 ─────────────────────────────────────
    max_points: 81920            # 每帧最大点数
    point_filter_num: 1           # 采样间隔
    publish_fsd: true
    fsd_resolution: 0.1           # m

    # ── 外参（lidar→IMU）────────────────────────────
    extrinsic_T: [0.0, 0.0, 0.0]  # lidar相对于IMU的位置
    extrinsic_R: [1.0, 0.0, 0.0,
                  0.0, 1.0, 0.0,
                  0.0, 0.0, 1.0]

    # ── IKFoM 状态估计 ───────────────────────────────
    estimate_extrinsic_R: false   # 是否在线标定外参旋转
    estimate_extrinsic_T: false

    # ── 地图 ────────────────────────────────────────
    map_file_path: ""
    save_pcd: false

    # ── 性能 ────────────────────────────────────────
    max_iteration: 20
    filter_size_sqrt: 6
YAMLEOF

cat > "$PKG_NAME/launch/slam.launch.py" <<'LAUNCHEOF'
"""3D SLAM launch using FAST-LIO2"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(package='fast_lio',
             executable='fast_lio_mapping',
             name='fast_lio',
             output='screen',
             parameters=['config/slam_params.yaml']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/slam.launch.py"

# ════════════════════════════════════════════════════════════
# Cartographer (2D + 3D)
# ════════════════════════════════════════════════════════════
elif [[ "$SLAM_TYPE" == "cartographer" ]]; then

cat > "$PKG_NAME/config/cartographer.lua" <<'LUAEOF'
-- Cartographer 2D SLAM configuration
-- ROS2 cartographer_ros

include "map_builder.lua"
include "trajectory_builder.lua"

MAP_BUILDER.use_trajectory_builder_2d = true
TRAJECTORY_BUILDER_2D.num_accumulated_range_data = 1

POSE_GRAPH.optimization_problem.huber_scale = 1e1
POSE_GRAPH.optimization_problem.max_num_iterations = 200

TRAJECTORY_BUILDER_2D.scan_matcher.occupied_space_weight = 20.0
TRAJECTORY_BUILDER_2D.scan_matcher.translation_weight = 10.0
TRAJECTORY_BUILDER_2D.scan_matcher.rotation_weight = 1.0

-- Submap appearance (visualization)
TRAJECTORY_BUILDER_2D.submaps.num_range_data = 90
LUAEOF

cat > "$PKG_NAME/config/cartographer_params.lua" <<'LUAEOF'
-- Cartographer parameters for PKGNAME
RETURN {
  map_builder = MAP_BUILDER,
  trajectory_builder = TRAJECTORY_BUILDER,
  map_frame = "map",
  tracking_frame = "base_link",
  published_frame = "odom",
  odom_frame = "odom",
  provide_odom_frame = true,
  use_odometry = true,
  use_nav_slam = false,
  num_laser_scans = 1,
  num_multi_echo_laser_scans = 0,
  num_point_clouds = 0,
  lookup_transform_timeout_sec = 0.2,
  submap_publish_period_sec = 0.3,
  pose_publish_period_sec = 5e-3,
  trajectory_publish_period_sec = 5e-3,
}
LUAEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/config/cartographer_params.lua"

cat > "$PKG_NAME/launch/slam.launch.py" <<'LAUNCHEOF'
"""Cartographer SLAM launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(package='cartographer_ros',
             executable='cartographer_node',
             name='cartographer',
             output='screen',
             parameters=[{
                 'configuration_directory': 'config',
                 'configuration_basename': 'cartographer_params.lua',
             }]),
        Node(package='cartographer_ros',
             executable='occupancy_grid_node',
             name='occupancy_grid_node',
             parameters=[{
                 'resolution': 0.05,
                 'publish_period_sec': 1.0,
             }]),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/slam.launch.py"

# ════════════════════════════════════════════════════════════
# 激光+IMU紧耦合
# ════════════════════════════════════════════════════════════
elif [[ "$SLAM_TYPE" == "lidar_imu_fusion" ]]; then

cat > "$PKG_NAME/config/slam_params.yaml" <<'YAMLEOF'
lidar_imu_fusion:
  ros__parameters:
    # ── 激光雷达参数 ─────────────────────────────────
    point_cloud_topic: /scan
    lidar_frame: laser_link
    scan_period: 0.1             # s

    # ── IMU参数 ─────────────────────────────────────
    imu_topic: /imu/data
    imu_frame: imu_link
    imu_frequency: 100.0         # Hz

    # ── 融合参数 ─────────────────────────────────────
    fusion_type: "eskf"          # eskf / ekf / ukf
    state_dim: 15                # [pos, vel, ori, bias_gyro, bias_acc]

    # ── 噪声参数（需标定）────────────────────────────
    process_noise:
      pos: 0.01                 # m
      vel: 0.1                   # m/s
      ori: 0.01                  # rad
      gyro_bias: 0.001           # rad/s
      accel_bias: 0.01           # m/s^2

    measurement_noise:
      lidar_pos: 0.05            # m (激光定位精度)
      imu_accel: 0.1             # m/s^2
      imu_gyro: 0.01             # rad/s

    # ── 帧配置 ───────────────────────────────────────
    map_frame: map
    odom_frame: odom
    base_frame: base_link

    # ── 建图 ─────────────────────────────────────────
    enable_mapping: true
    map_resolution: 0.05          # m
    map_size: 2048               # cells
YAMLEOF

cat > "$PKG_NAME/launch/slam.launch.py" <<'LAUNCHEOF'
"""Lidar+IMU fusion SLAM launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        # static TF: base → laser
        Node(package='tf2_ros',
             executable='static_transform_publisher',
             args=['0 0 0 0 0 0 base_link laser'],
             name='static_tf_laser'),
        # static TF: base → imu
        Node(package='tf2_ros',
             executable='static_transform_publisher',
             args=['0 0 0 0 0 0 base_link imu'],
             name='static_tf_imu'),
        # Lidar-IMU fusion node
        Node(package='PKGNAME',
             executable='lidar_imu_fusion_node',
             name='lidar_imu_fusion',
             output='screen',
             parameters=['config/slam_params.yaml']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/slam.launch.py"

# ════════════════════════════════════════════════════════════
# 视觉SLAM — VINS-Fusion / ORB-SLAM3
# ════════════════════════════════════════════════════════════
else  # visual

cat > "$PKG_NAME/config/vins_config.yaml" <<'YAMLEOF'
vins_fusion:
  ros__parameters:
    # ── 话题 ─────────────────────────────────────────
    imu_topic: /imu/data
    image_topic: /camera/image

    # ── 相机内参（需标定）────────────────────────────
    camera_matrix:
      fx: 554.38
      fy: 554.38
      cx: 320.73
      cy: 240.03

    # ── 外参（相机→IMU）──────────────────────────────
    extrinsic_T: [0.0, 0.0, 0.0]
    extrinsic_R: [1.0, 0.0, 0.0,
                   0.0, 1.0, 0.0,
                   0.0, 0.0, 1.0]

    # ── 初始化 ───────────────────────────────────────
    estimator_type: 1             # 0: VINS-Mono, 1: VINS-Fusion
    max_solver_time: 0.05          # s
    max_num_iterations: 10

    # ── 重定位 ───────────────────────────────────────
    relocalization: true
    reloc_distance_threshold: 2.0 # m

    # ── 滑动窗口 ─────────────────────────────────────
    sliding_window_size: 20        # 图像帧数

    # ── 帧配置 ───────────────────────────────────────
    map_frame: map
    odom_frame: odom
    body_frame: base_link

    # ── 输出 ─────────────────────────────────────────
    publish_odom_after_tf: false
    publish_extrinsic: true
YAMLEOF

cat > "$PKG_NAME/launch/slam.launch.py" <<'LAUNCHEOF'
"""Visual SLAM launch using VINS-Fusion"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(package='vins_estimator',
             executable='vins_node',
             name='vins',
             output='screen',
             parameters=['config/vins_config.yaml']),
        Node(package='loop_closure',
             executable='loop_closure_node',
             name='loop_closure',
             output='screen',
             parameters=['config/vins_config.yaml']),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/slam.launch.py"

fi

echo ""
echo "Generated: $PKG_NAME/"
echo "  config/slam_params.yaml"
echo "  launch/slam.launch.py"
echo ""
echo "SLAM type: $SLAM_TYPE"
echo ""
echo "Next steps:"
echo "  1. cd $PKG_NAME"
echo "  2. rosdep install --from-paths . --ignore-src -r -y"
echo "  3. colcon build --packages-select $PKG_NAME"
echo "  4. ros2 launch $PKG_NAME slam.launch.py"
echo ""
echo "Note: Install dependencies first:"
if [[ "$SLAM_TYPE" == "2d" ]]; then
  echo "  sudo apt install ros-\${ROS_DISTRO}-slam-toolbox"
elif [[ "$SLAM_TYPE" == "3d" ]]; then
  echo "  git clone https://github.com/hku-mars/FAST_LIO.git"
elif [[ "$SLAM_TYPE" == "cartographer" ]]; then
  echo "  sudo apt install ros-\${ROS_DISTRO}-cartographer-ros"
elif [[ "$SLAM_TYPE" == "lidar_imu_fusion" ]]; then
  echo "  实现参考: LIO-SAM, LIO-SAMv2"
else
  echo "  git clone https://github.com/HKUST-Aerial-Robotics/VINS-Fusion.git"
fi
