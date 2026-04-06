#!/bin/bash
# ros2-data-logger.sh — ROS2 数据记录和回放工具生成器
# 用法: bash ros2-data-logger.sh <pkg_name> [log_type]
# log_type: full | sensors_only | nav_only | custom
#
# 示例: bash ros2-data-logger.sh data_logger sensors_only

PKG_NAME="${1:-}"
LOG_TYPE="${2:-custom}"

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [记录类型]"
    echo "  full         — 全量记录（所有话题）"
    echo "  sensors_only — 仅传感器（camera/lidar/imu/gps）"
    echo "  nav_only    — 仅导航相关（odom/tf/cmd_vel/scan）"
    echo "  custom      — 自定义话题"
    exit 1
fi

mkdir -p "$PKG_NAME/scripts" "$PKG_NAME/launch" "$PKG_NAME/config"

# ── package.xml ─────────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'EOF'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKG_NAME</name>
  <version>0.1.0</version>
  <description>ROS2 data recording and playback package</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_python</buildtool_depend>
  <depend>rclpy</depend>
  <depend>ros2bag</depend>
  <depend>topic_monitor</depend>
  </build_type>ament_python</build_type></export>
</package>
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ════════════════════════════════════════════════════════════
# 全量记录
# ════════════════════════════════════════════════════════════
if [[ "$LOG_TYPE" == "full" ]]; then

cat > "$PKG_NAME/scripts/record.sh" <<'BASHEOF'
#!/bin/bash
# Full bag recording — all topics
BAG_NAME="full_$(date +%Y%m%d_%H%M%S)"

echo "Recording ALL topics to $BAG_NAME"

ros2 bag record -o "$BAG_NAME" --all

# Alternative: record by directory
# ros2 bag record -o "$BAG_NAME" --keep-all
BASHEOF

cat > "$PKG_NAME/config/record_config.yaml" <<'YAMLEOF'
topics:
  - /scan
  - /imu/data
  - /odom
  - /cmd_vel
  - /tf
  - /tf_static
  - /battery_state
  - /joint_states
  - /camera/image_raw
  - /gps/fix
  - /diagnostics

record_options:
  snapshot_mode: false
  default_topics: []
  regex: []
  exclude: []
YAMLEOF

# ════════════════════════════════════════════════════════════
# 仅传感器
# ════════════════════════════════════════════════════════════
elif [[ "$LOG_TYPE" == "sensors_only" ]]; then

cat > "$PKG_NAME/scripts/record.sh" <<'BASHEOF'
#!/bin/bash
# Sensor data recording
BAG_NAME="sensors_$(date +%Y%m%d_%H%M%S)"

TOPICS=(
  "/scan"
  "/imu/data"
  "/gps/fix"
  "/camera/image_raw"
  "/camera/camera_info"
  "/depth/camera/image_raw"
  "/livox/lidar"
  "/rplidar/scan"
)

echo "Recording sensor topics to $BAG_NAME"
echo "Topics: ${TOPICS[*]}"

ros2 bag record -o "$BAG_NAME" "${TOPICS[@]}"
BASHEOF

cat > "$PKG_NAME/config/record_config.yaml" <<'YAMLEOF'
topics:
  # Laser scanners
  - /scan
  - /scan_1
  - /scan_2
  - /livox/lidar
  - /rplidar/scan

  # IMU
  - /imu/data
  - /imu/data_raw
  - /microstrain/imu

  # Camera
  - /camera/image_raw
  - /camera/camera_info
  - /depth/image_raw
  - /rgb/image_raw

  # GPS
  - /gps/fix
  - /gps/vel
  - /navsat/fix

  # Ultrasonic
  - /ultrasonic_1
  - /ultrasonic_2
  - /sonar

record_options:
  snapshot_mode: true
  default_topics: []
YAMLEOF

# ════════════════════════════════════════════════════════════
# 仅导航
# ════════════════════════════════════════════════════════════
elif [[ "$LOG_TYPE" == "nav_only" ]]; then

cat > "$PKG_NAME/scripts/record.sh" <<'BASHEOF'
#!/bin/bash
# Navigation data recording
BAG_NAME="nav_$(date +%Y%m%d_%H%M%S)"

