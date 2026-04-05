# TDD-for-ROS2 — 测试驱动开发辅助指南

> 先写测试，再让 AI 生成满足测试的代码。测试即规格，规格即合同。

---

## TDD 工作流

```
1. 写测试（期望输出）→ 失败（预期）
2. AI 生成代码满足测试
3. 测试通过 → 代码合格
4. 再次运行测试验证
```

---

## 测试分层

| 层级 | 工具 | 内容 |
|------|------|------|
| 单元测试 | gtest | 单节点功能 |
| 集成测试 | launch_testing | 多节点通信 |
| 仿真测试 | Gazebo/Ignition | 硬件行为 |
| 硬件测试 | 实体机器人 | 最终验证 |

---

## 常用测试模板

### 1. Publisher 测试

```cpp
// 验证：发布频率、消息内容、QoS 兼容
auto pub = node->create_publisher<sensor_msgs::msg::Image>("/image", 10);
auto sub = node->create_subscription<sensor_msgs::msg::Image>("/image", 10,
  [&](auto) { count++; });

pub->publish(test_msg);
rclcpp::sleep_for(100ms);
rclcpp::spin_some(node);
EXPECT_EQ(count, 1);
```

### 2. Lifecycle 测试

```cpp
// 验证：状态转换顺序、on_configure 不阻塞
node->trigger_transition(TRANSITION_CONFIGURE);
EXPECT_EQ(node->get_current_state().label(), "inactive");
node->trigger_transition(TRANSITION_ACTIVATE);
EXPECT_EQ(node->get_current_state().label(), "active");
```

### 3. Service 测试

```cpp
// 验证：服务调用返回正确结果
auto client = node->create_client<AddTwoInts>("/add");
auto request = std::make_shared<AddTwoInts::Request>();
request->a = 3; request->b = 5;
auto result = client->async_send_request(request);
EXPECT_TRUE(rclcpp::spin_until_future_complete(node, result, 1s));
EXPECT_EQ(result.get()->sum, 8);
```

### 4. 参数测试

```cpp
// 验证：参数改变回调触发
node->declare_parameter("rate", 10.0);
node->set_parameter(rclcpp::Parameter("rate", 20.0));
EXPECT_EQ(new_rate, 20.0);  // 回调中验证
```

---

## 性能测试

```cpp
// 验证：发布频率不低
auto start = node->now();
while (count < 100) { rclcpp::spin_some(node); }
auto elapsed = (node->now() - start).seconds();
auto actual_hz = 100 / elapsed;
EXPECT_GE(actual_hz, 9.0);  // 允许 10% 误差
```

## 内存泄漏检测

```cpp
// valgrind 集成
// valgrind --leak-check=full --error-exitcode=1 ./test_node
EXPECT_EQ(0, system("valgrind --leak-check=full ./test_node"));
```

## 测试命令

```bash
# 运行单元测试
colcon test --packages-select <pkg> --event-handlers console_direct+

# 查看测试结果
colcon test-result --verbose

# 只运行指定测试
ctest -R test_publisher
```
