#!/bin/bash
# ros2-package-generator.sh — 生成标准 ROS2 包
# 用法: bash ros2-package-generator.sh <pkg_name> <type> [deps...] [--verify]
# 示例: bash ros2-package-generator.sh my_robot cpp rclcpp,std_msgs,geometry_msgs
# 示例: bash ros2-package-generator.sh my_python_pkg python --verify

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

PKG_NAME="${1:-}"
PKG_TYPE="${2:-cpp}"
shift 2 || true

# 解析 --verify 标志
VERIFY=0
REMAINING_DEPS=""
for arg in "$@"; do
    if [[ "$arg" == "--verify" ]]; then
        VERIFY=1
    else
        if [[ -n "$REMAINING_DEPS" ]]; then
            REMAINING_DEPS="$REMAINING_DEPS,$arg"
        else
            REMAINING_DEPS="$arg"
        fi
    fi
done
DEPS="${REMAINING_DEPS:-rclcpp,std_msgs}"

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <包名> <类型> [依赖...] [--verify]${NC}"
    echo "  包名: my_robot_control (小写+下划线，ROS2 允许)"
    echo "  类型: cpp | python | mixed"
    echo "  依赖: rclcpp,std_msgs,geometry_msgs (逗号分隔)"
    echo "  --verify: 生成后自动运行编译验证"
    echo ""
    echo "示例: $0 my_robot cpp rclcpp,std_msgs,geometry_msgs"
    echo "示例: $0 my_sensor python rclpy,std_msgs --verify"
    exit 1
fi

# 验证包名（ROS2 允许下划线，禁止连字符）
if [[ "$PKG_NAME" =~ - ]]; then
    echo -e "${RED}✗ 包名不能包含连字符（ROS2 限制）${NC}"
    echo "  正确: my_robot_control 或 myrobotcontrol"
    exit 1
fi

# 转换逗号为空格供其他工具用
DEPS_SPACE="${DEPS//,/ }"

echo -e "${BLUE}=== 生成 ROS2 包: $PKG_NAME ($PKG_TYPE) ===${NC}"

# 创建目录
mkdir -p "$PKG_NAME"/{src,msg,srv,action,launch,config,test}

# ── 检测自定义接口 ───────────────────────
if find "$PKG_NAME/msg" -name '*.msg' 2>/dev/null | grep -q .; then
    echo "  ✓ 检测到 msg 接口"
    HAS_MSG=1
else
    HAS_MSG=0
fi
if find "$PKG_NAME/srv" -name '*.srv' 2>/dev/null | grep -q .; then
    echo "  ✓ 检测到 srv 接口"
    HAS_SRV=1
else
    HAS_SRV=0
fi
if find "$PKG_NAME/action" -name '*.action' 2>/dev/null | grep -q .; then
    echo "  ✓ 检测到 action 接口"
    HAS_ACT=1
else
    HAS_ACT=0
fi
HAS_INTERFACE=$((HAS_MSG + HAS_SRV + HAS_ACT))

# ══════════════════════════════════════════════════════════════
# C++ 包
# ══════════════════════════════════════════════════════════════
if [[ "$PKG_TYPE" == "cpp" ]] || [[ "$PKG_TYPE" == "mixed" ]]; then

cat > "$PKG_NAME/package.xml" <<EOF
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>${PKG_NAME}</name>
  <version>0.1.0</version>
  <description>TODO: 描述这个包的功能</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>ament_cmake_python</buildtool_depend>

$(for dep in $DEPS_SPACE; do echo "  <depend>${dep}</depend>"; done)

$(if [[ $HAS_INTERFACE -gt 0 ]]; then
echo "  <build_depend>rosidl_default_generators</build_depend>"
echo "  <build_depend>builtin_interfaces</build_depend>"
echo "  <exec_depend>rosidl_default_runtime</exec_depend>"
echo "  <member_of_group>rosidl_interface_packages</member_of_group>"
fi)

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export><build_type>ament_cmake</build_type></export>
</package>
EOF

