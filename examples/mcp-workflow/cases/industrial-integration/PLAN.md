# industrial-integration Case — 工业机械臂 ROS2 集成

## 背景

工业机械臂（ABB、KUKA、FANUC、UR）传统使用专用控制器（IRC5、KUKA KRC、Cyberware）。ROS2 集成层将这些专有协议转换为标准 ROS2 接口，实现与 MoveIt2、Industrial Core 的无缝对接。

**核心协议：**
- Modbus TCP：寄存器读写（IO、状态字）
- PROFINET：实时控制（PN 机器人）
- EtherCAT：高速运动控制（总线型机器人）
- Socket TCP：自定义协议（UR、ABB）

---

## 用户需求

```
用户：KUKA iiwa 7轴机械臂，集成到 ROS2，控制末端以 0.5m/s 速度画圆，目标位置 (0.5, 0, 0.3)
```

---

## 技术方案

### KUKA RSI（Robot Sensor Interface）

```
ROS2 → RSI → KUKA 控制器 → 电机驱动器
```

### 运动控制架构

```
MoveIt2（轨迹规划）
    ↓
ros2_controllers（关节轨迹控制器）
    ↓
KUKA RSI（位置/力矩指令）
```

---

## 执行流程

### Step 1: 生成包

```bash
bash scripts/generators/ros2-package-generator.sh kuka_iiwa_control cpp
```

### Step 2: 启动 RSI 连接

```bash
ros2 launch kuka_iiwa_control rsi.launch.py
```

### Step 3: MoveIt2 控制

```bash
ros2 launch kuka_iiwa_moveit_config move_group.launch.py
```

### Step 4: 验证

```bash
bash scripts/ros2-build-verify-loop.sh kuka_iiwa_control
```
