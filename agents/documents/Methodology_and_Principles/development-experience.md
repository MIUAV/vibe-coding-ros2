# ROS2 开发经验总结

> 记录 ROS2 机器人开发中的坑点、最佳实践和经验教训

---

## 1. 环境配置

### 1.1 ROS2 安装坑点

```bash
# 常见问题1: locale 设置
locale  # 检查是否为 UTF-8
# 如果不是，修改 /etc/default/locale
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# 常见问题2: Ubuntu 22.04 + ROS2 Humble 源
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo apt install curl gnupg lsb-release
curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo apt-key add -
sudo sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list'

# 常见问题3: colcon 编译卡住
# 使用 --parallel-workers 加速
colcon build --parallel-workers $(nproc)
```

### 1.2 Docker 环境

```bash
# 问题: Docker 中 ROS2 无法访问 GPU
# 解决: 运行时添加 GPU 支持
docker run --gpus all -v /dev:/dev ...

# 问题: 容器中 rviz2 闪退
# 解决: 添加 --privileged 和 --net=host
```

### 1.3 ARM64 交叉编译

```bash
# 常见问题: sysroot 路径错误
# 解决: CMAKE_SYSROOT 设置为正确的根文件系统路径
cmake ... -DCMAKE_SYSROOT=/opt/orin_sysroot \
           -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
           -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++

# 常见问题: 找不到 sysroot 中的库
# 解决: 设置 CMAKE_FIND_ROOT_PATH_MODE
-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
```

---

## 2. 节点开发

### 2.1 生命周期节点 (Lifecycle Node)

```cpp
// 最佳实践: 使用 Lifecycle Node 管理节点状态
// 原因: 可以控制节点的启动顺序和状态转换

#include <rclcpp_lifecycle/lifecycle_node.hpp>

class MyNode : public rclcpp_lifecycle::LifecycleNode {
public:
    MyNode() : rclcpp_lifecycle::LifecycleNode("my_node") {}
    
    // 状态回调
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_configure(const rclcpp_lifecycle::State &) override {
        RCLCPP_INFO(this->get_logger(), "Configuring...");
        // 初始化资源
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
    
    rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn
    on_activate(const rclcpp_lifecycle::State &) override {
        RCLCPP_INFO(this->get_logger(), "Activating...");
        // 开始工作
        return rclcpp_lifecycle::node_interfaces::LifecycleNodeInterface::CallbackReturn::SUCCESS;
    }
};
```

### 2.2 多线程执行器

```cpp
// 问题: 节点处理慢，跟不上发布频率
// 解决: 使用多线程执行器

rclcpp::executors::MultiThreadedExecutor executor;
executor.add_node(node);
executor.spin();
```

### 2.3 定时器注意事项

```cpp
// 坑点: 定时器回调不要做耗时操作
// 解决: 用标志位 + spin_some 处理

auto timer_callback = [this]() {
    this->work_flag_ = true;  // 只设置标志位
};

auto spin_callback = [this]() {
    if (this->work_flag_) {
        this->do_work();  // 在 spin 中处理
        this->work_flag_ = false;
    }
};
```

---

## 3. 通信机制

### 3.1 Topic

```cpp
// 最佳实践: 使用一致的命名约定
// 格式: /<namespace>/<node_name>/<signal_name>

// Good
subscriber_ = this->create_subscription<sensor_msgs::msg::Image>(
    "/helmet/camera/image_raw", 10, callback);

// Bad - 省略了 namespace 和 node_name
subscriber_ = this->create_subscription<sensor_msgs::msg::Image>(
    "/image", 10, callback);
```

### 3.2 Service

```cpp
// 最佳实践: Service 设计要幂等
// 原因: 客户端可能重复调用

// Service 定义示例
// srv/SetCameraMode.srv
// ---
// bool success
// string message
// ---
// request: mode: uint8 mode
// response: success, message
```

### 3.3 Action

```cpp
// 最佳实践: Action 用于长时间任务
// 例: 导航、抓取、巡检

// 问题: ActionServer 崩溃后无法恢复
// 解决: 使用 lifecycle 管理 ActionServer
```

### 3.4 QoS 策略

```cpp
// 常见问题: 消息丢失
// 解决: 根据场景选择合适 QoS

// 传感器数据: RELIABLE + KEEP_LAST(10)
rclcpp::SensorDataQoS qos;

// 控制指令: RELIABLE + TRANSIENT_LOCAL (latch)
rclcpp::ParametersQoS qos;

// 实时性要求高: BEST_EFFORT
rclcpp::BestEffortQoS qos;
```

---

## 4. 消息定义

### 4.1 自定义 Msg

```msg
# 最佳实践: 嵌套消息要稳定
# 避免: 频繁修改字段

# Good: 独立的、功能性的消息
Header header
uint8 device_type
float32[] data

# Bad: 直接嵌套标准消息
std_msgs/Header header  # 不好追踪
sensor_msgs/Image image  # 太大，不好管理
```

### 4.2 Msg 版本管理

```cpp
// 问题: 升级 msg 后新旧节点不兼容
// 解决: 添加版本字段

uint8 msg_version = 1  # 消息版本
```

---

## 5. Launch 文件

### 5.1 参数传递

