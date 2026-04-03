#!/bin/bash
# ros2-package-generator.sh — 生成标准 ROS2 包
# 用法: bash ros2-package-generator.sh <pkg_name> <type> <depend1,depend2,...>
# 示例: bash ros2-package-generator.sh my_robot_control cpp "rclcpp,std_msgs,geometry_msgs"

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

PKG_NAME="${1:-}"
PKG_TYPE="${2:-cpp}"  # cpp | python | mixed
DEPS="${3:-rclcpp,std_msgs}"

if [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <包名> <类型> <依赖列表>${NC}"
    echo "  包名: my_robot_control (小写+下划线)"
    echo "  类型: cpp | python | mixed"
    echo "  依赖: rclcpp,std_msgs,geometry_msgs"
    echo ""
    echo "示例: $0 my_robot_control cpp rclcpp,std_msgs,geometry_msgs"
    exit 1
fi

# 验证包名（ROS2 不允许下划线）
if [[ "$PKG_NAME" =~ _ ]]; then
    echo -e "${RED}✗ 包名不能包含下划线（ROS2 限制）${NC}"
    echo "  建议: my-robot-control 或 myrobotcontrol"
    exit 1
fi

echo -e "${GREEN}=== 生成 ROS2 包: $PKG_NAME ===${NC}"

# 创建目录
mkdir -p "$PKG_NAME"/{src,msg,srv,action,launch,config,test}

# ========== package.xml (Format 3) ==========
cat > "$PKG_NAME/package.xml" <<EOF
<?xml version="1.0"?>
<!-- 自动生成 by vibe-coding-ros2 v0.0.1-beta -->
<package format="3">
  <name>${PKG_NAME}</name>
  <version>0.1.0</version>
  <description>TODO: 描述这个包的功能</description>
  <maintainer email="TODO@example.com">TODO: 维护者</maintainer>
  <license>Apache-2.0</license>

  <!-- 依赖 (由 vibe-coding-ros2 自动解析) -->
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
$(echo "$DEPS" | tr ',' '\n' | sed 's/^/  <depend>/' | sed 's/$/<\/depend>/')
  <depend>ament_lint_auto</depend>
  <depend>ament_lint_common</depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

# ========== CMakeLists.txt ==========
DEPS_CMAKE=$(echo "$DEPS" | tr ',' '\n' | sed 's/rclcpp/rclcpp REQUIRED/; s/std_msgs/std_msgs REQUIRED/; s/geometry_msgs/geometry_msgs REQUIRED/; s/$/ REQUIRED/' | sort -u | tr '\n' ' ')

cat > "$PKG_NAME/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.16)
project(${PKG_NAME})

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

# C++17 标准 (ROS2 Humble+ 要求)
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

# 警告处理
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-Wall -Wextra -Wpedantic -Wno-unused-parameter)
endif()

# ========== 1. 查找依赖 ==========
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
$(echo "$DEPS" | tr ',' '\n' | grep -v 'rclcpp\|std_msgs' | sed 's/^/find_package(/' | sed 's/$/ REQUIRED)/')

# ========== 2. 构建库 ==========
add_library(\${PROJECT_NAME} SHARED
  src/${PKG_NAME}_node.cpp
)
ament_target_dependencies(\${PROJECT_NAME}
  rclcpp
  std_msgs
  $(echo "$DEPS" | tr ',' '\n' | grep -v 'rclcpp\|std_msgs' | tr '\n' ' ')
)

