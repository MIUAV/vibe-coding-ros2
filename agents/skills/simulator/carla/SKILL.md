---
name: carla
description: CARLA 自动驾驶仿真开发技能 - 车辆动力学、传感器模拟、交通仿真、ROS2 集成
argument-hint: carla仿真 OR 自动驾驶 OR 车辆仿真 OR 传感器模拟
user-invocable: true
---

# CARLA Autonomous Driving Simulation Skill

> 用于 CARLA 自动驾驶仿真环境的配置和开发

---

## 何时使用

当需要以下帮助时使用此技能：
- 安装和配置 CARLA
- 创建车辆和场景
- 配置传感器（相机、雷达、LiDAR）
- 设置交通仿真
- 集成 ROS/ROS2

---

## 快速参考

### 安装 CARLA

```bash
# 方式1: 使用 pip (推荐)
pip install carla

# 方式2: 从源码构建
git clone https://github.com/carla-simulator/carla.git
cd carla
./Build/Linux

# 启动服务器
./CarlaUE4.sh -carla-rpc-port=2000

# 运行示例
python3 -c "import carla; print(carla.__version__)"
```

---

## 基本使用

### 连接仿真

```python
import carla

# 连接到仿真
client = carla.Client('localhost', 2000)
client.set_timeout(10.0)

# 获取世界
world = client.get_world()

# 获取蓝图
blueprint_library = world.get_blueprint_library()

# 加载地图
world = client.load_world('Town01')
```

### 车辆控制

```python
# 获取车辆蓝图
vehicle_bp = world.get_blueprint_library().filter('vehicle.*')[0]

# 生成车辆
transform = carla.Transform(
    carla.Location(x=0, y=0, z=2),
    carla.Rotation(yaw=0)
)
vehicle = world.spawn_actor(vehicle_bp, transform)

# 控制车辆
vehicle.apply_control(carla.VehicleControl(
    throttle=0.5,
    steer=0.0,
    brake=0.0
))

# 停车
vehicle.apply_control(carla.VehicleControl())
```

---

## 传感器配置

### RGB 摄像头

```python
# 创建摄像头
camera_bp = world.get_blueprint_library().find('sensor.camera.rgb')
camera_bp.set_attribute('image_size_x', '1920')
camera_bp.set_attribute('image_size_y', '1080')
camera_bp.set_attribute('fov', '90')

# 安装位置
camera_transform = carla.Transform(
    carla.Location(x=1.5, y=0, z=1.5),
    carla.Rotation(roll=0, pitch=0, yaw=0)
)

# 生成传感器
camera = world.spawn_actor(camera_bp, camera_transform, attach_to=vehicle)

# 接收数据
camera.listen(lambda image: process_image(image))

def process_image(image):
    # 转换为 numpy 数组
    array = np.array(image.raw_data)
    image_rgb = array.reshape((image.height, image.width, 4))
    image_rgb = image_rgb[:, :, :3]
```

### 深度摄像头

```python
# 深度摄像头
depth_bp = world.get_blueprint_library().find('sensor.camera.depth')
depth_bp.set_attribute('image_size_x', '1920')
depth_bp.set_attribute('image_size_y', '1080')

depth_camera = world.spawn_actor(depth_bp, camera_transform, attach_to=vehicle)
depth_camera.listen(lambda image: process_depth(image))

def process_depth(image):
    # 深度值 (米)
    depth = image.get_color_coded_buffer()
```

### 语义分割

```python
# 语义分割摄像头
semantic_bp = world.get_blueprint_library().find('sensor.camera.semantic_segmentation')
semantic_bp.set_attribute('image_size_x', '1920')
semantic_bp.set_attribute('image_size_y', '1080')

semantic_camera = world.spawn_actor(semantic_bp, camera_transform, attach_to=vehicle)
semantic_camera.listen(lambda image: process_semantic(image))

def process_semantic(image):
    # 分割掩码
    seg = image.get_color_coded_buffer()
```

### LiDAR

```python
# 创建 LiDAR
lidar_bp = world.get_blueprint_library().find('sensor.lidar.ray_cast')
lidar_bp.set_attribute('range', '50')
lidar_bp.set_attribute('rotation_frequency', '10')
lidar_bp.set_attribute('points_per_second', '100000')

lidar_transform = carla.Transform(
    carla.Location(x=0, y=0, z=2.0)
)

lidar = world.spawn_actor(lidar_bp, lidar_transform, attach_to=vehicle)

lidar.listen(lambda point_cloud: process_lidar(point_cloud))

def process_lidar(point_cloud):
    # 获取点云数据
    points = np.frombuffer(point_cloud.raw_data, dtype=np.float32)
    points = points.reshape((-1, 4))  # x, y, z, intensity
    
    # 过滤距离
    distance = np.linalg.norm(points[:, :3], axis=1)
    valid = distance < 50
    points = points[valid]
```

