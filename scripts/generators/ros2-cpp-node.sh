#!/bin/bash
# ros2-cpp-node.sh — 生成完整的可编译 ROS2 C++ 节点
# 用法: bash ros2-cpp-node.sh <node_type> <package_name> [deps...]
# 示例: bash ros2-cpp-node.sh publisher my_package rclcpp std_msgs
# 示例: bash ros2-cpp-node.sh lifecycle my_controller rclcpp rclcpp_lifecycle geometry_msgs

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

NODE_TYPE="${1:-}"
PKG_NAME="${2:-}"
DEPS="${3:-rclcpp}"

if [[ -z "$NODE_TYPE" ]] || [[ -z "$PKG_NAME" ]]; then
    echo -e "${RED}用法: $0 <node_type> <package_name> [deps]${NC}"
    echo "  node_type: publisher | subscriber | service | action | lifecycle | timer | parameters"
    echo "  package_name: my_package (小写+下划线)"
    echo "  deps: rclcpp,std_msgs,geometry_msgs,rclcpp_lifecycle (逗号分隔)"
    echo ""
    echo "示例: $0 publisher my_publisher rclcpp,std_msgs"
    echo "示例: $0 lifecycle my_controller rclcpp,rclcpp_lifecycle,geometry_msgs"
    exit 1
fi

# 替换 - 为 _
PKG_NAME=$(echo "$PKG_NAME" | tr '-' '_')
# 转换逗号分隔的依赖为数组
IFS=',' read -ra DEPS_ARRAY <<< "$DEPS"

echo -e "${BLUE}=== 生成 ROS2 C++ 节点: $PKG_NAME ($NODE_TYPE) ===${NC}"

# 创建包目录
mkdir -p "$PKG_NAME"/{src,include/$PKG_NAME,launch,config}

# ── package.xml ───────────────────────────────────────────
cat > "$PKG_NAME/package.xml" <<PKGEOF
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">
  <name>${PKG_NAME}</name>
  <version>0.1.0</version>
  <description>TODO: 描述这个包的作用</description>
  <maintainer email="dev@miuav.com">MIUAV Developer</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
PKGEOF

# 添加依赖
for dep in "${DEPS_ARRAY[@]}"; do
    # 跳过 cmake 相关的内部依赖
    if [[ "$dep" == "rclcpp" ]] || [[ "$dep" == "rclpy" ]]; then
        echo "  <depend>${dep}</depend>" >> "$PKG_NAME/package.xml"
    elif [[ "$dep" == "rclcpp_lifecycle" ]]; then
        echo "  <depend>rclcpp</depend>" >> "$PKG_NAME/package.xml"
        echo "  <depend>rclcpp_components</depend>" >> "$PKG_NAME/package.xml"
        echo "  <depend>lifecycle_msgs</depend>" >> "$PKG_NAME/package.xml"
    else
        echo "  <depend>${dep}</depend>" >> "$PKG_NAME/package.xml"
    fi
done

cat >> "$PKG_NAME/package.xml" <<PKGEOF

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <export><build_type>ament_cmake</build_type></export>
</package>
PKGEOF

# ── CMakeLists.txt ────────────────────────────────────────
cat > "$PKG_NAME/CMakeLists.txt" <<'CMAKEEOF'
cmake_minimum_required(VERSION 3.8)
project(PROJECT_NAME_PLACEHOLDER)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ── 查找依赖 ────────────────────────────────────────────
find_package(ament_cmake REQUIRED)
CMAKEEOF

# 动态添加 find_package
echo "" >> "$PKG_NAME/CMakeLists.txt"
for dep in "${DEPS_ARRAY[@]}"; do
    # 特殊处理
    if [[ "$dep" == "rclcpp_lifecycle" ]]; then
        echo "find_package(rclcpp REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
        echo "find_package(rclcpp_components REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
        echo "find_package(lifecycle_msgs REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
    elif [[ "$dep" == "geometry_msgs" ]]; then
        echo "find_package(${dep} REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
        echo "find_package(std_msgs REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
    elif [[ "$dep" != "rclcpp" ]]; then
        echo "find_package(${dep} REQUIRED)" >> "$PKG_NAME/CMakeLists.txt"
    fi
done

cat >> "$PKG_NAME/CMakeLists.txt" <<'CMAKEEOF'

include_directories(include)

