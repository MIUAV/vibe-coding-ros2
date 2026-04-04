# ROS2 节点实现提示词

> 用于指导 LLM 生成可工作的 ROS2 节点代码（C++ / Python）
> 覆盖：发布者、订阅者、Service、Action、Lifecycle、参数服务

---

## 一、必须遵守的硬规则

### ⚠️ CMake 禁区（AI 生成 CMakeLists.txt 后必须逐项确认）

1. **禁止省略 `ament_export_dependencies()`** — 传递依赖链断在此处
2. **禁止在 `find_package` 中不写 `REQUIRED`** — 静默依赖丢失
3. **禁止 link 未 `find_package` 的库** — 链接时找不到符号
4. **`ament_target_dependencies()` 必须列出所有传递依赖** — 不能只写直接依赖

### ⚠️ 消息类型禁区

1. **禁止裸消息类型** — 必须写 `std_msgs/msg/String`，不能写 `String`
2. **禁止字段类型写错** — `PoseStamped` 不是字段类型，是完整类型
3. **禁止 .msg 文件第一行非空** — 第一行必须是字段定义或空行

### ⚠️ QoS 禁区

1. **传感器数据必须用 `sensor_dataQoS()`** — 默认 Reliable 会导致数据积压
2. **控制命令必须用 Reliable** — sensor_dataQoS 的 BestEffort 会丢命令
3. **发布频率 > 50Hz 必须用 BestEffort** — 否则带宽不够

### ⚠️ Lifecycle 禁区

1. **Lifecycle 节点禁止使用 `rclcpp::Node`**，必须用 `rclcpp_lifecycle::LifecycleNode`
2. **禁止省略 `on_configure/on_activate/on_deactivate/on_cleanup/on_shutdown` 回调**
3. **Lifecycle 节点发布话题前必须 `create_publisher()` 后才能 publish**

---

## 二、C++ 标准节点模板

### 2.1 发布者节点

```cpp
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

class MinimalPublisher : public rclcpp::Node {
public:
  MinimalPublisher()
    : Node("minimal_publisher"), count_(0)
  {
    // QoS: 10 depth, Reliable for generic commands
    publisher_ = this->create_publisher<std_msgs::msg::String>("topic", 10);
    timer_ = this->create_wall_timer(
      500ms,
      [this]() { this->publish_callback(); });
    RCLCPP_INFO(this->get_logger(), "MinimalPublisher started");
  }

private:
  void publish_callback() {
    auto msg = std_msgs::msg::String();
    msg.data = "Hello ROS2 #" + std::to_string(count_++);
    RCLCPP_INFO(this->get_logger(), "Publishing: '%s'", msg.data.c_str());
    publisher_->publish(msg);
  }
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
  size_t count_;
};

int main(int argc, char * argv[]) {
  rclcpp::init(argc, argv);
  // MultiThreadedExecutor for multiple callbacks
  rclcpp::executors::MultiThreadedExecutor executor;
  auto node = std::make_shared<MinimalPublisher>();
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
```

### 2.2 订阅者节点

```cpp
#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class MinimalSubscriber : public rclcpp::Node {
public:
  MinimalSubscriber()
    : Node("minimal_subscriber")
  {
    // QoS: must match publisher. Use sensor_dataQoS for sensor data.
    subscription_ = this->create_subscription<std_msgs::msg::String>(
      "topic", 10,
      [this](const std_msgs::msg::String::SharedPtr msg) {
        RCLCPP_INFO(this->get_logger(), "I heard: '%s'", msg->data.c_str());
      });
    RCLCPP_INFO(this->get_logger(), "MinimalSubscriber started");
  }

private:
  rclcpp::Subscription<std_msgs::msg::String>::SharedPtr subscription_;
};

int main(int argc, char * argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<MinimalSubscriber>();
  rclcpp::spin(node);
  rclcpp::shutdown();
  return 0;
}
```

### 2.3 Service 服务器

```cpp
#include <rclcpp/rclcpp.hpp>
#include <example_interfaces/srv/add_two_ints.hpp>

class AddTwoIntsServer : public rclcpp::Node {
public:
  AddTwoIntsServer()
    : Node("add_two_ints_server")
  {
    service_ = this->create_service<example_interfaces::srv::AddTwoInts>(
      "add_two_ints",
      [this](const std::shared_ptr<rmw_request_id_t> request_header,
             const std::shared_ptr<example_interfaces::srv::AddTwoInts::Request> request,
             const std::shared_ptr<example_interfaces::srv::AddTwoInts::Response> response) {
        (void)request_header;
        response->sum = request->a + request->b;
        RCLCPP_INFO(this->get_logger(), "Incoming request: %ld + %ld",
          request->a, request->b);
      });
    RCLCPP_INFO(this->get_logger(), "AddTwoIntsServer ready");
  }

private:
  rclcpp::Service<example_interfaces::srv::AddTwoInts>::SharedPtr service_;
};

int main(int argc, char * argv[]) {
  rclcpp::init(argc, argv);
  auto node = std::make_shared<AddTwoIntsServer>();
  rclcpp::executors::MultiThreadedExecutor executor;
  executor.add_node(node);
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
```

