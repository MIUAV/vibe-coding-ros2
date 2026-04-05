cmake_minimum_required(VERSION 3.8)
project(ros2_tf2)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

add_library(tf2_broadcaster SHARED src/tf2_broadcaster.cpp)
ament_target_dependencies(tf2_broadcaster rclcpp tf2 tf2_ros geometry_msgs)
ament_export_dependencies(rclcpp)
ament_export_libraries(tf2_broadcaster)

install(TARGETS tf2_broadcaster
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)
ament_package()