TOPICS=(
  "/scan"
  "/odom"
  "/cmd_vel"
  "/tf"
  "/tf_static"
  "/map"
  "/path"
  "/plan"
  "/local_plan"
  "/global_costmap/costmap"
  "/local_costmap/costmap"
  "/battery_state"
  "/goal_pose"
)

echo "Recording navigation topics to $BAG_NAME"

ros2 bag record -o "$BAG_NAME" "${TOPICS[@]}"
BASHEOF

cat > "$PKG_NAME/config/record_config.yaml" <<'YAMLEOF'
topics:
  # Laser
  - /scan
  - /scan_filtered

  # Odometry
  - /odom
  - /odom_encoded
  - /wheel_odom

  # Control
  - /cmd_vel
  - /cmd_vel_nav

  # Transforms
  - /tf
  - /tf_static

  # Maps
  - /map
  - /map_metadata

  # Planning
  - /plan
  - /global_plan
  - /local_plan

  # Costmaps
  - /global_costmap/costmap
  - /global_costmap/costmap_raw
  - /local_costmap/costmap
  - /local_costmap/costmap_raw

  # Battery
  - /battery_state
  - /battery_voltage

  # Goals
  - /goal_pose
  - /move_base_simple/goal
YAMLEOF

# ════════════════════════════════════════════════════════════
# 自定义
# ════════════════════════════════════════════════════════════
else

cat > "$PKG_NAME/scripts/record.sh" <<'BASHEOF'
#!/bin/bash
# Custom recording
BAG_NAME="custom_$(date +%Y%m%d_%H%M%S)"

echo "Recording custom topics to $BAG_NAME"
echo "Edit config/record_config.yaml to set topics"

ros2 bag record -o "$BAG_NAME"
BASHEOF

cat > "$PKG_NAME/config/record_config.yaml" <<'YAMLEOF'
# 自定义记录话题列表
# 每行一个话题，支持 # 注释
topics:
  # 在此添加你的话题
  # - /your/topic

record_options:
  snapshot_mode: false
  default_topics: []
YAMLEOF

fi

# ════════════════════════════════════════════════════════════
# 通用：回放脚本
# ════════════════════════════════════════════════════════════

cat > "$PKG_NAME/scripts/playback.sh" <<'BASHEOF'
#!/bin/bash
# ROS2 bag playback script
# Usage: bash playback.sh <bag_dir> [--rate RATE] [--loop]

BAG_DIR="${1:-}"
RATE="${2:-1}"
LOOP_FLAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --loop) LOOP_FLAG="--loop"; shift ;;
    --rate) RATE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$BAG_DIR" ]]; then
  echo "Usage: bash playback.sh <bag_dir> [--rate RATE] [--loop]"
  exit 1
fi

echo "Playing bag: $BAG_DIR"
echo "Playback rate: ${RATE}x"

ros2 bag play "$BAG_DIR" --rate "$RATE" $LOOP_FLAG
BASHEOF

cat > "$PKG_NAME/scripts/analyze.sh" <<'BASHEOF'
#!/bin/bash
# Bag analysis script
# Usage: bash analyze.sh <bag_dir>

BAG_DIR="${1:-}"

if [[ -z "$BAG_DIR" ]]; then
  echo "Usage: bash analyze.sh <bag_dir>"
  exit 1
fi

echo "=== Bag Info ==="
ros2 bag info "$BAG_DIR"

echo ""
echo "=== Topic List ==="
ros2 bag info "$BAG_DIR" -o 2>/dev/null | grep "Topics:"

echo ""
echo "=== Duration ==="
ros2 bag info "$BAG_DIR" | grep -i duration

echo ""
echo "=== Size ==="
du -sh "$BAG_DIR"

echo ""
echo "=== Message Count per Topic ==="
for topic in $(ros2 bag info "$BAG_DIR" --json 2>/dev/null | jq -r '.topics[].topic_name' 2>/dev/null); do
  count=$(ros2 topic hz "$topic" 2>/dev/null | grep -i average | awk '{print $2}' || echo "N/A")
  echo "  $topic: $count Hz"
done
BASHEOF

cat > "$PKG_NAME/scripts/extract_images.sh" <<'BASHEOF'
#!/bin/bash
# Extract images from bag
# Usage: bash extract_images.sh <bag_dir> <output_dir>

