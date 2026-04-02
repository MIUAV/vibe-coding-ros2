---
name: rviz2
description: RViz2 可视化开发技能 - 3D可视化、插件开发、显示类型配置、交互工具开发
argument-hint: "rviz配置" / "创建显示" / "rviz插件" / "可视化"
user-invocable: true
---

# RViz2 Visualization Skill

> 用于 RViz2 可视化工具的配置和插件开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置 RViz2 显示项
- 创建自定义显示插件
- 开发交互工具
- 可视化传感器数据
- 配置导航可视化

---

## 快速参考

### 安装 RViz2

```bash
# ROS2 Humble
sudo apt install ros-humble-rviz2

# ROS2 Iron
sudo apt install ros-iron-rviz2

# 从源码构建
cd ~/ros2_ws
vcs import src < https://github.com/ros2/rviz.git
cd src/rviz
rosdep install -r --from-paths . --ignore-src -y
colcon build --packages-up-to rviz_common rviz_rendering rviz
```

### 启动 RViz2

```bash
# 启动默认配置
rviz2

# 加载指定配置文件
rviz2 -d /path/to/config.rviz

# 启动新窗口
rviz2 --window geometry
```

### RViz2 配置文件 (.rviz)

```yaml
Visualization Manager:
  Class: "rviz2/VisualizationManager"
  Fixed Frame: "map"
  Tools:
    - Class: "rviz_interactive_tools/MoveFace"
    - Class: "rviz_default_plugins/Interact"
      Hide Small Objects: false
    - Class: "rviz_default_plugins/SetInitialPose"
      Topic: "/initialpose"
    - Class: "rviz_default_plugins/SetGoal"
      Topic: "/move_base_simple/goal"
  
  Displays:
    - Class: "rviz_default_plugins/Grid"
      Name: "Grid"
      Plane: "XY"
      Cell Size: 1
      Reference Frame: "map"
    
    - Class: "rviz_default_plugins/RobotModel"
      Name: "Robot Model"
      Description Topic:
        Topic: "/robot_description"
        Type: "robot_state/JointState"
    
    - Class: "rviz_default_plugins/PointCloud2"
      Name: "Lidar Points"
      Topic:
        Topic: "/scan"
        Type: "sensor_msgs/PointCloud2"
      Color Transform: "RGB"
      Style: "Points"
    
    - Class: "rviz_default_plugins/Map"
      Name: "Occupancy Map"
      Topic:
        Topic: "/map"
        Type: "nav_msgs/OccupancyGrid"
      Color Scheme: "map"
    
    - Class: "rviz_default_plugins/Trajectory"
      Name: "Path"
      Topic:
        Topic: "/plan"
        Type: "nav_msgs/Path"
      Color: 0 0 255 255
      Line Width: 3
```

---

## 显示类型配置

### 激光雷达点云

```cpp
// 创建点云显示
rviz_common::Display* createPointCloudDisplay(rviz_common::DisplayContext* context)
{
  rviz_common::Display* display = context->createDisplay("rviz_default_plugins/PointCloud2");
  display->initialize(context);
  
  // 设置属性
  rviz_common::Property* props = display->getProperty();
  props->subProp("Topic")->subProp("Topic")->setValue("/scan");
  props->subProp("Style")->setValue("Points");
  props->subProp("Size (Pixels)")->setValue(3);
  
  return display;
}
```

### TF 变换树

```cpp
// TF 显示配置
{
  "Class": "rviz_default_plugins/TF",
  "Name": "TF Tree",
  "Frame Timeout": 5,
  "All Frames Enabled": true,
  "Marker Scale": 1.0,
  "Show Names": true,
  "Show Axes": true,
  "Show Arrows": true
}
```

### 机器人模型

```xml
<!-- robot.urdf.xacro -->
<?xml version="1.0" ?>
<robot name="my_robot" xmlns:xacro="http://www.ros.org/wiki/xacro">
  
  <!-- Base Link -->
  <link name="base_link">
    <visual>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry>
        <box size="0.5 0.4 0.2"/>
      </geometry>
      <material name="white">
        <color rgba="1 1 1 1"/>
      </material>
    </visual>
    <collision>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry>
        <box size="0.5 0.4 0.2"/>
      </geometry>
    </collision>
  </link>
  
  <!-- Wheel -->
  <joint name="left_wheel_joint" type="continuous">
    <parent link="base_link"/>
    <child link="left_wheel"/>
    <origin xyz="0 0.25 0" rpy="-1.5708 0 0"/>
    <axis xyz="0 0 1"/>
  </joint>
  
  <link name="left_wheel">
    <visual>
      <geometry>
        <cylinder radius="0.1" length="0.05"/>
      </geometry>
    </visual>
  </link>
</robot>
```

