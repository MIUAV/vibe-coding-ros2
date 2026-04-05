cmake_minimum_required(VERSION 3.16)
project(ros2_action_demo)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_action REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(example_interfaces REQUIRED)

add_library(action_demo SHARED src/fibonacci_action_server.cpp)
ament_target_dependencies(action_demo rclcpp rclcpp_action example_interfaces)
ament_export_dependencies(rclcpp_action)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

install(TARGETS action_demo
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib)
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()
ament_package()
