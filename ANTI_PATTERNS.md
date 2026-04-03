# Anti-Patterns — AI 常见错误清单

> 这些是 AI 在 ROS2 开发中最常犯的错误，用 `🚫 禁止` 标记，每次生成代码时必须检查。

---

## CMakeLists.txt

```
🚫 遗漏 find_package(rclcpp REQUIRED)
   → 必须先 find_package 所有依赖

🚫 遗漏 ament_target_dependencies()
   → add_library 后必须链接触参

🚫 遗漏 install(TARGETS ...)
   → 编译成功但无法安装运行

🚫 遗漏 ament_package()
   → 包无法被 rosdep 识别

🚫 混淆 ament_cmake 和 ament_python
   → C++ 包必须用 ament_cmake

🚫 用 add_executable 代替 add_library
   → 库才能被其他包链接
```

---

## package.xml

```
🚫 遗漏 <depend> 就使用某个包
   → 编译报错 "package 'xxx' not found"

🚫 遗漏 rosidl_default_generators (消息包)
   → 消息无法生成

🚫 用 build_depend 但遗漏 exec_depend
   → 运行时找不到.so

🚫 用 Format 2 但未声明 <export>
   → 下游包无法找到依赖

🚫 遗漏 <buildtool_depend>ament_cmake
   → 无法编译
```

---

## Python 节点

```
🚫 混用 rclpy.init() + MultiThreadedExecutor 无关闭逻辑
   → Ctrl+C 无法停止

🚫 在构造函数中创建订阅不用 SharedPtr
   → 内存泄漏
   ✅ sub_ = create_subscription<...>(..., [this](...) { ... });

🚫 不 source install/setup.bash 就运行
   → "package not found"

🚫 Python 节点忘记 `if __name__ == '__main__':`
   → 模块被 import 时直接执行

🚫 混用 rclpy 和 rclcpp
   → 两者不能在同一进程混用
```

---

## C++ 节点

```
🚫 混用 rclcpp::Node 和 rclcpp::Node::SharedPtr
   → 类型不匹配

🚫 在回调函数中执行耗时操作
   → 阻塞主循环
   ✅ 用多线程 executor 或将耗时操作移到 timer

🚫 遗漏 rclcpp::init() / rclcpp::shutdown()
   → 资源未正确初始化/清理

🚫 SharedPtr 循环引用
   → 内存泄漏
   ✅ 用 weak_ptr 打破循环
```

---

## Launch 文件

```
🚫 缺少 launch_description = LaunchDescription([...])
   → launchd 启动失败

🚫 Node 参数不完整
   → 必须包含: package, executable, name, output

🚫 省略 remappings 或 parameters
   → 默认值可能不符合预期

🚫 在 launch.py 中执行 os.system("source ...")
   → 不生效
   ✅ 在终端中 source 后再启动 launch

🚫 多个包写在同一个 launch 文件但未配置 namespace
   → 话题名冲突
```

---

## 消息/服务/动作

```
🚫 .msg 文件中有多余空格
   → 生成失败

🚫 .srv 定义不区分 --- 分隔符前后
   → 编译器混淆

🚫 动作的 result 和 feedback 类型设为空
   → action server 崩溃
```

---

## 命名规范

```
🚫 包名带下划线 _ (ROS2 不允许)
   ✅ 用 my_robot_control 而不是 my_robot_control

🚫 话题名用驼峰命名
   ✅ /cmd_vel (snake_case)

🚫 变量名与 ROS2 关键字冲突
   → class, public, private 等

🚫 命名空间硬编码
   → 用参数或 launch 配置替代
```

---

## 编译与运行

```
🚫 不运行 colcon build 就 source
   → 包不存在

🚫 用 colcon build 而非 --symlink-install 开发
   → 每次改代码都要重新编译

🚫 安装依赖后不更新 ROS_DOMAIN_ID
   → 跨机器通信失败

🚫 修改代码后不重新编译
   → 运行的还是旧代码
```

