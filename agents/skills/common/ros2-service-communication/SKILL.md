---
name: ros2-service-communication
description: ROS2 Service 通讯技能 - 服务端/客户端实现、同步/异步调用、常见服务类型
user-invocable: true
argument-hint: "创建 service" / "ros2 service" / "服务端客户端" / "server client"
---

# ROS2 Service Communication Skill

> ROS2 Service 服务通讯完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建服务服务端节点
- 实现服务客户端调用
- 处理同步/异步服务调用
- 定义自定义服务类型
- 处理服务超时和错误

---

## 快速参考

### 基础架构

```
Client (客户端)  ──[Request]──>  Server (服务端)
       <──[Response]──
```

### 服务类型示例

```bash
# 内置服务
/reset_positions          # 关节复位
/set_light_state          # 设置灯光
/get_map                  # 获取地图

# 自定义服务
/robot_control/ExecuteTrajectory
/navigation/SetGoal
```

---

## C++ 服务端

### 基本服务端

```cpp
#include <rclcpp/rclcpp.hpp>
#include <std_srvs/srv/set_bool.hpp>

class ServerNode : public rclcpp::Node {
public:
    ServerNode() : Node("server_node") {
        // 创建服务服务端
        server_ = this->create_service<std_srvs::srv::SetBool>(
            "/enable",
            [this](const std::shared_ptr<rmw_request_id_t> request_id,
                   const std::shared_ptr<std_srvs::srv::SetBool::Request> request,
                   const std::shared_ptr<std_srvs::srv::SetBool::Response> response) {
                RCLCPP_INFO(this->get_logger(), "Received request: %s", 
                    request->data ? "true" : "false");
                response->success = true;
                response->message = "Processed successfully";
            });
        
        RCLCPP_INFO(this->get_logger(), "Service server ready");
    }

private:
    rclcpp::Service<std_srvs::srv::SetBool>::SharedPtr server_;
};
```

### 带状态的服务端

```cpp
class StatefulServerNode : public rclcpp::Node {
public:
    StatefulServerNode() : Node("stateful_server"), enabled_(false) {
        server_ = this->create_service<std_srvs::srv::SetBool>(
            "/set_state",
            [this](const auto& request, auto& response) {
                enabled_ = request->data;
                response->success = true;
                response->message = enabled_ ? "Enabled" : "Disabled";
                RCLCPP_INFO(this->get_logger(), "State: %s", 
                    enabled_ ? "enabled" : "disabled");
            });
    }

private:
    bool enabled_;
    rclcpp::Service<std_srvs::srv::SetBool>::SharedPtr server_;
};
```

---

## C++ 客户端

### 同步调用

```cpp
class SyncClientNode : public rclcpp::Node {
public:
    SyncClientNode() : Node("sync_client") {
        client_ = this->create_client<std_srvs::srv::SetBool>("/enable");
        
        // 等待服务可用
        while (!client_->wait_for_service(1s)) {
            if (!rclcpp::ok()) {
                RCLCPP_ERROR(this->get_logger(), "Interrupted");
                return;
            }
            RCLCPP_INFO(this->get_logger(), "Waiting for service...");
        }
        
        // 发送请求
        auto request = std::make_shared<std_srvs::srv::SetBool::Request>();
        request->data = true;
        
        auto future = client_->async_send_request(request);
        
        // 等待响应
        if (rclcpp::spin_until_future_complete(this->get_node_base_interface(), 
                                               future) == rclcpp::FutureReturnCode::SUCCESS) {
            auto response = future.get();
            RCLCPP_INFO(this->get_logger(), "Response: %s, %s",
                response->success ? "success" : "failed",
                response->message.c_str());
        } else {
            RCLCPP_ERROR(this->get_logger(), "Service call failed");
        }
    }

private:
    rclcpp::Client<std_srvs::srv::SetBool>::SharedPtr client_;
};
```

### 异步回调

```cpp
class AsyncClientNode : public rclcpp::Node {
public:
    AsyncClientNode() : Node("async_client") {
        client_ = this->create_client<std_srvs::srv::SetBool>("/enable");
        
        auto request = std::make_shared<std_srvs::srv::SetBool::Request>();
        request->data = true;
        
        client_->async_send_request(
            request,
            [this](rclcpp::Client<std_srvs::srv::SetBool>::SharedFuture future) {
                auto response = future.get();
                RCLCPP_INFO(this->get_logger(), "Async response: %s",
                    response->message.c_str());
            });
    }

private:
    rclcpp::Client<std_srvs::srv::SetBool>::SharedPtr client_;
};
```

---

## Python 实现

### 服务端

```python
import rclpy
from rclpy.node import Node
from std_srvs.srv import SetBool

class ServerNode(Node):
    def __init__(self):
        super().__init__('server_node')
        self.srv = self.create_service(SetBool, '/enable', self.callback)
    
    def callback(self, request, response):
        self.get_logger().info(f'Request: {request.data}')
        response.success = True
        response.message = 'Processed'
        return response
```

### 客户端

