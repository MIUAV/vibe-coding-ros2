#!/bin/bash
# ros2-param-generator.sh — ROS2 参数配置文件生成器
# 用法: bash ros2-param-generator.sh <pkg_name> [robot_type]
# robot_type: diff_robot | arm_6dof | quadrotor | ackermann_vehicle | custom
#
# 示例: bash ros2-param-generator.sh my_robot diff_robot

PKG_NAME="${1:-}"
ROBOT_TYPE="${2:-custom}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [机器人类型]"
    echo "  diff_robot       — 差速驱动移动机器人"
    echo "  arm_6dof        — 6自由度机械臂"
    echo "  quadrotor       — 四旋翼无人机"
    echo "  ackermann_vehicle — 阿克曼车辆"
    echo "  custom          — 自定义参数"
    exit 1
fi

mkdir -p "$PKG_NAME/config" "$PKG_NAME/launch"

# ── 差速驱动机器人参数 ──────────────────────────────────
if [[ "$ROBOT_TYPE" == "diff_robot" ]]; then

cat > "$PKG_NAME/config/params.yaml" <<'YAMLEOF'
/**:
  ros__parameters:
    # ── 机器人几何 ───────────────────────────────────────
    wheel_radius: 0.165              # m
    wheel_separation: 0.6            # m (track width)
    robot_width: 0.4                # m
    robot_length: 0.5               # m

    # ── 运动学参数 ───────────────────────────────────────
    max_linear_vel: 1.0            # m/s
    max_angular_vel: 2.0           # rad/s
    max_linear_accel: 2.0          # m/s²
    max_angular_accel: 3.0         # rad/s²

    # ── 里程计参数 ───────────────────────────────────────
    odom_rate: 50.0               # Hz
    odom_frame: odom
    base_frame: base_link
    publish_tf: true

    # ── 激光雷达 ───────────────────────────────────────
    scan_topic: /scan
    scan_rate: 10.0               # Hz
    scan_range_min: 0.12         # m
    scan_range_max: 3.5          # m
    scan_angle_min: -3.14159      # rad
    scan_angle_max: 3.14159       # rad

    # ── IMU ─────────────────────────────────────────────
    imu_topic: /imu/data
    imu_rate: 100.0              # Hz
    imu_accel_bias: 0.01         # m/s²
    imu_gyro_bias: 0.001         # rad/s

    # ── 定位 ─────────────────────────────────────────────
    localization: ekf              # ekf / amcl / ukf
    ekf_params_file: config/ekf.yaml
    map_frame: map
    odom_frame: odom

    # ── 导航 ─────────────────────────────────────────────
    planner: nav2_navfn_planner    # navfn / Smacplanner / ThetaStar
    controller: dwa               # dwa / teb / mppi
    planner_rate: 10.0            # Hz
    controller_rate: 20.0         # Hz
    recovery_timeout: 10.0        # s

    # ── 安全 ─────────────────────────────────────────────
    obstacle_check_rate: 10.0     # Hz
    min_obstacle_dist: 0.3        # m
    emergency_stop_dist: 0.15     # m
    pitch_limit: 30.0             # degrees
    roll_limit: 30.0             # degrees
YAMLEOF

cat > "$PKG_NAME/config/ekf.yaml" <<'YAMLEOF'
ekf_filter_node:
  ros__parameters:
    frequency: 50.0
    sensor_timeout: 0.5
    two_d_mode: true

    # ── 坐标系 ──────────────────────────────────────
    map_frame: map
    odom_frame: odom
    base_link: base_link
    world_frame: map

    # ── odometry 来源 ───────────────────────────────
    odom0: /odom
    odom0_config: [true, true, false,
                   false, false, false,
                   false, false, false,
                   false, false, true,
                   false, false, false]

    # ── IMU ────────────────────────────────────────
    imu0: /imu/data
    imu0_config: [false, false, false,
                  false, false, false,
                  false, false, false,
                  false, false, true,
                  false, false, false]
    imu0_differential: false

    # ── 过程噪声（需调参）───────────────────────────
    process_noise_covariance: [
      0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0.025, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0.025, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0.04, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005
    ]
YAMLEOF

# ── 6轴机械臂参数 ─────────────────────────────────────
elif [[ "$ROBOT_TYPE" == "arm_6dof" ]]; then

cat > "$PKG_NAME/config/params.yaml" <<'YAMLEOF'
/**:
  ros__parameters:
    # ── 关节配置 ───────────────────────────────────────
    num_joints: 6
    joint_names: [joint1, joint2, joint3, joint4, joint5, joint6]

    # ── 关节限位 ───────────────────────────────────────
    joint_limits:
      joint1: {min: -3.14, max: 3.14, max_velocity: 2.0, max_effort: 100.0}
      joint2: {min: -2.36, max: 2.36, max_velocity: 2.0, max_effort: 100.0}
      joint3: {min: -2.62, max: 2.62, max_velocity: 2.0, max_effort: 100.0}
      joint4: {min: -3.14, max: 3.14, max_velocity: 2.0, max_effort: 50.0}
      joint5: {min: -2.09, max: 2.09, max_velocity: 2.0, max_effort: 50.0}
      joint6: {min: -6.28, max: 6.28, max_velocity: 3.0, max_effort: 30.0}

    # ── 速度/加速度缩放 ───────────────────────────────
    velocity_scale: 0.3            # 规划速度上限
    acceleration_scale: 0.3        # 规划加速度上限

    # ── 碰撞检测 ───────────────────────────────────────
    self_collision_check: true
    scene_collision_check: true
    collision_margin: 0.01         # m

    # ── 规划器 ─────────────────────────────────────────
    planner: pilz_industrial_motion_planner  # pilz / ompl
    planner_time_scale: 0.3       # 规划时间上限倍率
    planning_time: 5.0            # s

    # ── 执行器 ────────────────────────────────────────
    execution_mode: async           # async / sync
    goal_time_tolerance: 5.0     # s

    # ── 末端执行器 ─────────────────────────────────────
    eef_name: gripper
    tcp_offset: [0, 0, 0.1, 0, 0, 0]  # x y z roll pitch yaw
YAMLEOF

# ── 四旋翼参数 ─────────────────────────────────────────
elif [[ "$ROBOT_TYPE" == "quadrotor" ]]; then

cat > "$PKG_NAME/config/params.yaml" <<'YAMLEOF'
/**:
  ros__parameters:
    # ── 飞行器参数 ─────────────────────────────────────
    mass: 1.5                     # kg
    gravity: 9.81                 # m/s²
    arm_length: 0.23             # m
    drag_coeff: 0.1              # 拉力系数

    # ──电机参数 ───────────────────────────────────────
    motor_config:
      min_thrust: 0.0            # N
      max_thrust: 15.0           # N
      motor_time_constant: 0.02   # s

    # ── 控制器参数 ───────────────────────────────────
    rate_controller:
      kp_p: 0.8
      kp_q: 0.8
      kp_r: 0.5
      ki_p: 0.1
      ki_q: 0.1
      ki_r: 0.05

    position_controller:
      kp_xy: 1.5
      kd_xy: 0.3
      kp_z: 2.0
      kd_z: 0.5

    # ── 安全参数 ───────────────────────────────────────
    max_tilt_angle: 0.52         # rad (30°)
    max_thrust: 20.0             # N
    min_altitude: 0.2            # m
    max_altitude: 50.0           # m

    # ── EKF 定位 ───────────────────────────────────────
    local_origin: {x: 0.0, y: 0.0, z: 0.0}
    global_frame: map
    local_frame: local_origin

    # ── 自主飞行 ───────────────────────────────────────
    mission_server: /mission_server
    takeoff_height: 1.5           # m
    landing_speed: 0.3           # m/s
YAMLEOF

# ── 阿克曼车辆参数 ────────────────────────────────────
elif [[ "$ROBOT_TYPE" == "ackermann_vehicle" ]]; then

cat > "$PKG_NAME/config/params.yaml" <<'YAMLEOF'
/**:
  ros__parameters:
    # ── 车辆几何 ───────────────────────────────────────
    wheelbase: 1.2               # m
    front_track: 0.8             # m
    rear_track: 0.8              # m
    wheel_radius: 0.15           # m
    min_turning_radius: 3.0     # m

    # ── 运动学参数 ───────────────────────────────────────
    max_steering_angle: 0.52    # rad (30°)
    max_steering_rate: 2.0      # rad/s
    max_forward_speed: 5.0      # m/s
    max_reverse_speed: 2.0     # m/s
    max_accel: 3.0               # m/s²
    max_decel: 5.0               # m/s²

    # ── 控制器参数 ───────────────────────────────────────
    pure_pursuit:
      look_ahead_distance: 2.0    # m
      lookahead_time: 1.0         # s
      lookahead_ratio: 0.5        # m/m/s

    speed_controller:
      kp: 1.0
      ki: 0.1
      kd: 0.05
      max_output: 1.0

    # ── 安全参数 ───────────────────────────────────────
    min_obstacle_dist: 0.5       # m
    emergency_stop_dist: 0.2      # m
    steering_rate_limiter: 2.0   # rad/s

    # ── 定位 ─────────────────────────────────────────────
    odom_frame: odom
    base_frame: base_link
    publish_tf: true
    odom_rate: 50.0             # Hz
YAMLEOF

# ── 自定义参数 ──────────────────────────────────────────
else

cat > "$PKG_NAME/config/params.yaml" <<'YAMLEOF'
/**:
  ros__parameters:
    # ── 自定义参数 ───────────────────────────────────────
    # 在此添加你的参数

    # 示例：
    # my_param: 1.0
    # my_string_param: "default"
    # my_bool_param: false
    # my_list_param: [1.0, 2.0, 3.0]
YAMLEOF

fi

# ── launch 包含参数 ─────────────────────────────────────
cat > "$PKG_NAME/launch/params.launch.py" <<'LAUNCHEOF'
"""Load parameters for PKGNAME"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='PKGNAME',
            executable='some_node',
            name='some_node',
            parameters=['config/params.yaml'],
            output='screen',
        ),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/params.launch.py"

echo ""
echo "Generated: $PKG_NAME/config/params.yaml"
if [[ "$ROBOT_TYPE" == "diff_robot" ]]; then
  echo "Generated: $PKG_NAME/config/ekf.yaml"
fi
echo "Generated: $PKG_NAME/launch/params.launch.py"
echo ""
echo "Robot type: $ROBOT_TYPE"
echo ""
echo "Usage:"
echo "  ros2 launch PKGNAME params.launch.py"
echo ""
echo "Tuning tips:"
if [[ "$ROBOT_TYPE" == "diff_robot" ]]; then
  echo "  - EKF process_noise_covariance: larger = smoother but slower response"
  echo "  - velocity_scale in nav2: reduce if robot oscillates"
  echo "  - obstacle_check_rate: increase for faster reaction"
fi
