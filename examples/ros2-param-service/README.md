# ros2-param-service — 动态参数服务示例

> 演示 `declare_parameter` + `add_on_set_parameters_callback` 动态修改运行时参数。

## 编译

```bash
colcon build --packages-select ros2_param_service
source install/setup.bash
```

## 运行

```bash
ros2 run ros2_param_service param_node
```

## 动态修改参数

```bash
# 查看参数列表
ros2 param list /param_node

# 查看参数值
ros2 param get /param_node rate_hz

# 设置参数（立即生效，自动验证）
ros2 param set /param_node rate_hz 20.0

# 设置其他类型参数
ros2 param set /param_node string_param "new_value"
ros2 param set /param_node bool_param false

# 导出所有参数
ros2 param dump /param_node

# 从文件加载参数
ros2 param load /param_node /path/to/params.yaml
```

## 参数类型

| 类型 | 示例 | 获取方法 |
|------|------|---------|
| int | `42` | `get_parameter("x", i)` |
| double | `3.14` | `get_parameter("x", d)` |
| string | `"hello"` | `get_parameter("x", s)` |
| bool | `true` | `get_parameter("x", b)` |
| byte[] | `[0x01, 0x02]` | `get_parameter("x", v)` |

## 关键代码

```cpp
// 声明参数（带默认值）
this->declare_parameter("rate_hz", 10.0);

// 参数改变回调（自动验证）
callback_handle_ = this->add_on_set_parameters_callback(
  [](const std::vector<rclcpp::Parameter>& params) {
    rcl_interfaces::msg::SetParametersResult result;
    result.successful = true;
    for (const auto& param : params) {
      if (param.get_name() == "rate_hz" && param.as_double() <= 0) {
        result.successful = false;
        result.reason = "rate_hz must be positive";
      }
    }
    return result;
  }
);

// 读取参数
double rate;
this->get_parameter("rate_hz", rate);
```

## 禁止的写法

```cpp
// ❌ 禁止：参数名硬编码
if (param.name == "rate_hz")  // 容易拼写错误

// ✅ 正确：声明和读取都用 declare_parameter / get_parameter
```