# ========== 3. 安装 ==========
install(TARGETS \${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib
)

install(DIRECTORY launch config
  DESTINATION share/\${PROJECT_NAME}/
)

# ========== 4. 测试 ==========
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
EOF

# ========== C++ 节点骨架 ==========
cat > "$PKG_NAME/src/${PKG_NAME}_node.cpp" <<'CPPEOF'
// 自动生成 by vibe-coding-ros2 v0.0.1-beta
// ⚠️ 这只是骨架代码，业务逻辑需要人工填充

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

// ============================================================
// C++ 现代 ROS2 规范 (v0.0.1-beta)
// ============================================================
// ✅ 使用 SharedPtr 而非裸指针
// ✅ rclcpp::NodeOptions 构造
// ✅ 使用 RCLCPP_* 宏而非 printf
// ✅ RAII 原则：构造时初始化，析构时清理
// ============================================================

namespace
{
constexpr auto kNodeName = "${PKG_NAME}";
constexpr auto kLoggerName = "${PKG_NAME}_node";
}

class ${PKG_NAME^}Node : public rclcpp::Node
{
public:
  explicit ${PKG_NAME^}Node(const rclcpp::NodeOptions & options = rclcpp::NodeOptions{})
  : Node(kNodeName, options)
  {
    using namespace std::chrono_literals;

    // ── 1. 发布者 (Publisher) ──────────────────────────
    // TODO: 替换消息类型和话题名
    // rclcpp::QoS rclcpp::QoS(10);  // Queue depth
    // rclcpp::QoS rclcpp::QoS(10).best_effort();     // QoS: Best Effort
    // rclcpp::QoS rclcl::QoS(10).transient_local();  // QoS: Transient Local
    RCLCPP_INFO(get_logger(), "%s initialized", kNodeName);
  }

private:
  // TODO: 添加成员变量
  // rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  // rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
  // rclcpp::TimerBase::SharedPtr timer_;
  // rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

int main(int argc, char * argv[])
{
  // ── 标准入口模式 ─────────────────────────────────
  rclcpp::init(argc, argv);

  // 方式1: 单线程 spin
  auto node = std::make_shared<${PKG_NAME^}Node>();
  RCLCPP_INFO(node->get_logger(), "Node started, spinning...");
  rclcpp::spin(node);

  // 方式2 (注释掉上方，启用下方): 多线程 executor
  // auto executor = std::make_unique<rclcpp::executors::MultiThreadedExecutor>();
  // executor->add(node);
  // executor->spin();

  rclcpp::shutdown();
  return 0;
}
CPPEOF

# ========== Launch 骨架 ==========
cat > "$PKG_NAME/launch/${PKG_NAME}.launch.py" <<'LAUNCHEOF'
# 自动生成 by vibe-coding-ros2 v0.0.1-beta
# ⚠️ 这只是骨架，节点参数需要填充

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    """
    Launch 描述符 — 必须返回 LaunchDescription 对象
    """
    # ── 节点定义 ──────────────────────────────────
    # QoS 示例:
    #   unreliable = QoSProfile(depth=10, reliability=RMW_QOS_POLICY_RELIABILITY_BEST_EFFORT)
    #   reliable   = QoSProfile(depth=10, reliability=RMW_QOS_POLICY_RELIABILITY_RELIABLE)

    node = Node(
        package="${PKG_NAME}",
        executable="${PKG_NAME}_node",
        name="${PKG_NAME}",
        output="screen",
        # parameters=[{"param_name": "param_value"}],  # 取消注释以加载参数
        # remappings=[("/src_topic", "/dst_topic")],  # 取消注释以重映射话题
    )

    return LaunchDescription([
        node,
    ])
LAUNCHEOF

# ========== config 参数 YAML ==========
cat > "$PKG_NAME/config/default.yaml" <<'YAMLEOF'
# 自动生成 by vibe-coding-ros2 v0.0.1-beta
# 运行时加载: ros2 run <pkg> <node> --ros-args --params_file <this_file>
YAMLEOF

echo -e "${GREEN}✓ 包已生成: $PKG_NAME/${NC}"
echo ""
echo "生成的文件:"
find "$PKG_NAME" -type f | sort
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. 编辑 package.xml — 补全描述和维护者信息"
echo "  2. 编辑 src/${PKG_NAME}_node.cpp — 填充业务逻辑"
echo "  3. colcon build --packages-select $PKG_NAME --symlink-install"
echo "  4. source install/setup.bash"
echo "  5. ros2 run $PKG_NAME ${PKG_NAME}_node"
