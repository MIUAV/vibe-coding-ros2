cmake_minimum_required(VERSION 3.8)
project(wheeled_diff_drive)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ── 依赖 ──────────────────────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

# ── 组件库 ───────────────────────────────────────────
set(COMPONENTS
  diff_drive_controller
)

# 组件 1: diff_drive_controller
add_library(diff_drive_controller SHARED
  src/diff_drive_controller.cpp
)
ament_target_dependencies(diff_drive_controller
  rclcpp
  geometry_msgs
  nav_msgs
  std_msgs
)
ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(diff_drive_controller)

# ── 可执行节点（演示用）─────────────────────────────
add_executable(diff_drive_node src/diff_drive_controller.cpp)
ament_target_dependencies(diff_drive_node
  rclcpp
  geometry_msgs
  nav_msgs
  std_msgs
)

# ── 安装 ──────────────────────────────────────────────
install(TARGETS diff_drive_controller diff_drive_node
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