### 路径可视化

```yaml
- Class: "nav_msgs/Path"
  Name: "Global Path"
  Topic:
    Topic: "/move_base/NavfnROS/plan"
    Type: "nav_msgs/Path"
  Color: 0 255 0 255
  Line Style: "Lines"
  Line Width: 0.05
  
- Class: "nav_msgs/Path"
  Name: "Local Plan"
  Topic:
    Topic: "/move_base/DWAPlannerROS/local_plan"
    Type: "nav_msgs/Path"
  Color: 255 0 0 255
  Line Width: 0.03
```

---

## RViz2 插件开发

### 创建插件包

```bash
# 创建包
cd ~/ros2_ws/src
ros2 pkg create --dependencies rviz_common rviz_rendering rviz_ogre_vendor --library-name my_rviz_plugin my_rviz_display_plugin

# CMakeLists.txt
cmake_minimum_required(VERSION 3.8)
project(my_rviz_display_plugin)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wdeprecated-register)
endif()

find_package(ament_cmake REQUIRED)
find_package(rviz_common REQUIRED)
find_package(rviz_rendering REQUIRED)

include_directories(
  include
)

add_library(my_display SHARED
  src/my_display.cpp
)

target_link_libraries(my_display
  rviz_common::rviz_common
  rviz_rendering::rviz_rendering
)

ament_target_dependencies(my_display
  rclcpp
  visualization_msgs
)

# Install
ament_export_libraries(my_display)
install(TARGETS my_display
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
)
```

### 创建自定义 Display 插件

```cpp
// include/my_rviz_display_plugin/my_custom_display.hpp
#ifndef MY_CUSTOM_DISPLAY_HPP_
#define MY_CUSTOM_DISPLAY_HPP_

#include <rviz_common/display.hpp>
#include <rviz_common/properties/color_property.hpp>
#include <rviz_common/properties/float_property.hpp>

namespace my_rviz_plugin
{

class MyCustomDisplay : public rviz_common::Display
{
  Q_OBJECT
public:
  MyCustomDisplay();
  virtual ~MyCustomDisplay();

  // 重载父类方法
  virtual void onInitialize() override;
  virtual void update(float wall_dt, float ros_dt) override;
  virtual void reset() override;

protected:
  virtual void processMessage(const visualization_msgs::msg::Marker::ConstSharedPtr msg) override;

private Q_SLOTS:
  void updateColor();
  void updateScale();

private:
  rviz_common::properties::ColorProperty* color_property_;
  rviz_common::properties::FloatProperty* scale_property_;
  rviz_ogre_vendor::Ogre::SceneNode* scene_node_;
};

}  // namespace my_rviz_plugin

#endif  // MY_CUSTOM_DISPLAY_HPP_
```

```cpp
// src/my_custom_display.cpp
#include "my_rviz_display_plugin/my_custom_display.hpp"

#include <rviz_common/logging.hpp>
#include <rviz_common/frame_manager.hpp>
#include <rviz_common/properties/parse_color.hpp>

namespace my_rviz_plugin
{

MyCustomDisplay::MyCustomDisplay()
  : Display()
  , scene_node_(nullptr)
{
  // 创建属性
  color_property_ = new rviz_common::properties::ColorProperty(
    "Color", QColor(255, 0, 0),
    "Color of the markers",
    this, SLOT(updateColor()));

  scale_property_ = new rviz_common::properties::FloatProperty(
    "Scale", 1.0,
    "Scale of the markers",
    this, SLOT(updateScale()));
}

void MyCustomDisplay::onInitialize()
{
  scene_node_ = scene_manager_->getRootSceneNode()->createChildSceneNode();
}

void MyCustomDisplay::processMessage(
  const visualization_msgs::msg::Marker::ConstSharedPtr msg)
{
  // 处理消息并添加到场景
  Ogre::SceneNode* marker_node = scene_node_->createChildSceneNode();
  
  // 创建几何体
  Ogre::ManualObject* obj = scene_manager_->createManualObject(
    "marker_" + std::to_string(msg->header.stamp.nanosec));
  
  obj->begin("BaseWhiteNoLighting", Ogre::RenderOperation::OT_TRIANGLE_LIST);
  // 添加顶点...
  obj->end();
  
  marker_node->attachObject(obj);
  
  // 设置位置
  Ogre::Vector3 position(msg->pose.position.x, 
                        msg->pose.position.y, 
                        msg->pose.position.z);
  marker_node->setPosition(position);
}

void MyCustomDisplay::updateColor()
{
  // 更新颜色
}

void MyCustomDisplay::updateScale()
{
  // 更新缩放
}

void MyCustomDisplay::reset()
{
  // 清除所有对象
  scene_node_->removeAllChildren();
}

}  // namespace my_rviz_plugin

// 注册插件
#include <pluginlib/class_list_macros.hpp>
PLUGINLIB_EXPORT_CLASS(my_rviz_plugin::MyCustomDisplay, rviz_common::Display)
```