```python
# 最佳实践: 使用参数而不是硬编码

# Good: launch/mynode.launch.py
def generate_launch_description():
    declared_args = []
    declared_args.append(
        DeclareLaunchArgument(
            'device',
            default_value='cuda',
            description='Device type: cuda/cpu'
        )
    )
    
    return LaunchDescription([
        # ...
        SetEnvironmentVariable('DEVICE', LaunchConfiguration('device'))
    ])
```

### 5.2 条件启动

```python
# 根据条件启动不同节点
from launch.actions import ExecuteProcess, RegisterEventHandler
from launch.event_handlers import OnProcessExit

# 示例: 只有当某个参数为 true 时才启动
IfCondition(LaunchConfiguration('enable_perception'))
```

---

## 6. 调试技巧

### 6.1 日志级别

```cpp
// 动态调整日志级别
ros2 run rqt_logger_level rqt_logger_level

// 或在代码中
this->get_logger().set_level(rclcpp::Logger::DEBUG);
```

### 6.2 ros2cli 常用命令

```bash
# 查看节点
ros2 node list
ros2 node info /node_name

# 查看 topic
ros2 topic list
ros2 topic echo /topic_name --once
ros2 topic hz /topic_name

# 查看 service
ros2 service list
ros2 service call /service_name ...

# 查看 param
ros2 param list
ros2 param get /node_name parameter_name
ros2 param set /node_name parameter_name value
```

### 6.3 性能分析

```bash
# 延迟测量
ros2 topic delay /topic_name

# 带宽占用
ros2 topic bw /topic_name

# ros2 run 性能
time ros2 run pkg node
```

---

## 7. 跨平台开发

### 7.1 x86 ↔ ARM64

```bash
# 常见问题: 源码中硬编码路径
# 解决: 使用 cmake 变量或环境变量

# Good
target_include_directories(node PRIVATE 
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# 常见问题: 动态库加载
# 解决: 使用 ament 打包，避免 dlopen 跨平台问题
```

### 7.2 环境变量

```bash
# ROS2 环境变量
echo $ROS_DISTRO  # humble
echo $ROS_LOCALIZATION_ONLY
echo $AMENT_PREFIX_PATH

# 项目特定
export MY_ROBOT_CONFIG=/path/to/config
```

---

## 8. 常见错误处理

### 8.1 编译错误

```bash
# 错误: Could not find a package
# 解决: source 相应的 setup.bash
source /opt/ros/humble/setup.bash

# 错误: undefined reference to '...' 
# 解决: 检查 CMakeLists.txt 中的 target_link_libraries

# 错误: Cyclic dependency
# 解决: 拆分包，或使用 pluginlib 延迟加载
```

### 8.2 运行时错误

```bash
# 错误: Segmentation fault
# 调试: 使用 gdb
gdb -ex run --args ros2 run pkg node

# 错误: 节点崩溃后无法重启
# 检查: 是否有未释放的资源 (mutex, memory)

# 错误: Topic 没有数据
# 检查: 
# 1. ros2 topic list
# 2. ros2 topic info /topic_name
# 3. ros2 topic hz /topic_name
```

### 8.3 内存问题

```cpp
// 问题: 内存泄漏
// 解决: 使用智能指针

// Good: 使用 make_shared, make_unique
auto msg = std::make_shared<sensor_msgs::msg::Image>();

// Bad: 手动 new
auto msg = new sensor_msgs::msg::Image();  // 忘记 delete
```

---

## 9. 测试

### 9.1 单元测试

```cpp
// 使用 gtest
#include <gtest/gtest.h>

TEST(TestSuite, TestCase) {
    EXPECT_EQ(1, 1);
}

// 运行
colcon test --packages-select pkg_name
```

### 9.2 集成测试

```python
# 使用 launch_testing
import launch_testing

def test_something():
    # 启动节点，发送测试数据，验证结果
    pass
```

---

## 10. 性能优化

### 10.1 零拷贝

```cpp
// 问题: 大图像消息拷贝开销大
// 解决: 使用共享指针 + 借用（intra-process communication）

// 发布时用 shared_ptr
auto msg = std::make_shared<sensor_msgs::msg::Image>(*image);
publisher_->publish(msg);

// 订阅时
void callback(const sensor_msgs::msg::Image::SharedPtr msg) {
    // 零拷贝访问
}
```

### 10.2 异步处理

```cpp
// 问题: 同步处理阻塞主循环
// 解决: 使用 async + future

std::future<result> future = 
    std::async(std::launch::async, [&]() {
        return do heavy work();
    });
```

---

## 11. 安全

### 11.1 参数验证

```cpp
// 始终验证输入参数
void MyNode::setParam(int value) {
    if (value < 0 || value > 100) {
        throw std::invalid_argument("value out of range");
    }
    param_ = value;
}
```

### 11.2 资源限制

```cpp
// 防止内存溢出
const size_t MAX_QUEUE_SIZE = 10;
message_queue_.set_capacity(MAX_QUEUE_SIZE);
```

---

## 12. 文档编写

### 12.1 README

```markdown
# 包名称

## 功能描述

## 依赖

## 编译

## 运行

## 参数

## Topic
```

### 12.2 代码注释

```cpp
/// @brief 简要说明
/// @param input 输入参数说明
/// @return 返回值说明
/// @note 注意事项
int myFunction(int input) {
    // 实现
}
```

---

*本文档持续更新，欢迎贡献经验*
