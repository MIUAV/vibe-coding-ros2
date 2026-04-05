// param_node.cpp
// 动态参数服务示例 — declare_parameter / add_on_set_parameters_callback
//
// 功能:
// 1. 声明多种类型参数 (int/double/string/bool)
// 2. 动态修改参数（运行时生效）
// 3. 参数改变回调

#include <memory>
#include <string>
#include <vector>
#include <rclcpp/rclcpp.hpp>
#include <rcl_interfaces/srv/set_parameters.hpp>
#include <rcl_interfaces/srv/get_parameters.hpp>
#include <std_msgs/msg/string.hpp>

using namespace std::chrono_literals;

class ParamNode : public rclcpp::Node {
public:
  ParamNode() : Node("param_node"), tick_(0)
  {
    // ── 声明参数 ───────────────────────────────
    // 声明时指定默认值，类型自动推断
    this->declare_parameter("int_param", 42);
    this->declare_parameter("double_param", 3.14);
    this->declare_parameter("string_param", "hello");
    this->declare_parameter("bool_param", true);
    this->declare_parameter("rate_hz", 10.0);  // Hz，动态可调

    // ── 参数改变回调 ───────────────────────────
    // 当参数被外部修改时，自动触发此回调
    callback_handle_ = this->add_on_set_parameters_callback(
      std::bind(&ParamNode::on_parameter_changed, this, std::placeholders::_1));

    // ── 读取初始值 ───────────────────────────
    double rate;
    this->get_parameter("rate_hz", rate);
    RCLCPP_INFO(this->get_logger(), "rate_hz=%.1f Hz (will adjust if changed)", rate);

    // ── 定时器 ───────────────────────────────
    // 注意：rate 参数改变后需要重建 timer 才能生效（这里演示用）
    timer_ = this->create_wall_timer(100ms, std::bind(&ParamNode::tick, this));

    RCLCPP_INFO(this->get_logger(), "ParamNode started. Use: ros2 param set /param_node rate_hz 5.0");
  }

private:
  /**
   * 参数改变回调 — 验证参数合法性
   */
  rcl_interfaces::msg::SetParametersResult on_parameter_changed(
    const std::vector<rclcpp::Parameter>& params)
  {
    rcl_interfaces::msg::SetParametersResult result;
    result.successful = true;

    for (const auto& param : params) {
      if (param.get_name() == "rate_hz") {
        double rate = param.as_double();
        if (rate <= 0 || rate > 1000) {
          result.successful = false;
          result.reason = "rate_hz must be in (0, 1000]";
          RCLCPP_WARN(this->get_logger(), "Rejected rate_hz=%.1f (out of range)", rate);
          return result;
        }
        RCLCPP_INFO(this->get_logger(), "rate_hz changed to %.1f Hz", rate);
      }
      else if (param.get_name() == "string_param") {
        RCLCPP_INFO(this->get_logger(), "string_param changed to: '%s'",
                    param.as_string().c_str());
      }
    }
    return result;
  }

  void tick() {
    if (++tick_ % 100 == 0) {
      int i; double d; bool b; std::string s;
      this->get_parameter("int_param", i);
      this->get_parameter("double_param", d);
      this->get_parameter("bool_param", b);
      this->get_parameter("string_param", s);
      RCLCPP_INFO_THROTTLE(this->get_logger(), *this->get_clock(), 2000,
        "tick=%d | int=%d double=%.2f bool=%d str='%s'",
        tick_, i, d, b, s.c_str());
    }
  }

  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr callback_handle_;
  int tick_;
};

int main(int argc, char* argv[]) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ParamNode>());
  rclcpp::shutdown();
  return 0;
}
