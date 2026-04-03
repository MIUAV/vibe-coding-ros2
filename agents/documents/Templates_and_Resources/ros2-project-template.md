# ROS2 项目模板

> 标准 ROS2 机器人项目的目录结构和配置文件模板

---

## 1. 项目整体结构

```
robot_ws/
├── src/                          # 源代码
│   ├── my_robot_driver/          # 驱动包
│   ├── my_robot_perception/      # 感知包
│   ├── my_robot_navigation/      # 导航包
│   ├── my_robot_control/         # 控制包
│   ├── my_robot_bringup/         # 启动包
│   └── my_robot_msgs/             # 消息包
│
├── build/                        # 编译产物 (自动生成)
├── install/                       # 安装产物 (自动生成)
├── log/                          # 日志目录 (自动生成)
│
├── memory-bank/                   # AI 上下文 (VibeCoding)
│   ├── project-context.md
│   ├── implementation-plan.md
│   ├── progress.md
│   └── architecture.md
│
├── docker/                       # Docker 配置
│   ├── Dockerfile.x86_dev
│   ├── Dockerfile.arm64_dev
│   └── docker-compose.yml
│
├── scripts/                       # 工具脚本
│   ├── build.sh
│   ├── clean.sh
│   └── deploy.sh
│
├── config/                        # 全局配置
│   ├── default.yaml
│   └── robot.yaml
│
├── .gitignore
├── README.md
└── COLCON_IGNORE                 # 排除构建目录
```

---

## 2. 功能包模板

### 2.1 标准包结构 (C++)

```
my_package/
├── CMakeLists.txt
├── package.xml
├── include/
│   └── my_package/
│       ├── header1.h
│       └── header2.h
├── src/
│   ├── node_main.cpp           # 主入口
│   ├── class1.cpp
│   └── class2.cpp
├── launch/
│   └── my_node.launch.py
├── config/
│   └── params.yaml
├── test/
│   ├── test_node.cpp
│   └── test_class.cpp
├── msg/
│   └── MyMessage.msg
├── srv/
│   └── MyService.srv
└── README.md
```

### 2.2 CMakeLists.txt 模板

```cmake
cmake_minimum_required(VERSION 3.8)
project(my_package)

if(CMAKE_VERSION VERSION_LESS "3.10")
  cmake_policy(SET CMP0048 NEW)
endif()

# 标准 CMake 配置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 查找依赖
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(sensor_msgs REQUIRED)

# 头文件
include_directories(
  include
  ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# 库
add_library(my_library
  src/class1.cpp
  src/class2.cpp
)
ament_target_dependencies(my_library
  rclcpp
  std_msgs
)

# 节点
add_executable(my_node src/node_main.cpp)
ament_target_dependencies(my_node
  rclcpp
  my_library
)

# Install
install(TARGETS my_node my_library
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)

install(DIRECTORY launch/
  DESTINATION share/${PROJECT_NAME}/launch
)

install(DIRECTORY config/
  DESTORY share/${PROJECT_NAME}/config
)

# 测试
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
```

### 2.3 package.xml 模板

```xml
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd"?>
<package format="3">

  <name>my_package</name>
  <version>1.0.0</version>
  <description>My ROS2 package description</description>
  
  <maintainer email="user@example.com">User Name</maintainer>
  <license>Apache-2.0</license>

  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  
  <depend>rclcpp</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  
  <exec_depend>ament_index_python_package_index</exec_depend>
  
  <member_of_group>rosidl_interface_packages</member_of_group>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>launch</test_depend>
  <test_depend>launch_testing</test_depend>

  <export>
    <build_type>ament_cmake</build_type>
  </export>

</package>
```

### 2.4 Python 包结构

```
my_python_package/
├── package.xml
├── setup.py
├── setup.cfg
├── my_python_package/
│   ├── __init__.py
│   ├── node.py
│   └── utils.py
├── launch/
│   └── my_node.launch.py
├── config/
│   └── params.yaml
└── test/
    └── test_node.py
```

### 2.5 setup.py 模板

```python
from setuptools import setup
import os
from glob import glob

setup(
    name='my_python_package',
    version='1.0.0',
    packages=['my_python_package'],
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + 'my_python_package']),
        ('share/' + 'my_python_package',
            ['package.xml']),
        (os.path.join('share', 'my_python_package', 'launch'),
            glob('launch/*.launch.py')),
        (os.path.join('share', 'my_python_package', 'config'),
            glob('config/*.yaml')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='User',
    maintainer_email='user@example.com',
    description='My Python ROS2 package',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'my_node = my_python_package.node:main',
        ],
    },
)
```

---

## 3. 消息模板

### 3.1 消息定义 (.msg)

```msg
# MyMessage.msg
# 许可证: Apache-2.0
# 作者: Your Name
# 描述: 消息功能描述

# 文件头
std_msgs/Header header

# 枚举类型
uint8 TYPE_A = 0
uint8 TYPE_B = 1
uint8 data_type
uint8 MODE_MANUAL = 0
uint8 MODE_AUTO = 1
uint8 mode

# 标量字段
float32 temperature
float64 latitude
bool is_active

# 数组字段
float32[] temperatures
string[] names
```

### 3.2 服务定义 (.srv)

```srv
# MyService.srv
# 描述: 服务功能描述

# 请求
string device_id
uint8 command
---
# 响应
bool success
string message
float32[] data
```

### 3.3 动作定义 (.action)

```action
# MyAction.action
# 描述: 动作功能描述

# 目标
geometry_msgs/PoseStamped goal_pose
float32 speed
---
# 结果
bool success
string message
---
# 反馈
float32 progress
float32 estimated_time_remaining
```

---

## 4. Launch 文件模板

