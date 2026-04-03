---
name: environment-setup
description: ManiSkill3 环境配置技能 - 物理引擎、传感器、渲染设置
argument-hint: ManiSkill3环境 OR 物理配置 OR 渲染设置
user-invocable: true
---

# ManiSkill3 Environment Setup Skill

> 用于配置 ManiSkill3 环境

---

## 何时使用

当需要以下帮助时使用此技能：
- 配置物理引擎
- 设置传感器
- 调整渲染参数
- 环境变量配置

---

## 快速参考

### 初始化环境

```python
import mani_skill3
from mani_skill3 import env

env = mani_skill3.make("PickCube-v0")
obs = env.reset()
```

---

## 物理配置

### 物理引擎

```python
# 配置物理参数
env_cfg = {
    "physx": {
        "num_threads": 4,
        "solver_type": 1,
        "use_gpu": True,
    },
    "gravity": [0, 0, -9.81],
    "dt": 0.005
}
```

---

## 传感器配置

### 相机

```python
sensor_cfg = {
    "rgb_camera": {
        "resolution": [640, 480],
        "channel": "rgb",
        "intrinsics": [500, 0, 320, 0, 500, 240, 0, 0, 1]
    },
    "depth_camera": {
        "resolution": [640, 480],
        "channel": "depth",
        "depth_scale": 1000.0
    }
}
```

---

## 常见问题

### 问题 1: 渲染慢

**解决方案**：减少并行环境数量，降低分辨率

---

## 另见

- [manipulation-tasks](../manipulation-tasks/) - 操作任务
- [dataset-playback](../dataset-playback/) - 数据回放