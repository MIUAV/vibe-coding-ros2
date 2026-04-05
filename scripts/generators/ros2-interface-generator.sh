#!/bin/bash
# ros2-interface-generator.sh — 生成 ROS2 自定义接口包（msg/srv/action）
# 用法: bash ros2-interface-generator.sh <pkg_name> [msg_names...] [-s srv_names...] [-a action_names...]
# 示例: bash ros2-interface-generator.sh my_msgs LaserScan Image -s AddTwoInts -a Fibonacci

PKG_NAME="${1:-}"
shift 2>/dev/null || true

if [[ -z "$PKG_NAME" ]]; then
    echo "用法: $0 <包名> [msg_names...] [-s srv_names...] [-a action_names...]"
    echo "  例: $0 my_msgs LaserScan Image -s AddTwoInts"
    exit 1
fi

MSGS=() SRVS=() ACTIONS=()
MODE="msg"

for arg in "$@"; do
    case "$arg" in
        -s) MODE="srv" ;;
        -a) MODE="act" ;;
        *)  [[ "$MODE" == "msg" ]] && MSGS+=("$arg")
            [[ "$MODE" == "srv" ]] && SRVS+=("$arg")
            [[ "$MODE" == "act" ]] && ACTIONS+=("$arg") ;;
    esac
done

mkdir -p "$PKG_NAME"/{msg,srv,action}

# ── package.xml ───────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<'PKGXML'
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>PKGNAMEPLACEHOLDER</name>
  <version>0.1.0</version>
  <description>ROS2 custom interfaces</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>
  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <build_depend>builtin_interfaces</build_depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <member_of_group>rosidl_interface_packages</member_of_group>
  <export><build_type>ament_cmake</build_type></export>
</package>
PKGXML

sed -i "s/PKGNAMEPLACEHOLDER/$PKG_NAME/g" "$PKG_NAME/package.xml"

# ── CMakeLists.txt ──────────────────────────────────────
{
    echo "cmake_minimum_required(VERSION 3.16)"
    echo "project($PKG_NAME)"
    echo ""
    echo "find_package(ament_cmake REQUIRED)"
    echo "find_package(rosidl_default_generators REQUIRED)"
    echo "find_package(builtin_interfaces REQUIRED)"
    echo ""
    echo "rosidl_generate_interfaces(\${PROJECT_NAME}"
    for m in "${MSGS[@]}"; do echo "  msg/${m}.msg"; done
    for s in "${SRVS[@]}"; do echo "  srv/${s}.srv"; done
    for a in "${ACTIONS[@]}"; do echo "  action/${a}.action"; done
    echo "  DEPENDENCIES builtin_interfaces"
    echo ")"
    echo ""
    echo "ament_export_dependencies(rosidl_default_runtime)"
    echo "ament_package()"
} > "$PKG_NAME/CMakeLists.txt"

# ── .msg 文件 ─────────────────────────────────────────
for m in "${MSGS[@]}"; do
    cat > "$PKG_NAME/msg/${m}.msg" <<EOF
# TODO: define ${m} fields
# Example:
# string name
# geometry_msgs/PoseStamped pose
# uint32 id
EOF
done

# ── .srv 文件 ──────────────────────────────────────────
for s in "${SRVS[@]}"; do
    cat > "$PKG_NAME/srv/${s}.srv" <<EOF
# TODO: define ${s} request and response
# --- Request ---
string input

# --- Response ---
string output
EOF
done

# ── .action 文件 ──────────────────────────────────────
for a in "${ACTIONS[@]}"; do
    cat > "$PKG_NAME/action/${a}.action" <<EOF
# TODO: define ${a} Goal/Result/Feedback
# --- Goal ---
string target

# --- Result ---
bool success

# --- Feedback ---
float32 progress
EOF
done

# ── 结果 ────────────────────────────────────────────────
echo "ROS2 interface package generated: $PKG_NAME/"
echo "  MSG: ${MSGS[*]:-none}"
echo "  SRV: ${SRVS[*]:-none}"
echo "  ACT: ${ACTIONS[*]:-none}"
echo ""
echo "Next steps:"
echo "  1. Edit msg/*.msg / srv/*.srv / action/*.action — fill in field definitions"
echo "  2. colcon build --packages-select $PKG_NAME"
echo "  3. source install/setup.bash"
echo "  4. ros2 interface show $PKG_NAME/msg/${MSGS[0]:-Example}"
