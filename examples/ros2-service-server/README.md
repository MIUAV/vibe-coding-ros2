# ros2-service-server — Service Server 示例

> 演示 ROS2 Service 的同步调用模式。

## 编译

```bash
colcon build --packages-select ros2_service_server
source install/setup.bash
```

## 运行

```bash
# 启动 Service Server
ros2 run ros2_service_server add_two_ints_server

# 客户端调用
ros2 service call /add_two_ints example_interfaces/srv/AddTwoInts "{a: 3, b: 5}"
```

## Service vs Topic vs Action

| 特性 | Service | Topic | Action |
|------|---------|-------|--------|
| 模式 | 请求/响应 | 发布/订阅 | Goal/Feedback/Result |
| 延迟 | 同步等待 | 异步 | 异步 |
| 适用 | 查询/命令 | 持续数据流 | 长时间任务 |
| 取消 | 不支持 | 不支持 | 支持 |

## 关键代码

```cpp
// 创建 Service Server
service_ = this->create_service<AddTwoInts>(
  "add_two_ints",
  [](auto req, auto res) {
    res->sum = req->a + req->b;
  }
);

// 同步调用 Service（客户端）
auto client = this->create_client<AddTwoInts>("add_two_ints");
auto result = client->async_call(request);  // 异步
```