# ── 节点源文件 ─────────────────────────────────────────
set(NODE_SOURCES
  src/NODE_NAME_PLACEHOLDER.cpp
)

add_library(${PROJECT_NAME} SHARED ${NODE_SOURCES})

# ── 依赖链（必须同时有这三行）────────────────────────
ament_target_dependencies(${PROJECT_NAME}
CMAKEEOF

# 动态添加依赖到 ament_target_dependencies
for dep in "${DEPS_ARRAY[@]}"; do
    if [[ "$dep" == "rclcpp_lifecycle" ]]; then
        echo "  rclcpp" >> "$PKG_NAME/CMakeLists.txt"
        echo "  rclcpp_components" >> "$PKG_NAME/CMakeLists.txt"
        echo "  lifecycle_msgs" >> "$PKG_NAME/CMakeLists.txt"
    else
        echo "  ${dep}" >> "$PKG_NAME/CMakeLists.txt"
    fi
done

cat >> "$PKG_NAME/CMakeLists.txt" <<'CMAKEEOF'
)

# ── 这三行必须同时存在（防止链接错误）───────────────
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

# ── 可执行文件（可选）───────────────────────────────
# add_executable(${PROJECT_NAME}_node src/NODE_NAME_PLACEHOLDER.cpp)
# ament_target_dependencies(${PROJECT_NAME}_node <deps>)
# install(TARGETS ${PROJECT_NAME}_node DESTINATION lib/${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
CMAKEEOF

# 替换占位符
sed -i "s/PROJECT_NAME_PLACEHOLDER/${PKG_NAME}/g" "$PKG_NAME/CMakeLists.txt"
sed -i "s/NODE_NAME_PLACEHOLDER/${PKG_NAME}_node/g" "$PKG_NAME/CMakeLists.txt"
sed -i "s/PROJECT_NAME_PLACEHOLDER/${PKG_NAME}/g" "$PKG_NAME/package.xml"

# ── C++ 节点源文件 ──────────────────────────────────────
NODE_FILE="$PKG_NAME/src/${PKG_NAME}_node.cpp"

case "$NODE_TYPE" in
  publisher)
    cat > "$NODE_FILE" <<'CPPEOF'
// publisher node — 发布者节点模板
#include <chrono>
#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

class MinimalPublisher : public rclcpp::Node {
public:
  MinimalPublisher() : Node("minimal_publisher"), count_(0) {
    // QoS: RELIABLE (默认) — 适合控制命令
    // sensor 数据用: QoS profile = QoS(10).best_effort()
    publisher_ = this->create_publisher<std_msgs::msg::String>("topic", 10);
    timer_ = this->create_wall_timer(
      500ms, std::bind(&MinimalPublisher::timer_callback, this));
    RCLCPP_INFO(this->get_logger(), "Publisher started: /topic");
  }

private:
  void timer_callback() {
    auto msg = std_msgs::msg::String();
    msg.data = "Hello ROS2! " + std::to_string(count_++);
    RCLCPP_INFO(this->get_logger(), "Publishing: '%s'", msg.data.c_str());
    publisher_->publish(msg);
  }
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MinimalPublisher>());
  rclcpp::shutdown();
  return 0;
}
CPPEOF
    ;;

  subscriber)
    cat > "$NODE_FILE" <<'CPPEOF'
// subscriber node — 订阅者节点模板
#include <memory>
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class MinimalSubscriber : public rclcpp::Node {
public:
  MinimalSubscriber() : Node("minimal_subscriber") {
    // QoS: RELIABLE (默认)
    subscription_ = this->create_subscription<std_msgs::msg::String>(
      "topic", 10,
      std::bind(&MinimalSubscriber::topic_callback, this, std::placeholders::_1));
    RCLCPP_INFO(this->get_logger(), "Subscriber started: /topic");
  }

private:
  void topic_callback(const std_msgs::msg::String::SharedPtr msg) const {
    RCLCPP_INFO(this->get_logger(), "Received: '%s'", msg->data.c_str());
  }
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MinimalSubscriber>());
  rclcpp::shutdown();
  return 0;
}
CPPEOF
    ;;

  lifecycle)
    cat > "$NODE_FILE" <<'CPPEOF'
// lifecycle node — 生命周期节点（生产环境推荐）
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>

using rcl_interfaces::msg::Parameter;
using rcl_interfaces::msg::ParameterType;
using rcl_interfaces::msg::ParameterEvent;

