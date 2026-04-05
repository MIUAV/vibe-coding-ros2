cmake_minimum_required(VERSION 3.8)
project(ros2_imu_sensor)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2_ros REQUIRED)

include_directories(include)

add_library(imu_sensor_node SHARED src/imu_sensor_node.cpp)
ament_target_dependencies(imu_sensor_node rclcpp sensor_msgs geometry_msgs tf2_ros)
ament_export_dependencies(rclcpp)
ament_export_libraries(imu_sensor_node)

install(TARGETS imu_sensor_node
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)
ament_package()