### 2.4 Lifecycle 节点

```cpp
#include <rclcpp/rclcpp.hpp>
#include <rclcpp_lifecycle/rclcpp_lifecycle.hpp>
#include <lifecycle_msgs/msg/state.hpp>
#include <lifecycle_msgs/msg/transition.hpp>

class LifecycleDemoNode : public rclcpp_lifecycle::LifecycleNode {
public:
  LifecycleDemoNode()
    : rclcpp_lifecycle::LifecycleNode("lifecycle_demo")
  {
    RCLCPP_INFO(get_logger(), "LifecycleDemoNode created");
  }

  // 状态机回调 — 必须全部实现
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State &) {
    RCLCPP_INFO(get_logger(), "Configuring...");
    publisher_ = this->create_publisher<std_msgs::msg::String>("out_topic", 10);
    timer_ = this->create_wall_timer(1s, [this]() { this->publish(); });
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State &) {
    RCLCPP_INFO(get_logger(), "Activating... publisher is now live");
    publisher_->on_activate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State &) {
    RCLCPP_INFO(get_logger(), "Deactivating...");
    publisher_->on_deactivate();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State &) {
    RCLCPP_INFO(get_logger(), "Cleaning up...");
    timer_.reset();
    publisher_.reset();
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_shutdown(const rclcpp_lifecycle::State &) {
    RCLCPP_INFO(get_logger(), "Shutting down...");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

private:
  void publish() {
    auto msg = std_msgs::msg::String();
    msg.data = "ping";
    publisher_->publish(msg);
  }
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char * argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::executors::MultiThreadedExecutor executor;
  auto node = std::make_shared<LifecycleDemoNode>();
  executor.add_node(node->get_node_base_interface());
  executor.spin();
  rclcpp::shutdown();
  return 0;
}
```

---

## 三、Python 标准节点模板

### 3.1 发布者

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class MinimalPublisher(Node):
    def __init__(self):
        super().__init__('minimal_publisher')
        self.publisher_ = self.create_publisher(String, 'topic', 10)
        self.timer = self.create_timer(0.5, self.timer_callback)
        self.count = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Hello ROS2 #{self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1


def main(args=None):
    rclpy.init(args=args)
    node = MinimalPublisher()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()   # 必须调用，否则节点无法退出


if __name__ == '__main__':
    main()
```

### 3.2 订阅者

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class MinimalSubscriber(Node):
    def __init__(self):
        super().__init__('minimal_subscriber')
        self.subscription = self.create_subscription(
            String,
            'topic',
            self.listener_callback,
            10
        )

    def listener_callback(self, msg):
        self.get_logger().info(f'I heard: "{msg.data}"')


def main(args=None):
    rclpy.init(args=args)
    node = MinimalSubscriber()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()   # 必须调用


if __name__ == '__main__':
    main()
```

---

## 四、CMakeLists.txt 正确范式

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_CXX_STANDARD LESS 17)
  set(CMAKE_CXX_STANDARD 17)
endif()
if(NOT CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

ament_auto_find_build_dependencies()

# 节点源文件
ament_auto_add_library(${PROJECT_NAME}_node SHARED src/my_node.cpp)

# 可执行文件（独立于库）
ament_auto_add_executable(demo_publisher src/demo_publisher.cpp)
ament_auto_add_executable(demo_subscriber src/demo_subscriber.cpp)

# 安装
install(TARGETS ${PROJECT_NAME}_node demo_publisher demo_subscriber
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

# launch 文件
install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_auto_package()
```

---

## 五、编译验证流程（AI 生成后必须执行）

```bash
# 1. 构建单个包
colcon build --packages-select <package_name> --symlink-install 2>&1

# 2. 检查常见错误
# - "non-existent dependency XXX" → 缺 find_package(XXX REQUIRED)
# - "undefined reference to YYY" → 缺 ament_target_dependencies
# - "cannot find <ros2/...h>" → 缺 ament_include_directories

# 3. 如果报错，修正 CMakeLists.txt 后重新构建
# 4. 启动节点验证运行
ros2 run <package_name> <node_name>
```

---

## 六、QoS 配置速查

| 场景 | QoS 配置 | 原因 |
|------|----------|------|
| 激光扫描 | `sensor_dataQoS()` | 高频、允许丢帧 |
| 相机图像 | `sensor_dataQoS()` | 高频、允许丢帧 |
| 导航路径 | `reliable()` | 不能丢命令 |
| 控制命令 | `reliable()` | 必须可靠 |
| 参数服务 | `parameter_qos()` | 默认 |
| 地图数据 | `transient_local()` | 迟到订阅者也要收到 |

---

## 七、错误处理规范

1. **始终检查 SharedPtr 是否为空**再使用
2. **订阅回调中使用 `std::lock_guard`** 保护共享数据
3. **所有 `rclcpp::init` 必须配对 `rclcpp::shutdown`**
4. **不允许在回调中使用 `sleep()`** — 用 wall_timer 或 timer
5. **异常捕获**：节点崩溃时打印到 `/rosout` 的日志等级不低于 WARN