---

## 快速检查命令

```bash
# CMakeLists.txt 检查
grep -c "find_package" CMakeLists.txt
grep -c "ament_target_dependencies" CMakeLists.txt
grep -c "install(TARGETS" CMakeLists.txt
grep -c "ament_package" CMakeLists.txt

# package.xml 检查
grep -c "<depend>" package.xml

# Python 检查
grep -c "rclpy.shutdown" my_node.py
grep -c "if __name__" my_node.py

# Launch 检查
grep -c "LaunchDescription" my.launch.py
```

---

*ANTI_PATTERNS.md — 每次生成代码前必读*

---

# C++ & ROS2 并发安全规范（v0.0.1-beta 新增）

> 这些是 AI 在 ROS2 C++ 开发中最容易破坏的地方，用 `✅ 正确` / `🚫 禁止` 标记。

---

## 1. 智能指针（必须）

```
✅ C++98 禁止 new/delete，ROS2 C++ 必须用：
  - std::make_shared<T>()  创建 SharedPtr
  - std::make_unique<T>()  创建 UniquePtr
  - 注意：ROS2 Node 本身用 SharedPtr，无需 unique_ptr

🚫 禁止裸指针
   Node::SharedPtr node = new Node();  // 泄漏
   ✅ Node::SharedPtr node = std::make_shared<Node>();  // 正确

🚫 禁止类成员裸指针持有回调
   // 错误：成员 holding 裸指针
   MyClass {
     rclcpp::Subscription::SharedPtr sub_;  // 如果持有裸指针错误
   };
   ✅ 始终保持 SharedPtr: subscription_
```

### 回调中的 this 捕获

```
✅ Lambda 正确写法（捕获 this 的 SharedPtr）
auto sub = create_subscription<std_msgs::msg::String>(
    "/topic", 10,
    [this](const std_msgs::msg::String::SharedPtr msg) {  // ← SharedPtr
        RCLCPP_INFO(get_logger(), "Got: %s", msg->data.c_str());
        // this 在回调中安全，因为 SharedPtr 活着
    }
);

🚫 禁止裸指针捕获
auto sub = create_subscription<std_msgs::msg::String>(
    "/topic", 10,
    [this](const std_msgs::msg::String::SharedPtr msg) {
        // 禁止在 lambda 中 delete this
    }
);

⚠️ 危险：SharedPtr 循环引用
  class A { std::shared_ptr<B> b_; };   // A owns B
  class B { std::shared_ptr<A> a_; };   // B owns A → 循环引用 → 内存泄漏！
  ✅ 用 std::weak_ptr<B> 打破循环
```

---

## 2. QoS 配置（必须）

### QoS 原则

```
ROS2 QoS 不是"调优参数"，是通信契约！

可靠性 (Reliability):
  - BEST_EFFORT:   UDP 风格，可能丢包（用于传感器原始流）
  - RELIABLE:     TCP 风格，必达（用于控制命令）

历史 (History):
  - KEEP_LAST(n): 保留最近 n 条
  - KEEP_ALL:     保留所有（慎用，内存爆炸）

深度 (Depth): 队列长度，必须配合 History 使用

持久性 (Durability):
  - VOLATILE:        不保留，迟到者丢失
  - TRANSIENT_LOCAL:  发布者保留，迟到订阅者收到最新一条
```

### 常见 QoS 场景

```cpp
// ── 场景1: 传感器（激光雷达、深度相机）─────────────
// 传感器数据流：可能丢包，保留最新，队列=5
rclcpp::QoS qos_sensor(5);
qos_sensor.best_effort();  // 不重传，不阻塞

// ── 场景2: 控制命令（/cmd_vel）─────────────────
// 控制命令：必须到达，不丢包，队列=1（最新）
rclcpp::QoS qos_cmd(1);
qos_cmd.reliable();       // TCP 重传

// ── 场景3: 参数同步、服务调用 ─────────────────
// 服务：可靠，队列=1
rclcpp::QoS qos_svc(1);
qos_svc.reliable();

// ── 场景4: 生命周期节点的状态发布 ───────────────
// 状态发布：发布者离线时新订阅者需要状态
rclcpp::QoS qos_state(10);
qos_state.reliable().transient_local();
```

