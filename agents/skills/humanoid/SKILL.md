---
name: humanoid
description: 人形机器人导航堆栈 - 双足行走控制、平衡算法、全身运动规划
argument-hint: "人形机器人导航" / "双足行走" / "人形步态"
user-invocable: true
---

# 人形机器人导航技能

> 用于开发双足人形机器人的运动控制和导航系统

---

## 何时使用

当需要以下帮助时使用此技能：
- 实现双足行走
- 配置平衡控制
- 全身运动规划
- 复杂地形适应

---

## 快速参考

### 坐标系定义

```
人形机器人坐标系:
- X: 前进方向
- Y: 侧向 (左负右正)
- Z: 垂直向上
```

### 步态规划

```python
# 步态周期参数
gait_params = {
    "step_height": 0.05,      # 步高 (m)
    "step_length": 0.3,       # 步长 (m)
    "step_period": 0.6,        # 周期 (s)
    "support_ratio": 0.6,      # 支撑相占比
}
```

---

## 运动控制

### 逆运动学

```python
# 腿部 IK
def inverse_kinematics(target_pos):
    # 输入: 目标足端位置 (x, y, z)
    # 输出: 关节角度 [hip_pitch, hip_roll, knee, ankle_pitch, ankle_roll]
    
    # 计算腿长
    L = sqrt(x**2 + y**2 + z**2)
    
    # 膝关节角度
    knee_angle = 2 * acos(L / (2 * L_leg))
    
    # 髋关节角度
    hip_angle = atan2(z, x) + acos(L_leg * sin(knee_angle/2) / (L/2))
    
    return [hip_angle, 0, knee_angle, -hip_angle, 0]
```

### ZMP 平衡控制

```python
# Zero Moment Point 计算
def compute_zmp(forces, torques):
    # 地面反作用力
    F_total = sum(forces)
    
    # ZMP 位置
    x_zmp = sum(torques_y) / F_total.z
    y_zmp = -sum(torques_x) / F_total.z
    
    return (x_zmp, y_zmp)
```

---

## 导航功能

### 路径规划

```python
# 人形专用路径规划
class HumanoidPlanner:
    def plan(self, start, goal):
        # 考虑:
        # - 楼梯通行
        # - 狭窄通道
        # - 不平整地面
        
        path = []
        # ...
        return path
```

### 地形适应

```yaml
terrain_adaptation:
  max_step_height: 0.15   # 最大台阶高度
  max_slope: 20           # 最大坡度 (度)
  min_pass_width: 0.4     # 最小通行宽度
```

---

## 常用框架

### ROS 2 功能包

| 包 | 功能 |
|----|------|
| `humanoid_nav` | 导航堆栈 |
| `biped_control` | 双足控制器 |
| `whole_body_control` | 全身控制 |

---

## 相关文档

- [人形机器人指南](https://github.com/robotics/humanoid)
- [Walking Controllers](https://github.com/leggedrobotics)