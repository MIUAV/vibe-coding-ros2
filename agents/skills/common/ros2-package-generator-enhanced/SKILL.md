---
name: common-ros2-package-generator-enhanced
description: ROS2包生成增强技能 - workspace管理、overlay开发、colcon元构建、包模板生成、metapackage、大型项目管理
argument-hint: "创建ROS2包" / "workspace管理" / "overlay开发" / "colcon" / "metapackage" / "包生成"
user-invocable: true
---

# ROS2 包生成增强技能

> 深度掌握 ROS2 工作空间管理、colcon 构建、overlay 开发模式和大型项目管理

## 工作空间结构

### 标准 Workspace
```
workspace/
├── src/           # 源代码
├── build/          # 构建输出
├── install/        # 安装输出
└── log/            # 日志
```

### Overlay/Underlay 原理
```
Underlay = /opt/ros/iron/ (系统包)
Overlay = ~/ros2_ws/install/ (工作空间包，优先使用)
source 顺序: underlay 先 source，overlay 后 source 覆盖
```

### 初始化工作空间
```bash
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
git clone git@github.com:MIUAV/vibe-coding-ros2.git src/vibe-coding-ros2
rosdep install -r -y --from-paths src --ignore-src
colcon build --symlink-install
source install/setup.bash
```

## colcon 详解

### 常用命令
```bash
colcon build                          # 全量构建
colcon build --symlink-install       # 开发推荐(变更自动生效)
colcon build --packages-select pkg1 pkg2  # 选择性构建
colcon build --packages-up-to pkg    # pkg及其依赖
colcon build --packages-above pkg    # pkg及其反向依赖
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug
colcon build -j 4                  # 4核并行
colcon test
colcon graph  # 依赖图
colcon list --names-only
```

## 包模板生成

### 批量生成脚本
```bash
#!/bin/bash
PKG_PREFIX="my_robot"

generate_package() {
  local name=$1
  local pkg="${PKG_PREFIX}_${name}"
  mkdir -p src/$pkg/{src,msg,srv,launch,config,test}

  # package.xml (Format 3)
  cat > src/$pkg/package.xml <<EOF
<?xml version="1.0"?>
<package format="3">
  <name>${pkg}</name>
  <version>0.1.0</version>
  <description>${name} package</description>
  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>ament_lint_auto</depend>
  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

  # CMakeLists.txt
  cat > src/$pkg/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.16)
project($pkg)
if(CMAKE_VERSION VERSION_LESS "3.16.0")
  cmake_policy(SET CMP0077 NEW)
endif()
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
add_library(\${PROJECT_NAME} SHARED src/\${PROJECT_NAME}_node.cpp)
ament_target_dependencies(\${PROJECT_NAME} rclcpp std_msgs)
install(TARGETS \${PROJECT_NAME} LIBRARY DESTINATION lib)
ament_package()
EOF
  echo "Created $pkg"
}

generate_package "description"   # URDF/XACRO
generate_package "control"        # 控制器
generate_package "navigation"    # 导航
generate_package "perception"    # 感知
generate_package "bringup"        # 启动集合
```

## Metapackage

### 原理
```
Metapackage = 虚包，无源代码
            = 仅包含 package.xml + CMakeLists.txt
            = 用于组织一组相关包的依赖声明
```

### 实现
```xml
<!-- package.xml -->
<package format="3">
  <name>my_robot_metapackage</name>
  <version>1.0.0</version>
  <description>Complete robot metapackage</description>
  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>
  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(my_robot_metapackage)
ament_export_dependencies(
  my_robot_description
  my_robot_control
  my_robot_navigation
)
install(DIRECTORY DESTINATION share/${PROJECT_NAME}/)
ament_package()
```

## rosdep 依赖管理

```bash
rosdep install -r -y --from-paths src --ignore-src
rosdep check --from-paths src --ignore-src
rosdep depends my_package

# Git Submodule
git submodule add git@github.com:org/lib.git external/lib
git clone --recursive git@github.com:org/workspace.git
git submodule update --remote external/lib
```

## Docker 开发环境

```dockerfile
FROM ros:humble
RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep git && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
RUN rosdep init && \
    rosdep install -y --from-paths /workspace/src || true
COPY src/ ./src/
RUN colcon build --symlink-install
ENTRYPOINT ["/bin/bash"]
```

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 包找不到 | overlay 未 source | `source install/setup.bash` |
| overlay 不生效 | source 顺序错误 | underlay 先 source |
| colcon build 卡住 | 循环依赖 | `--packages-ignore pkg` |
| rosdep 安装失败 | sources 未配置 | `sudo rosdep init && rosdep update` |
| bloom-release 失败 | 包名非标准 | `--non-interactive` |

## 相关技能
- `common/cmake-configuration` — CMakeLists.txt 深度配置
- `common/ros2-interface-definition` — 消息/服务/动作定义
- `common/ros2-launch-advanced` — Launch 高级配置
- `common/ros2-lifecycle` — 生命周期节点管理
- `edge-platforms/ros2-cross-compile` — 交叉编译
