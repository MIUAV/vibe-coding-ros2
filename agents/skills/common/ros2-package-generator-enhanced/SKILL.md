---
name: common-ros2-package-generator-enhanced
description: ROS2包生成增强技能 - workspace管理、overlay开发、colcon元构建、包模板生成、metapackage、大型项目管理
argument-hint: "创建ROS2包" / "workspace管理" / "overlay开发" / "colcon" / "metapackage" / "包生成"
user-invocable: true
---

# ROS2 包生成增强技能

> 深度掌握 ROS2 工作空间管理、colcon 构建、overlay 开发模式和大型项目管理

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
├── src/           # 源代码 (必须)
├── build/          # colcon build 输出 (自动)
├── install/        # colcon install 输出 (自动)
└── log/            # colcon 日志 (自动)
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

### Overlay / Underlay 原理

```
Underlay (Base System):
  /opt/ros/iron/  → 系统包 (rclcpp, std_msgs, geometry_msgs)

Overlay (Workspace):
  ~/ros2_ws/install/  → 工作空间覆盖包

执行顺序:
  source /opt/ros/iron/setup.bash   # 先加载 underlay
  source ~/ros2_ws/install/setup.bash  # overlay 优先
```

---

## colcon 详解

### 常用命令

```bash
# 构建
colcon build                          # 全量构建
colcon build --symlink-install       # 开发推荐 (源文件变更自动生效)
colcon build --packages-select pkg1 pkg2  # 选择性构建
colcon build --packages-up-to pkg1   # pkg1 及其依赖
colcon build --packages-above pkg1   # pkg1 及其反向依赖
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Debug

# 并行
colcon build -j 4                   # 4核并行
colcon build --merge-install         # 合并安装

# 清理
colcon build --cmake-clean-cache
colcon build --cmake-clean

# 测试
colcon test
colcon test --packages-select pkg
colcon test-result

# 列表
colcon list --names-only
colcon graph  # 依赖图
```

---

## 包模板生成

### 批量生成脚本

```bash
#!/bin/bash
# generate_packages.sh

PKG_PREFIX="my_robot"
ROBOT_TYPE=$1

generate_package() {
  local name=$1
  local pkg_name="${PKG_PREFIX}_${name}"

  mkdir -p src/$pkg_name/{src,include,msg,srv,launch,config,test}

  # package.xml (Format 3)
  cat > src/$pkg_name/package.xml <<EOF
<?xml version="1.0"?>
<package format="3">
  <name>$pkg_name</name>
  <version>0.1.0</version>
  <description>$name package for $ROBOT_TYPE</description>
  <maintainer email="dev@example.com">Developer</maintainer>
  <license>Apache-2.0</license>
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>ament_lint_auto</depend>
  <depend>ament_lint_common</depend>
  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
EOF

  # CMakeLists.txt
  cat > src/$pkg_name/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.16)
project($pkg_name)
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

  echo "✓ Created $pkg_name"
}

# 生成五类包
generate_package "description"   # URDF/XACRO
generate_package "control"       # 控制器
generate_package "navigation"   # 导航
generate_package "perception"    # 感知
generate_package "bringup"       # 启动集合
```

### 机器人专用包结构

```
humanoid_robot/           # metapackage
├── humanoid_description/   # 机器人描述
│   ├── humanoid.urdf.xacro
│   └── humanoid.ros2_control.xacro
├── humanoid_control/        # 控制器
│   ├── humanoid_controller.ros2_control.xacro
│   └── config/
├── humanoid_navigation/     # 导航
│   ├── humanoid_nav2.launch.py
│   └── config/
└── humanoid_bringup/       # 启动集合
    └── humanoid_bringup.launch.py
```

---

## Metapackage

### Metapackage = 虚包（无源代码）

```xml
<!-- package.xml -->
<?xml version="1.0"?>
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

### Package Group

```xml
<!-- package_group.xml -->
<packages>
  <name>my_robot_packages_group</name>
  <group>my_robot_packages_group</group>
  <package>my_robot_description</package>
  <package>my_robot_control</package>
  <package>my_robot_navigation</package>
</packages>
```

---

## 依赖管理

### rosdep

```bash
# 安装依赖
rosdep install -r -y --from-paths src --ignore-src

# 检查依赖
rosdep check --from-paths src --ignore-src

# 查看依赖树
rosdep depends my_package
```

### Git Submodule

```bash
cd ~/ros2_ws/src
git submodule add git@github.com:org/external_lib.git external/lib

# 克隆时同步 submodule
git clone --recursive git@github.com:org/workspace.git

# 更新
git submodule update --remote external/lib
```

### 多仓库管理 (vcs)

```yaml
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
vcs import src < company-repos.yaml
vcs pull src
```

---

## 发布流程

```bash
# 1. 版本 bump
bump2version patch  # major / minor / patch

# 2. 打标签
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 3. Bloom 发布
source /opt/ros/humble/setup.bash
bloom-release --track humble --rosdistro humble my_package
```

---

## Docker 开发环境

```dockerfile
FROM ros:humble
RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    git && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace
RUN rosdep init && rosdep install -y --from-paths /workspace/src || true
COPY src/ ./src/
RUN . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install
ENTRYPOINT ["/bin/bash"]
```

---

## 故障排查

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 包找不到 | overlay 未 source | `source install/setup.bash` |
| 旧包优先 | source 顺序错误 | underlay 先 source |
| colcon build 卡住 | 循环依赖 | `--packages-ignore` 排除 |
| rosdep 失败 | sources 未配置 | `sudo rosdep init && rosdep update` |
| bloom-release 失败 | 包名非标准 | `--non-interactive` 跳过检查 |

### 调试命令

```bash
colcon graph | dot -Tpng > deps.png   # 依赖图
ros2 pkg prefix my_package            # 包路径
echo $AMENT_PREFIX_PATH              # 前缀路径
rm -rf build/ install/ log/ && colcon build --symlink-install  # 强制重构建
cat log/latest_build/colcon_*.log   # 构建日志
```

---

## 相关技能

- `common/cmake-configuration` — CMakeLists.txt 深度配置
- `common/ros2-interface-definition` — 消息/服务/动作定义
- `common/ros2-launch-advanced` — Launch 高级配置
- `common/ros2-lifecycle` — 生命周期节点管理
- `edge-platforms/ros2-cross-compile` — 交叉编译
