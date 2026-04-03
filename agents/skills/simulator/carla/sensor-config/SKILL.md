---
name: sensor-config
description: CARLA 传感器配置技能 - 相机、雷达、LiDAR、IMU 配置
argument-hint: CARLA传感器 OR 相机配置 OR 雷达配置
user-invocable: true
---

# CARLA Sensor Configuration Skill

> 用于 CARLA 传感器配置

---

## 快速参考

### 相机配置

```python
camera_bp = world.get_blueprint_library().find('sensor.camera.rgb')
camera_bp.set_attribute('image_size_x', '1920')
camera_bp.set_attribute('image_size_y', '1080')

camera = world.spawn_actor(camera_bp, transform, attach_to=vehicle)
camera.listen(lambda image: process_image(image))
```

---

## 传感器类型

### LiDAR

```python
lidar_bp = world.get_blueprint_library().find('sensor.lidar.ray_cast')
lidar_bp.set_attribute('range', '50')
lidar_bp.set_attribute('points_per_second', '100000')
```

---

## 另见

- [vehicle-dynamics](../vehicle-dynamics/) - 车辆动力学