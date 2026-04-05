cmake_minimum_required(VERSION 3.8)
project(ros2_composable_node)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(std_msgs REQUIRED)
find_package(example_interfaces REQUIRED)

include_directories(include)

# ── Component Library ────────────────────────────────────────────
# Composable nodes must be compiled as SHARED libraries to be loadable
add_library(${PROJECT_NAME} SHARED
  src/publisher_component.cpp
)

rclcpp_components_register_node(
  ${PROJECT_NAME}
  PLUGINLIB_EXPORT_NODE ros2_composable_node::PublisherComponent
  NODE_NAMESPACE ""
  PACKAGE_NAME ${PROJECT_NAME}
)

ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  std_msgs
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

# ── Component Loader (Executable) ─────────────────────────────────
# This executable uses ComponentManager to load composable nodes at runtime
add_executable(component_loader
  src/component_loader_main.cpp
)
ament_target_dependencies(component_loader
  rclcpp
  rclcpp_components
  std_msgs
)

install(TARGETS ${PROJECT_NAME} component_loader
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
