---
name: common-ros2-package-generator-enhanced
description: ROS2包生成增强技能 - workspace管理、overlay开发、colcon元构建、包模板生成、metapackage、大型项目管理
argument-hint: "创建ROS2包" / "workspace管理" / "overlay开发" / "colcon" / "metapackage" / "包生成"
user-invocable: true
---

# ROS2 包生成增强技能

> 深度掌握 ROS2 工作空间管理、colcon 构建、overlay 开发模式、包模板生成和大型项目管理

---

## 何时使用

当需要以下帮助时使用此技能：
- 创建完整的 ROS2 工作空间
- 管理 overlay/underlay 依赖关系
- 使用 colcon 元构建系统
- 生成多机器人/多功能包模板
- 构建 metapackage 组织大型项目
- 批量创建包结构和配置
- 实现包版本管理和发布

---

## 工作空间结构

### 标准 ROS2 Workspace

```
workspace/
├── src/                    # 源代码 (必须)
│   ├── package_1/
│   ├── package_2/
│   └── ...
├── build/                  # colcon build 输出 (自动创建)
├── install/                 # colcon install 输出 (自动创建)
├── log/                     # colcon 日志 (自动创建)
└──
```

### 初始化工作空间

```bash
# 1. 创建工作空间
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws

# 2. 拉取代码
git clone git@github.com:MIUAV/vibe-coding-ros2.git src/vibe-coding-ros2

# 3. 安装依赖 (自动安装 ROS2 包依赖)
rosdep install -r -y --from-paths src --ignore-src

# 4. 构建
colcon build --symlink-install

# 5. Source 环境
source install/setup.bash
```

### Overlay 和 Underlay

```
Underlay (Base) ──────────────────────────────────────
  /opt/ros/iron/
  └── 安装的系统包 (rclcpp, std_msgs, geometry_msgs...)

Overlay (Workspace) ────────────────────────────
  ~/ros2_ws/src/my_package/

工作原理:
1. source /opt/ros/iron/setup.bash   # 先加载 underlay
2. source ~/ros2_ws/install/setup.bash  # overlay 覆盖
3. colcon build 会在 install/ 目录生成新的包
4. 运行时 ROS2 使用 install/ 中的包 (overlay 优先)
```

---

## colcon 详解

### colcon 命令行

```bash
# 构建
colcon build                    # 全量构建
colcon build --packages-select pkg1 pkg2  # 选择性构建
colcon build --packages-up-to pkg1       # 构建 pkg1 及其依赖
colcon build --packages-above pkg1      # 构建 pkg1 及其反向依赖

# 增量构建 (推荐开发时使用)
colcon build --symlink-install    # 源文件变更自动生效
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug

# 并行构建
colcon build --jobs 4            # 4核并行
colcon build -p 4                # 同上

# 清理
colcon build --cmake-clean-cache  # 清理 CMake 缓存
colcon build --cmake-clean        # 完整清理

# 测试
colcon test                       # 运行所有测试
colcon test --packages-select pkg  # 只测试指定包
colcon test-result                # 查看测试结果

# 列出包
colcon list                       # 列出所有包
colcon list --names-only         # 只显示包名
```

### colcon meta 文件 (.meta)

```yaml
# robotics.meta
{
  "workspace": "robotics_ws",
  "packages": [
    {
      "name": "robot_control",
      "type": "ament_cmake",
      "description": "Robot control core"
    },
    {
      "name": "robot_navigation",
      "type": "ament_cmake",
      "description": "Navigation stack"
    }
  ]
}
```

```bash
# 使用 meta 文件批量构建
colcon build --metas robotics.meta
```

---

## 包模板生成

### 批量生成脚本

```bash
#!/bin/bash
# generate_robot_packages.sh

ROBOT_TYPE=$1
PKG_PREFIX="my_robot"

generate_package() {
  local name=$1
  local type=$2  # ament_cmake 或 ament_python

  echo "Creating $name ($type)..."

  # 创建包结构
  mkdir -p src/$name/{src,include,msg,srv,action,launch,config,test}

  # package.xml
  cat > src/$name/package.xml <<EOF
<?xml version="1.0"?>
<package format="3">
  <name>${PKG_PREFIX}_$name</name>
  <version>0.1.0</version>
  <description>$name package for $ROBOT_TYPE</description>
  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>
  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

  # CMakeLists.txt
  cat > src/$name/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.16)
project(${PKG_PREFIX}_$name)

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
find_package(geometry_msgs REQUIRED)

add_library(${PROJECT_NAME} SHARED src/${name}_node.cpp)
ament_target_dependencies(${PROJECT_NAME} rclcpp std_msgs geometry_msgs)

install(TARGETS ${PROJECT_NAME}
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib
)

install(DIRECTORY launch config
  DESTINATION share/\${PROJECT_NAME}/
)

ament_package()
EOF

  echo "✓ Created ${PKG_PREFIX}_$name"
}

# 生成五类包
generate_package "description" "ament_cmake"      # URDF/XACRO
generate_package "control" "ament_cmake"         # 控制器
generate_package "navigation" "ament_cmake"     # 导航
generate_package "perception" "ament_cmake"      # 感知
generate_package "bringup" "ament_cmake"          # 启动集合
```