### QoS 不匹配最常见错误

```
🚫 典型错误：传感器发布用默认 QoS（RELIABLE），订阅者用 BEST_EFFORT
   → 订阅者收不到数据，双方都不报错（静默失败）
   → 解决：明确声明 QoS 策略

✅ QoS 匹配检测命令：
  ros2 topic info /topic_name
  # 看 Reliability/History/Durability 是否匹配
```

---

## 3. Executor 并发模式（必须选一）

```
ROS2 有 4 种 Executor，只能选一种：

1. SingleThreadedExecutor  ← 最安全，适合大多数节点
   rclcpp::spin(node);

2. MultiThreadedExecutor  ← 多线程，必须考虑线程安全
   rclcpp::executors::MultiThreadedExecutor executor;
   executor.add_node(node);
   executor.spin();

3. StaticSingleThreadedExecutor  ← 订阅预注册，不支持动态增删
   // 用于性能极致优化场景

4. StaticExecutiveGroup  ← 实验性

⚠️ 危险混用：
  rclcpp::spin(node);           // ← SingleThreaded
  executor.add_node(node2);      // ← 但又加了 MultiThreaded
  // → 行为未定义
```

### 线程安全规则

```
🚫 禁止在回调中调用 rclcpp::shutdown()
🚫 禁止在回调中长时间阻塞
🚫 禁止两个回调同时写同一个变量（无锁保护）
🚫 禁止在回调中创建新的 Publisher（死锁风险）

✅ 用 Mutex 保护共享数据：
  std::mutex data_mutex_;
  std::atomic<bool> flag_{false};       // 原子类型
  std::lock_guard<std::mutex> lock(data_mutex_);  // 局部锁

✅ 用多线程 Executor 时，高频回调用互斥量：
  auto sub = create_subscription<std_msgs::msg::String>(
      "/topic", 10,
      [this](const String::SharedPtr msg) {
          std::lock_guard<std::mutex> lock(mutex_);
          latest_msg_ = msg;  // 线程安全写
      }
  );
```

---

## 4. 生命周期节点（Lifecycle Node）

```
🚫 普通节点没有状态机，无法优雅启停
🚫 控制类节点（arm_controller）必须用 LifecycleNode

Lifecycle 状态机：
  UNCONFIGURED → INACTIVE → ACTIVE → UNCONFIGURED
       ↑_________________________________|

✅ 生命周期节点代码骨架：

#include <rclcpp_lifecycle/lifecycle_node.hpp>

class MyLifecycleNode : public rclcpp_lifecycle::LifecycleNode
{
public:
  using Base = rclcpp_lifecycle::LifecycleNode;

  MyLifecycleNode()
  : Base("my_lifecycle_node")
  {
    RCLCPP_INFO(get_logger(), "Constructed");
  }

  // ── 状态回调（必须实现）─────────────────
  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_configure(const rclcpp_lifecycle::State &)
  {
    // 1. 读取参数
    // 2. 创建发布者/订阅者（但不 activate）
    // 3. 返回 SUCCESS / FAILURE / ERROR
    RCLCPP_INFO(get_logger(), "Configuring...");
    pub_ = create_publisher<std_msgs::msg::String>("/output", 10);
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_activate(const rclcpp_lifecycle::State &)
  {
    // 启动定时器、激活发布者
    RCLCPP_INFO(get_logger(), "Activating...");
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_deactivate(const rclcpp_lifecycle::State &)
  {
    // 停止发布、暂停定时器
    return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
  }

  rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
  on_cleanup(const rclcpp_lifecycle::State &)
  {
    // 清理资源
    pub_.reset();  // ← 显式 reset SharedPtr
    return SUCCESS;
  }

private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
};
```