BAG_DIR="${1:-}"
OUTPUT_DIR="${2:-./extracted_images}"

if [[ -z "$BAG_DIR" ]]; then
  echo "Usage: bash extract_images.sh <bag_dir> [output_dir]"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "Extracting images to $OUTPUT_DIR"

# 使用 ffmpeg 提取（需 rosbag2 to 转换）
# 或使用 ros1 bridge
echo "Tip: Use rosbag2-to-video for image extraction"
echo "  rosbag2_to_video --input $BAG_DIR --output $OUTPUT_DIR"
BASHEOF

# ════════════════════════════════════════════════════════════
# 定时记录
# ════════════════════════════════════════════════════════════

cat > "$PKG_NAME/scripts/auto_record.sh" <<'BASHEOF'
#!/bin/bash
# Auto record with time-based rotation
# Usage: bash auto_record.sh [--interval SECONDS] [--max-bags N]

INTERVAL=300  # 5 minutes
MAX_BAGS=10
BAG_PREFIX="auto_$(hostname)_"

while [[ $# -gt 0 ]]; do
  case $1 in
    --interval) INTERVAL="$2"; shift 2 ;;
    --max-bags) MAX_BAGS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "Auto-recording every ${INTERVAL}s, keeping last ${MAX_BAGS} bags"
echo "Host: $(hostname)"

COUNT=0
while true; do
  BAG_NAME="${BAG_PREFIX}$(date +%Y%m%d_%H%M%S)"
  echo "[$(date)] Starting bag: $BAG_NAME"

  timeout "$INTERVAL" ros2 bag record -o "$BAG_NAME" --all 2>/dev/null || true

  # 清理旧 bag
  BAG_COUNT=$(ls -d ${BAG_PREFIX}* 2>/dev/null | wc -l)
  if [[ $BAG_COUNT -gt $MAX_BAGS ]]; then
    echo "Cleaning old bags (count: $BAG_COUNT, max: $MAX_BAGS)"
    ls -dt ${BAG_PREFIX}* 2>/dev/null | tail -$((BAG_COUNT - MAX_BAGS)) | xargs rm -rf
  fi

  COUNT=$((COUNT + 1))
done
BASHEOF

# ── setup.py ────────────────────────────────────────────────
cat > "$PKG_NAME/setup.py" <<'EOF'
from setuptools import setup
setup(
    name='PKGNAME',
    version='0.1.0',
    packages=[],
    data_files=[
        ('share/PKGNAME/scripts', [
            'scripts/record.sh',
            'scripts/playback.sh',
            'scripts/analyze.sh',
            'scripts/extract_images.sh',
            'scripts/auto_record.sh',
        ]),
        ('share/PKGNAME/config', ['config/record_config.yaml']),
    ],
    install_requires=['setuptools'],
)
EOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/setup.py"

# ── launch ─────────────────────────────────────────────────
cat > "$PKG_NAME/launch/record.launch.py" <<'LAUNCHEOF'
"""Data recording launch"""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([
        Node(
            package='ros2bag',
            executable='record',
            name='ros2bag_record',
            arguments=['-a'],
            output='screen'),
    ])
LAUNCHEOF
sed -i "s/PKGNAME/$PKG_NAME/g" "$PKG_NAME/launch/record.launch.py"

echo ""
echo "Generated: $PKG_NAME/"
echo "  scripts/record.sh         # 记录脚本"
echo "  scripts/playback.sh      # 回放脚本"
echo "  scripts/analyze.sh       # 分析脚本"
echo "  scripts/extract_images.sh # 图像提取"
echo "  scripts/auto_record.sh   # 自动定时记录"
echo "  config/record_config.yaml"
echo "  launch/record.launch.py"
echo ""
echo "Log type: $LOG_TYPE"
echo ""
echo "Usage:"
echo "  ros2 bag record -o my_bag /scan /odom /imu"
echo "  bash scripts/record.sh          # 使用配置记录"
echo "  bash scripts/playback.sh <bag>  # 回放"
echo "  bash scripts/analyze.sh <bag>   # 分析 bag"
echo "  bash scripts/auto_record.sh --interval 300 --max-bags 10  # 自动旋转记录"