```python
class ClientNode(Node):
    def __init__(self):
        super().__init__('client_node')
        self.cli = self.create_client(SetBool, '/enable')
        self.req = SetBool.Request()
        self.req.data = True
        
        while not self.cli.wait_for_service(timeout=1.0):
            self.get_logger().info('Waiting...')
        
        self.future = self.cli.call_async(self.req)
    
    def timer_callback(self):
        if self.future.done():
            try:
                response = self.future.result()
                self.get_logger().info(f'Response: {response.message}')
            except Exception as e:
                self.get_logger().error(f'Service call failed: {e}')
```

---

## 服务类型定义

### 自定义服务文件

```yaml
# my_service.srv
---
# Response (响应)
bool success           # 是否成功
string message         # 消息
string[] data          # 返回的数据列表
---
# Request (请求) - 放在上面
bool enable            # 启用标志
string mode            # 运行模式
float64 timeout        # 超时时间
```

### CMakeLists.txt 配置

```cmake
find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/MyService.srv"
  "msg/MyMessage.msg"
)

# 依赖其他包
rosidl_get_typesupport_target(pkg_config ${PROJECT_NAME} 
  ${FOO_PACKAGE} "rosidl_typesupport_cpp")
```

### package.xml 依赖

```xml
<depend>rosidl_default_generators</depend>
<member_of_group>rosidl_interface_packages</member_of_group>
```

---

## 高级模式

### 异步多客户端

```cpp
class MultiClientNode : public rclcpp::Node {
public:
    MultiClientNode() : Node("multi_client") {
        // 创建多个服务客户端
        clients_["robot1"] = this->create_client<MyService>("/robot1/do_action");
        clients_["robot2"] = this->create_client<MyService>("/robot2/do_action");
        
        // 并发调用
        for (auto& [name, client] : clients_) {
            auto request = std::make_shared<MyService::Request>();
            request->task = "execute";
            
            client->async_send_request(request,
                [name](auto future) {
                    RCLCPP_INFO(rclcpp::get_logger("multi_client"), 
                        "%s: %s", name.c_str(), 
                        future.get()->result.c_str());
                });
        }
    }
    
private:
    std::map<std::string, rclcpp::Client<MyService>::SharedPtr> clients_;
};
```

### 定期服务调用

```cpp
class PeriodicClientNode : public rclcpp::Node {
public:
    PeriodicClientNode() : Node("periodic_client") {
        client_ = this->create_client<std_srvs::srv::SetBool>("/status");
        
        timer_ = this->create_wall_timer(5s, [this]() {
            auto request = std::make_shared<std_srvs::srv::SetBool::Request>();
            request->data = true;
            
            auto future = client_->async_send_request(request);
            rclcpp::sleep_for(100ms);  // 简短等待
            
            if (future.valid()) {
                auto response = future.get();
                // 处理响应
            }
        });
    }
    
private:
    rclcpp::Client<std_srvs::srv::SetBool>::SharedPtr client_;
    rclcpp::TimerBase::SharedPtr timer_;
};
```

### 服务链

```cpp
class ServiceChainNode : public rclcpp::Node {
public:
    ServiceChainNode() : Node("service_chain") {
        sub_ = this->create_subscription<std_msgs::msg::String>(
            "/input", 10, [this](const auto& msg) {
                call_service_a(msg->data);
            });
        
        client_a_ = this->create_client<MyService>("/service_a");
        client_b_ = this->create_client<MyService>("/service_b");
    }
    
    void call_service_a(const std::string& data) {
        auto req = std::make_shared<MyService::Request>();
        req->input = data;
        
        client_a_->async_send_request(req,
            [this](auto future) {
                auto response = future.get();
                if (response->success) {
                    call_service_b(response->output);
                }
            });
    }
    
    void call_service_b(const std::string& data) {
        auto req = std::make_shared<MyService::Request>();
        req->input = data;
        
        client_b_->async_send_request(req,
            [](auto future) {
                // 处理最终响应
            });
    }
};
```

---

## 命令行工具

```bash
# 列出服务
ros2 service list

# 查看服务类型
ros2 service type /service_name

# 调用服务
ros2 service call /enable std_srvs/srv/SetBool "{data: true}"

# 查找服务提供者
ros2 service find std_srvs/srv/SetBool
```

---

## 常见问题排查

### 服务不可用

```bash
# 检查服务列表
ros2 service list

# 检查节点
ros2 node list
ros2 node info /node_name

# 等待服务
ros2 service call /service std_srvs/srv/SetBool "{data: true}"
```

### 调用失败

```bash
# 使用 --help 查看详细用法
ros2 service call --help

# 调试输出
ros2 service call /enable std_srvs/srv/SetBool "{data: true}" -v
```

---

## 最佳实践

1. **超时处理**: 总是设置合理的超时时间
2. **错误处理**: 检查响应状态和错误消息
3. **服务发现**: 等待服务可用后再调用
4. **资源清理**: 正确管理客户端生命周期
5. **命名规范**: 使用清晰的服务名，如 `/robot/arm/move_to`