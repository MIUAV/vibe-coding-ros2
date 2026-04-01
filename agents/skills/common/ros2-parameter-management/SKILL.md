---
name: ros2-parameter-management
description: ROS2 参数管理技能 - 参数声明、获取、设置、类型验证、动态参数
user-invocable: true
argument-hint: "参数管理" / "ros2 param" / "动态参数" / "parameter" / "参数配置"
---

# ROS2 Parameter Management Skill

> ROS2 参数系统完整指南

---

## 何时使用

当需要以下帮助时使用此技能：
- 声明和使用节点参数
- 从 YAML 文件加载参数
- 实现动态参数更新
- 参数类型验证和约束
- 参数变化回调处理

---

## 快速参考

### 参数类型支持

| 类型 | C++ | Python |
|------|-----|--------|
| int | int | int |
| double | double | float |
| string | std::string | str |
| bool | bool | bool |
| byte[] | std::vector<uint8_t> | bytes |
| int[] | std::vector<int> | List[int] |
| double[] | std::vector<double> | List[float] |
| string[] | std::vector<std::string> | List[str] |

---

## C++ 参数使用

### 基础参数声明

```cpp
#include <rclcpp/rclcpp.hpp>

class MyNode : public rclcpp::Node {
public:
    MyNode() : Node("my_node") {
        // 声明参数（带默认值）
        this->declare_parameter<int>("robot_id", 1);
        this->declare_parameter<double>("speed", 1.0);
        this->declare_parameter<std::string>("frame_id", "base_link");
        this->declare_parameter<bool>("enable", true);
        
        // 获取参数
        int robot_id = this->get_parameter("robot_id").as_int();
        
        // 获取多个参数
        auto params = this->get_parameters({"robot_id", "speed", "frame_id"});
    }

    void update_params() {
        // 获取参数（带默认值）
        double speed = this->get_parameter_or("speed", 1.0);
        
        // 检查参数是否存在
        if (this->has_parameter("robot_id")) {
            // 参数存在
        }
    }
};
```

### 参数变化监听

```cpp
class ParamNode : public rclcpp::Node {
public:
    ParamNode() : Node("param_node") {
        // 声明参数
        this->declare_parameter<double>("rate", 10.0);
        
        // 添加参数变化回调
        param_callback_handle_ = this->add_on_set_parameters_callback(
            [this](const std::vector<rclcpp::Parameter> &params) 
                -> rcl_interfaces::msg::SetParametersResult {
                
                for (const auto& param : params) {
                    if (param.get_name() == "rate") {
                        if (param.as_double() <= 0) {
                            auto result = rcl_interfaces::msg::SetParametersResult();
                            result.successful = false;
                            result.reason = "rate must be positive";
                            return result;
                        }
                        RCLCPP_INFO(this->get_logger(), "Rate changed to %f", 
                            param.as_double());
                    }
                }
                
                auto result = rcl_interfaces::msg::SetParametersResult();
                result.successful = true;
                return result;
            });
    }

private:
    rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr 
        param_callback_handle_;
};
```

---

## Python 参数使用

### 基础参数声明

```python
import rclpy
from rclpy.node import Node

class MyNode(Node):
    def __init__(self):
        super().__init__('my_node')
        
        # 声明参数
        self.declare_parameter('robot_id', 1)
        self.declare_parameter('speed', 1.0)
        self.declare_parameter('frame_id', 'base_link')
        self.declare_parameter('enable', True)
        
        # 获取参数
        robot_id = self.get_parameter('robot_id').value
        
        # 获取多个参数
        params = self.get_parameters(['robot_id', 'speed'])
    
    def update_params(self):
        # 使用默认值获取
        speed = self.get_parameter_or('speed', 1.0).value
        
        # 检查参数存在
        if self.has_parameter('robot_id'):
            pass
```

### 动态参数更新

```python
class ParamNode(Node):
    def __init__(self):
        super().__init__('param_node')
        
        self.declare_parameter('rate', 10.0)
        
        # 添加参数变化回调
        self.add_on_set_parameters_callback(self.param_callback)
    
    def param_callback(self, params):
        for param in params:
            self.get_logger().info(f'Param changed: {param.name} = {param.value}')
        return SetParametersResult(successful=True)
```

---

## YAML 配置文件

### 参数文件示例

```yaml
# params.yaml
my_node:
  ros__parameters:
    robot_id: 1
    speed: 1.0
    frame_id: "base_link"
    enable: true
    rates:
      publish_rate: 10.0
      update_rate: 20.0
    topics:
      input: "/camera/image"
      output: "/detection/result"
    colors: [1.0, 0.5, 0.2]
```

### Launch 中加载参数

```python
# launch my_node.launch.py
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.parameters import load_yaml

def generate_launch_description():
    params_file = LaunchConfiguration('params_file')
    
    return LaunchDescription([
        DeclareLaunchArgument(
            'params_file',
            default_value=os.path.join(pkg_dir, 'config', 'params.yaml'),
        ),
        
        Node(
            package='my_package',
            executable='my_node',
            parameters=[params_file],
            output='screen',
        ),
    ])
```

### 命令行指定参数

```bash
# 命令行覆盖参数
ros2 run my_package my_node --ros-args -p robot_id:=2 -p speed:=2.0
```

---

## 命令行工具

```bash
# 列出节点参数
ros2 param list /node_name

# 获取参数值
ros2 param get /node_name rate

# 设置参数值
ros2 param set /node_name rate 20.0

# 导出参数
ros2 param dump /node_name > params.yaml

# 加载参数
ros2 param load /node_name params.yaml
```

---

## 最佳实践

1. **默认值**: 总是提供合理的默认值
2. **类型验证**: 在回调中验证参数范围
3. **日志记录**: 参数变化时记录日志
4. **文档**: 在代码中注释参数含义
5. **持久化**: 使用 YAML 文件持久化配置