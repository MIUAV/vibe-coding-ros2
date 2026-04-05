cmake_minimum_required(VERSION 3.8)
project(ros2_service_server)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(example_interfaces REQUIRED)

include_directories(include)

add_library(add_two_ints_server SHARED
  src/add_two_ints_server.cpp
)

ament_target_dependencies(add_two_ints_server
  rclcpp
  example_interfaces
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(add_two_ints_server)

install(TARGETS add_two_ints_server
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

ament_package()
