cmake_minimum_required(VERSION 3.8)
project(diff_drive_controller)

if(CMAKE_CXX_STANDARD LESS 17)
  set(CMAKE_CXX_STANDARD 17)
endif()

if(NOT CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

ament_auto_find_build_dependencies()

ament_auto_add_library(${PROJECT_NAME} SHARED src/diff_drive_controller.cpp)

install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)

install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

ament_auto_package()