### 注册插件

```xml
<!-- my_rviz_display_plugin.xml -->
<library path="lib/libmy_display">
  <class name="my_rviz_plugin/MyCustomDisplay"
         type="my_rviz_plugin::MyCustomDisplay"
         base_class_type="rviz_common::Display">
    <description>My custom display for RViz2</description>
  </class>
</library>
```

```cmake
# CMakeLists.txt 中添加
pluginlib_export_plugin_file()
```

---

## ROS2 Launch 集成

```python
# launch/rviz.launch.py
import os
from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration

def generate_launch_description():
    pkg_name = 'my_robot_bringup'
    pkg_dir = get_package_share_directory(pkg_name)
    
    rviz_config = os.path.join(pkg_dir, 'config', 'robot.rviz')
    
    return LaunchDescription([
        DeclareLaunchArgument(
            'rviz_config',
            default_value=rviz_config,
            description='Path to RViz config file'
        ),
        
        DeclareLaunchArgument(
            'namespace',
            default_value='',
            description='Robot namespace'
        ),
        
        Node(
            package='rviz2',
            executable='rviz2',
            name='rviz2',
            arguments=['-d', LaunchConfiguration('rviz_config')],
            output='screen',
            environment={
                'ROS_DOMAIN_ID': '42'
            }
        )
    ])
```

---

## 常用显示插件

### 图像显示

```yaml
- Class: "rviz_default_plugins/Image"
  Name: "Camera Image"
  Image Topic:
    Topic: "/camera/image_raw"
    Type: "sensor_msgs/Image"
  Max Value: 1
  Min Value: 0
  Queue Size: 2
```

### 标记显示

```yaml
- Class: "rviz_default_plugins/Marker"
  Name: "Markers"
  Marker Topic:
    Topic: "/visualization_marker"
    Type: "visualization_msgs/Marker"
  Namespaces:
    obstacles: true
    targets: true
```

### 里程计显示

```yaml
- Class: "rviz_default_plugins/Odometry"
  Name: "Odometry"
  Topic:
    Topic: "/odom"
    Type: "nav_msgs/Odometry"
  Keep: 100
  Length: 0.5
  Color: 0 255 255 255
  Alpha: 1
  Show Covariance: true
```

---

## 常见问题

### 问题 1: 无法加载模型

**解决方案**：
- 检查 `robot_description` 话题
- 验证 URDF 文件语法
- 确认 `Fixed Frame` 设置正确

### 问题 2: 传感器数据不显示

**解决方案**：
- 确认话题名称正确
- 检查消息类型
- 验证 ROS 节点正在发布

### 问题 3: 插件无法加载

**解决方案**：
- 检查插件路径
- 验证依赖已安装
- 确认插件已注册

---

## 相关资源

- [RViz2 官方文档](https://docs.ros.org/en/iron/p/rviz2/)
- [RViz2 教程](https://docs.ros.org/en/iron/Tutorials/Intermediate/RVIZ2/)
- [RViz 插件开发指南](https://github.com/ros-visualization/rviz/blob/rolling/docs/dev_guide.md)

---

## 另见

- [Gazebo Harmonic](../gazebo-harmonic/) - 仿真配置
- [ROS2 Launch Advanced](../ros2-launch-advanced/) - 启动配置
- [ROS2 Topic Communication](../ros2-topic-communication/) - 话题通信