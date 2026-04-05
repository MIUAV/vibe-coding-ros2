// component_loader_main.cpp
// Component Loader — 使用 ComponentManager 动态加载 composable nodes
//
// 运行方式:
//   ros2 run ros2_composable_node component_loader
//
// 然后在另一个终端:
//   ros2 component load /ComponentManager ros2_composable_node::PublisherComponent

#include <rclcpp/rclcpp.hpp>
#include <rclcpp_components/component_manager.hpp>

int main(int argc, char* argv[])
{
  rclcpp::init(argc, argv);

  // ComponentManager 负责动态加载和管理 composable nodes
  auto executor = std::make_shared<rclcpp::executors::SingleThreadedExecutor>();
  auto component_manager = std::make_shared<rclcpp_components::ComponentManager>(executor);

  executor->add_node(component_manager);
  executor->spin();

  rclcpp::shutdown();
  return 0;
}
