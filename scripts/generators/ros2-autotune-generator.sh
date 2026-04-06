#!/bin/bash
# ros2-autotune-generator.sh — ROS2 参数自动调优推荐生成器
# 彭志辉P1建议：只有"生成"能力不够，必须有"调参"能力
#
# 用法: bash ros2-autotune-generator.sh <pkg_name> --robot <params> --scenario <type>
#
# 示例:
#   bash ros2-autotune-generator.sh my_tuning --robot mass=3.5,wheel_radius=0.08,wheelbase=0.4 --scenario indoor_slow
#   bash ros2-autotune-generator.sh my_tuning --robot mass=15.0,wheel_radius=0.165,wheelbase=0.6 --scenario warehouse
#   bash ros2-autotune-generator.sh my_tuning --robot mass=50.0,arm_reach=0.8 --scenario industrial

set -e

PKG_NAME=""
ROBOT_PARAMS=""
SCENARIO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --robot)
      ROBOT_PARAMS="$2"; shift 2 ;;
    --scenario)
      SCENARIO="$2"; shift 2 ;;
    *)
      PKG_NAME="${1:-autotune}"; shift ;;
  esac
done

PKG_NAME="${PKG_NAME:-autotune}"

if [[ -z "$ROBOT_PARAMS" ]]; then
    echo "用法: $0 <包名> --robot <参数> --scenario <场景>"
    echo ""
    echo "参数格式: mass=3.5,wheel_radius=0.08,wheelbase=0.4"
    echo ""
    echo "机器人参数:"
    echo "  mass          机器人质量 (kg)"
    echo "  wheel_radius  轮子半径 (m)"
    echo "  wheelbase     前后轮中心距 (m)"
    echo "  wheel_sep     左右轮间距 (m)"
    echo "  arm_reach     机械臂末端最大伸距 (m)"
    echo "  max_speed    最大速度 (m/s)"
    echo ""
    echo "场景类型:"
    echo "  indoor_slow   室内低速（<0.5m/s）"
    echo "  indoor_fast   室内高速（0.5-1.0m/s）"
    echo "  warehouse     仓库/物流"
    echo "  outdoor       室外"
    echo "  rough_terrain 不平整地形"
    echo "  industrial    工业环境"
    exit 1
fi

mkdir -p "$PKG_NAME/scripts" "$PKG_NAME/config"

# ── 解析机器人参数 ─────────────────────────────────
declare -A ROBOT
IFS=',' read -ra PARTS <<< "$ROBOT_PARAMS"
for p in "${PARTS[@]}"; do
  IFS='=' read -r k v <<< "$p"
  ROBOT["$k"]="$v"
done

# ── 场景参数表 ─────────────────────────────────────
case "${SCENARIO:-indoor_slow}" in

  indoor_slow)
    SAFETY_FACTOR=0.5
    EKF_PROCESS_NOISE_POS=0.01
    EKF_PROCESS_NOISE_VEL=0.05
    NAV2_MAX_SPEED=0.3
    NAV2_MAX_ACCEL=0.2
    RCLCPP_LEVEL="DEBUG"
    ;;

  indoor_fast)
    SAFETY_FACTOR=0.7
    EKF_PROCESS_NOISE_POS=0.02
    EKF_PROCESS_NOISE_VEL=0.1
    NAV2_MAX_SPEED=0.7
    NAV2_MAX_ACCEL=0.5
    RCLCPP_LEVEL="INFO"
    ;;

  warehouse)
    SAFETY_FACTOR=0.8
    EKF_PROCESS_NOISE_POS=0.05
    EKF_PROCESS_NOISE_VEL=0.15
    NAV2_MAX_SPEED=1.0
    NAV2_MAX_ACCEL=0.8
    RCLCPP_LEVEL="INFO"
    ;;

  outdoor)
    SAFETY_FACTOR=0.9
    EKF_PROCESS_NOISE_POS=0.1
    EKF_PROCESS_NOISE_VEL=0.2
    NAV2_MAX_SPEED=1.5
    NAV2_MAX_ACCEL=1.0
    RCLCPP_LEVEL="INFO"
    ;;

  rough_terrain)
    SAFETY_FACTOR=0.4
    EKF_PROCESS_NOISE_POS=0.05
    EKF_PROCESS_NOISE_VEL=0.1
    NAV2_MAX_SPEED=0.2
    NAV2_MAX_ACCEL=0.15
    RCLCPP_LEVEL="WARN"
    ;;

  industrial)
    SAFETY_FACTOR=0.6
    EKF_PROCESS_NOISE_POS=0.02
    EKF_PROCESS_NOISE_VEL=0.08
    NAV2_MAX_SPEED=0.5
    NAV2_MAX_ACCEL=0.4
    RCLCPP_LEVEL="ERROR"
    ;;

  *)
    SAFETY_FACTOR=0.5
    EKF_PROCESS_NOISE_POS=0.01
    EKF_PROCESS_NOISE_VEL=0.05
    NAV2_MAX_SPEED=0.5
    NAV2_MAX_ACCEL=0.3
    RCLCPP_LEVEL="INFO"
    ;;