class LifecycleNode : public rclcpp_lifecycle::LifecycleNode {
public:
  LifecycleNode() : LifecycleNode("lifecycle_node") {}

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "Configuring...");
    // 在这里初始化资源（timer、publisher、subscription）
    timer_ = this->create_wall_timer(
      1s, std::bind(&LifecycleNode::timer_callback, this));
    publisher_ = this->create_publisher<std_msgs::msg::String>("output", 10);
    RCLCPP_INFO(get_logger(), "Configured successfully");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "Activating...");
    publisher_->on_activate();  // QoS: TRANSIENT_LOCAL for lifecycle state
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "Deactivating...");
    publisher_->on_deactivate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "Cleaning up...");
    timer_.reset();
    publisher_.reset();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State&) override {
    RCLCPP_INFO(get_logger(), "Shutting down...");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

private:
  void timer_callback() {
    auto msg = std_msgs::msg::String();
    msg.data = "Lifecycle node running at " + std::to_string(
      this->now().nanoseconds() / 1e9);
    publisher_->publish(msg);
  }
  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<LifecycleNode>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
CPPEOF
    # 添加 lifecycle 依赖
    echo "" >> "$PKG_NAME/package.xml"
    echo "  <depend>lifecycle_msgs</depend>" >> "$PKG_NAME/package.xml"
    ;;

  timer)
    cat > "$NODE_FILE" <<'CPPEOF'
// timer node — 定时器节点（周期任务）
#include <chrono>
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

class TimerNode : public rclcpp::Node {
public:
  TimerNode() : Node("timer_node"), param_(42) {
    this->declare_parameter("param", param_);
    this->get_parameter("param", param_);
    
    timer_ = this->create_wall_timer(
      1s, std::bind(&TimerNode::timer_callback, this));
    RCLCPP_INFO(this->get_logger(), "Timer started with param=%d", param_);
  }

private:
  void timer_callback() {
    RCLCPP_INFO_THROTTLE(
      this->get_logger(), *this->get_clock(), 5000,
      "Timer tick (param=%d)", param_);
  }
  rclcpp::TimerBase::SharedPtr timer_;
  int param_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<TimerNode>());
  rclcpp::shutdown();
  return 0;
}
CPPEOF
    ;;

  service)
    cat > "$NODE_FILE" <<'CPPEOF'
// service node — 服务节点
#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>

class AddTwoIntsService : public rclcpp::Node {
public:
  AddTwoIntsService() : Node("add_two_ints_service") {
    service_ = this->create_service<example_interfaces::srv::AddTwoInts>(
      "add_two_ints",
      std::bind(&AddTwoIntsService::handle_service, this,
                std::placeholders::_1, std::placeholders::_2));
    RCLCPP_INFO(this->get_logger(), "Service ready: /add_two_ints");
  }

private:
  void handle_service(
    const std::shared_ptr<example_interfaces::srv::AddTwoInts::Request> request,
    std::shared_ptr<example_interfaces::srv::AddTwoInts::Response> response) {
    response->sum = request->a + request->b;
    RCLCPP_INFO(this->get_logger(), "Incoming request: %ld + %ld = %ld",
                request->a, request->b, response->sum);
  }
  rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<AddTwoIntsService>());
  rclcpp::shutdown();
  return 0;
}
CPPEOF
    ;;

  action)
    cat > "$NODE_FILE" <<'CPPEOF'
// action node — Action Server 节点（rclcpp_action）
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_action/rclcpp_action.hpp>
#include <example_interfaces/action/fibonacci.hpp>

using Fibonacci = example_interfaces::action::Fibonacci;
using GoalHandle = rclcpp_action::ServerGoalHandle<Fibonacci>;

class FibonacciActionNode : public rclcpp::Node {
public:
  FibonacciActionNode() : Node("fibonacci_action") {
    action_server_ = rclcpp_action::create_server<Fibonacci>(
      this, "fibonacci",
      std::bind(&FibonacciActionNode::handle_goal, this, _1, _2),
      std::bind(&FibonacciActionNode::handle_cancel, this, _1),
      std::bind(&FibonacciActionNode::handle_accepted, this, _1));
    RCLCPP_INFO(get_logger(), "Action Server ready: /fibonacci");
  }

private:
  rclcpp_action::GoalResponse handle_goal(
      const rclcpp_action::GoalUUID&, std::shared_ptr<const Fibonacci::Goal> goal) {
    RCLCPP_INFO(get_logger(), "Received goal order: %d", goal->order);
    if (goal->order <= 0 || goal->order > 93) {
      return rclcpp_action::GoalResponse::REJECT;
    }
    return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
  }

