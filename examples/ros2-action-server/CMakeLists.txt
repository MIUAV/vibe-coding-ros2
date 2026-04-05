cmake_minimum_required(VERSION 3.8)
project(ros2_action_server)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(example_interfaces REQUIRED)

include_directories(include)

add_library(fibonacci_action_server SHARED
  src/fibonacci_action_server.cpp
)

ament_target_dependencies(fibonacci_action_server
  rclcpp
  rclcpp_action
  example_interfaces
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(fibonacci_action_server)

install(TARGETS fibonacci_action_server
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