esac

# ── 基于机器人参数计算初始值 ───────────────────────
MASS="${ROBOT[mass]:-1.0}"
WHEEL_RADIUS="${ROBOT[wheel_radius]:-0.1}"
WHEELBASE="${ROBOT[wheelbase]:-0.5}"
WHEEL_SEP="${ROBOT[wheel_sep]:-0.4}"
ARM_REACH="${ROBOT[arm_reach]:-0.5}"
MAX_SPEED="${ROBOT[max_speed]:-1.0}"

# 质量影响过程噪声（越重 → 惯性越大 → 过程噪声越大）
MASS_FACTOR=$(python3 -c "print(min(2.0, max(0.5, $MASS / 10.0 + 0.5))")

# 轮子半径影响速度估算精度（越大 → encoders分辨率越低）
WHEEL_FACTOR=$(python3 -c "print(0.5 + 0.1 / max(0.05, $WHEEL_RADIUS))")

# 计算推荐的最大安全速度（基于机器人惯性和场景）
RECOMMENDED_MAX_SPEED=$(python3 -c "print(min($MAX_SPEED, $WHEEL_RADIUS * 10.0 / $MASS_FACTOR))")

# 关节限位速度（机械臂）
if [[ -n "${ROBOT[arm_reach]}" ]]; then
  ARM_JOINT_VEL=$(python3 -c "print(min(2.0, 0.5 / max(0.1, $ARM_REACH)))")
  ARM_JOINT_ACCEL=$(python3 -c "print(min(3.0, 1.0 / max(0.1, $ARM_REACH)))")
fi

# ════════════════════════════════════════════════════════════
# 生成推荐参数文件
# ════════════════════════════════════════════════════════════

# ── EKF 参数 ────────────────────────────────────────
cat > "$PKG_NAME/config/ekf_approx.yaml" <<YAMLEOF
# EKF 参数推荐值（基于机器人参数估算）
# 场景: ${SCENARIO}
# 机器人: mass=${MASS}kg, wheel_radius=${WHEEL_RADIUS}m, wheelbase=${WHEELBASE}m
#
# 调参说明：
#   process_noise_covariance 对角线含义（行=列）：
#     [0-2] position: x,y,z (m²) — 越大=越信任传感器，越小=越信任模型
#     [3-5] orientation: roll,pitch,yaw (rad²) — 通常设小
#     [6-8] velocity: vx,vy,vz (m²/s²)
#     [9-11] angular_velocity: ωx,ωy,ωz (rad²/s²)
#
ekf_filter_node:
  ros__parameters:
    frequency: 50.0
    sensor_timeout: 0.5
    two_d_mode: true

    map_frame: map
    odom_frame: odom
    base_link: base_link
    world_frame: map

    # Odometry 来源
    odom0: /odom
    odom0_config: [true, true, false,
                   false, false, false,
                   false, false, false,
                   false, false, true,
                   false, false, false]

    # IMU（如果有）
    imu0: /imu/data
    imu0_config: [false, false, false,
                  false, false, false,
                  false, false, false,
                  false, false, true,
                  false, false, false]
    imu0_differential: false

    # ── 过程噪声矩阵（自动估算）───────────────────
    # mass_factor=${MASS_FACTOR}, wheel_factor=${WHEEL_FACTOR}
    process_noise_covariance:
      [$(python3 -c "print(f'{${EKF_PROCESS_NOISE_POS}*${MASS_FACTOR:.2f}, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0')"),
       0, $(python3 -c "print(f'{${EKF_PROCESS_NOISE_POS}*${MASS_FACTOR:.2f}')"), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0.06, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, $(python3 -c "print(f'{${EKF_PROCESS_NOISE_VEL}*${WHEEL_FACTOR:.2f}')"), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, $(python3 -c "print(f'{${EKF_PROCESS_NOISE_VEL}*${WHEEL_FACTOR:.2f}')"), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, $(python3 -c "print(f'{${EKF_PROCESS_NOISE_POS}*${MASS_FACTOR:.2f}')"), 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, $(python3 -c "print(f'{${EKF_PROCESS_NOISE_POS}*${MASS_FACTOR:.2f}')"), 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0.04, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.01, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.005]
