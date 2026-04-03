---
name: topic-service-design
description: 话题服务设计技能 - 话题命名、消息设计、服务 vs 话题、Action 设计
argument-hint: "话题设计" / "topic" / "service" / "命名规范" / "message design"
user-invocable: true
---

# 话题服务设计技能

> ROS2 话题和服务设计规范

---

## 何时使用

当需要以下帮助时使用此技能：
- 话题命名规范
- 消息设计
- 服务 vs 话题选择
- Action 设计
- 接口兼容性

---

## 核心设计原则

### 话题命名规范

```
# 命名空间结构
/robot/{robot_id}/
  ├── perception/
  │   ├── camera/
  │   │   ├── image_raw        # 原始图像
  │   │   ├── image_rectified  # 校正后图像
  │   │   └── camera_info      # 相机参数
  │   ├── lidar/
  │   │   ├── scan             # 激光扫描
  │   │   └── points           # 点云
  │   └── fusion/
  │       └── obstacles        # 融合障碍物
  ├── control/
  │   ├── cmd_vel              # 速度命令
  │   └── trajectory           # 轨迹
  └── state/
      ├── odometry             # 里程计
      └── battery             # 电池状态
```

### 消息设计

```python
# detection_msgs/msg/ObjectArray.msg
std_msgs/Header header

string[] class_names
float64[] confidences
geometry_msgs/Pose[] poses
geometry_msgs/Vector3[] dimensions

# 自定义消息示例
# my_robot_msgs/msg/RobotStatus.msg
std_msgs/Header header

uint8 robot_state  # 0=idle, 1=moving, 2=charging
uint8 battery_level
float32 cpu_temperature
float32 memory_usage
geometry_msgs/Pose robot_pose
```

### 服务设计

```python
# 服务定义
"""
服务 vs 话题选择指南:

使用话题 (Topic) 当:
- 数据流式传输 (传感器数据、控制命令)
- 多个订阅者
- 需要实时性
- 单向通信

使用服务 (Service) 当:
- 请求-响应模式
- 需要返回值
- 偶尔调用
- 同步操作
"""

# 示例: 地图服务
# my_robot_msgs/srv/GetMap.srv
---
nav_msgs/OccupancyGrid map
bool success
string message
```

### Action 设计

```python
# 导航 Action
# my_robot_msgs/action/NavigateToPose.action

# Goal
geometry_msgs/PoseStamped target_pose
float32 tolerance  # 容许误差
---
# Result
bool success
string message
geometry_msgs/PoseStamped final_pose
---
# Feedback
float32 distance_remaining
geometry_msgs/PoseStamped current_pose
nav_msgs/Path planned_path
```

### ROS2 接口最佳实践

```python
# 接口兼容性检查
class InterfaceCompatibility:
    @staticmethod
    def check_message_compatibility(pub_type, sub_type):
        """检查消息类型兼容性"""
        # 同一类型或子类型
        return pub_type == sub_type or issubclass(sub_type, pub_type)
        
    @staticmethod
    def get_missing_fields(msg_type_a, msg_type_b):
        """获取缺失字段"""
        fields_a = set(msg_type_a.get_fields_and_field_types().keys())
        fields_b = set(msg_type_b.get_fields_and_field_types().keys())
        return fields_a - fields_b
```
