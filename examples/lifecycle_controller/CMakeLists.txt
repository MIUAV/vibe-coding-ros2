cmake_minimum_required(VERSION 3.8)
project(lifecycle_controller)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# ── 依赖 ──────────────────────────────────────────────
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_components REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(lifecycle_msgs REQUIRED)
find_package(rcl_interfaces REQUIRED)
find_package(std_msgs REQUIRED)

include_directories(include)

# ── 源文件 ───────────────────────────────────────────
set(NODE_SOURCES
  src/lifecycle_controller_node.cpp
)

add_library(${PROJECT_NAME} SHARED ${NODE_SOURCES})

# ── 依赖链（必须同时有这三行）─────────────────────────
ament_target_dependencies(${PROJECT_NAME}
  rclcpp
  rclcpp_lifecycle
  lifecycle_msgs
  rcl_interfaces
  std_msgs
)

ament_export_dependencies(rclcpp)
ament_export_include_directories(include)
ament_export_libraries(${PROJECT_NAME})

# ── 安装 ──────────────────────────────────────────────
install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