YAMLEOF

# ── Nav2 参数 ────────────────────────────────────
cat > "$PKG_NAME/config/nav2_approx.yaml" <<YAMLEOF
# Nav2 参数推荐值
# 场景: ${SCENARIO}
# mass=${MASS}kg, wheel_radius=${WHEEL_RADIUS}m
#
# 调参说明：
#   max_speed: 机器人能达到的最大速度，但Nav2会根据安全性降低
#   max_accel: 加速度限制，越小=越平滑但响应越慢
#   max_angular_vel: 角速度限制
#   motion_model: differential（差速）/ omnidirectional（全向）

amcl:
  ros__parameters:
    max_beams: 30
    min_particles: 100
    max_particles: 2000
    update_min_d: 0.2
    update_min_a: 0.2

amcl_rcll_params_file: ""

bt_navigator:
  ros__parameters:
    # ── 速度约束（自动估算）───────────────────
    max_vel_x: $(python3 -c "print(min(${NAV2_MAX_SPEED}, ${RECOMMENDED_MAX_SPEED:.2f}))")
    max_vel_y: 0.0
    max_vel_theta: 2.0
    min_vel_x: -$(python3 -c "print(min(${NAV2_MAX_SPEED}, ${RECOMMENDED_MAX_SPEED:.2f}))")
    min_vel_y: 0.0
    min_vel_theta: -2.0
    max_accel_x: ${NAV2_MAX_ACCEL}
    max_accel_y: 0.0
    max_accel_theta: 2.0

    # ── DWA 局部规划器参数 ──────────────────────
    min_obstacle_dist: 0.3
    safety_dist: 0.5
    robot_radius: $(python3 -c "print(${WHEEL_SEP} / 2.0)")

controller_server:
  ros__parameters:
    follow_distance: $(python3 -c "print(max(0.3, ${WHEELBASE} * 0.5))")
    zoom_scale: 3.0
    transform_tolerance: 0.5
YAMLEOF

# ── ros2_control 参数 ─────────────────────────────
if [[ -n "${ROBOT[arm_reach]}" ]]; then
  cat > "$PKG_NAME/config/ros2_control_approx.yaml" <<YAMLEOF
# ros2_control 参数推荐值（机械臂）
# 场景: ${SCENARIO}
# arm_reach=${ARM_REACH}m

controller_manager:
  ros__parameters:
    update_rate: 100.0

    joint_trajectory_controller:
      type: joint_trajectory_controller/JointTrajectoryController
      joints: [joint1, joint2, joint3, joint4, joint5, joint6]
      command_interfaces: [position]
      state_interfaces: [position, velocity]

    joint_state_broadcaster:
      type: joint_state_broadcaster/JointStateBroadcaster

joint_trajectory_controller:
  ros__parameters:
    joints: [joint1, joint2, joint3, joint4, joint5, joint6]
    command_interfaces: [position]
    state_interfaces: [position, velocity]

    # 速度/加速度限制（自动估算）
    constraints:
      joint1: {trajectory: 0.1, goal: 0.1}
      joint2: {trajectory: 0.1, goal: 0.1}
      joint3: {trajectory: 0.1, goal: 0.1}
      joint4: {trajectory: 0.1, goal: 0.1}
      joint5: {trajectory: 0.1, goal: 0.1}
      joint6: {trajectory: 0.1, goal: 0.1}