### 雷达

```python
# 毫米波雷达
radar_bp = world.get_blueprint_library().find('sensor.other.radar')
radar_bp.set_attribute('range', '100')
radar_bp.set_attribute('horizontal_fov', '30')
radar_bp.set_attribute('vertical_fov', '20')
radar_bp.set_attribute('points_per_second', '1500')

radar_transform = carla.Transform(
    carla.Location(x=2.0, y=0, z=0.5)
)

radar = world.spawn_actor(radar_bp, radar_transform, attach_to=vehicle)

radar.listen(lambda radar_data: process_radar(radar_data))

def process_radar(radar_data):
    for detection in radar_data:
        distance = detection.depth
        azimuth = detection.azimuth
        altitude = detection.altitude
        velocity = detection.velocity
```

### IMU

```python
# IMU 传感器
imu_bp = world.get_blueprint_library().find('sensor.other.imu')
imu_bp.set_attribute('sensor_tick', '0.01')

imu_transform = carla.Transform(carla.Location(x=0, y=0, z=1.0))

imu = world.spawn_actor(imu_bp, imu_transform, attach_to=vehicle)

imu.listen(lambda imu_data: process_imu(imu_data))

def process_imu(imu_data):
    # 加速度
    acceleration = imu_data.accelerometer
    
    # 角速度
    angular_velocity = imu_data.gyroscope
    
    # 航向
    heading = imu_data.compass
```

### GNSS/GPS

```python
# GNSS 传感器
gnss_bp = world.get_blueprint_library().find('sensor.other.gnss')
gnss_bp.set_attribute('sensor_tick', '0.01')

gnss = world.spawn_actor(gnss_bp, imu_transform, attach_to=vehicle)

gnss.listen(lambda gnss_data: process_gnss(gnss_data))

def process_gnss(gnss_data):
    latitude = gnss_data.latitude
    longitude = gnss_data.longitude
    altitude = gnss_data.altitude
```

---

## 地图和场景

### 加载地图

```python
# 列出可用地图
maps = client.get_available_maps()
print(maps)

# 加载地图
world = client.load_world('Town01')

# 获取当前地图
map_name = world.get_map().name
```

### 天气设置

```python
# 设置天气
weather = world.get_weather()

# 太阳位置
weather.sun_azimuth_angle = 45
weather.sun_altitude_angle = -30

# 降雨
weather.precipitation = 50
weather.precipitation_deposits = 25

# 云层
weather.cloudiness = 40

# 应用
world.set_weather(weather)
```

### 时间控制

```python
# 设置时间
world.set_timestamp(carla.Timestamp(seconds=3600))  # 早上6点

# 或使用小时
world.set_time_of_day(carla.Timestamp(hours=18, minutes=30))  # 傍晚
```

---

## 交通仿真

### 生成车辆

```python
# 生成车辆
vehicle_bps = world.get_blueprint_library().filter('vehicle.*')

for i in range(10):
    bp = random.choice(vehicle_bps)
    
    # 随机位置
    transform = random.choice(world.get_map().get_spawn_points())
    
    # 生成
    vehicle = world.try_spawn_actor(bp, transform)
    
    if vehicle:
        # 设置自动驾驶
        vehicle.set_autopilot(True)
```

### 行人

```python
# 生成行人
walker_bp = world.get_blueprint_library().filter('walker.pedestrian.*')[0]

for i in range(20):
    transform = carla.Transform(
        carla.Location(x=random.randint(-50, 50),
                      y=random.randint(-50, 50),
                      z=1.0)
    )
    
    walker = world.try_spawn_actor(walker_bp, transform)
    
    if walker:
        # 应用控制
        controller_bp = world.get_blueprint_library().find('controller.walker')
        controller = world.spawn_actor(controller_bp, carla.Transform(), attach_to=walker)
        
        # 开始行走
        controller.start()
        controller.go_to_position(carla.Location(x=10, y=10, z=1))
```

### 交通标志

```python
# 获取交通标志
traffic_lights = world.get_actors().filter('traffic.traffic_light')

for light in traffic_lights:
    state = light.get_state()
    print(f"Traffic light: {state}")
    
    # 设置状态
    if state == carla.TrafficLightState.Red:
        light.set_state(carla.TrafficLightState.Green)
```

---

## 车辆动力学

### 物理控制

