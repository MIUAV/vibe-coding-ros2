cmake_minimum_required(VERSION 3.16)
project(ros2_lifecycle_demo)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  add_compile_options(-Wall -Wextra -Wpedantic -Wno-unused-parameter)
endif()

# ── 查找依赖 ──────────────────────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(lifecycle_msgs REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

include_directories(include)

# ── 构建库 ────────────────────────────────────────────────
add_library(lifecycle_demo SHARED
  src/lifecycle_controller_node.cpp
)

ament_target_dependencies(lifecycle_demo
  rclcpp
  rclcpp_lifecycle
  lifecycle_msgs
  std_msgs
  geometry_msgs
)

# ── 导出（三行必须同时存在）───────────────────────────────
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

# ── 安装 ──────────────────────────────────────────────────
install(TARGETS lifecycle_demo
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME})

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
