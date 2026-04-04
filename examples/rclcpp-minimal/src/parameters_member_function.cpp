// parameters_member_function.cpp
// 参数节点 - 演示 rclcpp 参数服务用法

#include <memory>

#include <rclcpp/rclcpp.hpp>
#include <std_msgs/msg/string.hpp>

class ParametersNode : public rclcpp::Node
{
public:
  ParametersNode()
    : Node("parameters_node"),
      // 声明参数并设置默认值
      publish_frequency_(this->declare_parameter("publish_frequency", 1.0)),
      robot_name_(this->declare_parameter("robot_name", std::string("default_robot"))),
      enable_debug_(this->declare_parameter("enable_debug", false))
  {
    // 参数变更回调（参数修改后自动触发）
    // 注意: set_on_parameters_set_callback 需要返回 rcl_interfaces::msg::SetParametersResult
    param_callback_handle_ = this->add_on_set_parameters_callback(
      [this](const std::vector<rclcpp::Parameter> & params) {
        rcl_interfaces::msg::SetParametersResult result;
        result.successful = true;
        for (const auto & param : params) {
          if (param.get_name() == "publish_frequency") {
            publish_frequency_ = param.as_double();
            RCLCPP_INFO(this->get_logger(), "publish_frequency 更新为: %.2f", publish_frequency_);
          } else if (param.get_name() == "robot_name") {
            robot_name_ = param.as_string();
            RCLCPP_INFO(this->get_logger(), "robot_name 更新为: %s", robot_name_.c_str());
          }
        }
        return result;
      });

    RCLCPP_INFO(this->get_logger(), "ParametersNode 启动，参数:");
    RCLCPP_INFO(this->get_logger(), "  robot_name: %s", robot_name_.c_str());
    RCLCPP_INFO(this->get_logger(), "  publish_frequency: %.2f Hz", publish_frequency_);
    RCLCPP_INFO(this->get_logger(), "  enable_debug: %s", enable_debug_ ? "true" : "false");

    // 使用 get_parameter 获取当前值
    rclcpp::Parameter robot_param;
    if (this->get_parameter("robot_name", robot_param)) {
      RCLCPP_INFO(this->get_logger(), "通过 get_parameter 获取: %s",
        robot_param.as_string().c_str());
    }
  }

private:
  double publish_frequency_;
  std::string robot_name_;
  bool enable_debug_;
  rclcpp::node_interfaces::OnSetParametersCallbackHandle::SharedPtr param_callback_handle_;
};

int main(int argc, char * argv[])
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<ParametersNode>());
  rclcpp::shutdown();
  return 0;
}
