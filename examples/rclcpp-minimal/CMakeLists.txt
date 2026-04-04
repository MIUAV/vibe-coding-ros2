cmake_minimum_required(VERSION 3.8)
project(rclcpp_minimal)

if(CMAKE_CXX_STANDARD LESS 17)
  set(CMAKE_CXX_STANDARD 17)
endif()
if(NOT CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# ── 依赖声明（必须先声明才能使用）───────────
ament_auto_find_build_dependencies()

# ── 编译节点 ──────────────────────────────────
ament_auto_add_library(${PROJECT_NAME}_publisher SHARED src/publisher_member_function.cpp)
ament_auto_add_library(${PROJECT_NAME}_subscriber SHARED src/subscription_member_function.cpp)
ament_auto_add_library(${PROJECT_NAME}_timer SHARED src/timer_member_function.cpp)
ament_auto_add_library(${PROJECT_NAME}_parameters SHARED src/parameters_member_function.cpp)
ament_auto_add_library(${PROJECT_NAME}_lifecycle SHARED src/lifecycle_node.cpp)

# ── 可执行文件 ─────────────────────────────────
ament_auto_add_executable(demo_publisher src/publisher_member_function.cpp)
ament_auto_add_executable(demo_subscriber src/subscription_member_function.cpp)
ament_auto_add_executable(demo_timer src/timer_member_function.cpp)
ament_auto_add_executable(demo_parameters src/parameters_member_function.cpp)
ament_auto_add_executable(demo_lifecycle src/lifecycle_node.cpp)

# ── 安装 ──────────────────────────────────────
install(TARGETS
  demo_publisher demo_subscriber demo_timer demo_parameters demo_lifecycle
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_auto_package()