### 机器人专用包模板

#### 人形机器人包结构

```
humanoid_robot/
├── description/              # 机器人描述
│   ├── humanoid.urdf.xacro
│   ├── humanoid.ros2_control.xacro
│   └── gazebo/
├── control/                  # 控制器
│   ├── humanoid_controller.ros2_control.xacro
│   ├── joint_trajectory_controller.yaml
│   └── launch/
├── navigation/              # 导航
│   ├── humanoid_nav2.launch.py
│   ├── config/
│   └── maps/
├── perception/              # 感知
│   ├── depth_camera.launch.py
│   └── lidar.launch.py
└── bringup/                # 启动集合
    ├── humanoid_bringup.launch.py
    └── rviz/
```

#### 四足机器人包结构

```
quadruped_robot/
├── description/
│   ├── quadruped.urdf.xacro
│   ├── gazebo_ros2_control.xacro
│   └── materials/
├── control/
│   ├── gait_controller/
│   ├── posture_controller/
│   └── config/
├── navigation/
│   ├── slam.launch.py
│   └── nav2.launch.py
└── bringup/
```

---

## Metapackage

### Metapackage 原理

```
Metapackage = 虚包
            = 不含源代码
            = 只是一个 package.xml + CMakeLists.txt
            = 用于组织一组相关包的依赖关系

典型用途:
- ros-base (ros-humble-ros-base)
- navigation2 (nav2_bringup)
- perception (perception_metapackage)
```

### Metapackage 模板

```xml
<?xml version="1.0"?>
<!-- Format 3 -->
<package format="3">
  <name>my_robot_metapackage</name>
  <version>1.0.0</version>
  <description>Complete robot metapackage</description>

  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>

  <!-- Metapackage 依赖声明 -->
  <member_of_group>my_robot_packages_group</member_of_group>

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

```cmake
# CMakeLists.txt (Metapackage)
cmake_minimum_required(VERSION 3.16)
project(my_robot_metapackage)

# 不需要 find_package(ament_cmake REQUIRED)
# Metapackage 不需要任何 target

ament_export_dependencies(
  my_robot_description
  my_robot_control
  my_robot_navigation
  my_robot_perception
)