### 4.1 基础 Launch

```python
# launch/my_node.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    
    # 参数声明
    param_file = DeclareLaunchArgument(
        'param_file',
        default_value=[os.path.join(get_package_share_directory('my_package'), 
                                    'config', 'params.yaml')],
        description='Full path to param file'
    )
    
    device_name = DeclareLaunchArgument(
        'device',
        default_value='/dev/video0',
        description='Camera device'
    )
    
    # 节点
    my_node = Node(
        package='my_package',
        executable='my_node',
        name='my_node',
        parameters=[LaunchConfiguration('param_file')],
        remappings=[
            ('/input', '/camera/image_raw'),
            ('/output', '/my_node/output'),
        ],
        output='screen',
        emulate_tty=True,
    )
    
    return LaunchDescription([
        param_file,
        device_name,
        my_node
    ])
```

### 4.2 带条件启动的 Launch

```python
# launch/composed.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node, ComposableNodeContainer
from launch_ros.descriptions import ComposableNode
from launch.actions import ExecuteProcess, RegisterEventHandler
from launch.event_handlers import OnExecutionComplete, OnProcessExit

def generate_launch_description():
    
    # 容器
    container = ComposableNodeContainer(
        name='my_container',
        package='rclcpp_components',
        executable='component_container',
        composable_node_descriptions=[
            ComposableNode(
                package='my_package',
                plugin='my_package::MyNode',
                name='my_node_1',
                parameters=[...],
            ),
            ComposableNode(
                package='my_package',
                plugin='my_package::MyNode',
                name='my_node_2',
                parameters=[...],
            ),
        ],
        output='screen',
    )
    
    # 额外节点 (非组件)
    extra_node = Node(
        package='other_package',
        executable='other_node',
    )
    
    return LaunchDescription([
        container,
        extra_node
    ])
```

---

## 5. 参数文件模板

### 5.1 YAML 格式

```yaml
my_node:
  ros__parameters:
    # 整数
    queue_size: 10
    timeout_ms: 100
    device_id: 0
    
    # 浮点
    threshold: 0.75
    scale: 1.0
    gravity: 9.81
    
    # 布尔
    enable_debug: false
    use_gpu: true
    is_enabled: true
    
    # 字符串
    frame_id: "base_link"
    topic_name: "/scan"
    
    # 数组
    target_ids: [1, 2, 3, 4, 5]
    coefficients: [0.1, 0.2, 0.3, 0.4]
    
    # 嵌套参数
    camera:
      width: 640
      height: 480
      fps: 30
      exposure: 100
```

---

## 6. Dockerfile 模板

### 6.1 开发容器

```dockerfile
# Dockerfile.x86_dev
FROM ros:humble

# 安装开发工具
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    vim \
    tmux \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 安装 ROS2 开发工具
RUN apt-get update && apt-get install -y \
    ros-humble-ros2launch \
    ros-humble-ros2run \
    ros-humble-ros2pkg \
    ros-humble-rqt* \
    ros-humble-rviz2 \
    ros-humble-eigenpy \
    && rm -rf /var/lib/apt/lists/*

# OpenCV
RUN apt-get update && apt-get install -y \
    libopencv-dev \
    python3-opencv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 拷贝工作区
COPY src/ ./src/

# 编译
RUN bash -c "source /opt/ros/humble/setup.bash && \
    colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release"

CMD ["bash"]
```

### 6.2 ARM64 交叉编译容器

```dockerfile
# Dockerfile.arm64_cross
FROM ros:humble

# 安装交叉编译工具
RUN apt-get update && apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    crossbuild-essential-arm64 \
    && rm -rf /var/lib/apt/lists/*

# 安装 ARM64 sysroot (Jetson OrinNX)
# 需要预先准备好根文件系统
COPY Linux_for_Tegra/rootfs /opt/orin_sysroot

WORKDIR /workspace

# 拷贝工作区
COPY src/ ./src/

# 交叉编译
RUN bash -c "source /opt/ros/humble/setup.bash && \
    colcon build \
    --cmake-args \
        -DCMAKE_TOOLCHAIN_FILE=/opt/ros/humble/aarch64.toolchain.cmake \
        -DCMAKE_SYSROOT=/opt/orin_sysroot \
        -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
        -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"

CMD ["bash"]
```

---

## 7. README 模板

```markdown
# My Robot Package

## 功能描述

机器人项目的功能描述，包括主要功能和特点。

## 系统要求

- ROS2 Humble
- Ubuntu 22.04
- [其他依赖]

## 安装

```bash
# 克隆仓库
cd ~/robot_ws/src
git clone https://github.com/user/my_robot.git

# 安装依赖
sudo apt install -y ros-humble-...

# 编译
cd ~/robot_ws
colcon build --packages-select my_package
source install/setup.bash
```

## 运行

```bash
# 启动节点
ros2 launch my_package my_node.launch.py

# 或运行启动集合
ros2 launch my_robot_bringup robot.launch.py
```

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| queue_size | int | 10 | 队列大小 |
| threshold | float | 0.5 | 阈值 |

## Topic

| Topic | 类型 | 方向 | 说明 |
|-------|------|------|------|
| /input | Image | Sub | 输入图像 |
| /output | Image | Pub | 输出图像 |

## License

Apache-2.0
```

---

## 8. .gitignore 模板

```gitignore
# Build
build/
install/
log/
*.pyc
__pycache__/

# IDE
.vscode/
.idea/
*.swp
*.swo

# ROS
*.bag
*.db3

# Python
venv/
*.egg-info/
dist/
build/

# Docker
.dockerignore

# OS
.DS_Store
Thumbs.db
```

---

*此模板遵循 ROS2 最佳实践，可根据项目需求调整*
