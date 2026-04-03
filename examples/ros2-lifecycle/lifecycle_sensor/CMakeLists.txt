cmake_minimum_required(VERSION 3.16)
project(lifecycle_sensor)

if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)
endif()

# ── 1. 查找依赖 ───────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(std_msgs REQUIRED)
find_package(lifecycle_msgs REQUIRED)

# ── 2. 构建库 ────────────────────────────────
add_library(lifecycle_sensor SHARED
  src/lifecycle_sensor_node.cpp
)
ament_target_dependencies(lifecycle_sensor
  rclcpp
  rclcpp_lifecycle
  std_msgs
  lifecycle_msgs
)

# ── 3. 安装 ────────────────────────────────
install(TARGETS lifecycle_sensor
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib
)
install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}/
)

# ── 4. 测试 ────────────────────────────────
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