install(
  DIRECTORY
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
```

### 在 package.xml 中声明 Group 成员

```xml
<!-- 在各子包的 package.xml 中 -->
<export>
  <build_type>ament_cmake</build_type>
  <!-- 声明属于某个 metapackage -->
</export>
```

### 创建 Package Group

```xml
<!-- package_group.xml -->
<packages>
  <name>my_robot_packages_group</name>
  <description>All packages for my robot</description>
  <group>my_robot_packages_group</group>
  <package>my_robot_description</package>
  <package>my_robot_control</package>
  <package>my_robot_navigation</package>
</packages>
```

---

## 依赖管理进阶

### rosdep 依赖管理

```yaml
# rosdep.yaml (项目根目录)
dependencies:
  apt:
    - ros-humble-rclcpp
    - ros-humble-geometry-msgs
    - ros-humble-nav2-msgs
    - libopencv-dev  # 系统依赖

  pip:
    - numpy
    - opencv-python
```

```bash
# rosdep 命令
rosdep update              # 更新数据库
rosdep install -r -y --from-paths src --ignore-src  # 安装所有依赖
rosdep check --from-paths src --ignore-src  # 检查依赖

# 查看依赖树
rosdep depends package_name
rosdep db | grep ros-humble
```

### 版本约束

```xml
<!-- package.xml 版本约束 -->
<depend condition="$ROS_DISTRO >= humble">nav2_msgs</depend>

<!-- CMakeLists.txt 版本检测 -->
include(G `${rmf_utils}/cmake/get_ros2_version.cmake`)
get_ros2_version(version)

if(version VERSION_LESS "humble")
  message(FATAL_ERROR "Requires ROS2 Humble or newer")
endif()
```

### Git Submodule 管理依赖

```bash
# 添加 submodule
cd ~/ros2_ws/src
git submodule add git@github.com:org/external_lib.git external/lib

# Clone 时同步 submodule
git clone --recursive git@github.com:org/my_workspace.git

# 更新 submodule
git submodule update --remote external/lib
```

---

## 大型项目管理

### 分层工作空间

```
company_robotics/
├── src/
│   ├── robot_platform/          # 硬件抽象层
│   │   ├── robot_hardware/
│   │   ├── robot_description/
│   │   └── robot_driver/
│   │
│   ├── robot_core/              # 核心算法
│   │   ├── robot_control/
│   │   ├── robot_navigation/
│   │   └── robot_perception/
│   │
│   ├── robot_apps/             # 应用层
│   │   ├── robot_application_1/
│   │   └── robot_application_2/
│   │
│   └── vendor/                 # 第三方依赖
│       ├── external_perception/
│       └── external_planning/
```

### 多仓库协作

```bash
# company-repos.yaml
repositories:
  robot_platform:
    type: git
    url: git@github.com:company/robot-platform.git
    version: main

  robot_core:
    type: git
    url: git@github.com:company/robot-core.git
    version: main
```

```bash
# 使用 vcs 批量管理
vcs import src < company-repos.yaml
vcs pull src  # 更新所有仓库
```

### 发布流程

```bash
# 1. 版本 bump
bump2version major  # 或 minor / patch

# 2. 打标签
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 3. 构建 Bloom 发布
source /opt/ros/humble/setup.bash
bloom-release --track humble --rosdistro humble my_package

# 4. 检查发布状态
rosdistro status humble | grep my_package
```

---

## Docker 开发环境

### Dockerfile 示例

```dockerfile
FROM ros:humble

# 安装构建工具
RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    git \
    && rm -rf /var/lib/apt/lists/*

# 设置工作空间
WORKDIR /workspace

# 预安装常用依赖
RUN rosdep init && \
    rosdep install -y --from-paths /workspace/src --ignore-src || true

# 编译
COPY src/ ./src/
RUN . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

# 默认入口
ENTRYPOINT ["/bin/bash"]
```

### docker-compose 开发

```yaml
version: '3.8'
services:
  ros2-dev:
    image: ros:humble
    container_name: ros2_dev
    environment:
      - DISPLAY=${DISPLAY}
      - ROS_DOMAIN_ID=42
    volumes:
      - ./workspace:/workspace
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
    network_mode: host
    command: >
      bash -c "
        source /opt/ros/humble/setup.bash &&
        cd /workspace &&
        colcon build --symlink-install &&
        bash"
```

---

## 常见错误排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 包找不到 | overlay 未 source | `source install/setup.bash` |
| 旧包优先 | workspace 层序错误 | 检查 source 顺序：underlay → overlay |
| colcon build 卡住 | 循环依赖 | `colcon build --packages-ignore pkg_with_cycle` |
| rosdep 安装失败 | sources.list 未配置 | `sudo rosdep init && rosdep update` |
| git submodule 不更新 | shallow clone | `git submodule update --init --recursive` |
| bloom-release 失败 | 非标准包名 | `bloom-release --track humble --rosdistro humble --non-interactive` |
| 多工作空间冲突 | 同名包 | 使用 `--isolated` 安装或确保包名唯一 |

### 调试命令

```bash
# 查看包的依赖关系
colcon graph | dot -Tpng > deps.png  # 依赖图
colcon graph --package-select my_package  # 单包依赖

# 查看 ROS2 包路径
ros2 pkg prefix my_package
ros2 pkg executables my_package
ros2 pkg libraries my_package

# 查看工作空间覆盖关系
ros2 pkg list  # 列出所有可见包
echo $AMENT_PREFIX_PATH  # 查看前缀路径

# 强制重新构建
rm -rf build/ install/ log/
colcon build --symlink-install

# 查看构建错误
cat log/latest_build/colcon_*.log
```

---

## 相关技能

- `common/cmake-configuration` — CMakeLists.txt 深度配置
- `common/ros2-interface-definition` — 消息/服务/动作定义
- `common/ros2-launch-advanced` — Launch 高级配置
- `common/ros2-lifecycle` — 生命周期节点管理
- `edge-platforms/ros2-cross-compile` — 交叉编译
- `common/docker-robotics` — Docker 机器人开发环境