cat > "$PKG_NAME/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.16)
project(${PKG_NAME})

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-Wall -Wextra -Wpedantic -Wno-unused-parameter)
endif()

# ── 查找依赖 ───────────────────────────
find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
$(for dep in $DEPS_SPACE; do
  [[ "$dep" == "rclcpp" || "$dep" == "std_msgs" ]] && continue
  echo "find_package(${dep} REQUIRED)"
done)

$(if [[ $HAS_INTERFACE -gt 0 ]]; then
echo ""
echo "# ── 自定义接口 ─────────────────────"
echo "find_package(rosidl_default_generators REQUIRED)"
echo "find_package(builtin_interfaces REQUIRED)"
fi)

include_directories(include)

# ── 构建库 ───────────────────────────
add_library(\${PROJECT_NAME} SHARED src/\${PROJECT_NAME}_node.cpp)

ament_target_dependencies(\${PROJECT_NAME}
  rclcpp
  std_msgs
$(for dep in $DEPS_SPACE; do
  [[ "$dep" == "rclcpp" || "$dep" == "std_msgs" ]] && continue
  echo "  ${dep}"
done)
)

# ── 导出（三行必须同时存在）─────────────
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(\${PROJECT_NAME})

$(if [[ $HAS_INTERFACE -gt 0 ]]; then
echo ""
echo "# ── 接口生成 ──────────────────────"
echo "rosidl_generate_interfaces(\${PROJECT_NAME}"
echo "  msg/"
echo "  srv/"
echo "  action/"
echo ")"
fi)

