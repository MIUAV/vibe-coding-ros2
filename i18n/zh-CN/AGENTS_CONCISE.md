# Vibe-Coding-ROS2 — 极简指令卡

> 任何 AI Agent 必须按此顺序执行，不得跳过任何步骤。

---

## 核心规则（不可违背）

### 执行顺序（强制）

```
1. 读 AGENTS_CONCISE.md（本文档）
2. 读 ANTI_PATTERNS.md（C++/Python/QoS/并发规范）
3. 读 examples/ 对应示例（看真实代码）
4. 生成代码
5. 自检清单
6. 更新 memory-bank/ROS2_MEMORY.md
```

### 文件生成顺序（强制）

```
接口定义(.msg/.srv) → package.xml → CMakeLists.txt → 节点代码 → launch → 编译
```

---

## Anti-Patterns 速查（禁止）

```
🚫 CMakeLists.txt 遗漏 find_package(rclcpp REQUIRED)
🚫 CMakeLists.txt 遗漏 ament_target_dependencies
🚫 CMakeLists.txt 遗漏 install(TARGETS)
🚫 CMakeLists.txt 遗漏 ament_package()
🚫 package.xml 遗漏 <depend> 就使用某个包
🚫 package.xml 有 rosidl 但没有 rosidl_default_generators
🚫 Python 混用 rclpy.init() 无 try/finally rclpy.shutdown()
🚫 launch 缺少 LaunchDescription([...])
🚫 C++ 裸指针（必须 SharedPtr）
🚫 QoS 不匹配静默失败（sensor=best_effort, cmd=reliable）
🚫 回调中 sleep / 阻塞 / rclcpp::shutdown()
🚫 MultiThreadedExecutor 无 Mutex 保护
🚫 服务调用无超时（必须 wait_for()）
🚫 假设 install/setup.bash 已被 source
```

**完整规范 → ANTI_PATTERNS.md**

---

## 可运行的示例代码（直接参照）

```
examples/
├── ros2-minimal/
│   ├── cpp_publisher/      # C++ 发布者 + QoS + wall_timer
│   └── py_subscriber/     # Python 订阅者 + rclpy 规范
├── ros2-lifecycle/
│   └── lifecycle_sensor/   # Lifecycle 节点状态机
└── ros2-service/
    └── add_two_ints/       # Service + Client + 超时保护
```

每个示例均可编译运行：
```bash
colcon build --packages-select <pkg> --symlink-install
ros2 run <pkg> <node>
```

---

## 节点代码模板

### C++（标准）

```cpp
#include <rclcpp/rclcpp.hpp>

class MyNode : public rclcpp::Node {
public:
  MyNode() : Node("my_node") {
    // ✅ SharedPtr
    pub_ = create_publisher<std_msgs::msg::String>("/topic", 10);
    RCLCPP_INFO(get_logger(), "Started");
  }
private:
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr pub_;
};

int main(int argc, char** argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<MyNode>());
  rclcpp::shutdown();
  return 0;
}
```

### Python

```python
def main():
    rclpy.init(args=args)
    try:
        rclpy.spin(node)
    finally:
        rclpy.shutdown()   # 必须有

if __name__ == '__main__':
    main()
```

---

## 内存约定

```
文件: /tmp/vibe-ros2-memory.md 或 memory-bank/ROS2_MEMORY.md
每次开始: 读取
每次完成模块: 更新
```

---

## 质量自检清单

```
□ package.xml 有所有 <depend>
□ CMakeLists.txt: find_package + ament_target_dependencies + install + ament_package
□ C++: SharedPtr（禁止裸指针 new/delete）
□ QoS: sensor=best_effort, cmd=reliable
□ Python: rclpy.shutdown() 在 try/finally 中
□ launch: LaunchDescription() 结构完整
□ 服务调用有超时 wait_for()
□ 提醒 source install/setup.bash
□ colcon build 通过
```

---

*完整版 → AGENTS.md | 详细规范 → ANTI_PATTERNS.md*
