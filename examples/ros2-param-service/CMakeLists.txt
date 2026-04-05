cmake_minimum_required(VERSION 3.8)
project(ros2_param_service)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rcl_interfaces REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

add_library(param_node SHARED src/param_node.cpp)
ament_target_dependencies(param_node rclcpp rcl_interfaces std_msgs)
ament_export_dependencies(rclcpp)
ament_export_libraries(param_node)

install(TARGETS param_node RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION})
ament_package()
