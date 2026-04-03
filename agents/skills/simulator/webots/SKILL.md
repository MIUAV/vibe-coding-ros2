---
name: webots
description: Webots 机器人仿真开发技能 - 机器人建模、控制器开发、传感器配置、ROS/ROS2 集成
argument-hint: webots仿真 OR webots机器人 OR 创建控制器 OR 传感器配置
user-invocable: true
---

# Webots Robot Simulation Skill

> 用于 Webots 机器人仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 Webots
- 创建机器人模型
- 编写控制器代码
- 配置传感器和执行器
- 集成 ROS/ROS2

---

## 快速参考

### 安装 Webots

```bash
# 下载 Webots
# https://cyberbotics.com/#download

# Ubuntu 安装
sudo apt install ./webots_*.deb

# 或使用 AppImage
chmod +x webots.AppImage
./webots.AppImage
```

### 启动 Webots

```bash
# 从命令行启动
webots

# 打开特定世界文件
webots /path/to/world.wbt
```

---

## 项目结构

```
my_project/
├── worlds/
│   └── my_robot.wbt          # 世界文件
├── protos/
│   └── MyRobot.proto         # 自定义 PROTO 定义
├── controllers/
│   ├── my_controller/        # 控制器目录
│   │   ├── my_controller.c  # C 控制器
│   │   ├── Makefile
│   │   └── (其他文件)
│   └── python_controller/    # Python 控制器
│       └── robot.py
└── libraries/
    └── (外部库)
```

---

## 创建机器人模型

### 基本 PROTO 文件

```protobuf
PROTO MyRobot [
  field SFVec3f    translation  0 0 0
  field SFRotation rotation     0 1 0 0
  field SFString   name         "my_robot"
  field SFFloat    wheelRadius  0.1
]
{
  Robot {
    translation IS translation
    rotation IS rotation
    name IS name
    children [
      # 主体
      Shape {
        appearance Appearance {
          material Material {
            diffuseColor 0.3 0.3 0.3
          }
        }
        geometry Box {
          size 0.5 0.3 0.1
        }
      }
      
      # 轮子
      HingeJoint {
        jointParameters HingeJointParameters {
          anchor 0.2 0.15 0
        }
        device Slot {
          device Slot {
            wheel Motor {
              maxVelocity 10
            }
          }
        }
        endPoint Solid {
          children [
            Shape {
              appearance Appearance {
                material Material { diffuseColor 0.1 0.1 0.1 }
              }
              geometry Cylinder {
                height 0.05
                radius 0.1
              }
            }
          ]
          boundingObject Box {
            size 0.1 0.1 0.05
          }
        }
      }
    ]
    controller "my_controller"
    boundingObject Box {
      size 0.5 0.3 0.1
    }
  }
}
```

### 完整机器人示例 - 差速驱动

```protobuf
PROTO DiffDriveRobot [
  field SFVec3f    translation  0 0 0.1
  field SFRotation rotation     0 1 0 0
  field SFString   name         "diff_drive"
  field SFFloat    wheelRadius  0.1
  field SFFloat    axleLength   0.3
]
{
  Robot {
    translation IS translation
    rotation IS rotation
    name IS name
    
    children [
      # 主体
      Solid {
        children [
          Shape {
            appearance Appearance {
              material Material {
                diffuseColor 0.4 0.4 0.8
              }
            }
            geometry Box {
              size 0.4 0.3 0.1
            }
          }
        ]
      }
      
      # 左轮
      HingeJoint {
        jointParameters HingeJointParameters {
          anchor 0 0.15 0
          axis 1 0 0
        }
        device Slot {
          device Slot {
            wheel Motor {
              maxVelocity 10
              maxTorque 10
            }
          }
        }
        endPoint Solid {
          children [
            Shape {
              appearance Appearance {
                material Material { diffuseColor 0.2 0.2 0.2 }
              }
              geometry Cylinder {
                height 0.05
                radius IS wheelRadius
              }
            }
          ]
          boundingObject Cylinder {
            height 0.05
            radius IS wheelRadius
          }
        }
      }
      
      # 右轮
      HingeJoint {
        jointParameters HingeJointParameters {
          anchor 0 -0.15 0
          axis 1 0 0
        }
        device Slot {
          device Slot {
            wheel Motor {
              maxVelocity 10
              maxTorque 10
            }
          }
        }
        endPoint Solid {
          children [
            Shape {
              appearance Appearance {
                material Material { diffuseColor 0.2 0.2 0.2 }
              }
              geometry Cylinder {
                height 0.05
                radius IS wheelRadius
              }
            }
          ]
          boundingObject Cylinder {
            height 0.05
            radius IS wheelRadius
          }
        }
      }
      
      # 激光雷达
      Lidar {
        name "lidar"
        translation 0.2 0 0.05
        numberOfLayers 1
        fieldOfView 3.14
        maxRange 10
        resolution 0.01
      }
      
      # 摄像头
      Camera {
        name "camera"
        translation 0.15 0 0.05
        width 640
        height 480
        fieldOfView 1.0
      }
    ]
    
    controller "my_controller"
    boundingObject Box {
      size 0.5 0.4 0.15
    }
  }
}
```

