---
name: vehicle-dynamics
description: CARLA 车辆动力学技能 - 物理控制、轮胎模型、动力传动
argument-hint: CARLA车辆 OR 车辆动力学 OR 物理控制
user-invocable: true
---

# CARLA Vehicle Dynamics Skill

> 用于 CARLA 车辆动力学

---

## 快速参考

### 车辆控制

```python
import carla

# 应用控制
vehicle.apply_control(carla.VehicleControl(
    throttle=0.5,
    steer=0.0,
    brake=0.0
))
```

---

## 另见

- [sensor-config](../sensor-config/) - 传感器配置