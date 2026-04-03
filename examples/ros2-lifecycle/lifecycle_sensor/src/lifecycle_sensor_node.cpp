/**
 * lifecycle_sensor_node — ROS2 Lifecycle 节点示例
 *
 * 功能: 传感器数据发布器，支持生命周期管理（优雅启停）
 *
 * Lifecycle 状态机:
 *   UNCONFIGURED → on_configure() → INACTIVE
 *        ↑                              ↓
 *     on_shutdown()              on_activate() → ACTIVE
 *                                             ↓
 *                              on_deactivate() → INACTIVE
 *                                             ↓
 *                              on_cleanup() → UNCONFIGURED
 *
 * 对应规范 (ANTI_PATTERNS.md):
 *   ✅ 实现 on_configure / on_activate / on_deactivate / on_cleanup / on_shutdown
 *   ✅ 状态转换时有 RCLCPP_INFO 日志
 *   ✅ 资源在对应状态创建/销毁
 *   ✅ SharedPtr 持有 publisher_，on_cleanup 中 reset
 *
 * 运行:
 *   ros2 run lifecycle_sensor lifecycle_sensor
 *   ros2 lifecycle list /lifcycle_sensor    # 查看状态
 *   ros2 lifecycle set /lifcycle_sensor configure
 *   ros2 lifecycle set /lifcycle_sensor activate
 */

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/lifecycle_node.hpp>
#include <std_msgs/msg/string.hpp>

using std::placeholders::_1;
using CallbackReturn = rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn;

namespace
{
  constexpr auto kNodeName  = "lifecycle_sensor";
  constexpr auto kTopicName = "/sensor_data";
}

class LifecycleSensor : public rclcpp_lifecycle::LifecycleNode
{
public:
  LifecycleSensor()
  : rclcpp_lifecycle::LifecycleNode(kNodeName)
  {
    RCLCPP_INFO(get_logger(), "LifecycleSensor constructed");
  }

  // ─────────────────────────────────────────
  // on_configure: 从 UNCONFIGURED 进入 INACTIVE
  // 在这里创建发布者/订阅者/服务，但不要 activate
  // ─────────────────────────────────────────
  CallbackReturn on_configure(const rclcpp_lifecycle::State & /*state*/) override
  {
    RCLCPP_INFO(get_logger(), "[configure] Configuring sensor...");

    // QoS: transient_local — 新订阅者能收到最新一条
    // 用于传感器状态发布（发布者离线时新订阅者也需要状态）
    rclcpp::QoS qos(10);
    qos.reliable().transient_local();

    publisher_ = this->create_publisher<std_msgs::msg::String>(kTopicName, qos);

    RCLCPP_INFO(get_logger(), "[configure] Publisher created, NOT activated yet");
    return CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────
  // on_activate: 从 INACTIVE 进入 ACTIVE
  // 在这里激活发布者、启动定时器
  // ─────────────────────────────────────────
  CallbackReturn on_activate(const rclcpp_lifecycle::State & /*state*/) override
  {
    RCLCPP_INFO(get_logger(), "[activate] Activating sensor...");

    // ⚠️ 必须显式 activate publisher
    publisher_->on_activate();

    // 启动定时器（在 ACTIVE 状态下才真正发布）
    timer_ = this->create_wall_timer(
      std::chrono::seconds(1),
      [this]() { this->publish_sensor_data(); }
    );

    RCLCPP_INFO(get_logger(), "[activate] Sensor activated and publishing");
    return CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────
  // on_deactivate: 从 ACTIVE 返回 INACTIVE
  // 停止定时器、停用发布者
  // ─────────────────────────────────────────
  CallbackReturn on_deactivate(const rclcpp_lifecycle::State & /*state*/) override
  {
    RCLCPP_INFO(get_logger(), "[deactivate] Deactivating sensor...");

    publisher_->on_deactivate();
    timer_.reset();  // 停止定时器

    RCLCPP_INFO(get_logger(), "[deactivate] Sensor deactivated");
    return CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────
  // on_cleanup: 从 INACTIVE 回到 UNCONFIGURED
  // 清理所有资源
  // ─────────────────────────────────────────
  CallbackReturn on_cleanup(const rclcpp_lifecycle::State & /*state*/) override
  {
    RCLCPP_INFO(get_logger(), "[cleanup] Cleaning up resources...");

    // 🚫 必须 reset SharedPtr，释放资源
    publisher_.reset();
    timer_.reset();

    RCLCPP_INFO(get_logger(), "[cleanup] All resources released");
    return CallbackReturn::SUCCESS;
  }

  // ─────────────────────────────────────────
  // on_shutdown: 从任意状态关闭
  // ─────────────────────────────────────────
  CallbackReturn on_shutdown(const rclcpp_lifecycle::State & /*state*/) override
  {
    RCLCPP_INFO(get_logger(), "[shutdown] Shutting down...");
    publisher_.reset();
    timer_.reset();
    return CallbackReturn::SUCCESS;
  }

private:
  void publish_sensor_data()
  {
    if (get_current_state().label() != "active") {
      return;  // 非 active 状态不发布
    }

    auto msg = std_msgs::msg::String();
    msg.data = "Sensor reading at " + std::to_string(
      std::chrono::system_clock::now().time_since_epoch().count()
    );
    publisher_->publish(msg);
    RCLCPP_INFO_ONCE(get_logger(), "[publish] Publishing sensor data");
  }

  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);

  // LifecycleNode 用 Executor spin
  auto node = std::make_shared<LifecycleSensor>();
  rclcpp::spin(node->get_node_base_interface());

  rclcpp::shutdown();
  return 0;
}