```python
# 物理控制 (更真实的物理)
vehicle.enable_collision True
vehicle.enable_pedals_invasion False

# 获取物理状态
physics = vehicle.get_physics_transform()

# 设置速度限制
vehicle.set_speed_limit(30.0)  # km/h
```

### 车辆参数

```python
# 获取车辆属性
vehicle_snapshot = world.get_actor(vehicle.id)

# 查找车辆
vehicles = world.get_actors().filter('vehicle.*')

for v in vehicles:
    # 速度
    velocity = v.get_velocity()
    speed = 3.6 * np.linalg.norm([velocity.x, velocity.y, velocity.z])  # km/h
    
    # 加速度
    acceleration = v.get_acceleration()
    
    # 变换
    transform = v.get_transform()
    location = transform.location
    rotation = transform.rotation
```

---

## ROS2 集成

### 安装 CARLA ROS

```bash
# 安装 CARLA ROS 桥接
sudo apt install ros-humble-carla-ros-bridge
sudo apt install ros-humble-carla-msgs

# 或从源码
cd ~/ros2_ws/src
git clone https://github.com/carla-simulator/ros-bridge.git
cd ros-bridge
colcon build
```

### 启动 ROS 桥接

```bash
# 启动 CARLA
./CarlaUE4.sh -carla-rpc-port=2000

# 启动 ROS 桥接
ros2 launch carla_ros_bridge carla_ros_bridge.launch.py
```

### 自定义 ROS2 节点

```python
# carla_control.py
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from sensor_msgs.msg import Image, PointCloud2
import carla
import numpy as np

class CarlaControl(Node):
    def __init__(self):
        super().__init__('carla_control')
        
        # 连接 CARLA
        self.client = carla.Client('localhost', 2000)
        self.client.set_timeout(10.0)
        self.world = self.client.get_world()
        
        # 车辆
        self.vehicle = None
        
        # 订阅 cmd_vel
        self.create_subscription(
            Twist,
            '/carla/cmd_vel',
            self.cmd_vel_callback,
            10)
        
    def cmd_vel_callback(self, msg):
        if self.vehicle:
            control = carla.VehicleControl(
                throttle=max(0, msg.linear.x),
                steer=msg.angular.z,
                brake=max(0, -msg.linear.x)
            )
            self.vehicle.apply_control(control)
```

---

## 数据记录

### 记录仿真

```python
# 开始记录
world.start_recorder('recording.log')

# 停止记录
world.stop_recorder()

# 回放
client.replay_file('recording.log', 0, 0, 0)
```

### 自定义数据采集

```python
# 采集数据
def collect_data(sensor, filename):
    sensor.listen(lambda data: save_data(data, filename))

def save_data(data, filename):
    if isinstance(data, carla.Image):
        data.save_to_disk(filename)
    elif isinstance(data, carla.PointCloud):
        points = np.frombuffer(data.raw_data, dtype=np.float32)
        np.save(filename, points)
```

---

## 场景配置

### 创建自定义场景

```python
# 自定义场景
world = client.load_world('Town01')

# 清理现有actors
world.tick()
world.apply_settings(carla.WorldSettings(synchronous_mode=True))

# 删除所有车辆
for actor in world.get_actors().filter('vehicle.*'):
    actor.destroy()

# 删除所有行人
for actor in world.get_actors().filter('walker.*'):
    actor.destroy()

# 关闭所有传感器
for actor in world.get_actors().filter('sensor.*'):
    actor.destroy()
```

---

## 常见问题

### 问题 1: 连接失败

**解决方案**：
- 确认 CARLA 服务器正在运行
- 检查端口 (默认 2000)
- 验证防火墙

### 问题 2: 传感器无数据

**解决方案**：
- 确认传感器已启用 listen
- 检查 attach_to
- 验证数据回调

### 问题 3: 车辆行为异常

**解决方案**：
- 检查 autopilot 状态
- 验证物理参数
- 确认地图匹配

---

## 相关资源

- [CARLA 文档](https://carla.readthedocs.io/)
- [CARLA ROS Bridge](https://github.com/carla-simulator/ros-bridge)
- [CARLA Examples](https://github.com/carla-simulator/carla/blob/master/PythonAPI/examples/)

---

## 另见

- [vehicle-dynamics](./vehicle-dynamics/) - 车辆动力学
- [sensor-config](./sensor-config/) - 传感器配置
- [gazebo-harmonic](../gazebo-harmonic/) - Gazebo 仿真
- [rviz2](../rviz2/) - RViz2 可视化
- [unreal-engine](../unreal-engine/) - Unreal Engine