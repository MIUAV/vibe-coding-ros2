# ANTI_PATTERNS.md — ROS2 开发常见反模式

> 这些代码模式会编译/运行，但会在某个时刻导致机器人失控、数据丢失或难以调试的问题。

---

## 🔴 CMake 反模式（必读！）

### ❌ 漏写 `ament_export_dependencies`

```cmake
# ❌ 错误 — 漏了 export
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)

add_library(${PROJECT_NAME} SHARED src/my_node.cpp)
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
# 缺了这三行！

ament_package()

# 在依赖这个包的代码里会报错:
# undefined reference to 'ros2_xxx'
```

```cmake
# ✅ 正确 — 完整的三行 export
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs)
ament_export_dependencies(rclcpp)           # 必须
ament_export_include_directories(include)      # 必须
ament_export_libraries(${PROJECT_NAME})       # 必须
```

### ❌ `find_package` 不带 `REQUIRED`

```cmake
# ❌ 错误 — 静默失败
find_package(rclcpp)  # 如果找不到，链接时才发现

# ✅ 正确
find_package(rclcpp REQUIRED)
```

---

## 🔴 QoS 反模式（静默失败！）

### ❌ 控制命令用 BEST_EFFORT

```cpp
// ❌ 错误 — 机器人会丢命令，可能失控！
auto pub = this->create_publisher<JointCommand>("/arm/command",
    QoS(10).best_effort());  // 控制命令必须可靠

// ✅ 正确
auto pub = this->create_publisher<JointCommand>("/arm/command",
    QoS(10).reliable());  // RELIABLE
```

### ❌ LaserScan 订阅用默认 RELIABLE

```cpp
// 很多 lidar 驱动发布时用 BEST_EFFORT
// 如果订阅端用默认 RELIABLE，收不到数据！
// （静默失败 — 发布/订阅都成功但没数据）

// ✅ 正确 — 强制匹配发布端
auto sub = this->create_subscription<LaserScan>("/scan",
    QoS(10).best_effort());  // 匹配 lidar 驱动
```

### ❌ Lifecycle 节点订阅用 VOLATILE

```cpp
// ❌ 错误 — 新订阅者无法收到已发布的状态
auto sub = this->create_subscription<RobotState>("/state",
    QoS(10).volatil());  // 错过所有历史数据

// ✅ 正确
auto sub = this->create_subscription<RobotState>("/state",
    QoS(10).transient_local());  // 保留最新状态
```

---

## 🔴 Lifecycle 反模式

### ❌ 生产环境用 `rclcpp::Node` 而非 `LifecycleNode`

```cpp
// ❌ 错误 — 生产机器人控制
auto node = std::make_shared<rclcpp::Node>("robot_controller");
// 无法优雅关闭/重启特定模块

// ✅ 正确 — LifecycleNode 支持状态机
class RobotController : public rclcpp_lifecycle::LifecycleNode { ... }
```

### ❌ `on_configure()` 里执行阻塞操作

```cpp
// ❌ 错误 — configure 阶段阻塞
rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
on_configure(const rclcpp::State&) override {
    // 不要在 on_configure 里: sleep / 等待服务 / 循环查询
    std::this_thread::sleep_for(5s);  // 阻塞！
    return SUCCESS;
}

// ✅ 正确 — on_configure 只能做轻量初始化
rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
on_configure(const rclcpp::State&) override {
    publisher_ = create_publisher<Msg>("/topic", 10);  // 立即返回
    return SUCCESS;
}
```

---

## 🔴 C++ 反模式

### ❌ 头文件里 `using namespace std`

```cpp
// ❌ my_node.hpp — 全局污染
#ifndef MY_NODE_HPP
#define MY_NODE_HPP
using namespace std;  // 污染所有包含此头文件的 translation unit

class MyNode { ... };
#endif

// ✅ 正确 — 只在 .cpp 里用
// my_node.hpp: 完整 std:: 前缀
// my_node.cpp: using namespace std;
```

### ❌ 线程不安全地跨线程访问

```cpp
// ❌ 错误 — timer 回调和主线程同时访问 shared_data
rclcpp::TimerBase::SharedPtr timer_;
std::string shared_data;  // 被两个线程同时访问！

void timer_callback() { shared_data = "modified"; }  // timer 线程
void another_method() { shared_data = "also modified"; }  // 主线程

// ✅ 正确 — 加锁
std::mutex data_mutex;
std::string shared_data;

void timer_callback() {
    std::lock_guard<std::mutex> lock(data_mutex);
    shared_data = "modified";
}
```

### ❌ 原始指针管理生命周期

```cpp
// ❌ 错误 — 裸指针，生命周期不清晰
class MyNode : public rclcpp::Node {
    Publisher* pub_;  // 谁管理内存？
};

// ✅ 正确 — shared_ptr
class MyNode : public rclcpp::Node {
    rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
};
```

---

## 🔴 Launch 文件反模式

### ❌ launch 文件里硬编码路径

```python
# ❌ 错误 — 不可移植
Node(package='my_pkg', executable='node',
     parameters=[{'config': '/home/user/ros2_ws/config/params.yaml'}])

# ✅ 正确 — 相对于 package
from ament_index_python.packages import get_package_share_directory
pkg_dir = get_package_share_directory('my_pkg')
config_file = os.path.join(pkg_dir, 'config', 'params.yaml')
Node(package='my_pkg', executable='node',
     parameters=[config_file])
```

---

## 🔴 参数反模式

### ❌ 运行时才声明参数

```cpp
// ❌ 错误 — 运行时 declare 每次都创建新参数
void callback() {
    this->declare_parameter("throttle", 0.5);  // 每次调用都创建
}

// ✅ 正确 — 构造函数里声明一次
MyNode() : Node("my_node") {
    this->declare_parameter("throttle", 0.5);
}
```

---

## 🟡 警告模式

### ⚠️ 全局 `using namespace`

```cpp
// ⚠️ 不推荐 — 在 .cpp 可以，.hpp 禁止
using namespace std;
```

### ⚠️ `std::endl` 在发布循环里

```cpp
// ⚠️ endl 会 flush 缓冲区，频繁调用影响性能
RCLCPP_INFO(stream, "msg" << endl);  // 每条消息都 flush

// ✅ 推荐
RCLCPP_INFO_THROTTLE(logger, *clock, 1000, "msg");  // 节流 + 不用 endl
```

### ⚠️ `while(rclcpp::ok())` 在 timer 回调外

```cpp
// ⚠️ 不推荐 — spin 已经在处理 rclcpp::ok()
while (rclcpp::ok()) {
    rclcpp::spin(node);
}

// ✅ 推荐
rclcpp::spin(node);  // executor 会自动处理 shutdown
```

---

## 检查清单

生成代码后，逐项检查：

- [ ] CMakeLists.txt 有完整的 `ament_export_dependencies`
- [ ] 控制命令话题用 `reliable()`
- [ ] Sensor 话题用 `best_effort()`
- [ ] Lifecycle 状态用 `transient_local()`
- [ ] 生产代码用 `LifecycleNode` 而非 `Node`
- [ ] `on_configure()` 里没有阻塞操作
- [ ] 线程访问共享数据有 `std::mutex` 保护
- [ ] 头文件没有 `using namespace std`
- [ ] Launch 文件路径用 `get_package_share_directory`
