---
name: remote-api
description: CoppeliaSim 远程 API 技能 - Python/C++ 远程控制、传感器读取、仿真控制
argument-hint: CoppeliaSim API OR 远程控制 OR Python API
user-invocable: true
---

# CoppeliaSim Remote API Skill

> 用于 CoppeliaSim 远程 API

---

## 快速参考

### Python API

```python
import sim

client = sim.simxStart('127.0.0.1', 19997, True, True, 5000, 5)

# 获取对象
ret, robot = sim.simxGetObjectHandle(client, 'Robot', sim.simx_opmode_blocking)

# 设置电机速度
sim.simxSetJointTargetVelocity(client, motor, 1.0, sim.simx_opmode_streaming)

# 读取传感器
ret, sensorData = sim.simxReadVisionSensor(client, sensor, sim.simx_opmode_buffer)
```

---

## 另见

- [lua-scripts](../lua-scripts/) - Lua 脚本