---

## 控制器开发

### Python 控制器

```python
# controllers/my_robot/robot.py
from controller import Robot, Camera, Lidar

class MyRobot:
    def __init__(self):
        self.robot = Robot()
        self.time_step = int(self.robot.getBasicTimeStep())
        
        # 获取执行器
        self.left_motor = self.robot.getMotor('left_wheel')
        self.right_motor = self.robot.getMotor('right_wheel')
        
        # 获取传感器
        self.camera = self.robot.getCamera('camera')
        self.lidar = self.robot.getLidar('lidar')
        self.gps = self.robot.getGPS('gps')
        self.gyro = self.robot.getGyro('gyro')
        
        # 启用传感器
        self.camera.enable(self.time_step)
        self.lidar.enable(self.time_step)
        self.gps.enable(self.time_step)
        self.gyro.enable(self.time_step)
        
    def run(self):
        while self.robot.step(self.time_step) != -1:
            # 获取传感器数据
            image = self.camera.getImage()
            range_data = self.lidar.getRangeImage()
            position = self.getPosition()
            
            # 控制逻辑
            self.set_velocity(1.0, 1.0)
            
    def set_velocity(self, left_vel, right_vel):
        self.left_motor.setVelocity(left_vel)
        self.right_motor.setVelocity(right_vel)
        
    def getPosition(self):
        gps_values = self.gps.getValues()
        return gps_values

# 主程序
robot = MyRobot()
robot.run()
```

### C 控制器

```c
// controllers/my_robot/my_robot.c
#include <webots/robot.h>
#include <webots/motor.h>
#include <webots/distance_sensor.h>
#include <webots/camera.h>

#define TIME_STEP 10

int main(int argc, char **argv) {
    wb_robot_init();
    
    // 获取设备
    WbDeviceTag left_motor = wb_robot_get_device("left_wheel");
    WbDeviceTag right_motor = wb_robot_get_device("right_wheel");
    WbDeviceTag camera = wb_robot_get_device("camera");
    
    // 设置电机模式
    wb_motor_set_position(left_motor, INFINITY);
    wb_motor_set_position(right_motor, INFINITY);
    
    // 启用摄像头
    wb_camera_enable(camera, TIME_STEP);
    
    while (wb_robot_step(TIME_STEP) != -1) {
        // 获取摄像头数据
        const unsigned char *image = wb_camera_get_image(camera);
        
        // 设置速度
        wb_motor_set_velocity(left_motor, 2.0);
        wb_motor_set_velocity(right_motor, 2.0);
    }
    
    wb_robot_cleanup();
    return 0;
}
```

---

## 传感器配置

### GPS

```python
gps = self.robot.getGPS('gps')
gps.enable(self.time_step)
position = gps.getValues()  # [x, y, z]
```

### IMU (Gyro + Accelerometer)