YAMLEOF
fi

# ── 调参脚本 ───────────────────────────────────
cat > "$PKG_NAME/scripts/tune_and_validate.sh" <<BASHEOF
#!/bin/bash
# tune_and_validate.sh — 参数验证脚本
# 用法: bash tune_and_validate.sh <param_file.yaml>
#
# 彭志辉方法论：理论计算初始值 → 仿真验证 → 真机微调
#
set -e

PARAM_FILE="\${1:-config/nav2_approx.yaml}"

echo "=== 参数验证 ==="
echo "文件: $PARAM_FILE"

if [[ ! -f "\$PARAM_FILE" ]]; then
  echo "ERROR: 文件不存在: \$PARAM_FILE"
  exit 1
fi

# 1. 语法检查（ros2 param dump）
echo ""
echo "=== 1. YAML 语法检查 ==="
python3 -c "import yaml; yaml.safe_load(open('$PARAM_FILE'))" && echo "YAML OK" || { echo "YAML SYNTAX ERROR"; exit 1; }

# 2. 值域检查
echo ""
echo "=== 2. 值域检查 ==="
python3 << 'PYEOF'
import yaml

with open('${PARAM_FILE}') as f:
    params = yaml.safe_load(f)

errors = []
warnings = []

def check(key, value, min_v, max_v, unit):
    if value < min_v:
        errors.append(f"  {key}={value} ({unit}) < 最小值 {min_v}")
    elif value > max_v:
        warnings.append(f"  {key}={value} ({unit}) > 推荐最大值 {max_v} (可能不稳定)")

if 'bt_navigator' in params:
    bt = params['bt_navigator']['ros__parameters']
    if 'max_vel_x' in bt:
        check('max_vel_x', bt['max_vel_x'], 0.0, 2.0, 'm/s')
    if 'max_accel_x' in bt:
        check('max_accel_x', bt['max_accel_x'], 0.0, 3.0, 'm/s²')

if errors:
    print("ERRORS:")
    for e in errors: print(e)
    exit(1)
else:
    print("值域检查: PASSED")

if warnings:
    print("WARNINGS:")
    for w in warnings: print(w)
else:
    print("推荐值检查: OK")
PYEOF

# 3. 生成对比报告
echo ""
echo "=== 3. 与默认值对比 ==="
echo "推荐值 vs ROS2 默认值:"
echo "  max_vel_x: $(grep max_vel_x "$PARAM_FILE" | grep -v '#' | head -1 || echo 'N/A')"
echo "  max_accel_x: $(grep max_accel_x "$PARAM_FILE" | grep -v '#' | head -1 || echo 'N/A')"
echo ""
echo "验证完成！建议下一步："
echo "  1. 在 Gazebo 仿真中测试"
echo "  2. 观察机器人运动是否平滑"
echo "  3. 如有振荡，逐步降低 max_accel"
echo "  4. 如响应太慢，逐步提高 max_vel_x"
BASHEOF
chmod +x "$PKG_NAME/scripts/tune_and_validate.sh"

# ── Python 参数分析脚本 ──────────────────────────
cat > "$PKG_NAME/scripts/analyze_robot_data.py" <<PYEOF
#!/usr/bin/env python3
"""
analyze_robot_data.py — 基于机器人实测数据优化参数
彭志辉方法：采集真实运动数据 → 分析误差 → 反馈到参数

用法:
  python3 analyze_robot_data.py --bag /path/to/recording.bag --output tuned_params.yaml

输入: ros2 bag 录制机器人运动数据
输出: 优化后的 EKF/Nav2 参数
"""
import argparse
import numpy as np
import sys

def analyze_odom_drift(bag_path):
    """分析里程计漂移，估计 EKF 过程噪声"""
    # TODO: 实现 rosbag2 分析
    # 1. 读取 /odom 话题
    # 2. 计算 position 误差（与 ground truth 或 SLAM 对比）
    # 3. 分析速度噪声的统计特性
    print("WARN: rosbag2 analysis not yet implemented")
    print("  TODO: use ros2bag_py or rosbag2 API")

