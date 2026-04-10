# Manipulator Context

## 运动规划类型
| 类型 | 说明 | API |
|------|------|-----|
| 关节空间（Joint Space）| 直接指定各关节角度 | `set_joint_value_target()` |
| 笛卡尔空间（Cartesian）| 末端执行器位姿 | `set_pose_target()` |
| 抓取规划（Grasp）| 目标物体 → 抓取姿态 | `grasp planning` |

## MoveIt2 核心组件
```
move_group → planning_pipeline → constraint_sampler
     ↓
collision_world → fcl (碰撞检测)
     ↓
trajectory_execution → controller_manager
```

## 关键依赖
```cmake
find_package(moveit_ros_planning_interface REQUIRED)
find_package(moveit_visual_tools REQUIRED)
find_package(moveit_kinematics REQUIRED)
find_package(moveit_msgs REQUIRED)  # Grasp, Pickup, MoveItErrorCode
```

## 核心 Service / Action
| 名称 | 类型 | 用途 |
|------|------|------|
| `/plan` | `MotionPlanRequest` | 运动规划请求 |
| `/execute` | `ExecuteTrajectory` | 轨迹执行 |
| `/pickup` | `Pickup` | 抓取动作 |
| `/place` | `Place` | 放置动作 |

## URDF/XACRO 关键约定
```xml
<xacro:macro name="robot_base" params="prefix">
  <group name="${prefix}arm">
    <chain base_link="${prefix}base_link" tip_link="${prefix}ee_link" />
  </group>
  <group name="${prefix}gripper">
    <joint name="${prefix}finger_joint" />
  </group>
  <xacro:robotiq_85_gripper prefix="${prefix}" parent="${prefix}ee_link" />
</xacro:macro>
```

## 生成器选择
- 包生成：`ros2-package-generator.sh <pkg> cpp moveit_ros_planning_interface,moveit_visual_tools`
- MoveIt节点：`ros2-moveit-generator.sh move_group|cartesian|pick_place|mobile_manipulator`
- 仿真：`ros2-simulator-generator.sh manipulator`
- 标定：`ros2-camera-calibration-generator.sh hand_eye`

## 碰撞检测配置
```yaml
planning_scene_monitor:
  publish_robot_description: true
  publish_robot_description_semantic: true
  publish_planning_scene: true

ompl:
  planners:
    PRM: # 关节空间
    RRTConnect: # 快速探索随机树
    TRAC_IK: # 逆运动学
```