---

## 5. WaitSet 与 Guard Condition（手写异步）

```
🚫 不要在高性能场景用 busy-wait 或 sleep 轮询
✅ 用 WaitSet 等待多个条件

rclcpp::WaitSet wait_set{};
wait_set.add_subscription(sub1_);
wait_set.add_subscription(sub2_);
wait_set.add_timer(timer_);

auto [subscriptions, timers, ..] = wait_set.wait(1s);  // 阻塞等待

for (auto & sub : subscriptions) {
    auto msg = sub->take_message();
    if (msg) process(msg);
}
```

---

## 6. Timer 与 回调周期

```
🚫 不要在 Timer 回调中做耗时操作
  → 阻塞主循环，其他回调堆积

✅ 耗时操作必须：
  1. 扔到线程池：rclcpp::CallbackGroup
  2. 或用 async_compose 执行器

rclcpp::CallbackGroup::SharedPtr bg = create_callback_group(
    rclcpp::CallbackGroupType::MutuallyExclusive);

auto timer = create_wall_timer(
    100ms,
    [this]() { /* 轻量任务 */ },
    bg
);
```

---

## 7. 跨节点通信死锁检测

```
⚠️ 两个节点互相等待对方响应，容易死锁

NodeA:                    NodeB:
  subscribe /b   →           subscribe /a
  client.call(b)  →           client.call(a)

✅ 解决：设置超时
  auto future = client->async_send_request(request);
  if (future.wait_for(5s) != std::future_status::ready) {
      RCLCPP_WARN("Service call timeout");
  }
```

---

## 快速自检清单（v0.0.1-beta）

```
□ 所有 new/delete 替换为 make_shared / make_unique
□ 回调捕获 SharedPtr 而非裸指针
□ QoS 策略明确声明（sensor=best_effort, cmd=reliable）
□ 多线程 Executor 使用 Mutex 保护共享变量
□ 生命周期节点正确实现 on_configure/activate/deactivate/cleanup
□ Timer 回调不超过 1ms 耗时
□ 服务调用有超时保护
□ SharedPtr 循环引用用 weak_ptr 打破
□ launch 文件包含 LaunchDescription()
□ 每次提醒 source install/setup.bash
```


---

# 🚦 QoS 速查卡（最常静默失败的地方）

```
QoS 不匹配 = 静默失败（不报错，但收不到数据）

发布者 QoS          订阅者 QoS          能通信？
──────────────────────────────────────────────
reliable(10)    →   reliable(10)      ✅
best_effort(5)  →   best_effort(5)   ✅
reliable(10)    →   best_effort(5)   ❌ 静默失败
best_effort(5)  →   reliable(10)      ❌ 静默失败
```

## 场景 → QoS 选择

| 场景 | Reliability | History | Depth | Durability |
|------|-------------|---------|-------|------------|
| 传感器原始流（激光、深度图） | `best_effort` | `KEEP_LAST` | 5 | `VOLATILE` |
| 控制命令（/cmd_vel） | `reliable` | `KEEP_LAST` | 1 | `VOLATILE` |
| 参数/配置同步 | `reliable` | `KEEP_LAST` | 1 | `TRANSIENT_LOCAL` |
| 地图/状态发布 | `reliable` | `KEEP_LAST` | 10 | `TRANSIENT_LOCAL` |
| 日志/调试信息 | `best_effort` | `KEEP_LAST` | 5 | `VOLATILE` |
| 服务调用 | `reliable` | `KEEP_LAST` | 1 | `VOLATILE` |

## C++ QoS 代码

```cpp
// 传感器（不重传，不阻塞）
rclcpp::QoS qos_sensor(5);
qos_sensor.best_effort();

// 控制命令（必须到达）
rclcpp::QoS qos_cmd(1);
qos_cmd.reliable();

// 状态持久化（新订阅者收到最新一条）
rclcpp::QoS qos_state(10);
qos_state.reliable().transient_local();
```

