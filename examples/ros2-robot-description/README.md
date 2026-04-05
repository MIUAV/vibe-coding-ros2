# ros2-robot-description — URDF/Xacro 机器人描述

> 差速驱动轮式机器人的完整 URDF 描述：base_link + 2 wheels + caster + laser。

## TF2 树

```
world → base_footprint → base_link → laser_link
                              → wheel_left
                              → wheel_right
                              → caster_link
```

## 文件结构

```
ros2-robot-description/
├── urdf/
│   └── robot.urdf          # 完整 URDF（无 xacro）
├── xacro/
│   └── robot.urdf.xacro    # Xacro 版本（参数化）
└── launch/
    └── display.launch.py   # robot_state_publisher + rviz2
```

## 使用方法

### 在自己的 package 中使用

```bash
# 在 package.xml 添加
<exec_depend>robot_state_publisher</exec_depend>
<exec_depend>joint_state_publisher_gui</exec_depend>

# 在代码中
#include <robot_state_publisher/robot_state_publisher.h>
```

### 在 RViz 中显示

```bash
# 方式1: launch 文件
ros2 launch ros2_robot_description display.launch.py

# 方式2: 手动
ros2 run robot_state_publisher robot_state_publisher \
  --ros-args -p robot_description:=$(xacro robot.urdf)

# 方式3: joint_state_publisher GUI
ros2 run joint_state_publisher joint_state_publisher
```

## URDF 检查

```bash
# 检查 URDF 语法
check_urdf robot.urdf

# 查看 link/joint
urdf_to_graphiz robot.urdf  # 生成 PDF

# 在 ROS2 中
ros2 run robot_state_publisher robot_state_publisher --ros-args -p robot_description:="$(xacro robot.urdf)"
```

## 关键概念

| 元素 | 说明 |
|------|------|
| `link` | 刚体（visual/collision/inertial） |
| `joint` | 连接关系（fixed/revolute/continuous） |
| `visual` | 外观几何 |
| `collision` | 碰撞几何 |
| `inertial` | 质量和惯性矩阵 |