install(TARGETS \${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib)

install(DIRECTORY launch config msg srv action
  DESTINATION share/\${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
EOF

# ── C++ 节点骨架 ─────────────────────────
cat > "$PKG_NAME/src/${PKG_NAME}_node.cpp" <<'CPPEOF'
// 自动生成 by vibe-coding-ros2
// Lifecycle 节点模板（生产环境推荐）

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

class PkgNode : public rclcpp_lifecycle::LifecycleNode
{
public:
  PkgNode() : LifecycleNode("pkg_name")
  {
    RCLCPP_INFO(get_logger(), "PkgNode constructed");
  }

  // ── on_configure: 初始化资源 ───────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "Configuring...");
    publisher_ = this->create_publisher<std_msgs::msg::String>(
      "output_topic", QoS(10).reliable());
    RCLCPP_INFO(get_logger(), "Configured successfully");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ── on_activate: 开始发布 ─────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "Activating...");
    publisher_->on_activate();
    timer_ = this->create_wall_timer(
      1s, std::bind(&PkgNode::timer_callback, this));
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ── on_deactivate: 停止发布 ───────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "Deactivating...");
    timer_.reset();
    publisher_->on_deactivate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ── on_cleanup: 清理资源 ──────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "Cleaning up...");
    timer_.reset();
    publisher_.reset();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  // ── on_shutdown: 关闭 ───────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp::State&) override
  {
    RCLCPP_INFO(get_logger(), "Shutting down...");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

private:
  void timer_callback()
  {
    auto msg = std_msgs::msg::String();
    msg.data = "tick at " + std::to_string(this->now().nanoseconds() / 1e9);
    publisher_->publish(msg);
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);
  auto node = std::make_shared<PkgNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF

# 替换包名占位符
sed -i "s/pkg_name/${PKG_NAME}/g" "$PKG_NAME/src/${PKG_NAME}_node.cpp"

fi

# ══════════════════════════════════════════════════════════════
# Python 包
# ══════════════════════════════════════════════════════════════
if [[ "$PKG_TYPE" == "python" ]] || [[ "$PKG_TYPE" == "mixed" ]]; then

cat > "$PKG_NAME/package.xml" <<EOF
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>${PKG_NAME}</name>
  <version>0.1.0</version>
  <description>TODO: 描述这个包的功能</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_python</buildtool_depend>

$(for dep in $DEPS_SPACE; do echo "  <exec_depend>${dep}</exec_depend>"; done)

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export><build_type>ament_python</build_type></export>
</package>
EOF

cat > "$PKG_NAME/setup.py" <<EOF
from setuptools import setup

setup(
    name='${PKG_NAME}',
    version='0.1.0',
    packages=['${PKG_NAME}'],
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/${PKG_NAME}']),
        ('share/${PKG_NAME}', ['package.xml']),
        ('share/${PKG_NAME}/launch', glob('launch/*.launch.py')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='MIUAV Developer',
    maintainer_email='dev@miuav.com',
    description='TODO: 描述这个包的功能',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            '${PKG_NAME}_node = ${PKG_NAME}.my_node:main',
        ],
    },
)
EOF

mkdir -p "$PKG_NAME/${PKG_NAME}"
cat > "$PKG_NAME/${PKG_NAME}/__init__.py" <<'PYEOF'
"""${PKG_NAME} package."""
PYEOF

cat > "$PKG_NAME/${PKG_NAME}/my_node.py" <<'PYEOF'
"""Python ROS2 节点模板."""
import rclpy
from rclpy.node import Node


class MyNode(Node):
    def __init__(self):
        super().__init__('my_node')
        self.get_logger().info('MyNode started')

    def timer_callback(self):
        self.get_logger().info('tick')


def main(args=None):
    rclpy.init(args=args)
    node = MyNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYEOF

fi

# ── Launch 骨架 ───────────────────────────
cat > "$PKG_NAME/launch/${PKG_NAME}.launch.py" <<'LAUNCHEOF'
"""Launch 描述符."""
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    node = Node(
        package='PLACEHOLDER_PKG',
        executable='PLACEHOLDER_PKG_node',
        name='PLACEHOLDER_PKG',
        output='screen',
    )
    return LaunchDescription([node])
LAUNCHEOF

sed -i "s/PLACEHOLDER_PKG/${PKG_NAME}/g" "$PKG_NAME/launch/${PKG_NAME}.launch.py"

# ── config 骨架 ───────────────────────────
cat > "$PKG_NAME/config/params.yaml" <<YAMLEOF
/**:
  ros__parameters:
    param_name: "value"
YAMLEOF

# ── README ────────────────────────────────
cat > "$PKG_NAME/README.md" <<READMEEOF
# ${PKG_NAME}

TODO: 描述这个包的作用

## 构建

\`\`\`bash
cd /path/to/workspace
colcon build --packages-select ${PKG_NAME}
source install/setup.bash
\`\`\`

## 运行

\`\`\`bash
ros2 run ${PKG_NAME} ${PKG_NAME}_node
\`\`\`
READMEEOF

# ── 结果 ─────────────────────────────────
echo ""
echo -e "${GREEN}✓ 包已生成: $PKG_NAME/${NC}"
echo ""
echo "生成的文件:"
find "$PKG_NAME" -type f | sort | sed 's/^/  /'
echo ""

# ── 自动编译验证 ─────────────────────────────────────────
if [[ $VERIFY -eq 1 ]]; then
    VERIFY_SCRIPT="$(dirname "$0")/../ros2-build-verify-loop.sh"
    if [[ -f "$VERIFY_SCRIPT" ]]; then
        echo -e "${BLUE}🔍 运行编译验证...${NC}"
        if bash "$VERIFY_SCRIPT" "$PKG_NAME"; then
            echo -e "${GREEN}✓ 编译验证通过${NC}"
        else
            echo -e "${YELLOW}⚠ 编译验证失败，请检查上面的错误${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ros2-build-verify-loop.sh 未找到，跳过验证${NC}"
    fi
fi
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. 编辑 $PKG_NAME/package.xml — 补全描述和维护者"
echo "  2. 编辑 $PKG_NAME/src/${PKG_NAME}_node.cpp — 填充业务逻辑"
echo "  3. colcon build --packages-select $PKG_NAME --symlink-install"
echo "  4. source install/setup.bash"
echo "  5. ros2 run $PKG_NAME ${PKG_NAME}_node"
