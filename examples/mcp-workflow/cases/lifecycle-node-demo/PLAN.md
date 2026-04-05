# Case: lifecycle-node-demo

> 用工具链生成生产级 LifecycleNode 的完整流程。

## 目标

生成一个遵循 LifecycleNode 状态机的 ROS2 C++ 节点，包含：
- `on_configure` / `on_activate` / `on_deactivate` / `on_cleanup` / `on_shutdown`
- QoS 正确配置（RELIABLE 控制命令 + BEST_EFFORT 状态反馈）
- RCLCPP 日志规范
- MultiThreadedExecutor

## 工具链使用步骤

### Step 1: 生成包骨架

```bash
bash scripts/generators/ros2-package-generator.sh lifecycle_demo cpp rclcpp,std_msgs,geometry_msgs,lifecycle_msgs --verify
```

### Step 2: 生成节点代码

替换 `src/lifecycle_demo_node.cpp`：

```cpp
// src/lifecycle_demo_node.cpp — 生产级 LifecycleNode
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>
#include <std_msgs/msg/string.hpp>
#include <geometry_msgs/msg/twist.hpp>

using namespace std::chrono_literals;

class LifecycleDemo : public rclcpp_lifecycle::LifecycleNode {
public:
  LifecycleDemo() : LifecycleNode("lifecycle_demo") {}

  // ── on_configure: 创建发布者/订阅者/计时器 ───────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp::State&) override {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Configuring...");

    // RELIABLE QoS — 控制命令必须可靠
    cmd_pub_ = create_publisher<geometry_msgs::msg::Twist>(
      "/cmd_vel", rclcpp::QoS(10).reliable());

    // BEST_EFFORT — 状态反馈允许丢帧
    status_pub_ = create_publisher<std_msgs::msg::String>(
      "/controller_status", rclcpp::QoS(10).best_effort());

    // 在 configure 阶段不要启动计时器（Inactive 状态不能发布）
    RCLCPP_INFO(get_logger(), "[Lifecycle] Configured");
    return CallbackReturn::SUCCESS;
  }

  // ── on_activate: 激活发布者 + 启动计时器 ─────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp::State&) override {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Activating...");
    cmd_pub_->on_activate();
    status_pub_->on_activate();

    // 计时器必须在 on_activate 后才触发
    timer_ = create_wall_timer(1s, [this]() {
      geometry_msgs::msg::Twist cmd;
      cmd.linear.x = 0.0;
      cmd_pub_->publish(cmd);
    });

    RCLCPP_INFO(get_logger(), "[Lifecycle] Activated");
    return CallbackReturn::SUCCESS;
  }

  // ── on_deactivate: 停止计时器（不销毁）────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp::State&) override {
    RCLCPP_INFO(get_logger(), "[Lifecycle] Deactivating...");
    timer_->cancel();
    cmd_pub_->on_deactivate();
    status_pub_->on_deactivate();
    return CallbackReturn::SUCCESS;
  }

  // ── on_cleanup: 销毁资源 ─────────────────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp::State&) override {
    timer_.reset();
    cmd_pub_.reset();
    status_pub_.reset();
    return CallbackReturn::SUCCESS;
  }

  // ── on_shutdown: 任意状态都可关闭 ───────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp::State&) override {
    timer_.reset();
    cmd_pub_.reset();
    status_pub_.reset();
    return CallbackReturn::SUCCESS;
  }

private:
  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr status_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<LifecycleDemo>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
```

### Step 3: 编译验证

```bash
colcon build --packages-select lifecycle_demo
source install/setup.bash
```

### Step 4: 测试状态机

```bash
ros2 run lifecycle_demo lifecycle_demo_node

# 新终端：
ros2 lifecycle list /lifecycle_demo
ros2 lifecycle set /lifecycle_demo configure
ros2 lifecycle set /lifecycle_demo activate
ros2 topic echo /controller_status
ros2 lifecycle set /lifecycle_demo deactivate
ros2 lifecycle set /lifecycle_demo cleanup
```

## 关键规范总结

| 规则 | 错误做法 | 正确做法 |
|------|---------|---------|
| 计时器启动 | 在 `on_configure` 创建并启动 | 在 `on_activate` 中创建并启动 |
| QoS 控制命令 | `best_effort()` | `reliable()` |
| 发布者激活 | 不调用 `on_activate()` | 必须调用 `pub->on_activate()` |
| 资源销毁 | 在 `on_deactivate` 中 `reset()` | 在 `on_cleanup` 中 `reset()` |
| 多线程 | 使用 `SingleThreadedExecutor` | 使用 `MultiThreadedExecutor` |
