# ros2-test-templates — ROS2 节点测试模板库

> 配合 vibe-coding 使用。先写测试，再让 AI 生成满足测试的代码（TDD 辅助）。

## 模板列表

| 模板 | 用途 |
|------|------|
| `src/publisher_test.cpp` | 发布者节点测试 |
| `src/subscriber_test.cpp` | 订阅者节点测试 |
| `src/service_test.cpp` | 服务节点测试 |
| `src/action_test.cpp` | Action 节点测试 |
| `test/test_node.cpp` | gtest 单元测试 |
| `launch/test.launch.py` | launch 测试 |

## TDD 工作流

```
1. 编写测试用例（期望输出）
2. 运行测试 → 失败（预期）
3. AI 生成代码满足测试
4. 测试通过 → 代码合格
5. 再次运行测试验证
```

## 示例：publisher 测试

```cpp
// test_publisher.cpp
#include <gtest/gtest.h>
#include <std_msgs/msg/string.hpp>
#include <rclcpp/rclcpp.hpp>

TEST(TestPublisher, publishes_message)
{
  auto node = std::make_shared<MinimalPublisher>();
  
  // 期望：发布 5 条消息
  std::atomic<int> count{0};
  auto sub = node->create_subscription<std_msgs::msg::String>(
    "topic", 10,
    [&](const std_msgs::msg::String::SharedPtr) { count++; });
  
  rclcpp::spin_some(node);
  EXPECT_EQ(count, 5);
}
```

## 使用方法

```bash
# 将测试模板复制到你的包
cp -r scripts/test-templates/test/* my_package/test/

# 在 CMakeLists.txt 添加
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  add_test(NAME test_node COMMAND test_node)
endif()
```