def suggest_ekf_noise(position_error_m, velocity_error_ms):
    """基于测量误差推荐 EKF 噪声参数"""
    # 经验公式：process_noise ≈ 2 * measurement_error
    pos_noise = 2.0 * position_error_m
    vel_noise = 2.0 * velocity_error_ms
    return pos_noise, vel_noise

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bag', required=True, help='ros2 bag path')
    parser.add_argument('--output', default='tuned_params.yaml', help='output yaml')
    args = parser.parse_args()

    print(f"Analyzing bag: {args.bag}")
    print("WARN: Bag analysis requires rosbag2 Python API")
    print("  pip install rosbag2_py")
    print("")
    print("Manual method:")
    print("  1. ros2 bag play <bag> --remap /odom:=/odom_raw")
    print("  2. Use rtabmap or survey mode to get ground truth")
    print("  3. Compare ground truth vs odometry to estimate drift")

if __name__ == '__main__':
    main()
PYEOF

# ── README 调参指南 ──────────────────────────────
cat > "$PKG_NAME/README.md" <<RDMEOF
# ros2-autotune — 参数自动调优推荐

彭志辉核心观点：
> "SLAM 参数调好了，机器人能自主导航；没调好，就是一个高级遥控车。"

## 工作原理

```
机器人参数（mass/wheel_radius/etc.）
    ↓
物理模型估算（惯性、摩擦、Encoder分辨率）
    ↓
场景系数（室内/室外/粗糙地形）
    ↓
推荐初始参数值
    ↓
Gazebo 仿真验证
    ↓
真机微调（±10-20%）
```

## 使用方法

```bash
# 室内低速机器人
bash ros2-autotune-generator.sh my_robot \
  --robot mass=3.5,wheel_radius=0.08,wheelbase=0.4 \
  --scenario indoor_slow

# 仓库AGV（重型）
bash ros2-autotune-generator.sh agv_params \
  --robot mass=50.0,wheel_radius=0.165,wheelbase=0.8 \
  --scenario warehouse
```

## 生成文件

| 文件 | 说明 |
|------|------|
| `config/ekf_approx.yaml` | EKF 过程噪声矩阵 |
| `config/nav2_approx.yaml` | Nav2 速度/加速度限制 |
| `scripts/tune_and_validate.sh` | 参数验证脚本 |
| `scripts/analyze_robot_data.py` | 实测数据参数优化 |

## 参数含义速查

| 参数 | 影响 | 调大= | 调小= |
|------|------|-------|--------|
| `process_noise_covariance[0]` | 位置信任度 | 信任传感器 | 信任模型 |
| `max_vel_x` | 最大速度 | 快但危险 | 安全但慢 |
| `max_accel_x` | 加速度限制 | 响应快但抖动 | 平滑但迟钝 |
| `min_obstacle_dist` | 障碍物安全距离 | 更安全 | 更激进 |

## 彭志辉调参三板斧

1. **先看里程计漂移**：机器人走直线后偏了多少？
2. **仿真先于真机**：Gazebo 调通再上机器人
3. **每次只改一个参数**：同时改两个参数不知道谁有效

## 与 ros2-safety-generator.sh 配合

safety_monitor 提供的动态速度限制会进一步约束 Nav2 的速度输出，
两者配合实现"理论最大速度" + "实际安全速度"的二层防护。
RDMEOF

echo ""
echo "Generated: $PKG_NAME/"
echo "  config/ekf_approx.yaml       (EKF 过程噪声矩阵)"
echo "  config/nav2_approx.yaml       (Nav2 速度限制)"
if [[ -n "${ROBOT[arm_reach]}" ]]; then
  echo "  config/ros2_control_approx.yaml (机械臂限位)"
fi
echo "  scripts/tune_and_validate.sh  (参数验证脚本)"
echo "  scripts/analyze_robot_data.py (实测数据优化)"
echo "  README.md"
echo ""
echo "Robot params: mass=${MASS}kg, wheel_radius=${WHEEL_RADIUS}m"
echo "Scenario: ${SCENARIO:-default}"
echo ""
echo "Recommended max speed: ${RECOMMENDED_MAX_SPEED:.2f} m/s"
echo "EKF position noise: $(python3 -c "print(f'${EKF_PROCESS_NOISE_POS}*${MASS_FACTOR:.2f}')") (base × mass_factor=${MASS_FACTOR:.2f})"
