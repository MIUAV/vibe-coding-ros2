cmake_minimum_required(VERSION 3.16)
project(add_two_ints)

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
find_package(example_interfaces REQUIRED)
find_package(rosidl_default_generators REQUIRED)

# ── 2. rosidl: .srv 接口 ─────────────────────
rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/AddTwoInts.srv"
  DEPENDENCIES example_interfaces
)

# ── 3. 构建服务端可执行文件 ─────────────────────
add_executable(add_two_ints_server
  src/add_two_ints_server.cpp
)
ament_target_dependencies(add_two_ints_server
  rclcpp
  example_interfaces
)

# ── 4. 构建客户端可执行文件 ─────────────────────
add_executable(add_two_ints_client
  src/add_two_ints_client.cpp
)
ament_target_dependencies(add_two_ints_client
  rclcpp
  example_interfaces
)

# ── 5. 安装 ────────────────────────────────
install(TARGETS add_two_ints_server add_two_ints_client
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)
install(DIRECTORY launch srv
  DESTINATION share/${PROJECT_NAME}/
)

# ── 6. 测试 ────────────────────────────────
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_cmake_files()
endif()

ament_package()