```python
gyro = self.robot.getGyro('gyro')
accelerometer = self.robot.getAccelerometer('accelerometer')
gyro.enable(self.time_step)
accelerometer.enable(self.time_step)

angular_velocity = gyro.getValues()  # [wx, wy, wz]
linear_acceleration = accelerometer.getValues()  # [ax, ay, az]
```

### 距离传感器

```python
# 红外传感器
ds = self.robot.getDistanceSensor('ds_left')
ds.enable(self.time_step)
distance = ds.getValue()  # 0-4095 (距离越近值越大)
```

### 编码器

```python
# 轮子编码器
left_encoder = self.robot.getEncoder('left_wheel')
right_encoder = self.robot.getEncoder('right_wheel')
left_encoder.enable(self.time_step)
right_encoder.enable(self.time_step)

left_angle = left_encoder.getValue()  # 弧度
```

---

## ROS2 集成

### 安装 webots_ros2 包

```bash
# 安装 ROS2 包
sudo apt install ros-humble-webots-ros2

# 或从源码
cd ~/ros2_ws/src
git clone https://github.com/cyberbotics/webots_ros2.git
cd webots_ros2
rosdep install -r --from-paths . --ignore-src -y
colcon build
```

### 启动 Webots

```python
# launch/webots.launch.py
from launch import LaunchDescription
from launch_ros.actions import Node
from launch.actions import IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource

def generate_launch_description():
    return LaunchDescription([
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(
                '/opt/webots/projects/default/worlds/ros2.launch.py'
            )
        ),
        
        Node(
            package='webots_ros2_driver',
            executable='webots_ros2_driver',
            output='screen',
            parameters=[{
                'robot_description': 'robot_description',
                'robot_name': 'my_robot',
            }]
        )
    ])
```

### 自定义 ROS2 控制器

```python
# ros2_driver/my_driver.py
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import Image

class WebotsDriver(Node):
    def __init__(self):
        super().__init__('webots_driver')
        
        # 订阅 cmd_vel
        self.cmd_vel_sub = self.create_subscription(
            Twist,
            '/cmd_vel',
            self.cmd_vel_callback,
            10)
        
        # 发布图像
        self.image_pub = self.create_publisher(Image, '/camera', 10)
        
    def cmd_vel_callback(self, msg):
        # 转换为 Webots motor 控制
        velocity = (msg.linear.x + msg.angular.z * 0.15) / 0.1
        # 设置电机速度
```

---

## 世界文件

### 基本世界

```protobuf
#WorldInfo {
#  basicTimeStep 10
#  FPS 30
#  coordinateSystem "NUE"
#}

Viewpoint {
  orientation -0.3 0.9 0.3 2.5
  position -3 -3 2
}

Background {
  skyColor 0.5 0.7 1.0
}

Floor {
  size 10 10
  tileSize 1 1
  appearance PBRAppearance {
    baseColor 0.5 0.5 0.5
    roughness 1
  }
}

DEF MY_ROBOT DiffDriveRobot {
  translation 0 0 0.1
}
```

---

## 常见问题

### 问题 1: 控制器无法编译

**解决方案**：
- 检查 Makefile 路径
- 确认依赖库
- 验证编译器版本

### 问题 2: 传感器数据为 0

**解决方案**：
- 确认 enable() 已调用
- 检查时间步长
- 验证传感器名称

### 问题 3: ROS 连接失败

**解决方案**：
- 检查 ROS_DOMAIN_ID
- 确认话题名称
- 验证包路径

---

## 相关资源

- [Webots 官方文档](https://cyberbotics.com/doc/guide/index)
- [Webots ROS2](https://github.com/cyberbotics/webots_ros2)
- [Webots 模型库](https://cyberbotics.com/models/)

---

## 另见

- [proto-models](./proto-models/) - PROTO 模型
- [robot-controllers](./robot-controllers/) - 机器人控制器
- [ros2-integration](./ros2-integration/) - ROS2 集成
- [gazebo-harmonic](../gazebo-harmonic/) - Gazebo 仿真
- [pybullet](../pybullet/) - PyBullet 仿真