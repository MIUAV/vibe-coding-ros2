cmake_minimum_required(VERSION 3.16)
project(diff_drive_controller)

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

# ── 1. 查找依赖 ───────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(tf2_ros REQUIRED)

# ── 2. 构建库 ────────────────────────────────
add_library(diff_drive SHARED
  src/diff_drive_controller.cpp
)
ament_target_dependencies(diff_drive
  rclcpp
  geometry_msgs
  nav_msgs
  tf2_ros
)

# ── 3. 安装 ────────────────────────────────
install(TARGETS diff_drive
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib
)
install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}/
)

# ── 4. 测试 ────────────────────────────────
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
