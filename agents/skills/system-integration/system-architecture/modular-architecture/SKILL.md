---
name: modular-architecture
description: 模块化架构技能 - 组件化设计、接口定义、配置管理、ROS2 组件容器
argument-hint: 模块化 OR modular OR component OR 接口 OR plugin
user-invocable: true
---

# 模块化架构技能

> 机器人模块化软件架构

---

## 何时使用

当需要以下帮助时使用此技能：
- 组件化设计
- 接口定义
- 配置管理
- ROS2 组件容器
- 插件系统

---

## 核心实现

### ROS2 组件

```cpp
// camera_component.hpp
#include <rclcpp/rclcpp.hpp>
#include <image_transport/image_transport.hpp>
#include <sensor_msgs/msg/image.hpp>

namespace robot_components {

class CameraComponent : public rclcpp::Node {
public:
    explicit CameraComponent(const rclcpp::NodeOptions& options)
        : Node("camera_component", options) {
        
        // 参数声明
        this->declare_parameter<std::string>("device", "/dev/video0");
        this->declare_parameter<int>("frame_rate", 30);
        
        // 发布者
        publisher_ = image_transport::create_publisher(
            this, "/camera/image_raw");
            
        // 定时器
        timer_ = this->create_wall_timer(
            std::chrono::milliseconds(33),
            std::bind(&CameraComponent::capture, this));
    }
    
private:
    void capture();
    
    image_transport::Publisher publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
};

}  // namespace robot_components

// 注册组件
#include <rclcpp_components/register_node_macro.hpp>
RCLCPP_COMPONENTS_REGISTER_NODE(robot_components::CameraComponent)
```

### 模块接口定义

```python
# base_perception.py
from abc import ABC, abstractmethod
from typing import List, Dict, Any
import numpy as np

class PerceptionModule(ABC):
    """感知模块基类"""
    
    @abstractmethod
    def process(self, sensor_data: Dict[str, Any]) -> Dict[str, Any]:
        """处理传感器数据"""
        pass
        
    @abstractmethod
    def get_output_topics(self) -> List[str]:
        """获取输出话题"""
        pass
        
    @abstractmethod
    def get_parameters(self) -> Dict[str, Any]:
        """获取参数定义"""
        pass

# lidar_perception.py
class LidarPerceptionModule(PerceptionModule):
    def __init__(self):
        self.node_name = "lidar_perception"
        
    def process(self, sensor_data):
        pointcloud = sensor_data['pointcloud']
        # 处理点云
        detections = self.detect_objects(pointcloud)
        return {'detections': detections}
```

### 配置管理

```python
# config_manager.py
import yaml
from typing import Dict, Any
import copy

class ConfigManager:
    def __init__(self, config_path: str):
        with open(config_path) as f:
            self.base_config = yaml.safe_load(f)
            
    def get_config(self, robot_type: str, robot_id: int) -> Dict[str, Any]:
        """获取特定机器人配置"""
        config = copy.deepcopy(self.base_config)
        
        # 机器人特定参数
        robot_params = config['robots'].get(robot_type, {})
        config.update(robot_params)
        
        # 添加 ID
        config['robot_id'] = robot_id
        
        return config
        
    def validate_config(self, config: Dict[str, Any]) -> bool:
        """验证配置"""
        required_keys = ['robot_id', 'sensors', 'control_rate']
        for key in required_keys:
            if key not in config:
                return False
        return True
```

### ROS2 组件容器 Launch

```python
# launch/component_container.launch.py
from launch import LaunchDescription
from launch_ros.actions import ComposableNodeContainer

def generate_launch_description():
    container = ComposableNodeContainer(
        name='perception_container',
        namespace='',
        package='rclcpp_components',
        executable='component_container',
        composable_node_descriptions=[
            # 相机组件
           ComposableNode(
                package='robot_components',
                plugin='robot_components::CameraComponent',
                name='front_camera',
                parameters=[{'device': '/dev/video0'}]
            ),
            # 激光雷达组件
            ComposableNode(
                package='robot_components',
                plugin='robot_components::LidarComponent',
                name='lidar',
                parameters=[{'frame_rate': 10}]
            ),
            # 感知融合组件
            ComposableNode(
                package='robot_components',
                plugin='robot_components::PerceptionFusion',
                name='fusion'
            )
        ]
    )
    
    return LaunchDescription([container])
```
