# aerial-photography Case — 航拍无人机控制

## 背景

航拍无人机（UAV）需要同时管理飞行控制、相机云台、任务规划。ROS2 可以对接 PX4/ArduPilot 的 MAVLink 协议，实现自主飞行和拍照任务。

**应用场景：**
- 测绘建模（3D reconstruction）
- 电力巡检
- 影视航拍

---

## 用户需求

```
用户：控制无人机从起飞点 (0,0,20) 飞往 5 个航点，执行拍照任务，然后返回
```

---

## 技术方案

### MAVLink + ROS2

```
ROS2 → mavros → MAVLink → PX4/ArduPilot
```

### 航点任务

```
WP1: (0, 0, 20) — 起飞
WP2: (10, 5, 20) — 拍照点1
WP3: (20, 0, 20) — 拍照点2
WP4: (10, -5, 20) — 拍照点3
WP5: (0, 0, 30) — 悬停
WP6: (0, 0, 20) — 返航
```

---

## 执行流程

### Step 1: 生成包

```bash
bash scripts/generators/ros2-package-generator.sh aerial_photo python
```

### Step 2: 启动 MAVROS

```bash
ros2 launch mavros apm.launch fcu_url:=serial:///dev/ttyUSB0:57600
```

### Step 3: 验证

```bash
bash scripts/ros2-build-verify-loop.sh aerial_photo
```