  rclcpp_action::CancelResponse handle_cancel(std::shared_ptr<GoalHandle>) {
    return rclcpp_action::CancelResponse::ACCEPT;
  }

  void handle_accepted(std::shared_ptr<GoalHandle> gh) {
    std::thread{[this, gh]() { execute(gh); }}.detach();
  }

  void execute(std::shared_ptr<GoalHandle> gh) {
    auto goal = gh->get_goal();
    Fibonacci::Feedback fb; fb.sequence = {0, 1};
    for (int i = 1; i < goal->order; ++i) {
      if (gh->is_canceling()) { gh->canceled(fb); return; }
      fb.sequence.push_back(fb.sequence[i] + fb.sequence[i-1]);
      gh->publish_feedback(fb);
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    Fibonacci::Result r; r.sequence = fb.sequence;
    gh->succeed(r);
    RCLCPP_INFO(get_logger(), "Goal succeeded: Fibonacci(%d) = %zu", goal->order, r.sequence.back());
  }

  rclcpp_action::Server<Fibonacci>::SharedPtr action_server_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<FibonacciActionNode>());
  rclcpp::shutdown(); return 0;
}
CPPEOF
    ;;

  parameters)
    cat > "$NODE_FILE" <<'CPPEOF'
// parameters node — 参数节点（动态参数读写）
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class ParametersNode : public rclcpp::Node {
public:
  ParametersNode() : Node("parameters_node"), int_param_(42), str_param_("hello") {
    // 声明参数（类型 + 默认值）
    this->declare_parameter("int_param", int_param_);
    this->declare_parameter("str_param", str_param_);
    this->declare_parameter("double_param", 3.14);

    // 参数变更回调
    param_callback_ = this->add_on_set_parameters_callback(
      std::bind(&ParametersNode::on_param_change, this, std::placeholders::_1));

    timer_ = this->create_wall_timer(
      2s, std::bind(&ParametersNode::timer_callback, this));

    RCLCPP_INFO(get_logger(), "Parameters node started");
  }

private:
  rcl_interfaces::msg::SetParametersResult on_param_change(
      const std::vector<rclcpp::Parameter>& params) {
    rcl_interfaces::msg::SetParametersResult result;
    result.successful = true;
    for (const auto& param : params) {
      if (param.get_name() == "int_param") {
        int_param_ = param.as_int();
        RCLCPP_INFO(get_logger(), "int_param changed to: %d", int_param_);
      } else if (param.get_name() == "str_param") {
        str_param_ = param.as_string();
        RCLCPP_INFO(get_logger(), "str_param changed to: %s", str_param_.c_str());
      }
    }
    return result;
  }

  void timer_callback() {
    RCLCPP_INFO(get_logger(), "Params: int=%d str=%s",
                int_param_, str_param_.c_str());
  }

  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::node_parameters::OnSetParametersCallbackHandle::SharedPtr param_callback_;
  int int_param_;
  std::string str_param_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ParametersNode>());
  rclcpp::shutdown(); return 0;
}
CPPEOF
    ;;

  *)
    echo -e "${RED}未知 node_type: $NODE_TYPE${NC}"
    echo "可用类型: publisher | subscriber | service | action | lifecycle | timer"
    rm -rf "$PKG_NAME"
    exit 1
    ;;
esac

# ── 清理注释中的占位符（如果是 lifecycle 模板）──────────
if [[ "$NODE_TYPE" != "lifecycle" ]]; then
    echo "  <depend>std_msgs</depend>" >> "$PKG_NAME/package.xml"
fi

# ── 结果 ────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✓ 生成完成: $PKG_NAME/${NC}"
echo ""
echo "生成的文件:"
find "$PKG_NAME" -type f | sort | sed 's/^/  /'
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  cd $PKG_NAME"
echo "  colcon build --packages-select $PKG_NAME"
echo "  source install/setup.bash"
echo "  ros2 run $PKG_NAME ${PKG_NAME}_node"
echo ""
echo -e "${BLUE}验证编译:${NC}"
echo "  colcon build --packages-select $PKG_NAME --event-handlers console_direct+"
