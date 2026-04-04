---
name: ros2-cmake-guard
description: ROS2 CMakeLists.txt 依赖检查规则库 - 禁止省略ament_export_dependencies、禁止裸消息类型、禁止find_package不写REQUIRED
argument-hint: CMakeLists.txt OR find_package OR ament_export OR ROS2编译错误 OR link依赖
user-invocable: true
---

# ROS2 CMake 依赖检查规则

> AI 生成 CMakeLists.txt 时必须逐项确认的强制规则库

---

## 一、绝对禁区（违反必出错）

### 1. 禁止省略 `ament_export_dependencies()`

```cmake
# 错误 ❌
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
ament_target_dependencies(my_node rclcpp std_msgs)
# 传递依赖链断在这里，运行时找不到符号

# 正确 ✅
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
ament_export_dependencies(rclcpp std_msgs)
ament_target_dependencies(my_node rclcpp std_msgs)
# 或使用 ament_auto（推荐）
ament_auto_find_build_dependencies()
ament_auto_add_library(${PROJECT_NAME} SHARED src/my_node.cpp)
```

### 2. 禁止 `find_package` 不写 `REQUIRED`

```cmake
# 错误 ❌
find_package(rclcpp)           # 静默失败，依赖可能缺失
find_package(std_msgs)         # 同上

# 正确 ✅
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
```

### 3. 禁止 link 未 `find_package` 的库

```cmake
# 错误 ❌
find_package(rclcpp REQUIRED)
ament_target_dependencies(my_node rclcpp cv_bridge)  # cv_bridge 未 find_package

# 正确 ✅
find_package(rclcpp REQUIRED)
find_package(cv_bridge REQUIRED)
ament_export_dependencies(rclcpp cv_bridge)
ament_target_dependencies(my_node rclcpp cv_bridge)
```

### 4. 禁止裸消息类型

```cmake
# 错误 ❌
# 在 .msg 文件中
---
int32 data       # 裸类型
String message   # 裸类型

# 正确 ✅
---
std_msgs/msg/String message
geometry_msgs/msg/PoseStamped pose
```

### 5. 禁止在 .msg 第一行写注释

```cmake
# 错误 ❌
# My custom message
---
int32 data

# 正确 ✅
#（空行）
int32 data
# 或者没有注释
```

---

## 二、强制检查清单

AI 生成 CMakeLists.txt 后，逐项确认：

- [ ] 所有依赖都有 `find_package(xxx REQUIRED)`
- [ ] `ament_export_dependencies()` 列出了所有传递依赖
- [ ] `ament_target_dependencies()` 列出了所有直接依赖
- [ ] 消息类型使用 `pkg/msg/Type` 格式（无裸类型）
- [ ] 使用 `ament_auto_*` 宏可以避免大部分依赖问题
- [ ] `.msg`/`.srv`/`.action` 文件在 `ament_auto_add_library()` 之前已声明

---

## 三、常见错误自动修复

### 修复 1：`non-existent dependency XXX`

```bash
# 提示：在 CMakeLists.txt 添加缺失的 find_package
find_package(XXX REQUIRED)
ament_target_dependencies(my_node XXX)
ament_export_dependencies(XXX)
```

### 修复 2：`undefined reference to YYY`

```bash
# 提示：YYY 是 XXX 的传递依赖，需要在 ament_target_dependencies 中添加 XXX
ament_target_dependencies(my_node XXX YYY)
```

### 修复 3：`ament_index_is_register_plugins` 失败

```bash
# 提示：plugin_description.xml 中的插件未注册
# 检查 ament_register_plugins 调用
ament_register_plugins(${PROJECT_NAME} "plugins/${PROJECT_NAME}/plugin_description.xml")
```

---

## 四、正确 CMakeLists.txt 范式

### 最小正确模板

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_CXX_STANDARD LESS 17)
  set(CMAKE_CXX_STANDARD 17)
endif()
if(NOT CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

# 1. 声明依赖
ament_auto_find_build_dependencies()

# 2. 添加库/可执行文件
ament_auto_add_library(${PROJECT_NAME} SHARED src/my_node.cpp)

# 3. 安装
install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION ${AMENT_PACKAGE_BIN_DESTINATION}
  LIBRARY DESTINATION ${AMENT_PACKAGE_LIB_DESTINATION}
)
install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

# 4. 打包
ament_auto_package()
```

### 带消息接口的模板

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_CXX_STANDARD LESS 17)
  set(CMAKE_CXX_STANDARD 17)
endif()
if(NOT CMAKE_CXX_STANDARD_REQUIRED)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

ament_auto_find_build_dependencies()

# 必须在 ament_auto_add_library 之前
rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/MyMsg.msg"
  "srv/MySrv.srv"
  "action/My.action"
)

ament_auto_add_library(${PROJECT_NAME} SHARED src/my_node.cpp)
ament_auto_library_discoverability(${PROJECT_NAME})

ament_auto_package()
```