## 调试命令

```bash
# 查看话题 QoS
ros2 topic info /topic_name

# 查看发布/订阅 QoS 是否匹配
ros2 topic pub /chatter std_msgs/msg/String "{data: 'test'}" --qos-reliability reliable
ros2 topic echo /chatter --qos-reliability reliable
```

## 静默失败最常见场景

```
🚫 相机发布用默认 QoS（reliable），Gazebo 仿真订阅用 best_effort
   → RViz 显示无数据，但无报错
   → 检查：ros2 topic info /camera/image

🚫 激光雷达发布 best_effort，导航节点订阅 reliable
   → 导航正常但偶尔丢数据包
   → 检查：ros2 topic bw /scan

🚫 两个节点在同一机器通信正常，跨机器后失败
   → QoS 不匹配，或 ROS_DOMAIN_ID 不同
```

---

# 🔧 CMakeLists.txt/colcon build 错误速查

> colcon build 报错 → 原因 → 解决

| 报错信息 | 原因 | 解决 |
|---------|------|------|
| `Could not find a package configuration file` | find_package 遗漏 | 添加 `find_package(xxx REQUIRED)` |
| `target link libraries without target` | ament_target_dependencies 位置错误 | 确保在 `add_library()`/`add_executable()` 之后 |
| `ament_package() must be called once` | ament_package() 重复调用 | 删除重复的 ament_package() |
| `No CMake file named "ament_cmake"` | 缺少 `find_package(ament_cmake REQUIRED)` | 在 CMakeLists.txt 第一行 find_package 后添加 |
| `Unable to find package 'rclcpp'` | ROS2 环境未 source | `source /opt/ros/humble/setup.bash` |
| `package 'xxx' not found in workspace` | colcon build 未执行或未成功 | `colcon build --packages-select xxx` |
| `ament_target_dependencies: Cannot find target` | add_library/add_executable 在 ament_target_dependencies 之后 | 调换顺序 |
| `Unknown CMake command "ament_find_package"` | ament_cmake 版本问题 | `find_package(ament_cmake REQUIRED)` |
| `AMENT_DEPENDENCIES requires ament_cmake` | ament_target_dependencies 在 find_package 之前 | 重新排序 |
| `Could not find the file ... install(TARGETS` | install 路径拼写错误 | 检查 ARCHIVE/LIBRARY/RUNTIME 拼写 |
| `Failed to find module 'xxx'` | ROS2 包未安装 | `sudo apt install ros-humble-xxx` |
| `error: package 'xxx' not found` | 包名拼写错误或大小写不匹配 | 检查 package.xml 中的包名 |

## colcon build 正确顺序

```
1. cmake_minimum_required(VERSION 3.16)
2. project(pkg_name)
3. find_package(ament_cmake REQUIRED)
4. find_package(rclcpp REQUIRED)
5. find_package(其他依赖 REQUIRED)
6. rosidl_generate_interfaces (如有自定义接口)
7. add_library 或 add_executable
8. ament_target_dependencies
9. install(TARGETS ...)
10. install(DIRECTORY ...)
11. ament_package()
```

## package.xml ↔ CMakeLists.txt 依赖对应关系

| package.xml | CMakeLists.txt |
|------------|----------------|
| `<depend>rclcpp</depend>` | `find_package(rclcpp REQUIRED)` |
| `<depend>geometry_msgs</depend>` | `find_package(geometry_msgs REQUIRED)` |
| `<depend>rosidl_default_runtime</depend>` | 无需单独 find_package |
| `<exec_depend>xxx</exec_depend>` | 无需 find_package（运行时依赖） |
| `<buildtool_depend>ament_cmake</buildtool_depend>` | `find_package(ament_cmake REQUIRED)` |
