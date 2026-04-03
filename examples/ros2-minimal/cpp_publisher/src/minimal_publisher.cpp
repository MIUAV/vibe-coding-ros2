/**
 * cpp_publisher — ROS2 C++ 发布者示例节点
 *
 * 功能: 定时发布 std_msgs/String 消息到 /chatter 话题
 *
 * 对应规范 (ANTI_PATTERNS.md):
 *   ✅ 使用 SharedPtr 而非裸指针
 *   ✅ rclcpp::init() / rclcpp::shutdown() 完整生命周期
 *   ✅ 使用 RCLCPP_INFO 而非 printf
 *   ✅ QoS 声明: reliable + depth=10
 *   ✅ 禁止在回调中 sleep（使用 wall_timer）
 *   ✅ CMAKE_CXX_STANDARD 17
 *
 * 编译: colcon build --packages-select cpp_publisher --symlink-install
 * 运行: ros2 run cpp_publisher minimal_publisher
 */

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

namespace
{
  constexpr auto kNodeName  = "minimal_publisher";
  constexpr auto kTopicName = "/chatter";
  constexpr auto kQoSDepth = 10;
}

class MinimalPublisher : public rclcpp::Node
{
public:
  explicit MinimalPublisher(const rclcpp::NodeOptions & options = rclcpp::NodeOptions{})
  : Node(kNodeName, options), count_(0)
  {
    // ── 1. 创建发布者 ─────────────────────────────
    // QoS 说明:
    //   reliability = RELIABLE   → TCP 重传，消息必达（适合控制命令）
    //   history     = KEEP_LAST  → 保留最近 kQoSDepth 条
    //   depth       = kQoSDepth → 队列深度
    rclcpp::QoS qos(kQoSDepth);
    qos.reliable();       // 可靠传输（默认，可省略）
    // qos.best_effort();  // 用于传感器数据流（不重传，不阻塞）

    publisher_ = this->create_publisher<std_msgs::msg::String>(kTopicName, qos);

    // ── 2. 创建定时器 ────────────────────────────
    // 注意: 定时器回调中不能有耗时操作，否则阻塞主循环
    timer_ = this->create_wall_timer(
      std::chrono::milliseconds(500),
      [this]() { timer_callback(); }
    );

    RCLCPP_INFO(this->get_logger(), "Publisher node started, publishing to '%s'", kTopicName);
  }

private:
  void timer_callback()
  {
    // ── 定时器回调必须轻量 ───────────────────────
    // 🚫 禁止: sleep() / usleep() / 耗时计算
    // ✅ 正确: 直接构建消息并发布

    auto msg = std_msgs::msg::String();
    msg.data = "Hello, ROS2! count = " + std::to_string(count_++);

    RCLCPP_INFO(this->get_logger(), "Publishing: '%s'", msg.data.c_str());
    publisher_->publish(msg);
  }

  // ── 成员变量 ─────────────────────────────────
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

int main(int argc, char * argv[])
{
  // ── 标准入口模式 ─────────────────────────────
  rclcpp::init(argc, argv);

  // 方式1: 单线程 spin（最安全，大多数场景用这个）
  auto node = std::make_shared<MinimalPublisher>();
  rclcpp::spin(node);

  // 方式2: 多线程 executor（需要在回调中做耗时操作时用）
  // auto executor = std::make_unique<rclcpp::executors::MultiThreadedExecutor>();
  // executor->add_node(node);
  // executor->spin();

  rclcpp::shutdown();
  return 0;
}
